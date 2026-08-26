-- 0059 — Faire sortir les notifications de la base.
--
-- Depuis 0014, chaque événement notable écrit une ligne dans `notifications` :
-- un objectif à valider, un message, un blocage répété, une récompense atteinte.
-- Aucune ne quitte jamais la base. Un parent qui n'ouvre pas l'application
-- n'apprend rien — et c'est précisément le parent qu'il faut atteindre.
--
-- ---------------------------------------------------------------------------
-- AGNOSTIQUE AU CANAL, DÈS MAINTENANT
--
-- Le courriel est indispensable : c'est le seul canal qui atteint quelqu'un qui
-- n'a rien installé. Le push est nécessaire aussi — sur iPhone, une notification
-- fiable suppose une application native, et beaucoup de familles sont sur iOS.
--
-- Les deux coexisteront donc, et la file les traite pareil : un envoi porte un
-- canal, un destinataire, un contenu et un état. Ajouter un canal plus tard sera
-- une valeur d'énumération, pas une refonte.
--
-- ---------------------------------------------------------------------------
-- POURQUOI UNE FILE, ET NON UN APPEL DIRECT
--
-- La tentation serait d'appeler le service d'envoi depuis l'action serveur qui
-- crée la notification. Trois raisons de ne pas le faire, toutes vécues :
--
--   un envoi qui échoue dans une action serveur échoue en silence. L'action
--   réussit, l'utilisateur voit sa page, et personne n'apprend que le courriel
--   n'est jamais parti ;
--
--   les notifications naissent dans des triggers — un badge attribué, une
--   alerte de blocage. Postgres ne peut pas appeler un service HTTP depuis un
--   trigger sans extension, et le voudrait-il qu'un service lent bloquerait la
--   transaction qui l'a déclenché ;
--
--   sans trace, un envoi perdu est indiscernable d'un envoi jamais demandé.
--
-- La file rend l'échec visible et l'envoi rejouable. C'est toute sa raison
-- d'être.
-- ---------------------------------------------------------------------------

create type canal_envoi as enum ('courriel', 'push');
create type statut_envoi as enum ('a_envoyer', 'envoye', 'echec', 'abandonne');
create type plateforme_appareil as enum ('ios', 'android', 'web');

-- ------------------------------------------------------------ les appareils

create table appareils (
  id uuid primary key default gen_random_uuid(),
  profil_id uuid not null references profils on delete cascade,

  jeton_push text not null,
  plateforme plateforme_appareil not null,
  -- « iPhone de Camille » : sert à ce que quelqu'un puisse retirer un appareil
  -- perdu sans se demander lequel des trois jetons lui appartenait.
  libelle text not null default '',

  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  derniere_utilisation timestamptz,

  unique (jeton_push)
);

create index appareils_profil_idx on appareils (profil_id) where actif;

alter table appareils enable row level security;

-- Chacun ne voit et ne gère que ses propres appareils. Un jeton push est un
-- identifiant d'appareil personnel : le rendre lisible à un tiers reviendrait à
-- lui dire sur quoi et depuis où quelqu'un se connecte.
create policy appareils_gestion on appareils for all to authenticated
  using (profil_id = auth.uid()) with check (profil_id = auth.uid());

-- ------------------------------------------------------- les préférences

-- Par défaut, tout le monde reçoit tout par courriel. C'est le bon défaut au
-- démarrage : mieux vaut une famille qui coupe ce qui la gêne qu'une famille
-- qui n'apprend jamais qu'un objectif attend sa signature.
--
-- Une exception : `interaction_courte` et les mouvements de récompense ne
-- justifient pas un courriel. Ils vivent dans l'application.
create table preferences_notification (
  profil_id uuid not null references profils on delete cascade,
  type type_notification not null,
  canal canal_envoi not null,
  actif boolean not null default true,
  primary key (profil_id, type, canal)
);

alter table preferences_notification enable row level security;

create policy preferences_gestion on preferences_notification for all to authenticated
  using (profil_id = auth.uid()) with check (profil_id = auth.uid());

-- Les types qui méritent de sortir de l'application. Les autres restent
-- consultables sans venir chercher personne.
create or replace function type_notifie_hors_application(p_type type_notification)
returns boolean
language sql immutable as $$
  select p_type in (
    'message',
    'objectif_propose',
    'objectif_modification_demandee',
    'mission_a_valider',
    'difficulte_repetee',
    'bilan_pret',
    'invitation',
    'acces_exceptionnel',
    'habilitation_demandee',
    'habilitation_traitee',
    'quete_reussie'
  );
