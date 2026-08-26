-- 0014 — La messagerie, et qui lit quoi.
--
-- Jusqu'ici le schéma ne savait porter que des objets scolaires : un objectif,
-- un support, une mission. Rien pour ce qui s'échange autour — une observation
-- d'un orthophoniste, une question d'un parent, un compte rendu de réunion.
--
-- La tentation était de déduire les destinataires du rôle : la famille d'un
-- côté, l'équipe de l'autre. Elle est fausse. Des parents doivent pouvoir parler
-- à un enseignant sans le référent ; ailleurs le référent sera précisément celui
-- qu'on veut dans la boucle. Aucune règle fondée sur les rôles ne tient les deux
-- cas à la fois, et celle qui les manque produit la pire panne possible pour ce
-- produit : une conversation qu'on croyait privée et qui ne l'était pas.
--
-- Deux portées, donc, et une seule d'entre elles se déduit :
--
--   equipe    — tous ceux qui accompagnent l'enfant, y compris ceux qui
--               arriveront après. C'est ce qu'on décide ensemble et que chacun
--               doit pouvoir retrouver.
--   restreint — exactement les personnes inscrites au fil, et personne d'autre.
--               Aucun rôle n'y donne droit d'entrée, pas même celui de référent.
--
-- Un fil ne change jamais de portée, et ne se rouvre jamais. Élargir après coup
-- reviendrait à publier des propos tenus en confiance. Si un échange doit être
-- partagé, il est réécrit dans un fil d'équipe par la personne qui l'a tenu, qui
-- choisit ce qu'elle en reprend.

create type portee_fil as enum ('restreint', 'equipe');

create table fils (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  portee portee_fil not null,

  sujet text not null default '',

  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  -- Dénormalisé volontairement : trier les fils par activité est la première
  -- chose que fait l'écran, et le faire par sous-requête sur `messages` à chaque
  -- affichage coûterait plus que la colonne ne coûte à tenir à jour.
  dernier_message_le timestamptz not null default now(),
  clos_le timestamptz
);

create index fils_enfant_idx on fils (enfant_id, dernier_message_le desc);

-- Qui est dans le fil, nommément. La table ne sert qu'aux fils restreints ; un
-- fil d'équipe se passe de liste, puisqu'il s'adresse à tout le monde — y
-- compris à l'enseignant qui rejoindra l'équipe le mois prochain.
create table fils_participants (
  fil_id uuid not null references fils on delete cascade,
  profil_id uuid not null references profils on delete cascade,
  ajoute_par uuid references profils on delete set null,
  ajoute_le timestamptz not null default now(),
  primary key (fil_id, profil_id)
);

create index fils_participants_profil_idx on fils_participants (profil_id);

create table messages (
  id uuid primary key default gen_random_uuid(),
  fil_id uuid not null references fils on delete cascade,
  auteur_id uuid not null references profils on delete restrict,
  corps text not null,
  cree_le timestamptz not null default now(),
  -- Un message corrigé le dit. On ne réécrit pas silencieusement ce qu'une
  -- autre personne a déjà lu.
  modifie_le timestamptz
);

create index messages_fil_idx on messages (fil_id, cree_le);

-- Le document partagé vit dans le bucket `echanges` (voir 0015). Une table
-- plutôt qu'une colonne sur `messages` : un compte rendu de réunion arrive
-- rarement seul.
create table pieces_jointes (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references messages on delete cascade,
  nom text not null,
  chemin text not null,
  type_mime text not null default '',
  octets bigint,
  cree_le timestamptz not null default now()
);

create index pieces_jointes_message_idx on pieces_jointes (message_id);

-- Le créateur d'un fil en fait partie. C'est la seule inscription automatique :
-- tout le reste est un geste explicite, sinon on retombe sur des participants
-- déduits, c'est-à-dire sur le défaut qu'on vient d'écarter.
create or replace function inscrire_le_createur()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into fils_participants (fil_id, profil_id, ajoute_par)
  values (new.id, new.cree_par, new.cree_par)
  on conflict do nothing;
  return new;
