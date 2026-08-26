-- 0016 — Les deux chemins par lesquels un objectif se décide.
--
--   En réunion — parents, référent et enseignants autour de la table. L'objectif
--                est arrêté ensemble ; celui qui saisit enregistre une décision
--                déjà prise, il ne la prend pas.
--   À distance — un professeur estime qu'un objectif doit changer. Il ne le
--                modifie pas lui-même : il le demande, et parents et référent
--                sont prévenus au même instant.
--
-- Ce « au même instant » n'est pas un détail d'ergonomie. Prévenir le référent
-- d'abord, à charge pour lui de transmettre, ferait de lui un filtre entre le
-- professeur et la famille — exactement la position que le §3.3 refuse de lui
-- donner. Un seul trigger, une seule requête, tout le monde en même temps.

-- ------------------------------------------------------ décision en réunion

alter table objectifs
  add column valide_en_reunion boolean not null default false;

comment on column objectifs.valide_en_reunion is
  'Vrai quand la décision a été prise collectivement. valide_par porte alors qui a saisi, pas qui a décidé seul.';

-- ------------------------------------------------ demande de modification

create type statut_demande as enum ('ouverte', 'acceptee', 'refusee', 'retiree');

-- Un professeur ne réécrit pas un objectif validé : il en propose la
-- modification, et la version en vigueur reste celle que la famille a acceptée
-- tant qu'elle n'a pas tranché. Sans cette table, la seule façon de faire
-- remonter un désaccord serait de modifier l'objectif — donc de passer outre.
create table objectifs_demandes (
  id uuid primary key default gen_random_uuid(),
  objectif_id uuid not null references objectifs on delete cascade,
  demande_par uuid not null references profils on delete restrict,

  motif text not null,
  -- Facultatifs : une demande peut se contenter de signaler qu'un objectif n'est
  -- plus adapté, sans proposer sa rédaction de remplacement.
  libelle_propose text not null default '',
  echeance_proposee date,

  statut statut_demande not null default 'ouverte',
  reponse text not null default '',
  traite_par uuid references profils on delete set null,
  traite_le timestamptz,

  cree_le timestamptz not null default now(),

  constraint demande_traitee_a_un_decideur
    check (statut = 'ouverte' or (traite_par is not null and traite_le is not null))
);

create index objectifs_demandes_objectif_idx
  on objectifs_demandes (objectif_id, cree_le desc);
create index objectifs_demandes_ouvertes_idx
  on objectifs_demandes (objectif_id) where statut = 'ouverte';

create or replace function enfant_de_l_objectif(p_objectif uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from objectifs where id = p_objectif;
$$;

-- --------------------------------------------------------- notifications

-- Parents et référent, tous, en une seule requête. L'auteur de la demande est
-- exclu : il sait déjà.
create or replace function notifier_demande_objectif()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid;
  v_libelle text;
begin
  select o.enfant_id, o.libelle into v_enfant, v_libelle
  from objectifs o where o.id = new.objectif_id;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id,
    v_enfant,
    'objectif_modification_demandee',
    'Modification demandée : ' || v_libelle,
    new.motif,
    '/enfants/' || v_enfant || '/objectifs/' || new.objectif_id
  from intervenants_enfant i
  where i.enfant_id = v_enfant
    and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> new.demande_par;

  return new;
end;
$$;

create trigger objectifs_demandes_notifient
  after insert on objectifs_demandes
  for each row execute function notifier_demande_objectif();

-- Un objectif proposé suit le même chemin : la famille est prévenue, sinon
-- « quelques minutes par trimestre » (§3.1) se transforme en obligation d'aller
-- vérifier soi-même si quelque chose attend.
create or replace function notifier_objectif_propose()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id,
    new.enfant_id,
    'objectif_propose',
    'Objectif à valider',
    new.libelle,
    '/enfants/' || new.enfant_id || '/objectifs/' || new.id
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id is distinct from new.propose_par;

  return new;
end;
$$;

create trigger objectifs_proposes_notifient
  after insert on objectifs
  for each row when (new.statut = 'propose')
  execute function notifier_objectif_propose();

-- ==================================================================== RLS

alter table objectifs_demandes enable row level security;

-- Toute l'équipe lit les demandes : savoir qu'un objectif est contesté fait
-- partie de la photographie du §3.1, et l'ignorer conduirait deux intervenants
-- à demander la même chose deux fois.
create policy objectifs_demandes_lecture on objectifs_demandes for select to authenticated
  using (est_intervenant(enfant_de_l_objectif(objectif_id)));

-- Un enseignant demande dans sa matière ; la clause de matière est portée par
-- l'objectif visé, pas par la demande.
create policy objectifs_demandes_creation on objectifs_demandes for insert to authenticated
  with check (
    demande_par = auth.uid()
    and est_intervenant(enfant_de_l_objectif(objectif_id))
    and exists (
      select 1 from objectifs o
      where o.id = objectif_id
        and matiere_ouverte_a_l_ecriture(o.enfant_id, o.matiere_code)
    )
  );

-- Trancher revient à la famille. Le demandeur peut seulement retirer la sienne.
create policy objectifs_demandes_traitement on objectifs_demandes for update to authenticated
  using (
    peut_valider(enfant_de_l_objectif(objectif_id))
    or (demande_par = auth.uid() and statut = 'ouverte')
  )
  with check (
    peut_valider(enfant_de_l_objectif(objectif_id))
    or (demande_par = auth.uid() and statut in ('ouverte', 'retiree'))
  );
