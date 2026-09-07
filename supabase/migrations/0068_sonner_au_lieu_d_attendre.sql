-- 0068 — Faire partir un courriel maintenant, sans l'envoyer deux fois.
--
-- 0059 a fait de la file la source de vérité, et c'était juste. Restait à
-- décider quand on la vide. Une tâche planifiée sur l'hébergeur ne descend pas
-- sous la journée dans le plan gratuit, et une alerte de blocage qui arrive le
-- lendemain arrive après le découragement qu'elle devait éviter — c'est le
-- risque du §3.4, pas un confort.
--
-- ---------------------------------------------------------------------------
-- UNE SONNETTE, PAS UN APPEL DIRECT
--
-- 0059 refusait d'appeler le service d'envoi depuis un trigger, pour deux
-- raisons dont une seule tient encore :
--
--   « Postgres ne peut pas appeler un service HTTP sans extension » — pg_net
--   est cette extension ;
--
--   « un service lent bloquerait la transaction qui l'a déclenché » — pg_net
--   est asynchrone : il dépose la requête dans sa propre file et rend la main.
--   La transaction qui a créé la notification ne l'attend pas.
--
-- Ce qui reste vrai, et qui ne change pas : un envoi déclenché ainsi peut se
-- perdre en silence. La sonnette ne remplace donc pas la file, elle la réveille.
-- Trois filets, du plus rapide au plus sûr :
--
--   la sonnette      — à l'insertion, quelques secondes ;
--   pg_cron          — toutes les cinq minutes, rattrape les échecs et ce que
--                      la sonnette a perdu ;
--   la tâche Vercel  — une fois par jour, si les extensions sont tombées.
--
-- ---------------------------------------------------------------------------
-- POURQUOI RÉSERVER AVANT D'ENVOYER
--
-- Trois déclencheurs, c'est trois passages qui peuvent se recouvrir. Deux
-- passages simultanés liraient les mêmes lignes `a_envoyer` et enverraient deux
-- fois le même courriel. Le moment où cela arriverait est précisément le pire :
-- au redémarrage après une panne, quand la file est pleine et que chaque lot
-- prend longtemps.
--
-- Un verrou consultatif ne convient pas ici : les appels passent par PostgREST,
-- dont les connexions sont mutualisées — poser le verrou et le lever seraient
-- deux requêtes qui n'atterrissent pas forcément sur la même session, et le
-- verrou resterait pris par une connexion au repos.
--
-- La réservation vit donc dans la ligne elle-même, et `for update skip locked`
-- fait que deux passages simultanés se partagent le travail au lieu de le
-- refaire.
-- ---------------------------------------------------------------------------

alter table envois add column reserve_le timestamptz;

-- Au-delà, on considère que le passage qui avait réservé n'ira pas au bout —
-- fonction interrompue, instance recyclée — et la ligne redevient à prendre.
-- Cinq minutes couvrent largement un lot complet, qui se compte en secondes.
create or replace function reserver_envois(
  p_lot integer default 50,
  p_tentatives_max integer default 5
)
returns setof envois
language sql
volatile
security definer
set search_path = public
as $$
  update envois e
  set reserve_le = now()
  where e.id in (
    select c.id
    from envois c
    where c.canal = 'courriel'
      -- On reprend aussi les échecs récupérables : un envoi raté une fois doit
      -- repartir, sinon la file se remplit d'attentes que rien ne relance.
      and (
        c.statut = 'a_envoyer'
        or (c.statut = 'echec' and c.tentatives < p_tentatives_max)
      )
      and (c.reserve_le is null or c.reserve_le < now() - interval '5 minutes')
    order by c.cree_le
    limit p_lot
    for update skip locked
  )
  returning e.*;
$$;

-- SECURITY DEFINER contourne RLS : exposée telle quelle, cette fonction
-- laisserait n'importe quel compte connecté réserver la file entière, donc
-- empêcher tout envoi pendant cinq minutes, en boucle. Elle n'appartient qu'au
-- service d'envoi, qui n'emprunte aucun de ces rôles.
revoke execute on function reserver_envois(integer, integer) from public;
revoke execute on function reserver_envois(integer, integer) from anon;
revoke execute on function reserver_envois(integer, integer) from authenticated;

-- Et rendu explicitement au seul rôle qui doit l'appeler. Le retrait à `public`
-- ci-dessus emporte l'héritage de `service_role` : sans cette ligne, la route
-- d'envoi se verrait refuser sa propre fonction.
grant execute on function reserver_envois(integer, integer) to service_role;

-- ------------------------------------------------------------- la sonnette

-- L'adresse et le secret vivent dans Vault, pas dans cette migration : ils
-- diffèrent entre l'aperçu et la production, et une migration appliquée ne se
-- modifie jamais. À créer une fois, dans Supabase › Project Settings › Vault :
--
--   xylou_url_envois   https://…/api/envois
--   xylou_cron_secret  la même valeur que CRON_SECRET côté hébergeur
--
-- Tant qu'ils manquent, la sonnette ne sonne pas et les deux autres filets
-- suffisent : c'est un envoi plus tardif, jamais un envoi perdu.
create or replace function sonner_la_file()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'xylou_url_envois';
  select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'xylou_cron_secret';

  if v_url is null or v_secret is null then
    return null;
  end if;

  -- Asynchrone : la transaction qui vient d'écrire dans la file ne l'attend pas.
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_secret
    ),
    timeout_milliseconds := 60000
  );

  return null;
end;
$$;

-- Par instruction et non par ligne : un message d'équipe crée autant d'envois
-- que de destinataires, et il suffit d'une sonnette pour les faire tous partir.
create trigger envois_sonnent
  after insert on envois
  for each statement execute function sonner_la_file();

-- ==================================================== ce qui reste à faire
--
-- Ces deux commandes ne sont pas dans la migration : elles supposent les
-- extensions activées (Database › Extensions : `pg_net`, `pg_cron`) et les
-- secrets créés. À passer une fois, après le reste de ce fichier.
--
--   select cron.schedule(
--     'xylou-vider-la-file',
--     '*/5 * * * *',
--     $cron$
--     select net.http_post(
--       url := (select decrypted_secret from vault.decrypted_secrets
--               where name = 'xylou_url_envois'),
--       headers := jsonb_build_object(
--         'Content-Type', 'application/json',
--         'Authorization', 'Bearer ' || (select decrypted_secret
--                                        from vault.decrypted_secrets
--                                        where name = 'xylou_cron_secret')
--       ),
--       timeout_milliseconds := 60000
--     );
--     $cron$
--   );
--
-- Pour l'arrêter : select cron.unschedule('xylou-vider-la-file');
