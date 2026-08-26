-- 0018 — La bibliothèque de modèles d'exercice.
--
-- Jusqu'ici tout était jetable. Un exercice appartenait à une mission, qui
-- appartenait à un enfant : le travail de calibrage d'un professeur mourait avec
-- la mission qui l'avait porté. Refaire le même exercice avec d'autres nombres
-- pour le même enfant, ou le reprendre pour un autre élève l'année suivante,
-- demandait de tout régénérer — et de tout revalider.
--
-- Un modèle est ce qui survit à l'instance : la structure de l'exercice sans les
-- données qui le peuplent, et sans l'enfant pour qui il avait été écrit.
--
-- ---------------------------------------------------------------------------
-- CE QU'UN MODÈLE NE DOIT JAMAIS CONTENIR
--
-- Un modèle voyage d'un enfant à l'autre. Il est donc, par construction, hors du
-- périmètre de protection que le reste du schéma applique aux données de
-- l'enfant — pas de `enfant_id`, donc pas de RLS pour le rattraper.
--
-- `consigne` porte la formulation SCOLAIRE, jamais la narrative. Un exercice tel
-- que l'enfant le voit est écrit dans le lexique de son projet moteur (0002) :
-- reprendre cette formulation telle quelle pour un autre élève lui livrerait
-- l'univers du premier — et, pour un enfant dont la passion est le sujet même de
-- l'accompagnement, c'est une information personnelle.
--
-- La transposition dans l'univers se refait à chaque instanciation. C'est un
-- appel IA de plus, et c'est le prix à payer pour que la bibliothèque soit
-- partageable.
-- ---------------------------------------------------------------------------

create type statut_modele as enum ('propose', 'valide', 'retire');

create table modeles_exercice (
  id uuid primary key default gen_random_uuid(),

  matiere_code text not null references matieres on delete restrict,
  repere_id uuid references reperes_competences on delete set null,
  cycle cycle_scolaire,

  -- Comment le professeur le retrouve dans sa bibliothèque.
  libelle text not null,
  consigne text not null,
  type_reponse type_reponse not null default 'qcm',

  -- La structure : propositions, appariements, unités attendues. Les valeurs
  -- concrètes sont des variables, pas des littéraux.
  contenu jsonb not null default '{}'::jsonb,
  -- Ce qui varie d'une instance à l'autre : plages de valeurs, listes de mots,
  -- contraintes de tirage. C'est ce champ qui permet « le même exercice avec
  -- d'autres données ».
  parametres jsonb not null default '{}'::jsonb,
  correction jsonb not null default '{}'::jsonb,
  indice text not null default '',

  difficulte smallint not null default 3 check (difficulte between 1 and 5),

  statut statut_modele not null default 'propose',
  valide_par uuid references profils on delete set null,
  valide_le timestamptz,
  motif_retrait text not null default '',

  -- L'exercice dont ce modèle a été extrait, quand il vient d'une instance
  -- réussie plutôt que d'une rédaction directe. Nul après suppression de
  -- l'exercice d'origine : le modèle, lui, reste.
  origine_exercice_id uuid references exercices on delete set null,

  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),

  constraint modele_valide_a_un_validateur
    check ((statut = 'valide') = (valide_par is not null and valide_le is not null))
);

create trigger modeles_exercice_touch
  before update on modeles_exercice
  for each row execute function touch_modifie_le();

-- La recherche que fait le professeur : sa matière, le repère visé, et seulement
-- ce qui a déjà été validé.
create index modeles_utilisables_idx
  on modeles_exercice (matiere_code, repere_id, difficulte)
  where statut = 'valide';

create index modeles_a_valider_idx
  on modeles_exercice (matiere_code, cree_le)
  where statut = 'propose';

-- De quel modèle vient cet exercice. Rend mesurable ce qui sert et ce qui dort,
-- et permet de retrouver toutes les instances d'un modèle qu'on découvre bancal.
alter table exercices
  add column modele_id uuid references modeles_exercice on delete set null;

create index exercices_modele_idx on exercices (modele_id);

-- Un modèle validé qu'on retouche redevient une proposition. Sans cette règle,
-- la validation porterait sur une version que plus personne ne peut consulter :
-- il suffirait de faire valider un modèle anodin puis d'en réécrire le contenu.
create or replace function invalider_le_modele_retouche()
returns trigger language plpgsql as $$
begin
  if old.statut = 'valide' and (
       new.consigne is distinct from old.consigne
    or new.contenu is distinct from old.contenu
    or new.parametres is distinct from old.parametres
    or new.correction is distinct from old.correction
    or new.type_reponse is distinct from old.type_reponse
  ) then
    new.statut := 'propose';
    new.valide_par := null;
    new.valide_le := null;
  end if;
  return new;
end;
$$;

create trigger modeles_retouches_a_revalider
  before update on modeles_exercice
  for each row execute function invalider_le_modele_retouche();

-- ==================================================================== RLS

-- Un modèle n'appartient à aucun enfant : les fonctions d'accès du reste du
-- schéma, toutes construites autour de `enfant_id`, ne s'y appliquent pas.
create or replace function accompagne_un_enfant()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from intervenants_enfant i
    where i.profil_id = auth.uid() and i.retire_le is null
  );
$$;

-- Enseigner une matière est ici une propriété de la personne, pas de sa relation
-- à un enfant donné : un professeur de mathématiques valide un modèle de
-- mathématiques, quel que soit l'élève pour lequel il a été écrit au départ.
create or replace function enseigne_la_matiere(p_matiere text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from intervenants_enfant i
    where i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and i.matiere_code = p_matiere
  );
$$;

alter table modeles_exercice enable row level security;

-- Lisible par quiconque accompagne un enfant. La bibliothèque ne contient aucune
-- donnée personnelle — c'est sa définition même — et la cloisonner par matière
-- empêcherait un parent de comprendre ce que son enfant va faire.
create policy modeles_lecture on modeles_exercice for select to authenticated
  using (accompagne_un_enfant());

-- Proposer est ouvert : un parent qui a vu quel type d'exercice débloque son
-- enfant a quelque chose à verser à la bibliothèque. C'est la validation qui
-- filtre, pas le dépôt — et un modèle non validé n'est utilisable par personne.
create policy modeles_proposition on modeles_exercice for insert to authenticated
  with check (
    cree_par = auth.uid()
    and statut = 'propose'
    and accompagne_un_enfant()
  );

-- Valider relève du professeur de la matière, et de lui seul. C'est un jugement
-- disciplinaire — un parent sait si un exercice a convenu à son enfant, pas s'il
-- est juste. Le verrou du §3.2 n'est pas en cause ici : valider un modèle ne le
-- met dans les mains d'aucun enfant, la mission qui l'instanciera suivra ses
-- propres règles de validation.
create policy modeles_validation on modeles_exercice for update to authenticated
  using (
    enseigne_la_matiere(matiere_code)
    or (cree_par = auth.uid() and statut = 'propose')
  )
  with check (
    (
      enseigne_la_matiere(matiere_code)
      or (cree_par = auth.uid() and statut = 'propose')
    )
    -- Qui valide signe. La contrainte de table exige un validateur ; celle-ci
    -- exige que ce soit celui qui écrit, sans quoi un professeur validerait au
    -- nom d'un collègue dont la bibliothèque porterait ensuite la caution.
    and (statut <> 'valide' or valide_par = auth.uid())
  );

create policy modeles_suppression on modeles_exercice for delete to authenticated
  using (cree_par = auth.uid() and statut = 'propose');
