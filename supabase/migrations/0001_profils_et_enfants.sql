-- 0001 — Qui est qui, et qui accompagne quel enfant.
--
-- Trois rôles seulement, parce que le document (§3.5) reporte en v2 toute la
-- coordination multi-intervenants. Un « coordinateur ULIS » est un référent dont
-- la fonction est renseignée en clair : on ne multiplie pas les rôles pour
-- décrire des métiers, on multiplie les droits pour décrire des accès.

create extension if not exists "pgcrypto";

-- Horodatage de modification, réutilisé par presque toutes les tables.
create or replace function touch_modifie_le()
returns trigger
language plpgsql
as $$
begin
  new.modifie_le = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------- profils

create table profils (
  id uuid primary key references auth.users on delete cascade,
  prenom text not null default '',
  nom text not null default '',
  email text not null default '',
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create trigger profils_touch
  before update on profils
  for each row execute function touch_modifie_le();

-- Un compte auth sans profil est un compte inutilisable : on crée la ligne dès
-- l'inscription plutôt que de la créer paresseusement à la première lecture.
create or replace function creer_profil_a_l_inscription()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into profils (id, email, prenom, nom)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'prenom', ''),
    coalesce(new.raw_user_meta_data ->> 'nom', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger creer_profil_apres_inscription
  after insert on auth.users
  for each row execute function creer_profil_a_l_inscription();

-- ---------------------------------------------------------------- enfants

create type niveau_classe as enum (
  'cp', 'ce1', 'ce2', 'cm1', 'cm2',
  '6e', '5e', '4e', '3e',
  '2nde', '1ere', 'terminale'
);

create type profil_communication as enum ('verbal', 'non_verbal', 'mixte');

create table enfants (
  id uuid primary key default gen_random_uuid(),
  prenom text not null,
  date_naissance date,
  classe niveau_classe,
  communication profil_communication not null default 'verbal',

  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  -- Suppression douce : l'historique reste exportable pour la famille (§3.3,
  -- portabilité lors des transitions scolaires) avant purge définitive.
  archive_le timestamptz
);

create trigger enfants_touch
  before update on enfants
  for each row execute function touch_modifie_le();

create index enfants_cree_par_idx on enfants (cree_par) where archive_le is null;

-- Ce qui relève de la donnée de santé au sens RGPD (§3.4) vit dans une table
-- séparée, et pas dans deux colonnes de plus sur `enfants`. La raison est
-- pratique : un enseignant doit pouvoir lire la fiche de l'enfant — prénom,
-- classe, mode de communication — sans lire son diagnostic ni ses aménagements.
-- Une politique RLS distincte sur une table distincte rend cette frontière
-- vérifiable d'un coup d'œil ; des droits par colonne, non.
create table enfants_sante (
  enfant_id uuid primary key references enfants on delete cascade,
  besoins_particuliers text not null default '',
  amenagements text not null default '',
  suivis_exterieurs text not null default '',
  modifie_le timestamptz not null default now()
);

create trigger enfants_sante_touch
  before update on enfants_sante
  for each row execute function touch_modifie_le();

-- ------------------------------------------------ intervenants et invitations

create type role_intervenant as enum ('parent', 'referent', 'enseignant');

create table intervenants_enfant (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  profil_id uuid not null references profils on delete cascade,
  role role_intervenant not null,
  -- « coordinatrice ULIS », « AVS », « professeure de mathématiques »…
  fonction text not null default '',
  -- Renseigné pour un enseignant : limite ses dépôts et ses objectifs à sa matière.
  matiere_code text,
  invite_par uuid references profils on delete set null,
  cree_le timestamptz not null default now(),
  retire_le timestamptz,
  unique (enfant_id, profil_id)
);

create index intervenants_profil_idx
  on intervenants_enfant (profil_id) where retire_le is null;
create index intervenants_enfant_idx
  on intervenants_enfant (enfant_id) where retire_le is null;

-- Une invitation vit avant que la personne ait un compte : elle est donc
-- rattachée à un email, pas à un profil.
create table invitations (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  email text not null,
  role role_intervenant not null,
  fonction text not null default '',
  matiere_code text,
  jeton text not null unique default encode(gen_random_bytes(24), 'hex'),
  invite_par uuid not null references profils on delete cascade,
  cree_le timestamptz not null default now(),
  expire_le timestamptz not null default now() + interval '30 days',
  acceptee_le timestamptz,
  annulee_le timestamptz
);

create index invitations_email_idx on invitations (lower(email))
  where acceptee_le is null and annulee_le is null;

-- ------------------------------------------------------- fonctions d'accès
--
-- Toutes les politiques RLS passent par ces trois fonctions. Elles sont
-- SECURITY DEFINER pour casser la récursion : une politique sur
-- intervenants_enfant qui interrogerait intervenants_enfant en RLS bouclerait.

create or replace function est_intervenant(p_enfant uuid, p_roles role_intervenant[] default null)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from intervenants_enfant i
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and (p_roles is null or i.role = any (p_roles))
  );
$$;

-- Qui a le dernier mot sur une suggestion de l'IA : les parents et le référent,
-- et personne d'autre (§3.2, dernière puce).
create or replace function peut_valider(p_enfant uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[]);
$$;

-- La matière d'un enseignant, null pour les autres rôles. Sert à cantonner un
-- professeur de maths aux objectifs et supports de maths.
create or replace function matiere_de_l_intervenant(p_enfant uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select i.matiere_code
  from intervenants_enfant i
  where i.enfant_id = p_enfant
    and i.profil_id = auth.uid()
    and i.retire_le is null
  limit 1;
$$;
