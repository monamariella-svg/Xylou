-- 0005 — Ce que l'école attend, et ce qu'elle dépose.
--
-- Deux entrées côté enseignant, et le document est explicite sur leur coût :
-- « valider un objectif proposé, quelques minutes par trimestre » (§3.1), et
-- déposer un support sans rien construire (§3.2). Le schéma doit rendre ces deux
-- gestes possibles en un clic, sinon l'adoption enseignante — déjà identifiée
-- comme incertaine au §3.4 — ne se fera pas.

-- L'année scolaire au sens usuel : elle bascule en août, pas en janvier.
create or replace function annee_scolaire_courante()
returns text
language sql
stable
as $$
  select case
    when extract(month from now()) >= 8
      then extract(year from now())::int || '-' || (extract(year from now())::int + 1)
    else (extract(year from now())::int - 1) || '-' || extract(year from now())::int
  end;
$$;

-- ------------------------------------------------------------- objectifs

create type origine_contenu as enum ('enseignant', 'parent', 'referent', 'ia');
create type statut_objectif as enum ('propose', 'valide', 'atteint', 'abandonne');

create table objectifs (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  matiere_code text not null references matieres on delete restrict,
  repere_id uuid references reperes_competences on delete set null,

  libelle text not null,
  description text not null default '',

  origine origine_contenu not null default 'enseignant',
  propose_par uuid references profils on delete set null,
  statut statut_objectif not null default 'propose',

  valide_par uuid references profils on delete set null,
  valide_le timestamptz,
  atteint_le timestamptz,

  trimestre smallint not null default 1 check (trimestre between 1 and 3),
  annee_scolaire text not null default annee_scolaire_courante(),

  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),

  constraint objectif_valide_a_un_validateur
    check (statut = 'propose' or (valide_par is not null and valide_le is not null))
);

create trigger objectifs_touch
  before update on objectifs
  for each row execute function touch_modifie_le();

create index objectifs_enfant_idx
  on objectifs (enfant_id, annee_scolaire, trimestre);
create index objectifs_a_valider_idx
  on objectifs (enfant_id) where statut = 'propose';

-- -------------------------------------------------------------- supports

create type type_support as enum ('cours', 'devoir', 'evaluation', 'autre');
create type statut_support as enum ('depose', 'en_traitement', 'adapte', 'echec');

create table supports (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  matiere_code text not null references matieres on delete restrict,
  type_support type_support not null default 'cours',
  titre text not null,

  -- Chemin dans le bucket `supports` (voir 0010). Le fichier d'origine est
  -- conservé : une adaptation ratée doit pouvoir être relancée sans redemander
  -- le document à l'enseignant.
  fichier_chemin text,
  fichier_type text,
  fichier_octets bigint,
  texte_extrait text not null default '',

  statut statut_support not null default 'depose',
  erreur text not null default '',

  depose_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create trigger supports_touch
  before update on supports
  for each row execute function touch_modifie_le();

create index supports_enfant_idx on supports (enfant_id, cree_le desc);

-- ----------------------------------------------------------- adaptations
--
-- Un même support donne deux sorties de nature différente : une version
-- lisible autrement (mise en forme, découpage, allègement visuel) et une
-- transposition dans l'univers de l'enfant. La première est une aide, la
-- seconde est un jeu ; les confondre reviendrait à transformer un contrôle
-- de maths en énigme sans que personne l'ait décidé.

create type forme_adaptation as enum ('visuelle', 'mission');
create type statut_adaptation as enum ('brouillon', 'validee', 'rejetee');

create table adaptations (
  id uuid primary key default gen_random_uuid(),
  support_id uuid not null references supports on delete cascade,
  forme forme_adaptation not null,
  contenu jsonb not null default '{}'::jsonb,

  modele_ia text,
  genere_le timestamptz not null default now(),

  statut statut_adaptation not null default 'brouillon',
  valide_par uuid references profils on delete set null,
  valide_le timestamptz,
  motif_rejet text not null default '',

  constraint adaptation_decidee_a_un_decideur
    check (statut = 'brouillon' or (valide_par is not null and valide_le is not null))
);

create index adaptations_support_idx on adaptations (support_id, forme);
