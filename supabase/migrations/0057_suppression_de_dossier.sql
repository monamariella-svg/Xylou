-- 0057 — Supprimer un dossier : masquer d'abord, purger au terme légal.
--
-- 0024 interdit la suppression dès que deux titulaires sont rattachés, et
-- renvoie vers l'archivage. C'était juste, mais il n'existait aucune procédure :
-- les cas légitimes — dossier ouvert par erreur, doublon, famille qui quitte le
-- dispositif — se réglaient à la main dans le SQL Editor, dans un ordre que
-- personne ne devine.
--
-- ---------------------------------------------------------------------------
-- SUPPRIMER SE FAIT EN DEUX TEMPS
--
-- Il n'y a pas deux voies concurrentes — une suppression immédiate et un
-- archivage — mais une seule, en deux temps :
--
--   1. le masquage, dès l'accord des titulaires. Le dossier disparaît pour
--      tout le monde, famille comprise. C'est ce que la famille demande et ce
--      qu'elle constate : pour elle, c'est supprimé.
--
--   2. la purge, au terme de la durée légale de conservation. Les données sont
--      alors physiquement effacées.
--
-- Entre les deux, personne ne lit rien. `est_intervenant()` écarte les dossiers
-- archivés depuis 0031, et aucune politique n'ouvre le contenu à
-- l'administration. Un besoin légitime dans l'intervalle — réquisition, litige
-- — passe par l'accès d'exception de 0028, motivé et tracé.
--
-- La durée reste celle de 0031, et elle reste un placeholder de cinq ans. C'est
-- la question 5.1 du document juriste, et elle est maintenant bloquante : elle
-- ne détermine plus seulement une politique interne, mais ce qu'on écrit à une
-- famille qui demande l'effacement.
--
-- ---------------------------------------------------------------------------
-- CE QUI SURVIT À LA PURGE
--
-- Tout part en cascade, `journal_acces` compris — donc la trace disparaîtrait
-- avec ce qu'elle documente. `suppressions_effectuees` n'a volontairement
-- aucune clé étrangère vers `enfants` : c'est ce qui lui permet de rester.
--
-- Elle ne conserve aucune donnée du dossier — seulement qui a demandé, qui a
-- consenti, qui a exécuté, quand le masquage a eu lieu et quand la purge a
-- suivi. C'est la preuve qu'on avait le droit, pas une copie de ce qu'on a
-- effacé.
-- ---------------------------------------------------------------------------

create type statut_suppression as enum ('en_attente', 'accordee', 'masquee', 'purgee', 'annulee');

create table demandes_suppression (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid references enfants on delete set null,

  demandee_par uuid not null references profils on delete restrict,
  motif text not null check (length(btrim(motif)) >= 15),

  statut statut_suppression not null default 'en_attente',
  masquee_par uuid references profils on delete set null,
  masquee_le timestamptz,
  purge_prevue_le date,
  purgee_le timestamptz,
  motif_annulation text not null default '',

  cree_le timestamptz not null default now()
);

-- `on delete set null` et non `cascade` : la demande doit survivre à la purge du
-- dossier qu'elle a provoquée, sinon la dernière étape efface sa propre
-- justification.
create unique index suppression_une_seule_en_cours
  on demandes_suppression (enfant_id)
  where statut in ('en_attente', 'accordee') and enfant_id is not null;

-- L'accord de chaque titulaire, signé comme un consentement. Une case cochée par
-- un parent au nom du couple ne vaut rien, et c'est exactement le cas qu'on
-- craint : le parent qui efface avant que l'autre s'en aperçoive.
create table suppressions_accords (
  demande_id uuid not null references demandes_suppression on delete cascade,
  profil_id uuid not null references profils on delete cascade,
  signature_nom text not null check (length(btrim(signature_nom)) >= 2),
  accorde_le timestamptz not null default now(),
  primary key (demande_id, profil_id)
);

create table suppressions_effectuees (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null,
  prenom text not null default '',
  demandee_par uuid references profils on delete set null,
  motif text not null,
  accords jsonb not null default '[]'::jsonb,
  masquee_par uuid references profils on delete set null,
  masquee_le timestamptz not null default now(),
  purge_prevue_le date,
  purgee_le timestamptz
);

