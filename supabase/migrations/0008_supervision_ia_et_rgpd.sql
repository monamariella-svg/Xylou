-- 0008 — Ce que l'IA a fait, ce que ça a coûté, et ce que la famille a consenti.
--
-- Trois obligations distinctes traitées ensemble parce qu'elles portent sur les
-- mêmes lignes :
--
--   - §3.4 : les données relèvent du handicap, donc de la donnée de santé au
--     sens RGPD. Consentement explicite et journal d'accès ne sont pas optionnels.
--   - §3.7 : le budget IA du pilote (400 à 2 000 € pour 12 enfants) n'est tenable
--     que s'il est mesuré. On ne mesure pas ce qu'on n'enregistre pas.
--   - §3.2 : toute suggestion de l'IA reste supervisée. Le journal dit qui a
--     décidé quoi, et quand.

-- ------------------------------------------------------------- journal IA

create type operation_ia as enum (
  'bilan_questions',
  'bilan_evaluation',
  'bilan_synthese',
  'adaptation_visuelle',
  'adaptation_mission',
  'generation_mission',
  'generation_exercices',
  'bilan_trimestriel',
  'interaction_courte'
);

create table journal_ia (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid references enfants on delete cascade,
  operation operation_ia not null,
  modele text not null,

  -- On enregistre la longueur et l'empreinte du prompt, jamais son contenu :
  -- il porte le profil de l'enfant. Assez pour diagnostiquer une régression de
  -- qualité, pas assez pour reconstituer une donnée de santé depuis les logs.
  empreinte_prompt text,
  tokens_entree integer not null default 0,
  tokens_sortie integer not null default 0,
  tokens_cache_lus integer not null default 0,
  cout_centimes numeric(10, 4) not null default 0,
  duree_ms integer,

  succes boolean not null default true,
  erreur text not null default '',
  declenche_par uuid references profils on delete set null,
  cree_le timestamptz not null default now()
);

create index journal_ia_enfant_idx on journal_ia (enfant_id, cree_le desc);
create index journal_ia_cout_idx on journal_ia (cree_le desc);

-- Le suivi de budget du §3.7, mois par mois.
create view cout_ia_mensuel
with (security_invoker = true) as
  select
    enfant_id,
    date_trunc('month', cree_le) as mois,
    count(*) as appels,
    sum(tokens_entree) as tokens_entree,
    sum(tokens_sortie) as tokens_sortie,
    round(sum(cout_centimes) / 100, 2) as cout_euros
  from journal_ia
  group by enfant_id, date_trunc('month', cree_le);

-- ---------------------------------------------------------- consentements

create type type_consentement as enum (
  'traitement_donnees_sante',
  'generation_ia',
  'partage_equipe_pedagogique',
  'conservation_historique'
);

create table consentements (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  -- Le titulaire de l'autorité parentale qui consent. Un consentement est donné
  -- par une personne identifiée, jamais par « la famille ».
  profil_id uuid not null references profils on delete cascade,
  type type_consentement not null,

  accorde boolean not null,
  -- Version du texte présenté au moment du clic. Sans elle, un consentement
  -- recueilli il y a un an ne prouve rien sur ce qui a été accepté.
  version_texte text not null,

  accorde_le timestamptz not null default now(),
  revoque_le timestamptz
);

create index consentements_enfant_idx
  on consentements (enfant_id, type) where revoque_le is null;

create or replace function consentement_actif(p_enfant uuid, p_type type_consentement)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from consentements c
    where c.enfant_id = p_enfant
      and c.type = p_type
      and c.accorde
      and c.revoque_le is null
  );
$$;

-- ------------------------------------------------------- journal d'accès

create table journal_acces (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  profil_id uuid references profils on delete set null,
  action text not null,
  table_cible text not null default '',
  ligne_id uuid,
  detail jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now()
);

create index journal_acces_enfant_idx on journal_acces (enfant_id, cree_le desc);
