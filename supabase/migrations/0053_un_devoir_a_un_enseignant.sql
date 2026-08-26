-- 0053 — Un devoir sans enseignant n'existe pas.
--
-- 0050 et 0052 ont rendu `fourni_par` possible. Facultatif, il ne servait qu'à
-- ceux qui pensaient à le renseigner — c'est-à-dire, le soir, à personne. Et une
-- attribution oubliée est invisible : le devoir se crée, l'enfant le fait, et
-- seul le professeur constate, des semaines plus tard, qu'il n'a jamais rien vu.
--
-- Un devoir vient de l'école. S'il n'est rattaché à personne, on ne sait ni qui
-- l'a donné, ni qui doit en lire les copies, ni qui le corrigera. Autant ne pas
-- le créer.
--
-- ---------------------------------------------------------------------------
-- DEUX SITUATIONS, DEUX MESSAGES
--
-- Le blocage arrive dans deux cas très différents, et les confondre enverrait
-- chercher au mauvais endroit :
--
--   il existe un enseignant de la matière, on a juste oublié de le désigner
--     → « choisissez-le dans la liste », c'est l'affaire de trois secondes.
--
--   aucun enseignant de cette matière n'est rattaché au dossier
--     → il faut l'inviter, et c'est une démarche.
--
-- Le second cas est le plus utile des deux. C'est souvent le seul moment où une
-- famille s'aperçoit qu'il manque quelqu'un : elle veut saisir le devoir de
-- mathématiques du soir, et découvre que le professeur de mathématiques n'a
-- jamais rejoint le dossier. Un message générique lui ferait chercher un bug.
-- ---------------------------------------------------------------------------

-- ------------------------------------------------------------- les missions

create or replace function verifier_le_fournisseur()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_libelle text;
  v_candidats integer;
begin
  -- Un devoir doit dire de qui il vient. Les autres natures n'y sont pas
  -- tenues : un entraînement composé par le référent n'a pas d'enseignant
  -- derrière lui, et l'exiger bloquerait le transversal.
  if new.nature::text = 'devoir' and new.fourni_par is null then
    select libelle into v_libelle from matieres where code = new.matiere_code;

    select count(*) into v_candidats
    from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.retire_le is null
      and i.role = 'enseignant'
      and (new.matiere_code is null or intervenant_couvre(i.id, new.matiere_code));

    if v_candidats = 0 then
      raise exception 'Aucun enseignant de % n''est rattaché au dossier. Un devoir vient de l''école : sans savoir de qui, personne ne pourra en lire les copies ni le corriger. Invitez l''enseignant, ou demandez au référent de le faire.',
        coalesce(v_libelle, 'cette matière');
    else
      raise exception 'Indiquez l''enseignant dont vient ce devoir : il est le seul à pouvoir en lire les copies et le noter.';
    end if;
  end if;

  if new.fourni_par is null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.profil_id = new.fourni_par
      and i.retire_le is null
      and i.role = 'enseignant'
      and (new.matiere_code is null or intervenant_couvre(i.id, new.matiere_code))
  ) then
    raise exception 'Le travail doit être attribué à un enseignant de cette matière, rattaché à l''enfant.';
  end if;

  return new;
end;
$$;

-- ------------------------------------------------------------- les supports

-- Même règle sur le document scanné. Un support de type « devoir » ou
-- « évaluation » vient nécessairement de l'école ; un support de type « cours »
-- ou « autre » peut venir d'ailleurs — un manuel, une fiche trouvée par un
-- parent — et n'a personne à qui être attribué.
create or replace function verifier_le_fournisseur_du_support()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_libelle text;
  v_candidats integer;
begin
  if new.type_support in ('devoir', 'evaluation') and new.fourni_par is null then
    -- Sauf si celui qui dépose est lui-même l'enseignant de la matière : il est
    -- alors la provenance, et se désigner soi-même serait une formalité vide.
    if exists (
      select 1 from intervenants_enfant i
      where i.enfant_id = new.enfant_id
        and i.profil_id = new.depose_par
        and i.retire_le is null
        and i.role = 'enseignant'
        and intervenant_couvre(i.id, new.matiere_code)
    ) then
      new.fourni_par := new.depose_par;
      return new;
    end if;

    select libelle into v_libelle from matieres where code = new.matiere_code;

    select count(*) into v_candidats
    from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, new.matiere_code);

    if v_candidats = 0 then
      raise exception 'Aucun enseignant de % n''est rattaché au dossier. Ce document vient de l''école : sans savoir de qui, personne ne pourra en lire les résultats. Invitez l''enseignant, ou demandez au référent de le faire.',
        coalesce(v_libelle, 'cette matière');
    else
      raise exception 'Indiquez l''enseignant dont vient ce document.';
    end if;
  end if;

  if new.fourni_par is null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.profil_id = new.fourni_par
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, new.matiere_code)
  ) then
    raise exception 'Le document doit être attribué à un enseignant de cette matière, rattaché à l''enfant.';
  end if;

  return new;
end;
$$;

-- ------------------------------------------------- de qui peut venir le travail

-- La liste que l'interface propose au moment de la saisie. Sans elle,
-- l'application devinerait les candidats à partir de trois tables, et se
-- tromperait sur les enseignants qui couvrent toutes les matières.
create or replace function enseignants_de_la_matiere(p_enfant uuid, p_matiere text)
returns table (
  profil_id uuid,
  prenom text,
  nom text,
  fonction text
)
language sql stable security definer set search_path = public as $$
  select p.id, p.prenom, p.nom, i.fonction
  from intervenants_enfant i
  join profils p on p.id = i.profil_id
  where i.enfant_id = p_enfant
    and i.retire_le is null
    and i.role = 'enseignant'
    and intervenant_couvre(i.id, p_matiere)
    and est_intervenant(p_enfant)
  order by p.nom, p.prenom;
$$;

-- ------------------------------------------------- ce que ça implique pour l'IA

-- Aucune règle nouvelle à écrire pour la génération : l'IA crée ses missions par
-- les mêmes chemins que tout le monde, et les triggers ci-dessus s'appliquent à
-- elle comme au reste. Une génération de devoir sans enseignant rattaché échoue,
-- avec le même message.
--
-- Ce qui compte est que l'application le vérifie AVANT d'appeler le modèle.
-- Découvrir le blocage après coup aurait deux coûts : l'appel est facturé (§3.7)
-- et le texte produit est perdu. `enseignants_de_la_matiere()` renvoie zéro
-- ligne dans ce cas — c'est le test à faire en amont.
