-- 0006 — Ce que l'enfant voit réellement : des missions, pas des exercices.
--
-- La mission porte deux titres. `titre` est la formulation scolaire, celle que
-- lisent les adultes dans le bilan trimestriel. `intitule_narratif` est la seule
-- que l'enfant voit, écrite dans le lexique de son projet moteur. Séparer les
-- deux permet de changer d'univers — un enfant se lasse — sans reconstruire les
-- apprentissages qu'il a déjà faits.

create type statut_mission as enum (
  'proposee', 'validee', 'en_cours', 'reussie', 'abandonnee'
);

create table missions (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  projet_moteur_id uuid not null references projets_moteurs on delete restrict,
  objectif_id uuid references objectifs on delete set null,
  -- Renseigné quand la mission naît d'un support déposé par un enseignant.
  adaptation_id uuid references adaptations on delete set null,
  matiere_code text not null references matieres on delete restrict,

  titre text not null,
  intitule_narratif text not null default '',
  difficulte smallint not null default 3 check (difficulte between 1 and 5),
  points integer not null default 10 check (points >= 0),

  statut statut_mission not null default 'proposee',
  genere_par_ia boolean not null default true,
  modele_ia text,

  valide_par uuid references profils on delete set null,
  valide_le timestamptz,

  ordre smallint not null default 0,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),

  -- Le verrou central du produit : une mission générée par l'IA n'atteint
  -- l'enfant qu'après le passage d'un parent ou du référent (§3.2).
  constraint mission_proposee_tant_qu_elle_n_est_pas_validee
    check (statut = 'proposee' or (valide_par is not null and valide_le is not null))
);

create trigger missions_touch
  before update on missions
  for each row execute function touch_modifie_le();

create index missions_enfant_idx on missions (enfant_id, statut, ordre);
create index missions_a_valider_idx
  on missions (enfant_id) where statut = 'proposee';

create table exercices (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references missions on delete cascade,
  ordre smallint not null default 0,

  consigne text not null,
  type_reponse type_reponse not null default 'qcm',
  contenu jsonb not null default '{}'::jsonb,
  correction jsonb not null default '{}'::jsonb,

  -- Un indice disponible à la demande vaut mieux qu'un échec sec : le recours à
  -- l'indice est tracé dans `tentatives`, il informe sans pénaliser.
  indice text not null default '',
  cree_le timestamptz not null default now()
);

create index exercices_mission_idx on exercices (mission_id, ordre);

create table tentatives (
  id uuid primary key default gen_random_uuid(),
  exercice_id uuid not null references exercices on delete cascade,
  enfant_id uuid not null references enfants on delete cascade,
  reponse jsonb not null default '{}'::jsonb,
  reussie boolean not null default false,
  aide_utilisee boolean not null default false,
  duree_secondes integer,
  cree_le timestamptz not null default now()
);

-- On garde toutes les tentatives, pas seulement la dernière : trois essais avant
-- de réussir, c'est une information sur la façon d'apprendre de l'enfant.
create index tentatives_exercice_idx on tentatives (exercice_id, cree_le desc);
create index tentatives_enfant_idx on tentatives (enfant_id, cree_le desc);

create table recompenses_obtenues (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  recompense_id uuid not null references recompenses on delete cascade,
  mission_id uuid references missions on delete set null,
  obtenue_le timestamptz not null default now()
);

create index recompenses_obtenues_enfant_idx
  on recompenses_obtenues (enfant_id, obtenue_le desc);

-- Le solde de points, calculé et jamais stocké : un compteur dénormalisé finit
-- toujours par diverger de l'historique qui le justifie.
create view points_enfant
with (security_invoker = true) as
  select
    e.id as enfant_id,
    coalesce(gagnes.total, 0) as points_gagnes,
    coalesce(depenses.total, 0) as points_depenses,
    coalesce(gagnes.total, 0) - coalesce(depenses.total, 0) as solde
  from enfants e
  left join (
    select m.enfant_id, sum(m.points)::integer as total
    from missions m
    where m.statut = 'reussie'
    group by m.enfant_id
  ) gagnes on gagnes.enfant_id = e.id
  left join (
    select ro.enfant_id, sum(r.cout_points)::integer as total
    from recompenses_obtenues ro
    join recompenses r on r.id = ro.recompense_id
    group by ro.enfant_id
  ) depenses on depenses.enfant_id = e.id;
