-- 0054 — Devenir référent se demande.
--
-- 0026 a créé la qualité de référent sans dire comment on l'obtient.
-- L'administration devait connaître les gens de l'extérieur et les promouvoir à
-- la main — ce qui marche pour les trois premiers et pour personne ensuite.
--
-- Or c'est le rôle qu'on accorde le moins à la légère. Un référent ouvre des
-- dossiers d'enfants handicapés, établit qui détient l'autorité parentale,
-- accède aux données de santé. Une promotion décidée sur un message reçu on ne
-- sait où ne laisse aucune trace de ce qui a été vérifié.
--
-- ---------------------------------------------------------------------------
-- POURQUOI SEULEMENT LES RÉFÉRENTS
--
-- Les enseignants, les accompagnants et les parents entrent par invitation :
-- quelqu'un qui les connaît déjà les rattache à un enfant précis. Leur qualité
-- de plateforme reste « membre », et leurs droits ne viennent que de ce
-- rattachement.
--
-- Le référent est le seul à devoir exister AVANT tout dossier. C'est ce qui
-- rend son habilitation différente, et c'est pourquoi elle seule se demande.
--
-- L'administration, elle, ne se demande pas. Elle se pose depuis la base, comme
-- en 0026 — une qualité qu'on peut solliciter est une qualité qu'on finit par
-- obtenir.
-- ---------------------------------------------------------------------------

-- Les deux valeurs ne sont employées que dans des corps de fonction, exécutés
-- après validation de cette transaction : leur ajout ici ne pose pas le
-- problème habituel. Si Supabase refuse malgré tout, passez ces deux lignes
-- seules avant le reste du fichier.
alter type type_notification add value if not exists 'habilitation_demandee';
alter type type_notification add value if not exists 'habilitation_traitee';

create type statut_habilitation as enum ('en_attente', 'acceptee', 'refusee', 'retiree');

create table demandes_habilitation (
  id uuid primary key default gen_random_uuid(),
  profil_id uuid not null references profils on delete cascade,

  -- Ce que la personne déclare d'elle-même. Rien n'est vérifiable
  -- automatiquement : c'est l'administration qui instruit, et ces champs sont
  -- la matière de son instruction.
  organisation text not null default '',
  fonction text not null,
  numero_professionnel text not null default '',
  motivation text not null default '',

  statut statut_habilitation not null default 'en_attente',
  traitee_par uuid references profils on delete set null,
  traitee_le timestamptz,
  -- Un refus se motive : la personne a le droit de savoir ce qui manquait, et
  -- de revenir avec la pièce qu'on lui demande.
  motif text not null default '',

  -- Une habilitation n'est pas éternelle. Une personne change d'employeur, un
  -- agrément expire, une structure ferme. Sans échéance, la file des référents
  -- ne fait que grossir et personne ne revérifie jamais rien.
  --
  -- L'échéance ne révoque pas toute seule : un référent qui perdrait ses droits
  -- au milieu d'un trimestre laisserait des dossiers sans personne. Elle
  -- alimente une liste que l'administration relit.
  valable_jusqu_au date,

  cree_le timestamptz not null default now(),

  constraint habilitation_traitee_a_un_auteur
    check (statut = 'en_attente' or (traitee_par is not null and traitee_le is not null)),
  constraint refus_motive
    check (statut <> 'refusee' or length(btrim(motif)) >= 10)
);

-- ------------------------------------------------------------- les pièces
--
-- Plusieurs documents par demande, chacun typé. « Un justificatif » ne dit rien
-- de ce qui a été vérifié : une carte professionnelle, une attestation de
-- direction et un agrément ne prouvent pas la même chose, et l'administration
-- doit pouvoir dire lequel lui manque plutôt que refuser en bloc.
create type type_piece_habilitation as enum (
  'piece_identite',
  'carte_professionnelle',
  'attestation_employeur',
  'attestation_direction',   -- le directeur de l'établissement scolaire
  'diplome',
  'agrement',                -- MDPH, ARS, association agréée
  'assurance_responsabilite',
  'autre'
);

create table habilitation_pieces (
  id uuid primary key default gen_random_uuid(),
  demande_id uuid not null references demandes_habilitation on delete cascade,

  type_piece type_piece_habilitation not null,
  libelle text not null default '',
  chemin text not null unique,

  -- Une attestation de 2019 ne prouve rien de 2026. La date d'émission est
  -- lisible sur le document ; l'exiger à la saisie évite d'avoir à l'ouvrir
  -- pour s'en apercevoir.
  delivree_le date,
  valable_jusqu_au date,

  deposee_le timestamptz not null default now(),

  constraint piece_valide_apres_emission
    check (valable_jusqu_au is null or delivree_le is null
           or valable_jusqu_au >= delivree_le)
);

create index habilitation_pieces_demande_idx on habilitation_pieces (demande_id);

-- Une seule demande en attente par personne : en déposer trois n'accélère rien
-- et brouille la file de l'administration.
create unique index habilitation_une_seule_en_attente
  on demandes_habilitation (profil_id) where statut = 'en_attente';

