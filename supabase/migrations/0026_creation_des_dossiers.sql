-- 0026 — Qui ouvre un dossier.
--
-- Jusqu'ici n'importe quel compte pouvait créer une fiche enfant, et 0025
-- s'appuyait là-dessus : faute de référent au démarrage, c'est le créateur —
-- présumé parent — qui déclarait la composition parentale. Le raisonnement
-- tombe si la fiche est ouverte par un professionnel.
--
-- Il tombe pour le mieux. La question que 0025 peinait à résoudre — comment
-- désigner un arbitre neutre avant que quiconque soit rattaché — disparaît si
-- l'arbitre est là dès le premier geste. Le dossier naît de la main du référent
-- ou de l'administration, jamais de celle d'une famille.
--
-- Cela suppose une notion que le schéma n'avait pas : un rôle qui ne dépende
-- d'aucun enfant. `role_intervenant` décrit une relation — on est le parent
-- *de cet enfant-là*, l'enseignant *de celui-ci*. Ouvrir un dossier précède
-- toute relation, et demande donc une qualité attachée à la personne.

create type role_plateforme as enum ('membre', 'referent', 'admin');

alter table profils
  add column role_plateforme role_plateforme not null default 'membre';

comment on column profils.role_plateforme is
  'Qualité de la personne, indépendante de tout enfant. « membre » couvre les familles et les enseignants, dont les droits viennent de leur rattachement.';

-- Un enseignant reste « membre » : ses droits lui viennent de son rattachement à
-- un enfant, pas de sa qualité. Seuls le référent et l'administration ont besoin
-- d'exister avant tout dossier.
--
-- Le premier administrateur ne peut pas être créé depuis l'application — aucune
-- politique n'accorde la promotion, et il n'existe personne pour l'accorder.
-- Il se pose une fois, depuis le SQL Editor ou la clé de service :
--
--   update profils set role_plateforme = 'admin' where email = '…';
--
-- C'est volontaire. Une amorce en libre-service serait une porte ouverte, et
-- elle ne servirait qu'une fois.

create or replace function est_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profils p where p.id = auth.uid() and p.role_plateforme = 'admin'
  );
$$;

create or replace function peut_ouvrir_un_dossier()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profils p
    where p.id = auth.uid() and p.role_plateforme in ('referent', 'admin')
  );
$$;

-- `profils_maj` (0009) laisse chacun modifier sa propre ligne — ce qui
-- inclurait désormais sa propre qualité. Une promotion en libre-service viderait
-- de son sens tout ce fichier.
create or replace function proteger_le_role_plateforme()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role_plateforme is distinct from old.role_plateforme and not est_admin() then
    raise exception 'La qualité d''un compte est établie par l''administration.';
  end if;
  return new;
end;
$$;

create trigger profils_protegent_leur_role
  before update on profils
  for each row execute function proteger_le_role_plateforme();

-- ------------------------------------------------------- ouvrir un dossier

drop policy enfants_creation on enfants;

create policy enfants_creation on enfants for insert to authenticated
  with check (cree_par = auth.uid() and peut_ouvrir_un_dossier());

-- --------------------------------------------- l'arbitre de l'autorité

-- La clause de démarrage de 0025 — « le créateur tant qu'aucun référent n'est
-- rattaché » — n'a plus lieu d'être : le créateur *est* le référent, ou
-- l'administration qui lui confie le dossier. Elle disparaît, et avec elle le
-- cas où un parent aurait pu déclarer lui-même la composition de sa famille.
create or replace function definit_l_autorite_parentale(p_enfant uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select
    est_intervenant(p_enfant, array['referent']::role_intervenant[])
    or est_admin();
$$;

-- ------------------------------------------------------ le rattachement

drop policy intervenants_ajout on intervenants_enfant;

-- Deux cas d'insertion directe, et un seul geste ordinaire derrière :
--
--   - le référent qui vient d'ouvrir le dossier s'y rattache lui-même ;
--   - l'administration rattache le référent à qui elle confie le suivi.
--
-- Les familles et les enseignants entrent par `accepter_l_invitation()` (0024),
-- c'est-à-dire par leur propre geste. Personne n'est inscrit à son insu.
create policy intervenants_ajout on intervenants_enfant for insert to authenticated
  with check (
    est_admin()
    or (
      profil_id = auth.uid()
      and role = 'referent'
      and exists (
        select 1 from enfants e
        where e.id = enfant_id and e.cree_par = auth.uid()
      )
    )
  );

-- L'administration peut aussi corriger un rattachement : c'est le recours quand
-- un référent quitte la structure sans avoir passé la main, cas où plus personne
-- n'aurait qualité pour agir.
drop policy intervenants_maj on intervenants_enfant;
drop policy intervenants_retrait on intervenants_enfant;

create policy intervenants_maj on intervenants_enfant for update to authenticated
  using (
    profil_id = auth.uid()
    or est_admin()
    or est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
  )
  with check (
    profil_id = auth.uid()
    or est_admin()
    or est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
  );

create policy intervenants_retrait on intervenants_enfant for delete to authenticated
  using (
    profil_id = auth.uid()
    or est_admin()
    or est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
  );

-- --------------------------------------------- lecture des dossiers ouverts

-- `enfants_lecture` (0009) accorde la fiche à `cree_par` en plus des
-- intervenants. La clause existait pour couvrir l'instant entre la création et
-- le rattachement ; elle garde exactement le même rôle ici, pour le référent.
-- Rien à changer.

-- L'administration voit les dossiers qu'elle ouvre, et ceux dont le suivi est
-- interrompu. Elle ne voit pas leur contenu : aucune politique de ce fichier ne
-- lui ouvre les objectifs, les tentatives ou les échanges, et `est_admin()`
-- n'apparaît dans aucune d'elles. Administrer n'est pas accompagner.
create policy enfants_lecture_admin on enfants for select to authenticated
  using (est_admin());
