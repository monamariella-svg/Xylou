-- 0077 — Générer un bilan : une file, un bouton, et une raison quand il est gris.
--
-- `docs/pre-bilan-et-bilan.md` pose la règle : rien ne se génère tout seul, un
-- bilan produit pour un enfant qui ne le passera pas est une dépense pour rien.
-- Le geste appartient au référent, enfant par enfant.
--
-- Mais un référent prépare une séance pour son groupe. Douze générations ne
-- tiennent pas dans une requête : chacune prend des dizaines de secondes, une
-- boucle synchrone dépasserait la limite d'exécution d'une fonction serverless,
-- et le référent verrait une page d'erreur au milieu sans savoir lesquels sont
-- partis.
--
-- C'est exactement la situation de la file d'envoi (0059, 0068), et la réponse
-- est la même : le bouton dépose des demandes, un traitement de fond les prend
-- une par une, l'écran montre l'avancement. Une génération qui échoue se rejoue
-- sans refaire les onze autres.
--
-- ---------------------------------------------------------------------------
-- CE QUE CETTE FILE PROTÈGE QUE CELLE DES ENVOIS NE PROTÉGEAIT PAS
--
-- Un courriel envoyé deux fois est une gêne. Un bilan généré deux fois est une
-- facture double, et deux brouillons contradictoires pour le même enfant.
--
-- D'où deux verrous, et non un :
--
--   `reserver_generations()` reprend le `for update skip locked` de 0068 —
--   deux traitements simultanés ne prennent jamais la même ligne ;
--
--   un index unique partiel interdit qu'une seconde demande soit *déposée*
--   pour un enfant qui en a déjà une en attente. Le double-clic ne coûte rien.
-- ---------------------------------------------------------------------------

create type statut_generation as enum (
  'en_attente',
  'en_cours',
  'terminee',
  'echec',
  -- Le référent se ravise avant que le traitement ne parte. Distinct de
  -- `echec` : rien n'a été tenté, rien n'a été facturé.
  'annulee'
);

create table generations_bilan (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  -- Le bilan produit. Nul tant que la génération n'a pas abouti : c'est elle
  -- qui le crée, pas le bouton. Un bilan vide déposé à l'avance apparaîtrait
  -- dans le dossier de l'enfant comme un bilan raté.
  bilan_id uuid references bilans_positionnement on delete set null,

  -- Recopiés au dépôt, comme 0059 recopie l'adresse d'un envoi : la classe de
  -- l'enfant peut changer entre la demande et le traitement, et ce qui a été
  -- demandé doit rester lisible tel qu'il a été demandé.
  classe_reference niveau_classe,
  matieres text[] not null default '{}',

  statut statut_generation not null default 'en_attente',
  tentatives smallint not null default 0,
  derniere_erreur text not null default '',
  reserve_le timestamptz,

  -- Ce que la génération a réellement coûté, une fois faite. `journal_ia`
  -- porte le détail ; ici, le total, pour que l'écran puisse le montrer sans
  -- une jointure d'agrégation à chaque affichage.
  cout_centimes numeric(10, 4) not null default 0,

  demande_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  terminee_le timestamptz
);

-- Une seule demande vivante par enfant. Le pendant, pour la file, de
-- `bilans_un_seul_en_cours` (0004) : celui-là empêche deux bilans ouverts,
-- celui-ci empêche que deux soient commandés.
create unique index generations_une_seule_en_cours
  on generations_bilan (enfant_id)
  where statut in ('en_attente', 'en_cours');

create index generations_a_traiter_idx
  on generations_bilan (cree_le)
  where statut in ('en_attente', 'echec');

alter table generations_bilan enable row level security;

-- Toute l'équipe voit qu'une génération est en cours — sans quoi deux
-- intervenants se demanderaient pourquoi le bouton ne répond pas.
create policy generations_lecture on generations_bilan
  for select to authenticated
  using (est_intervenant(enfant_id) or est_admin());

-- Mais le geste appartient au référent. Un enseignant invité sur un dossier ne
-- déclenche pas une dépense sur le budget de la famille.
create policy generations_depot on generations_bilan
  for insert to authenticated
  with check (
    est_intervenant(enfant_id, array['referent', 'parent']::role_intervenant[])
    and demande_par = auth.uid()
  );

create policy generations_annulation on generations_bilan
  for update to authenticated
  using (est_intervenant(enfant_id, array['referent', 'parent']::role_intervenant[]))
  with check (est_intervenant(enfant_id, array['referent', 'parent']::role_intervenant[]));

-- ------------------------------------------- pourquoi le bouton est gris
--
-- Un bouton grisé sans explication produit un appel au référent. Cette
-- fonction rend la liste de ce qui manque, en clair, dans l'ordre où ça se
-- règle. Vide : le bouton s'active.
--
-- Elle vit en base et non dans React pour la même raison que `est_intervenant`
-- (convention du projet) : la règle qui autorise une dépense sur des données de
-- santé ne se décide pas dans un composant qu'on peut oublier de mettre à jour.