create index habilitations_a_instruire_idx
  on demandes_habilitation (cree_le) where statut = 'en_attente';

-- ---------------------------------------------------------------- déposer

create or replace function demander_l_habilitation(
  p_fonction text,
  p_organisation text default '',
  p_numero text default '',
  p_motivation text default ''
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_demande uuid;
  v_role role_plateforme;
begin
  select role_plateforme into v_role from profils where id = auth.uid();

  if v_role in ('referent', 'admin') then
    raise exception 'Votre compte a déjà cette habilitation.';
  end if;

  if length(btrim(p_fonction)) < 3 then
    raise exception 'Indiquez votre fonction : c''est ce que l''administration lira en premier.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, numero_professionnel, motivation)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation),
     btrim(p_numero), btrim(p_motivation))
  returning id into v_demande;

  -- Sans ce signal, une demande attendrait qu'un administrateur pense à
  -- regarder une file qu'il n'a aucune raison d'ouvrir.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, null, 'habilitation_demandee',
         'Demande de référent : ' || coalesce(nullif(btrim(p_organisation), ''), btrim(p_fonction)),
         btrim(p_fonction),
         '/administration/habilitations/' || v_demande
  from profils p where p.role_plateforme = 'admin';

  return v_demande;
end;
$$;

-- --------------------------------------------------------------- instruire

-- L'échéance est un paramètre et non un calcul : une attestation de direction
-- vaut une année scolaire, un agrément cinq ans, et l'administration seule sait
-- ce qu'elle vient de lire. Nulle signifie « sans terme », ce qui doit rester
-- l'exception plutôt que le défaut.
create or replace function accepter_l_habilitation(
  p_demande uuid,
  p_valable_jusqu_au date default null,
  p_motif text default ''
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_profil uuid;
  v_pieces integer;
begin
  if not est_admin() then
    raise exception 'L''instruction des demandes revient à l''administration.';
  end if;

  select profil_id into v_profil
  from demandes_habilitation
  where id = p_demande and statut = 'en_attente';

  if v_profil is null then
    raise exception 'Demande introuvable ou déjà instruite.';
  end if;

  -- Accorder sans avoir rien lu reste possible — vous connaissez peut-être la
  -- personne — mais cela se dit. Le motif tiendra lieu de trace le jour où
  -- quelqu'un demandera sur quoi l'habilitation reposait.
  select count(*) into v_pieces from habilitation_pieces where demande_id = p_demande;

  if v_pieces = 0 and length(btrim(p_motif)) < 10 then
    raise exception 'Aucune pièce justificative n''a été versée. Vous pouvez accorder l''habilitation malgré tout, mais dites sur quoi vous vous fondez.';
  end if;

  update demandes_habilitation
    set statut = 'acceptee', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif), valable_jusqu_au = p_valable_jusqu_au
    where id = p_demande;

  update profils set role_plateforme = 'referent' where id = v_profil;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (v_profil, null, 'habilitation_traitee',
          'Votre habilitation de référent est accordée',
          'Vous pouvez désormais ouvrir des dossiers.',
          '/tableau-de-bord');
end;
$$;

create or replace function refuser_l_habilitation(p_demande uuid, p_motif text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_profil uuid;
begin
  if not est_admin() then
    raise exception 'L''instruction des demandes revient à l''administration.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Un refus se motive : la personne doit savoir ce qui manquait pour revenir avec.';
  end if;

  select profil_id into v_profil
  from demandes_habilitation
  where id = p_demande and statut = 'en_attente';

  if v_profil is null then
    raise exception 'Demande introuvable ou déjà instruite.';
  end if;

  update demandes_habilitation
    set statut = 'refusee', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif)
    where id = p_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (v_profil, null, 'habilitation_traitee',
          'Votre demande d''habilitation n''a pas été retenue',
          btrim(p_motif),
          '/habilitation');
end;
$$;

-- Retirer une habilitation déjà accordée : une personne quitte la structure, ou
-- l'instruction se révèle fautive. Le compte redevient « membre » et perd
-- l'ouverture de dossiers — mais garde ses rattachements existants, sinon les
-- enfants qu'elle suit se retrouveraient sans référent du jour au lendemain.
create or replace function retirer_l_habilitation(p_profil uuid, p_motif text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not est_admin() then
    raise exception 'Le retrait d''une habilitation revient à l''administration.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Le retrait d''une habilitation se motive.';
  end if;

  update profils set role_plateforme = 'membre'
    where id = p_profil and role_plateforme = 'referent';

  update demandes_habilitation
    set statut = 'retiree', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif)
    where profil_id = p_profil and statut = 'acceptee';

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (p_profil, null, 'habilitation_traitee',
          'Votre habilitation de référent a été retirée',
          btrim(p_motif), '/tableau-de-bord');
end;
$$;

-- ==================================================================== RLS

alter table demandes_habilitation enable row level security;

-- Chacun voit la sienne, l'administration voit toutes. Personne d'autre : une
-- demande refusée dit quelque chose de la personne qu'elle n'a pas à exposer.
create policy habilitations_lecture on demandes_habilitation
  for select to authenticated
  using (profil_id = auth.uid() or est_admin());

