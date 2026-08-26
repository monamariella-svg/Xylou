-- 0047 — Le parent voit tout, décide de la trajectoire, ne rédige pas.
--
-- 0019 posait `restreindre_le_pilotage()` avec une porte grande ouverte en
-- première ligne : `if peut_valider(enfant_id) then return new;`. Les parents et
-- le référent pouvaient donc réécrire n'importe quoi sur un objectif — le
-- libellé, le critère de fin, le nombre d'exercices, la matière.
--
-- C'était un reste du moment où `peut_valider()` servait de raccourci pour
-- « les adultes de confiance ». Mais faire confiance à quelqu'un ne veut pas
-- dire lui donner un métier qui n'est pas le sien.
--
-- ---------------------------------------------------------------------------
-- TROIS NATURES DE MODIFICATION, TROIS TITULAIRES
--
--   le contenu     — libellé, description, matière, granularité, rattachement.
--                    C'est la formulation pédagogique : elle appartient à celui
--                    qui la propose, et il peut la retoucher tant qu'elle est
--                    encore en discussion.
--
--   la cadence     — période, nombre d'exercices visés, réussites attendues,
--                    critère de fin. C'est le réglage fin de l'accompagnement,
--                    et il appartient au pilote : l'enseignant de la matière,
--                    le référent pour un domaine transversal. Un élève a besoin
--                    de trois exercices sur une leçon et de quinze sur la
--                    suivante ; seul celui qui le suit le sait.
--
--   la trajectoire — valider, abandonner, déclarer atteint. C'est ce qui engage
--                    l'enfant, et cela reste à la famille. Le quorum de 0023 en
--                    gouverne l'entrée, ce fichier ne le touche pas.
--
-- Le parent garde donc exactement ce qui lui revient : il voit tout — les
-- objectifs, les attendus, la progression, les jauges de badge — il signe ou
-- refuse, et s'il n'est pas d'accord sur la formulation, il ouvre une demande
-- de modification (0016). C'est un désaccord qui se discute, pas une correction
-- qu'on applique par-dessus le travail de quelqu'un d'autre.
-- ---------------------------------------------------------------------------

create or replace function restreindre_le_pilotage()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_pilote boolean;
  v_auteur boolean;
begin
  -- Contexte de confiance (SQL Editor, clé de service) : rien à arbitrer.
  if auth.uid() is null then
    return new;
  end if;

  v_pilote := (new.granularite = 'fin' and pilote_l_objectif(new.id))
              or pilote_l_objectif(new.id);
  v_auteur := old.propose_par = auth.uid() and old.statut = 'propose';

  -- --------------------------------------------------------------- contenu
  -- Réécrire la formulation d'un objectif déjà validé revient à changer ce que
  -- la famille a accepté sans le lui redemander. Seul son auteur y touche, et
  -- seulement tant que personne n'a signé.
  if new.libelle            is distinct from old.libelle
  or new.description        is distinct from old.description
  or new.matiere_code       is distinct from old.matiere_code
  or new.domaine_code       is distinct from old.domaine_code
  or new.granularite        is distinct from old.granularite
  or new.objectif_parent_id is distinct from old.objectif_parent_id
  or new.repere_id          is distinct from old.repere_id
  or new.enfant_id          is distinct from old.enfant_id then
    if not v_auteur then
      raise exception 'La formulation d''un objectif appartient à qui l''a proposé, et se fige dès qu''il est signé. Ouvrez une demande de modification.';
    end if;
  end if;

  -- --------------------------------------------------------------- cadence
  -- Le réglage fin revient au pilote. Un parent qui trouve le rythme trop
  -- soutenu le dit à l'enseignant ; il ne baisse pas le compteur lui-même.
  if new.debute_le        is distinct from old.debute_le
  or new.echeance_le      is distinct from old.echeance_le
  or new.exercices_vises  is distinct from old.exercices_vises
  or new.reussites_visees is distinct from old.reussites_visees
  or new.critere_fin      is distinct from old.critere_fin
  or new.trimestre        is distinct from old.trimestre
  or new.annee_id         is distinct from old.annee_id then
    if not (v_pilote or v_auteur) then
      raise exception 'La période, le nombre d''exercices et le critère de fin sont réglés par l''enseignant de la matière — ou par le référent pour un domaine transversal.';
    end if;
  end if;

  -- ---------------------------------------------------------- trajectoire
  -- Valider, abandonner, déclarer atteint : cela engage l'enfant, et cela
  -- revient à la famille. Le quorum de 0023 et les signatures de 0022
  -- continuent de gouverner l'entrée dans « validé » ; ici on vérifie
  -- seulement que la décision vient du bon cercle.
  if new.statut     is distinct from old.statut
  or new.valide_par is distinct from old.valide_par
  or new.valide_le  is distinct from old.valide_le
  or new.atteint_le is distinct from old.atteint_le then
    if not (peut_valider(new.enfant_id) or v_pilote) then
      raise exception 'Le statut d''un objectif se décide par la famille, le référent, ou l''enseignant qui le pilote.';
    end if;
  end if;

  return new;
end;
$$;

-- ------------------------------------------------- ce que le parent regarde

-- Tout était déjà lisible : `objectifs_lecture` (0009) passe par
-- `est_intervenant()`, et les attendus sont des colonnes de la table. Cette
-- fonction ne débloque rien — elle rassemble, pour éviter que l'application
-- reconstitue à cinq requêtes ce qui tient en une.
--
-- « Voir les progrès » et « voir ce qui est attendu » sont deux colonnes de la
-- même ligne : sans le second, le premier ne veut rien dire. Trois réussites
-- sur cinq n'est une information que si l'on sait qu'il en fallait cinq.
create or replace function objectifs_de_l_enfant(p_enfant uuid)
returns table (
  objectif_id uuid,
  granularite granularite_objectif,
  objectif_parent_id uuid,
  libelle text,
  description text,
  matiere_code text,
  domaine_code text,
  statut statut_objectif,
  debute_le date,
  echeance_le date,
  -- ce qui est attendu
  critere_fin text,
  reussites_visees smallint,
  exercices_vises smallint,
  -- où en est l'enfant
  exercices_proposes bigint,
  reussites bigint,
  seuil_atteint boolean,
  -- qui l'a proposé, qui l'a signé
  propose_par_prenom text,
  signatures bigint,
  signatures_attendues bigint
)
language sql stable security definer set search_path = public as $$
  select
    o.id, o.granularite, o.objectif_parent_id, o.libelle, o.description,
    o.matiere_code, o.domaine_code, o.statut, o.debute_le, o.echeance_le,
    o.critere_fin, o.reussites_visees, o.exercices_vises,
    coalesce(p.exercices_proposes, 0), coalesce(p.reussites, 0),
    coalesce(p.seuil_atteint, false),
    coalesce(pr.prenom, ''),
    (select count(*) from objectifs_validations v where v.objectif_id = o.id),
    (select count(*) from valideurs_requis(o.id))
  from objectifs o
  left join profils pr on pr.id = o.propose_par
  left join lateral progression_objectif(o.id) p on o.granularite = 'fin'
  where o.enfant_id = p_enfant
    and est_intervenant(p_enfant)
  order by o.granularite, o.debute_le desc;
$$;