create index suppressions_effectuees_idx on suppressions_effectuees (masquee_le desc);
create index suppressions_a_purger_idx
  on suppressions_effectuees (purge_prevue_le) where purgee_le is null;

-- ---------------------------------------------------------------- demander

create or replace function demander_la_suppression(p_enfant uuid, p_motif text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_demande uuid;
begin
  if not (est_admin() or est_intervenant(p_enfant, array['parent']::role_intervenant[])) then
    raise exception 'La suppression d''un dossier se demande par un titulaire de l''autorité parentale, ou par l''administration.';
  end if;

  if length(btrim(p_motif)) < 15 then
    raise exception 'Dites pourquoi ce dossier doit être supprimé : c''est ce que les titulaires liront avant de donner leur accord.';
  end if;

  insert into demandes_suppression (enfant_id, demandee_par, motif)
  values (p_enfant, auth.uid(), btrim(p_motif))
  returning id into v_demande;

  -- Tous les titulaires sont prévenus, y compris le demandeur s'il en est un :
  -- il doit signer comme les autres, et le voir dans sa liste évite qu'il
  -- attende un accord qui n'attend que lui.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'message',
         'Demande de suppression du dossier',
         btrim(p_motif),
         '/enfants/' || p_enfant || '/suppression/' || v_demande
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.retire_le is null
    and i.role in ('parent', 'referent');

  return v_demande;
end;
$$;

-- ---------------------------------------------------------------- accorder

create or replace function accorder_la_suppression(p_demande uuid, p_signature text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid;
  v_manquants integer;
begin
  select enfant_id into v_enfant from demandes_suppression
  where id = p_demande and statut = 'en_attente';

  if v_enfant is null then
    raise exception 'Demande introuvable, déjà accordée ou annulée.';
  end if;

  if not est_intervenant(v_enfant, array['parent']::role_intervenant[]) then
    raise exception 'Seuls les titulaires de l''autorité parentale accordent la suppression.';
  end if;

  insert into suppressions_accords (demande_id, profil_id, signature_nom)
  values (p_demande, auth.uid(), btrim(p_signature))
  on conflict do nothing;

  -- Tous les titulaires rattachés, sans exception. La composition déclarée sert
  -- ici comme pour le quorum de 0023 : si un second titulaire est annoncé mais
  -- n'a jamais rejoint, rien ne s'efface — et c'est voulu.
  select count(*) into v_manquants
  from intervenants_enfant i
  where i.enfant_id = v_enfant and i.role = 'parent' and i.retire_le is null
    and not exists (
      select 1 from suppressions_accords a
      where a.demande_id = p_demande and a.profil_id = i.profil_id
    );

  if v_manquants > 0 or not composition_parentale_complete(v_enfant) then
    return false;
  end if;

  update demandes_suppression set statut = 'accordee' where id = p_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, v_enfant, 'message',
         'Suppression de dossier accordée',
         'Tous les titulaires ont donné leur accord. Le dossier peut être masqué.',
         '/administration/suppressions/' || p_demande
  from profils p where p.role_plateforme = 'admin';

  return true;
end;
$$;

-- ------------------------------------------------------ premier temps : masquer

create or replace function masquer_le_dossier(p_demande uuid)
returns date
language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid;
  v_prenom text;
  v_motif text;
  v_demandeur uuid;
  v_accords jsonb;
  v_purge date;
begin
  if not est_admin() then
    raise exception 'Le masquage d''un dossier revient à l''administration.';
  end if;

  select d.enfant_id, d.motif, d.demandee_par
    into v_enfant, v_motif, v_demandeur
  from demandes_suppression d
  where d.id = p_demande and d.statut = 'accordee';

  if v_enfant is null then
    raise exception 'Cette demande n''a pas reçu l''accord de tous les titulaires.';
  end if;

  select prenom into v_prenom from enfants where id = v_enfant;

  select coalesce(jsonb_agg(jsonb_build_object(
           'profil', a.profil_id, 'signature', a.signature_nom, 'le', a.accorde_le)), '[]'::jsonb)
    into v_accords
  from suppressions_accords a where a.demande_id = p_demande;

  -- Même durée qu'en 0031 : une suppression demandée et un archivage ordinaire
  -- n'ont aucune raison de se conserver différemment.
  v_purge := (now() + interval '5 years')::date;

  -- Le laissez-passer de 0031 : les colonnes d'archivage ne se posent que par
  -- les fonctions prévues.
  perform set_config('xylou.archivage', 'en_cours', true);

  update enfants
    set archive_le = now(),
        archive_par = auth.uid(),
        motif_archivage = v_motif,
        purge_prevue_le = v_purge
    where id = v_enfant;

  perform set_config('xylou.archivage', '', true);

  update demandes_suppression
    set statut = 'masquee', masquee_par = auth.uid(),
        masquee_le = now(), purge_prevue_le = v_purge
    where id = p_demande;

  insert into suppressions_effectuees
    (enfant_id, prenom, demandee_par, motif, accords, masquee_par, purge_prevue_le)
  values
    (v_enfant, coalesce(v_prenom, ''), v_demandeur, v_motif, v_accords, auth.uid(), v_purge);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (v_enfant, auth.uid(), 'dossier_masque', 'enfants', v_enfant,
          jsonb_build_object('motif', v_motif, 'purge_prevue_le', v_purge));

  return v_purge;
end;
$$;

-- ------------------------------------------------------ second temps : purger

-- L'effacement physique, une fois le terme atteint. Il porte sur tous les
-- dossiers archivés dont la date est passée — qu'ils l'aient été sur demande de
-- la famille ou par l'archivage ordinaire de 0031.
--
-- Volontairement manuel : une purge automatique effacerait des dossiers un
-- dimanche matin sans que personne ne l'ait décidé ce jour-là, et une erreur de
-- date se paierait sans recours. L'administration lance, et voit ce qu'elle
-- lance.
-- 0031 en renvoyait trois colonnes, celle-ci en renvoie six. `create or replace`
-- ne sait pas changer la forme d'une fonction qui retourne une table : il faut
-- la supprimer d'abord.
drop function if exists dossiers_a_purger();

create function dossiers_a_purger()
returns table (
  enfant_id uuid,
  prenom text,
  archive_le timestamptz,
  purge_prevue_le date,
  jours_de_retard integer,
  sur_demande boolean
)
language sql stable security definer set search_path = public as $$
  select
    e.id, e.prenom, e.archive_le, e.purge_prevue_le,
    (current_date - e.purge_prevue_le)::integer,
    exists (select 1 from demandes_suppression d
            where d.enfant_id = e.id and d.statut = 'masquee')
  from enfants e
  where e.archive_le is not null
    and e.purge_prevue_le is not null
    and e.purge_prevue_le <= current_date
    and est_admin()
  order by e.purge_prevue_le;
$$;

create or replace function purger_le_dossier(p_enfant uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_prenom text;
  v_purge date;
begin
  if not est_admin() then
    raise exception 'La purge revient à l''administration.';
  end if;

  select prenom, purge_prevue_le into v_prenom, v_purge
  from enfants
  where id = p_enfant and archive_le is not null;

  if v_prenom is null then
    raise exception 'Ce dossier n''existe pas, ou n''est pas masqué.';
  end if;

  if v_purge is null or v_purge > current_date then
    raise exception 'Le terme de conservation n''est pas atteint : purge prévue le %.', v_purge;
  end if;

  -- Consigner d'abord. Après les suppressions, il n'y aurait plus de quoi
  -- écrire, et une transaction qui échouerait entre les deux laisserait un
  -- dossier effacé sans justification.
  update suppressions_effectuees
    set purgee_le = now()
    where enfant_id = p_enfant and purgee_le is null;

  if not found then
    -- Archivage ordinaire, sans demande de suppression : on inscrit tout de
    -- même la purge, sinon elle ne laisserait aucune trace.
    insert into suppressions_effectuees
      (enfant_id, prenom, motif, masquee_par, masquee_le, purge_prevue_le, purgee_le)
    select p_enfant, coalesce(v_prenom, ''),
           coalesce(nullif(e.motif_archivage, ''), 'Archivage arrivé à terme'),
           e.archive_par, e.archive_le, e.purge_prevue_le, now()
    from enfants e where e.id = p_enfant;
  end if;

  update demandes_suppression
    set statut = 'purgee', purgee_le = now()
    where enfant_id = p_enfant and statut = 'masquee';

  -- L'ordre qui piège, encapsulé une fois pour toutes.
  delete from intervenants_enfant where enfant_id = p_enfant;
  delete from enfants where id = p_enfant;
end;
$$;

-- ---------------------------------------------------------------- annuler

create or replace function annuler_la_suppression(p_demande uuid, p_motif text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid;
  v_statut statut_suppression;
begin
  select enfant_id, statut into v_enfant, v_statut
  from demandes_suppression where id = p_demande;

  if v_statut not in ('en_attente', 'accordee', 'masquee') then
    raise exception 'Demande introuvable ou déjà purgée.';
  end if;

  -- Un seul titulaire suffit à arrêter. Il faut l'unanimité pour effacer, une
  -- seule voix pour s'y opposer : l'asymétrie est le but.
  --
  -- Tant que la purge n'a pas eu lieu, le retour en arrière reste possible — et
  -- c'est tout l'intérêt des deux temps. Une famille qui se ravise trois mois
  -- plus tard retrouve son dossier intact.
  if not (est_admin() or est_intervenant(v_enfant, array['parent']::role_intervenant[])) then
    raise exception 'Seuls les titulaires de l''autorité parentale et l''administration peuvent arrêter une suppression.';
  end if;

  if v_statut = 'masquee' then
    if not est_admin() then
      raise exception 'Un dossier déjà masqué se rouvre par l''administration.';
    end if;
    perform desarchiver_le_dossier(v_enfant, btrim(p_motif));
    delete from suppressions_effectuees
      where enfant_id = v_enfant and purgee_le is null;
  end if;

  update demandes_suppression
    set statut = 'annulee', motif_annulation = btrim(p_motif)
    where id = p_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, v_enfant, 'message',
         'Suppression annulée', btrim(p_motif),
         '/enfants/' || v_enfant
  from intervenants_enfant i
  where i.enfant_id = v_enfant and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();
end;
$$;

-- ------------------------------------------------- le tableau de l'administration

create or replace function suppressions_en_cours()
returns table (
  demande_id uuid,
  enfant_id uuid,
  prenom text,
  motif text,
  statut statut_suppression,
  demandee_par_prenom text,
  accords bigint,
  titulaires bigint,
  purge_prevue_le date,
  depuis_jours integer
)
language sql stable security definer set search_path = public as $$
  select
    d.id, d.enfant_id, coalesce(e.prenom, ''), d.motif, d.statut,
    coalesce(p.prenom, ''),
    (select count(*) from suppressions_accords a where a.demande_id = d.id),
    (select count(*) from intervenants_enfant i
      where i.enfant_id = d.enfant_id and i.role = 'parent' and i.retire_le is null),
    d.purge_prevue_le,
    (current_date - d.cree_le::date)::integer
  from demandes_suppression d
  left join enfants e on e.id = d.enfant_id
  left join profils p on p.id = d.demandee_par
  where d.statut in ('en_attente', 'accordee', 'masquee')
    and est_admin()
  order by d.statut, d.cree_le;
$$;

-- ==================================================================== RLS

alter table demandes_suppression enable row level security;
alter table suppressions_accords enable row level security;
alter table suppressions_effectuees enable row level security;

-- Une fois le dossier masqué, `est_intervenant()` renvoie faux : la famille ne
-- voit plus sa demande non plus. C'est cohérent — pour elle, c'est supprimé.
create policy suppressions_lecture on demandes_suppression for select to authenticated
  using (
    est_admin()
    or (enfant_id is not null and est_intervenant(enfant_id))
  );

create policy suppressions_accords_lecture on suppressions_accords for select to authenticated
  using (
    est_admin()
    or exists (select 1 from demandes_suppression d
               where d.id = demande_id and d.enfant_id is not null
                 and est_intervenant(d.enfant_id))
  );

-- Le registre n'appartient qu'à l'administration : il porte des noms d'enfants
-- dont les dossiers n'existent plus, et personne d'autre n'a de raison de les
-- lire.
create policy suppressions_effectuees_lecture on suppressions_effectuees
  for select to authenticated using (est_admin());

-- Aucune politique d'écriture : tout passe par les fonctions ci-dessus, qui
-- vérifient les droits, l'unanimité, le terme, et l'ordre des opérations.