-- Le dépôt passe par `demander_l_habilitation()`, qui vérifie la qualité
-- actuelle et prévient l'administration. La politique couvre le cas où
-- l'application insère directement.
create policy habilitations_depot on demandes_habilitation
  for insert to authenticated
  with check (profil_id = auth.uid() and statut = 'en_attente');

-- Retirer sa propre demande tant qu'elle n'est pas instruite.
create policy habilitations_retrait on demandes_habilitation
  for update to authenticated
  using (profil_id = auth.uid() and statut = 'en_attente')
  with check (profil_id = auth.uid() and statut in ('en_attente', 'retiree'));

-- L'instruction passe par les fonctions ci-dessus, en SECURITY DEFINER.
create policy habilitations_instruction on demandes_habilitation
  for update to authenticated
  using (est_admin()) with check (est_admin());

-- ==================================================== le justificatif

create or replace function habilitation_du_chemin(p_name text)
returns uuid language sql immutable as $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;

insert into storage.buckets (id, name, public) values
  ('habilitations', 'habilitations', false)
on conflict (id) do nothing;

-- Le demandeur dépose, l'administration lit. Une carte professionnelle ou une
-- attestation d'employeur n'a pas à circuler au-delà.
create policy "habilitations_depot" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'habilitations'
    and exists (
      select 1 from public.demandes_habilitation d
      where d.id = public.habilitation_du_chemin(name)
        and d.profil_id = auth.uid()
        and d.statut = 'en_attente'
    )
  );

create policy "habilitations_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'habilitations'
    and (
      public.est_admin()
      or exists (
        select 1 from public.demandes_habilitation d
        where d.id = public.habilitation_du_chemin(name)
          and d.profil_id = auth.uid()
      )
    )
  );

-- ------------------------------------------------- la file de l'administration

create or replace function habilitations_a_instruire()
returns table (
  demande_id uuid,
  prenom text,
  nom text,
  email text,
  fonction text,
  organisation text,
  numero_professionnel text,
  motivation text,
  pieces bigint,
  types_fournis text,
  pieces_perimees bigint,
  depuis_jours integer
)
language sql stable security definer set search_path = public as $$
  select
    d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation,
    d.numero_professionnel, d.motivation,
    count(pi.id),
    coalesce(string_agg(distinct pi.type_piece::text, ', '), ''),
    count(pi.id) filter (where pi.valable_jusqu_au is not null
                           and pi.valable_jusqu_au < current_date),
    (current_date - d.cree_le::date)::integer
  from demandes_habilitation d
  join profils p on p.id = d.profil_id
  left join habilitation_pieces pi on pi.demande_id = d.id
  where d.statut = 'en_attente' and est_admin()
  group by d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation,
           d.numero_professionnel, d.motivation, d.cree_le
  order by d.cree_le;
$$;

-- Les habilitations qui arrivent à terme, deux mois avant. C'est la liste qui
-- empêche le dispositif de se déliter en silence : sans elle, les échéances
-- passeraient et personne ne revérifierait jamais rien, ce qui reviendrait à ne
-- pas en avoir posé.
create or replace function habilitations_a_renouveler(p_preavis_jours integer default 60)
returns table (
  profil_id uuid,
  prenom text,
  nom text,
  email text,
  organisation text,
  valable_jusqu_au date,
  jours_restants integer,
  dossiers_suivis bigint
)
language sql stable security definer set search_path = public as $$
  select
    p.id, p.prenom, p.nom, p.email, d.organisation, d.valable_jusqu_au,
    (d.valable_jusqu_au - current_date)::integer,
    (select count(*) from intervenants_enfant i
      where i.profil_id = p.id and i.role = 'referent' and i.retire_le is null)
  from demandes_habilitation d
  join profils p on p.id = d.profil_id
  where d.statut = 'acceptee'
    and d.valable_jusqu_au is not null
    and d.valable_jusqu_au <= current_date + p_preavis_jours
    and p.role_plateforme = 'referent'
    and est_admin()
  order by d.valable_jusqu_au;
$$;

-- ==================================================================== pièces

alter table habilitation_pieces enable row level security;

create policy habilitation_pieces_lecture on habilitation_pieces
  for select to authenticated
  using (
    est_admin()
    or exists (
      select 1 from demandes_habilitation d
      where d.id = demande_id and d.profil_id = auth.uid()
    )
  );

-- On verse ses pièces tant que la demande n'est pas instruite. Après, la
-- décision porte sur ce qui a été lu : ajouter une pièce ensuite donnerait à
-- croire qu'elle a compté.
create policy habilitation_pieces_depot on habilitation_pieces
  for insert to authenticated
  with check (
    exists (
      select 1 from demandes_habilitation d
      where d.id = demande_id
        and d.profil_id = auth.uid()
        and d.statut = 'en_attente'
    )
  );

create policy habilitation_pieces_retrait on habilitation_pieces
  for delete to authenticated
  using (
    exists (
      select 1 from demandes_habilitation d
      where d.id = demande_id
        and d.profil_id = auth.uid()
        and d.statut = 'en_attente'
    )
  );
