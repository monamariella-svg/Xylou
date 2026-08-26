-- 0055 — Un référent principal, et autant de suppléants qu'il faut.
--
-- Rien n'interdisait déjà d'en rattacher deux : `intervenants_enfant` accepte
-- plusieurs référents pour un même enfant. Mais le schéma les traitait comme
-- interchangeables, et deux conséquences s'ensuivaient.
--
--   Le quorum de 0023 exige la signature de tous les référents sur un objectif
--   de matière. Habiliter un suppléant doublait la charge de signature de
--   chaque objectif — et suffisait à bloquer le dossier si le suppléant, par
--   définition peu présent, ne signait pas.
--
--   Rien ne disait qui répondait de l'enfant. Deux référents également
--   responsables, c'est zéro référent responsable le jour où il faut trancher.
--
-- ---------------------------------------------------------------------------
-- CE QUE LE SUPPLÉANT PEUT DÉJÀ FAIRE
--
-- Tout, sauf entrer dans le quorum. Il lit le dossier, pilote les domaines
-- transversaux, valide les propositions de l'IA, accède aux données de santé.
-- C'est voulu : un suppléant qui devrait demander des droits le jour où le
-- principal tombe malade n'est pas un suppléant, c'est une formalité.
--
-- La distinction ne porte que sur la signature — donc sur ce qui bloque quand
-- quelqu'un manque.
-- ---------------------------------------------------------------------------

alter table intervenants_enfant
  add column principal boolean not null default false,
  add column designe_le timestamptz;

comment on column intervenants_enfant.principal is
  'Pour un référent : celui qui répond du dossier et entre dans le quorum de validation. Les autres sont suppléants — mêmes accès, sans la signature.';

-- L'index d'abord, la reprise des données ensuite, tout à la fin du fichier.
-- Une mise à jour laisse en attente les événements des triggers différés posés
-- sur cette table depuis 0025, et Postgres refuse de construire un index tant
-- qu'il en reste — « cannot CREATE INDEX because it has pending trigger
-- events ». L'ordre n'est donc pas cosmétique.
create unique index referent_un_seul_principal
  on intervenants_enfant (enfant_id)
  where role = 'referent' and principal and retire_le is null;

-- Le premier référent rattaché à un dossier en devient le principal sans que
-- personne ait à y penser. Sans cela, ouvrir un dossier laisserait un dossier
-- sans référent responsable, et le quorum se réduirait aux parents en silence.
create or replace function designer_le_premier_referent()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role <> 'referent' or new.principal or new.retire_le is not null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.role = 'referent'
      and i.principal
      and i.retire_le is null
  ) then
    new.principal := true;
    new.designe_le := now();
  end if;

  return new;
end;
$$;

create trigger intervenants_designent_le_premier_referent
  before insert on intervenants_enfant
  for each row execute function designer_le_premier_referent();

-- ------------------------------------------------- le quorum, resserré

-- Seul le principal signe. Un suppléant qui entrerait dans le quorum le
-- bloquerait précisément dans le cas où il sert : quand le principal est absent.
create or replace function valideurs_requis(p_objectif uuid)
returns table (profil_id uuid)
language sql stable security definer set search_path = public as $$
  select i.profil_id
  from objectifs o
  join intervenants_enfant i on i.enfant_id = o.enfant_id
  where o.id = p_objectif
    and i.retire_le is null
    and (
      i.role = 'parent'
      or (i.role = 'referent' and i.principal and o.matiere_code is not null)
    );
$$;

-- ------------------------------------------------------------ passer la main

create or replace function designer_le_referent_principal(
  p_enfant uuid,
  p_profil uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_ancien uuid;
  v_prenom text;
begin
  -- L'administration, ou le principal en exercice qui passe la main. Pas les
  -- parents : le référent est désigné par la structure, et un désaccord avec
  -- lui se règle en le disant à l'administration, pas en le remplaçant.
  if not (
    est_admin()
    or exists (
      select 1 from intervenants_enfant i
      where i.enfant_id = p_enfant and i.profil_id = auth.uid()
        and i.role = 'referent' and i.principal and i.retire_le is null
    )
  ) then
    raise exception 'Désigner le référent principal revient à l''administration, ou au référent en exercice qui passe la main.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Un changement de référent se motive : c''est ce que la famille lira.';
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    join profils p on p.id = i.profil_id
    where i.enfant_id = p_enfant and i.profil_id = p_profil
      and i.role = 'referent' and i.retire_le is null
      and p.role_plateforme in ('referent', 'admin')
  ) then
    raise exception 'Cette personne doit d''abord être rattachée au dossier comme référent, et disposer de l''habilitation.';
  end if;

  select i.profil_id into v_ancien
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.role = 'referent'
    and i.principal and i.retire_le is null;

  -- Dans cet ordre : l'index unique n'admet qu'un principal à la fois.
  update intervenants_enfant
    set principal = false
    where enfant_id = p_enfant and role = 'referent' and principal and retire_le is null;

  update intervenants_enfant
    set principal = true, designe_le = now()
    where enfant_id = p_enfant and profil_id = p_profil and role = 'referent';

  select prenom into v_prenom from profils where id = p_profil;

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'changement_referent', 'intervenants_enfant', null,
          jsonb_build_object('ancien', v_ancien, 'nouveau', p_profil, 'motif', btrim(p_motif)));

  -- La famille est prévenue. Un changement de référent la concerne au premier
  -- chef : c'est la personne à qui elle confie ce qu'elle ne dit pas à l'école.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'message',
         'Changement de référent',
         coalesce(v_prenom, 'Une nouvelle personne') || ' suit désormais le dossier. ' || btrim(p_motif),
         '/enfants/' || p_enfant || '/equipe'
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();
end;
$$;

