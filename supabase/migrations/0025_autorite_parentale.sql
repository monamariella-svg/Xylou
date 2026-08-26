-- 0025 — Qui détient l'autorité parentale, et qui le dit.
--
-- 0024 a fermé la porte à tout le monde : personne ne pouvait modifier la ligne
-- d'un parent, pas même pour corriger une erreur. C'était protecteur et
-- impraticable. Le rôle `parent` étant posé à l'inscription par la personne qui
-- crée la fiche, une erreur de saisie devenait définitive — et un beau-parent
-- très impliqué mais sans autorité parentale acquérait un droit de veto sur
-- chaque objectif, sans que personne puisse le retirer.
--
-- L'autorité parentale relève donc du référent. C'est le seul acteur qui
-- convienne : le parent créateur est juge et partie, l'autre parent est en
-- conflit d'intérêts par construction, et les enseignants n'ont pas à connaître
-- la situation familiale. Le référent, lui, est un professionnel du suivi qui
-- dispose des pièces — jugement, livret de famille, décision de placement — et
-- dont c'est le métier de les lire.
--
-- Trois garde-fous, sans quoi le pouvoir serait trop grand :
--
--   - Le référent ne se promeut pas lui-même titulaire de l'autorité parentale.
--   - Un enfant conserve toujours au moins un parent rattaché.
--   - Chacun reste maître de son propre rattachement : le référent définit qui
--     détient l'autorité, il ne retient personne de force.

-- Au démarrage, aucun référent n'est encore rattaché : c'est la personne qui
-- crée la fiche qui se déclare parent, et ce doit rester possible. La bascule
-- vers le référent se fait dès qu'il en existe un.
create or replace function definit_l_autorite_parentale(p_enfant uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select
    est_intervenant(p_enfant, array['referent']::role_intervenant[])
    or (
      not exists (
        select 1 from intervenants_enfant i
        where i.enfant_id = p_enfant and i.role = 'referent' and i.retire_le is null
      )
      and exists (
        select 1 from enfants e where e.id = p_enfant and e.cree_par = auth.uid()
      )
    );
$$;

-- ------------------------------------------- révision du verrou de 0024

create or replace function proteger_le_lien_parental()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_profil uuid := coalesce(old.profil_id, new.profil_id);
  v_enfant uuid := coalesce(old.enfant_id, new.enfant_id);
  v_touche_un_parent boolean :=
    coalesce(old.role, new.role) = 'parent'
    or (tg_op = 'UPDATE' and new.role = 'parent');
begin
  if v_profil = auth.uid() then
    -- On agit sur son propre rattachement : se retirer reste toujours possible.
    -- Se déclarer soi-même titulaire de l'autorité parentale, non — ce serait
    -- au référent de s'accorder le droit de veto qu'il est chargé d'attribuer.
    if tg_op = 'UPDATE'
       and new.role = 'parent'
       and old.role is distinct from 'parent' then
      raise exception 'On ne se déclare pas soi-même titulaire de l''autorité parentale.';
    end if;

  elsif v_touche_un_parent and not definit_l_autorite_parentale(v_enfant) then
    raise exception 'Seul le référent établit qui détient l''autorité parentale.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

-- --------------------------------------- un enfant garde toujours un parent

-- Contrainte différée : corriger une erreur suppose souvent de retirer un
-- rattachement et d'en poser un autre. Vérifier à chaque ligne interdirait la
-- correction elle-même ; vérifier en fin de transaction laisse faire l'échange
-- et refuse seulement le résultat vide.
create or replace function exiger_un_parent_rattache()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid := coalesce(new.enfant_id, old.enfant_id);
begin
  -- La fiche a pu disparaître entre-temps : une suppression d'enfant fait
  -- cascader ses rattachements, et il n'y a alors rien à exiger.
  if not exists (select 1 from enfants e where e.id = v_enfant) then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = v_enfant
      and i.role = 'parent'
      and i.retire_le is null
  ) then
    raise exception 'Un enfant conserve au moins un titulaire de l''autorité parentale rattaché.';
  end if;

  return null;
end;
$$;

create constraint trigger intervenants_exigent_un_parent
  after update or delete on intervenants_enfant
  deferrable initially deferred
  for each row execute function exiger_un_parent_rattache();

-- ------------------------------- combien de titulaires, et qui le déclare