$$;

-- --------------------------------------------------------------- la file

create table envois (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid references notifications on delete set null,

  destinataire_id uuid not null references profils on delete cascade,
  canal canal_envoi not null,

  -- Recopiés, pas joints. Une adresse change, un jeton se révoque, une
  -- notification se supprime : ce qui a été envoyé doit rester lisible tel qu'il
  -- a été envoyé, sans dépendre de ce que les tables sont devenues.
  adresse text not null,
  sujet text not null default '',
  corps text not null default '',
  lien text not null default '',

  statut statut_envoi not null default 'a_envoyer',
  tentatives smallint not null default 0,
  derniere_erreur text not null default '',
  envoye_le timestamptz,

  cree_le timestamptz not null default now()
);

create index envois_a_traiter_idx
  on envois (cree_le) where statut = 'a_envoyer';
create index envois_destinataire_idx on envois (destinataire_id, cree_le desc);

-- ------------------------------------------------- de la notification à l'envoi

create or replace function mettre_en_file()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_email text;
  v_appareil record;
begin
  if not type_notifie_hors_application(new.type) then
    return new;
  end if;

  select email into v_email from profils where id = new.destinataire_id;

  -- Courriel : actif sauf refus explicite. L'absence de préférence vaut accord,
  -- sinon personne ne recevrait rien tant qu'il n'a pas visité un écran de
  -- réglages qu'il n'a aucune raison d'ouvrir.
  if v_email is not null and v_email <> '' and not exists (
    select 1 from preferences_notification p
    where p.profil_id = new.destinataire_id
      and p.type = new.type and p.canal = 'courriel' and not p.actif
  ) then
    insert into envois
      (notification_id, destinataire_id, canal, adresse, sujet, corps, lien)
    values
      (new.id, new.destinataire_id, 'courriel', v_email, new.titre, new.corps, new.lien);
  end if;

  -- Push : un envoi par appareil actif. Pas de préférence par défaut non plus,
  -- mais la question ne se pose que pour qui a installé l'application — donc
  -- pour qui a déjà accepté les notifications au niveau du système.
  for v_appareil in
    select a.jeton_push from appareils a
    where a.profil_id = new.destinataire_id and a.actif
  loop
    if not exists (
      select 1 from preferences_notification p
      where p.profil_id = new.destinataire_id
        and p.type = new.type and p.canal = 'push' and not p.actif
    ) then
      insert into envois
        (notification_id, destinataire_id, canal, adresse, sujet, corps, lien)
      values
        (new.id, new.destinataire_id, 'push', v_appareil.jeton_push,
         new.titre, new.corps, new.lien);
    end if;
  end loop;

  return new;
end;
$$;

create trigger notifications_alimentent_la_file
  after insert on notifications
  for each row execute function mettre_en_file();

-- ==================================================================== RLS

alter table envois enable row level security;

-- Chacun voit ce qui lui a été envoyé — et c'est utile : « je n'ai rien reçu »
-- se vérifie alors en un coup d'œil, au lieu de se discuter.
create policy envois_lecture on envois for select to authenticated
  using (destinataire_id = auth.uid() or est_admin());

-- Aucune écriture depuis l'application : la file se remplit par le trigger et se
-- vide par le service d'envoi, qui utilise la clé de service et n'est pas soumis
-- à ces politiques.

-- ------------------------------------------------- ce que l'administration voit

-- Les envois qui échouent. Sans cet écran, une clé d'API expirée passerait
-- inaperçue jusqu'à ce qu'une famille signale n'avoir rien reçu depuis trois
-- semaines — et il serait alors trop tard pour les alertes de blocage.
create or replace function envois_en_echec(p_depuis_jours integer default 7)
returns table (
  canal canal_envoi,
  statut statut_envoi,
  nombre bigint,
  derniere_erreur text,
  dernier_le timestamptz
)
language sql stable security definer set search_path = public as $$
  select e.canal, e.statut, count(*), max(e.derniere_erreur), max(e.cree_le)
  from envois e
  where e.statut in ('echec', 'abandonne')
    and e.cree_le >= now() - make_interval(days => p_depuis_jours)
    and est_admin()
  group by e.canal, e.statut
  order by 3 desc;
$$;