-- ------------------------------------------- un dossier garde son référent

-- Différée, pour la même raison qu'en 0025 : remplacer suppose souvent de
-- retirer avant d'ajouter. On refuse le résultat vide, pas l'étape
-- intermédiaire.
create or replace function exiger_un_referent_principal()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid := coalesce(new.enfant_id, old.enfant_id);
begin
  if not exists (select 1 from enfants e where e.id = v_enfant) then
    return null;
  end if;

  if exists (
    select 1 from enfants e where e.id = v_enfant and e.archive_le is not null
  ) then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = v_enfant
      and i.role = 'referent'
      and i.principal
      and i.retire_le is null
  ) then
    raise exception 'Ce dossier n''a plus de référent principal. Désignez un suppléant, ou demandez à l''administration d''en rattacher un.';
  end if;

  return null;
end;
$$;

create constraint trigger intervenants_exigent_un_referent
  after update or delete on intervenants_enfant
  deferrable initially deferred
  for each row execute function exiger_un_referent_principal();

-- ------------------------------------------------- voir l'équipe encadrante

create or replace function referents_du_dossier(p_enfant uuid)
returns table (
  profil_id uuid,
  prenom text,
  nom text,
  email text,
  fonction text,
  principal boolean,
  designe_le timestamptz,
  habilitation_jusqu_au date
)
language sql stable security definer set search_path = public as $$
  select p.id, p.prenom, p.nom, p.email, i.fonction, i.principal, i.designe_le,
         (select d.valable_jusqu_au from demandes_habilitation d
          where d.profil_id = p.id and d.statut = 'acceptee'
          order by d.traitee_le desc limit 1)
  from intervenants_enfant i
  join profils p on p.id = i.profil_id
  where i.enfant_id = p_enfant
    and i.role = 'referent'
    and i.retire_le is null
    and est_intervenant(p_enfant)
  order by i.principal desc, p.nom;
$$;

-- Les dossiers dont le référent principal perd bientôt son habilitation. Le
-- croisement des deux échéances — celle de la personne, celle du dossier — est
-- exactement ce que personne ne fait à la main, et ce qui laisse des dossiers
-- sans référent valide sans que quiconque l'ait décidé.
create or replace function dossiers_sans_referent_valide()
returns table (
  enfant_id uuid,
  prenom text,
  referent_prenom text,
  referent_nom text,
  habilitation_jusqu_au date,
  suppleants bigint
)
language sql stable security definer set search_path = public as $$
  select
    e.id, e.prenom, p.prenom, p.nom, d.valable_jusqu_au,
    (select count(*) from intervenants_enfant s
      where s.enfant_id = e.id and s.role = 'referent'
        and not s.principal and s.retire_le is null)
  from enfants e
  join intervenants_enfant i
    on i.enfant_id = e.id and i.role = 'referent'
   and i.principal and i.retire_le is null
  join profils p on p.id = i.profil_id
  left join lateral (
    select dd.valable_jusqu_au from demandes_habilitation dd
    where dd.profil_id = p.id and dd.statut = 'acceptee'
    order by dd.traitee_le desc limit 1
  ) d on true
  where e.archive_le is null
    and est_admin()
    and (
      p.role_plateforme not in ('referent', 'admin')
      or (d.valable_jusqu_au is not null and d.valable_jusqu_au <= current_date + 60)
    )
  order by d.valable_jusqu_au nulls first;
$$;

-- ==================================================== reprise des dossiers

-- En dernier, une fois tout le DDL posé. Le premier référent de chaque dossier
-- existant devient le principal — c'est celui qui l'a ouvert, donc celui qui en
-- répond déjà en pratique.
update intervenants_enfant i
set principal = true, designe_le = i.cree_le
where i.role = 'referent'
  and i.retire_le is null
  and not exists (
    select 1 from intervenants_enfant p
    where p.enfant_id = i.enfant_id and p.role = 'referent'
      and p.principal and p.retire_le is null
  )
  and i.id = (
    select i2.id from intervenants_enfant i2
    where i2.enfant_id = i.enfant_id and i2.role = 'referent' and i2.retire_le is null
    order by i2.cree_le, i2.id
    limit 1
  );