create or replace function raisons_de_ne_pas_generer(p_enfant uuid)
returns text[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(r order by ordre), '{}')
  from (
    -- Sans pré-bilan, la génération produirait un bilan standard et mesurerait
    -- le handicap de l'enfant plutôt que ses savoirs.
    select 1 as ordre,
           'Le pré-bilan n''a pas été rempli.' as r
    where not exists (
      select 1 from observations_capacites o
      where o.enfant_id = p_enfant and o.statut = 'complete'
    )

    union all

    select 2, 'L''autorisation de génération assistée n''est pas signée.'
    where not consentement_actif(p_enfant, 'generation_ia')

    union all

    -- Pas un blocage de principe, un blocage de fait : la file traite déjà
    -- cette demande, en déposer une seconde violerait l'index unique.
    select 3, 'Une génération est déjà en cours pour cet enfant.'
    where exists (
      select 1 from generations_bilan g
      where g.enfant_id = p_enfant
        and g.statut in ('en_attente', 'en_cours')
    )

    union all

    select 4, 'Un bilan est déjà ouvert pour cet enfant.'
    where exists (
      select 1 from bilans_positionnement b
      where b.enfant_id = p_enfant and b.statut = 'en_cours'
    )
  ) as raisons;
$$;

-- ------------------------------------------------------ réserver avant de faire
--
-- Copie fidèle de `reserver_envois` (0068), y compris le `grant` explicite à
-- `service_role` : le `revoke ... from public` qui suit lui retirerait sinon le
-- droit d'appeler sa propre fonction, et la route de traitement se verrait
-- refuser l'accès en production seulement.

create or replace function reserver_generations(
  p_lot integer default 5,
  p_tentatives_max integer default 3
)
returns setof generations_bilan
language sql
volatile
security definer
set search_path = public
as $$
  update generations_bilan g
  set statut = 'en_cours',
      reserve_le = now(),
      tentatives = g.tentatives + 1
  where g.id in (
    select c.id
    from generations_bilan c
    where (
        c.statut = 'en_attente'
        or (c.statut = 'echec' and c.tentatives < p_tentatives_max)
        -- Une réservation abandonnée — processus tué, déploiement au mauvais
        -- moment — doit repartir. Vingt minutes : une génération longue tient
        -- largement dedans, un traitement mort n'attend pas la journée.
        or (c.statut = 'en_cours' and c.reserve_le < now() - interval '20 minutes')
      )
    order by c.cree_le
    limit p_lot
    for update skip locked
  )
  returning g.*;
$$;

revoke execute on function reserver_generations(integer, integer) from public;
grant execute on function reserver_generations(integer, integer) to service_role;

-- Le lot est petit — cinq, contre cinquante pour les courriels. Une génération
-- prend des dizaines de secondes, pas des dixièmes : au-delà, la route dépasse
-- son `maxDuration` et rend la main en laissant des lignes réservées.

-- --------------------------------------------------------------- la sonnette
--
-- Même mécanisme qu'en 0068 : la file se signale au lieu d'être attendue. Sans
-- cela, un référent qui clique à 9 h 05 verrait sa génération partir au
-- prochain passage du balayeur.

create or replace function sonner_les_generations()
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
    from vault.decrypted_secrets where name = 'xylou_url_generations';
  select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'xylou_cron_secret';

  if v_url is null or v_secret is null then
    return null;
  end if;

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

-- Par instruction, pas par ligne : douze enfants déposés d'un coup sonnent une
-- fois. Douze appels HTTP pour une file qui se vide en une passe seraient onze
-- de trop.
create trigger generations_sonnent
  after insert on generations_bilan
  for each statement execute function sonner_les_generations();

-- ==================================================== ce qu'il faut savoir
--
-- LE COÛT ANNONCÉ AVANT LE CLIC
--
-- L'écran doit dire l'ordre de grandeur avant qu'on clique — c'est le sens même
-- d'un bouton manuel. `cout_ia_mensuel` (0008) donne le réalisé ; la moyenne des
-- générations passées donne l'estimation. Rien à ajouter en base pour cela.
--
-- CE QUI RESTE À FAIRE HORS MIGRATION
--
-- Créer le secret `xylou_url_generations` dans le Vault, à côté de
-- `xylou_url_envois`, et programmer le balayeur — même forme qu'en 0068 :
--
--   select cron.schedule(
--     'xylou-vider-les-generations',
--     '*/5 * * * *',
--     $cron$
--     select net.http_post(
--       url := (select decrypted_secret from vault.decrypted_secrets
--               where name = 'xylou_url_generations'),
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
-- La sonnette rend le balayeur rare, elle ne le rend pas inutile : un `pg_net`
-- qui échoue ne réessaie pas.
