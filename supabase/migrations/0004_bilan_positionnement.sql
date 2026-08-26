-- 0004 — Le bilan de positionnement.
--
-- Le §3.4 en fait le point de fragilité principal du produit : « un mauvais
-- calibrage pourrait décourager l'enfant plutôt que le motiver ». Trois
-- conséquences directes sur le schéma :
--
--   1. Chaque question posée et chaque réponse donnée sont conservées. Sans la
--      trace, on ne peut pas comprendre après coup pourquoi le bilan s'est trompé.
--   2. L'estimation de l'IA et le jugement humain occupent des colonnes
--      distinctes. On ne remplace jamais l'une par l'autre : on les compare.
--   3. Rien n'est publié tant que `valide_par` est nul.

-- Où en est l'enfant sur un repère donné. Le vocabulaire décrit son état à lui,
-- jamais un écart à une classe d'âge : « à travailler » et non « en retard »,
-- « point fort » et non « au-dessus de la moyenne » (§3.3).
create type maitrise as enum (
  'non_evaluee',
  'a_travailler',
  'en_cours',
  'acquise',
  'point_fort'
);

create type statut_bilan as enum ('en_cours', 'complete', 'valide', 'abandonne');

create table bilans_positionnement (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  statut statut_bilan not null default 'en_cours',

  -- Classe de référence au moment du bilan : elle sert à choisir les repères,
  -- pas à situer l'enfant par rapport à ses camarades.
  classe_reference niveau_classe,
  matieres text[] not null default '{}',

  modele_ia text,
  demarre_le timestamptz not null default now(),
  complete_le timestamptz,

  -- Supervision humaine obligatoire avant que quoi que ce soit soit exploité.
  valide_par uuid references profils on delete set null,
  valide_le timestamptz,
  commentaire_referent text not null default '',

  cree_par uuid not null references profils on delete restrict,
  modifie_le timestamptz not null default now(),

  constraint bilan_valide_a_un_validateur
    check ((statut = 'valide') = (valide_par is not null and valide_le is not null))
);

create trigger bilans_positionnement_touch
  before update on bilans_positionnement
  for each row execute function touch_modifie_le();

create index bilans_enfant_idx on bilans_positionnement (enfant_id, demarre_le desc);

-- Un seul bilan ouvert par enfant : deux bilans en parallèle produiraient deux
-- niveaux contradictoires sans qu'on sache lequel fait foi.
create unique index bilans_un_seul_en_cours
  on bilans_positionnement (enfant_id) where statut = 'en_cours';

-- ------------------------------------------------------------- questions

create type type_reponse as enum ('qcm', 'texte', 'numerique', 'association', 'ordre', 'oui_non');

create table bilan_questions (
  id uuid primary key default gen_random_uuid(),
  bilan_id uuid not null references bilans_positionnement on delete cascade,
  repere_id uuid not null references reperes_competences on delete restrict,
  ordre smallint not null default 0,

  enonce text not null,
  type_reponse type_reponse not null default 'qcm',
  -- Propositions, appariements, unités attendues… selon `type_reponse`.
  contenu jsonb not null default '{}'::jsonb,
  correction jsonb not null default '{}'::jsonb,

  genere_par_ia boolean not null default true,
  modele_ia text,
  cree_le timestamptz not null default now()
);

create index bilan_questions_bilan_idx on bilan_questions (bilan_id, ordre);

create table bilan_reponses (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references bilan_questions on delete cascade unique,
  reponse jsonb not null default '{}'::jsonb,
  duree_secondes integer,
  aide_utilisee boolean not null default false,

  -- Lecture automatique de la réponse, puis correction humaine éventuelle.
  -- La seconde ne réécrit pas la première : les deux restent lisibles.
  maitrise_ia maitrise not null default 'non_evaluee',
  commentaire_ia text not null default '',
  maitrise_corrigee maitrise,
  corrigee_par uuid references profils on delete set null,
  corrigee_le timestamptz,

  repondu_le timestamptz not null default now()
);

-- ------------------------------------------------- synthèse par repère

create table bilan_maitrises (
  id uuid primary key default gen_random_uuid(),
  bilan_id uuid not null references bilans_positionnement on delete cascade,
  repere_id uuid not null references reperes_competences on delete restrict,
  maitrise maitrise not null default 'non_evaluee',
  commentaire text not null default '',
  unique (bilan_id, repere_id)
);

-- ------------------------------------------------- synthèse par matière

create table bilan_niveaux_matiere (
  id uuid primary key default gen_random_uuid(),
  bilan_id uuid not null references bilans_positionnement on delete cascade,
  enfant_id uuid not null references enfants on delete cascade,
  matiere_code text not null references matieres on delete restrict,

  -- Le niveau où l'enfant travaille effectivement dans cette matière. Il peut
  -- être au-dessus comme en dessous de sa classe d'inscription, et les deux sont
  -- des informations utiles, pas des jugements.
  niveau_estime niveau_classe,

  appuis text[] not null default '{}',
  fragilites text[] not null default '{}',
  synthese_ia text not null default '',
  synthese_humaine text not null default '',

  valide_par uuid references profils on delete set null,
  valide_le timestamptz,

  unique (bilan_id, matiere_code)
);

create index bilan_niveaux_enfant_idx
  on bilan_niveaux_matiere (enfant_id, matiere_code);