end;
$$;

create trigger fils_inscrivent_leur_createur
  after insert on fils
  for each row execute function inscrire_le_createur();

-- ------------------------------------------------------------ accès aux fils

-- SECURITY DEFINER, comme les résolutions de 0009 : la politique de `messages`
-- interroge `fils`, dont la politique interrogerait `messages`.
create or replace function acces_au_fil(p_fil uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from fils f
    where f.id = p_fil
      and (
        (f.portee = 'equipe' and est_intervenant(f.enfant_id))
        or exists (
          select 1 from fils_participants p
          where p.fil_id = f.id and p.profil_id = auth.uid()
        )
      )
  );
$$;

create or replace function acces_au_message(p_message uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from messages m where m.id = p_message and acces_au_fil(m.fil_id)
  );
$$;

-- Modifier la composition d'un fil restreint revient à décider qui entend quoi :
-- cela appartient aux parents, et à celui qui a ouvert le fil. Un enseignant
-- inscrit à une conversation privée ne peut pas y faire entrer un collègue.
create or replace function peut_composer_le_fil(p_fil uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from fils f
    where f.id = p_fil
      and (
        f.cree_par = auth.uid()
        or est_intervenant(f.enfant_id, array['parent']::role_intervenant[])
      )
  );
$$;

-- `est_intervenant()` répond pour le compte connecté. Inscrire quelqu'un dans un
-- fil demande de vérifier l'inverse : que la personne *ajoutée* accompagne bien
-- l'enfant. Sans cette fonction, un parent inscrirait à la conversation un
-- compte totalement étranger au dossier.
create or replace function est_intervenant_de(p_profil uuid, p_enfant uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = p_enfant
      and i.profil_id = p_profil
      and i.retire_le is null
  );
$$;

-- La portée se fige ici plutôt que dans la politique : une clause WITH CHECK qui
-- relirait `fils` pour comparer à l'ancienne valeur rouvrirait la table sur
-- elle-même en pleine mise à jour. Un trigger voit OLD et NEW sans détour.
create or replace function figer_la_portee()
returns trigger language plpgsql as $$
begin
  if new.portee is distinct from old.portee then
    raise exception 'La portée d''un fil ne se modifie pas : ouvrez un fil d''équipe et reprenez-y ce qui doit être partagé.';
  end if;
  return new;
end;
$$;

create trigger fils_portee_figee
  before update on fils
  for each row execute function figer_la_portee();

-- ------------------------------------------------------------ notifications

create type type_notification as enum (
  'message',
  'objectif_propose',
  'objectif_modification_demandee',
  'objectif_valide',
  'mission_a_valider',
  'examen_rendu',
  'difficulte_repetee',
  'bilan_pret',
  'invitation',
  'acces_exceptionnel',
  'recompense_approche',
  'recompense_atteinte',
  'badge_obtenu'
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  destinataire_id uuid not null references profils on delete cascade,
  enfant_id uuid references enfants on delete cascade,
  type type_notification not null,

  titre text not null,
  corps text not null default '',
  -- Chemin applicatif : la notification doit mener quelque part, sinon elle
  -- informe sans permettre d'agir.
  lien text not null default '',

  message_id uuid references messages on delete cascade,

  lue_le timestamptz,
  cree_le timestamptz not null default now()
);

-- L'index qui porte la pastille « non lues » sur toutes les pages.
create index notifications_non_lues_idx
  on notifications (destinataire_id, cree_le desc) where lue_le is null;