-- Compter les comptes rattachés ne dit pas combien de personnes détiennent
-- l'autorité parentale : il dit combien en ont déjà créé un. Tant que le second
-- parent n'a pas rejoint, le quorum de 0023 vaut un, et l'objectif se valide
-- sans lui — précisément ce que le quorum devait empêcher. Le nombre doit donc
-- être déclaré, et par le référent.
--
-- Deux par défaut, parce qu'un défaut se choisit par la direction de son erreur.
-- À 1, l'oubli de déclaration laisse valider seul un parent qui n'en avait pas
-- le droit, et personne ne s'en aperçoit — c'est la panne silencieuse. À 2,
-- l'oubli bloque, le message dit ce qui manque, et le référent corrige. Une
-- famille monoparentale attend une déclaration ; une famille séparée n'attend
-- pas qu'on répare un objectif validé sans elle.
alter table enfants
  add column titulaires_autorite_parentale smallint not null default 2
  check (titulaires_autorite_parentale in (1, 2));

comment on column enfants.titulaires_autorite_parentale is
  'Établi par le référent. Deux par défaut : tant que le second titulaire n''a pas rejoint, aucun objectif ne se valide.';

create or replace function proteger_la_composition_parentale()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.titulaires_autorite_parentale is distinct from old.titulaires_autorite_parentale
     and not definit_l_autorite_parentale(new.id) then
    raise exception 'Seul le référent établit le nombre de titulaires de l''autorité parentale.';
  end if;
  return new;
end;
$$;

create trigger enfants_protegent_leur_composition
  before update on enfants
  for each row execute function proteger_la_composition_parentale();

-- La composition est complète quand le nombre déclaré correspond au nombre de
-- comptes effectivement rattachés. Entre les deux — le référent a déclaré deux
-- titulaires, un seul a rejoint — rien ne se valide, et c'est voulu.
create or replace function composition_parentale_complete(p_enfant uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select e.titulaires_autorite_parentale = (
    select count(*) from intervenants_enfant i
    where i.enfant_id = p_enfant
      and i.role = 'parent'
      and i.retire_le is null
  )
  from enfants e where e.id = p_enfant;
$$;

-- Le quorum de 0023 s'y adosse désormais.
create or replace function objectif_pleinement_valide(p_objectif uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select
    composition_parentale_complete((select enfant_id from objectifs where id = p_objectif))
    and not exists (
      select 1 from valideurs_requis(p_objectif) r
      where not exists (
        select 1 from objectifs_validations v
        where v.objectif_id = p_objectif and v.profil_id = r.profil_id
      )
    );
$$;

-- Message plus précis que celui de 0023 : « il manque une signature » est faux
-- quand ce qui manque est un compte, et envoie chercher au mauvais endroit.
create or replace function exiger_le_quorum()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_declares smallint;
  v_rattaches integer;
begin
  if new.statut <> 'valide'
     or (tg_op = 'UPDATE' and old.statut is not distinct from 'valide') then
    return new;
  end if;

  if objectif_pleinement_valide(new.id) then
    return new;
  end if;

  select e.titulaires_autorite_parentale into v_declares
  from enfants e where e.id = new.enfant_id;

  select count(*) into v_rattaches
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id and i.role = 'parent' and i.retire_le is null;

  if v_rattaches < v_declares then
    raise exception 'Autorité parentale : % titulaire(s) attendu(s), % rattaché(s). Invitez le titulaire manquant, ou demandez au référent de ramener le nombre à 1 si la famille est monoparentale.', v_declares, v_rattaches;
  end if;

  raise exception 'Il manque une signature : cet objectif attend encore la validation d''un titulaire de l''autorité parentale ou du référent.';
end;
$$;

-- ------------------------------------------------- inviter comme parent

drop policy invitations_creation on invitations;

-- Inviter quelqu'un en qualité de parent, c'est déjà définir l'autorité
-- parentale : la règle serait sans effet si elle ne portait que sur les
-- rattachements existants et laissait la porte ouverte à l'invitation.
create policy invitations_creation on invitations for insert to authenticated
  with check (
    invite_par = auth.uid()
    and peut_valider(enfant_id)
    and (role <> 'parent' or definit_l_autorite_parentale(enfant_id))
  );

-- ------------------------------------------------- politiques d'écriture

-- `intervenants_maj` et `intervenants_retrait` de 0001 n'autorisaient que les
-- parents. Le référent doit pouvoir agir, sur les lignes de parent comme sur les
-- autres — c'est le trigger ci-dessus qui borne ce qu'il peut faire, pas la
-- politique, puisque le discernement porte sur le rôle et non sur la ligne.

drop policy intervenants_maj on intervenants_enfant;
drop policy intervenants_retrait on intervenants_enfant;

create policy intervenants_maj on intervenants_enfant for update to authenticated
  using (
    profil_id = auth.uid()
    or est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
  )
  with check (
    profil_id = auth.uid()
    or est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
  );

create policy intervenants_retrait on intervenants_enfant for delete to authenticated
  using (
    profil_id = auth.uid()
    or est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
  );