-- Personne n'insère de notification à la main : elles naissent d'un événement.
-- Le trigger est SECURITY DEFINER et il n'existe aucune politique d'insertion,
-- ce qui rend une notification impossible à forger depuis un client.
--
-- Les destinataires sont exactement ceux qui liront le message. Deux requêtes
-- selon la portée, plutôt qu'une seule qui ruserait : notifier quelqu'un d'un
-- message qu'il ne peut pas ouvrir serait une fuite en soi — le titre du fil
-- suffirait à révéler qu'une conversation existe.
create or replace function notifier_nouveau_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_fil fils%rowtype;
begin
  select * into v_fil from fils where id = new.fil_id;

  update fils
    set dernier_message_le = new.cree_le
    where id = new.fil_id;

  if v_fil.portee = 'equipe' then
    insert into notifications (destinataire_id, enfant_id, type, titre, lien, message_id)
    select
      i.profil_id,
      v_fil.enfant_id,
      'message',
      coalesce(nullif(v_fil.sujet, ''), 'Nouveau message'),
      '/enfants/' || v_fil.enfant_id || '/echanges/' || v_fil.id,
      new.id
    from intervenants_enfant i
    where i.enfant_id = v_fil.enfant_id
      and i.retire_le is null
      and i.profil_id <> new.auteur_id;
  else
    insert into notifications (destinataire_id, enfant_id, type, titre, lien, message_id)
    select
      p.profil_id,
      v_fil.enfant_id,
      'message',
      coalesce(nullif(v_fil.sujet, ''), 'Nouveau message'),
      '/enfants/' || v_fil.enfant_id || '/echanges/' || v_fil.id,
      new.id
    from fils_participants p
    where p.fil_id = v_fil.id
      and p.profil_id <> new.auteur_id;
  end if;

  return new;
end;
$$;

create trigger messages_notifient
  after insert on messages
  for each row execute function notifier_nouveau_message();

-- ==================================================================== RLS

alter table fils              enable row level security;
alter table fils_participants enable row level security;
alter table messages          enable row level security;
alter table pieces_jointes    enable row level security;
alter table notifications     enable row level security;

create policy fils_lecture on fils for select to authenticated
  using (acces_au_fil(id));

create policy fils_creation on fils for insert to authenticated
  with check (cree_par = auth.uid() and est_intervenant(enfant_id));

-- Le sujet et la clôture se modifient ; la portée est tenue par le trigger.
create policy fils_maj on fils for update to authenticated
  using (acces_au_fil(id))
  with check (acces_au_fil(id));

create policy fils_participants_lecture on fils_participants for select to authenticated
  using (acces_au_fil(fil_id));

create policy fils_participants_ajout on fils_participants for insert to authenticated
  with check (
    peut_composer_le_fil(fil_id)
    and exists (
      select 1 from fils f
      where f.id = fil_id and est_intervenant_de(profil_id, f.enfant_id)
    )
  );

create policy fils_participants_retrait on fils_participants for delete to authenticated
  using (peut_composer_le_fil(fil_id) or profil_id = auth.uid());

create policy messages_lecture on messages for select to authenticated
  using (acces_au_fil(fil_id));

create policy messages_ecriture on messages for insert to authenticated
  with check (acces_au_fil(fil_id) and auteur_id = auth.uid());

-- On corrige ses propres mots, jamais ceux d'un autre.
create policy messages_correction on messages for update to authenticated
  using (auteur_id = auth.uid()) with check (auteur_id = auth.uid());

create policy pieces_jointes_lecture on pieces_jointes for select to authenticated
  using (acces_au_message(message_id));

create policy pieces_jointes_depot on pieces_jointes for insert to authenticated
  with check (acces_au_message(message_id));

create policy notifications_lecture on notifications for select to authenticated
  using (destinataire_id = auth.uid());

-- Marquer comme lue, et rien d'autre.
create policy notifications_maj on notifications for update to authenticated
  using (destinataire_id = auth.uid()) with check (destinataire_id = auth.uid());

create policy notifications_suppression on notifications for delete to authenticated
  using (destinataire_id = auth.uid());
