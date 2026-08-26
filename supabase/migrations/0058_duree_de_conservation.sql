-- 0058 — La durée gouverne, la date se déduit.
--
-- 0031 puis 0057 calculent `purge_prevue_le` au moment du masquage et le
-- stockent. C'est une erreur, et elle est du genre à ne jamais se voir : le jour
-- où la durée légale change, tous les dossiers déjà masqués gardent une date
-- calculée sous l'ancienne règle. Elles ont l'air justes, elles ne le sont plus,
-- et rien ne le signale.
--
-- Une durée de conservation n'est pas une propriété du dossier. C'est une
-- propriété de la loi, et elle vaut pour tous les dossiers à la fois — y compris
-- ceux masqués hier.
--
-- ---------------------------------------------------------------------------
-- CE QU'ON DIT À LA FAMILLE
--
-- La conséquence pratique est dans l'interface : l'écran de confirmation
-- annonce **la durée**, pas une date. « Vos données seront effacées cinq ans
-- après le masquage » reste vrai si la loi change ; « effacées le 12 mars
-- 2031 » devient faux sans que personne ne le reprenne.
--
-- La date reste calculable et affichable — elle est même plus parlante — mais
-- elle se recalcule à chaque affichage, et c'est ce qui la rend fiable.
-- ---------------------------------------------------------------------------

-- L'unique endroit où la durée est écrite. Quand la question 5.5 sera tranchée,
-- c'est cette fonction qu'on modifie, et rien d'autre : tous les dossiers, y
-- compris ceux déjà masqués, suivent immédiatement.
create or replace function duree_conservation()
returns interval
language sql immutable as $$
  select interval '5 years';
$$;

comment on function duree_conservation() is
  'Durée légale de conservation après masquage. Placeholder de 5 ans — voir la question 5.5 du document juriste. Modifier ici et nulle part ailleurs.';

create or replace function purge_prevue(p_enfant uuid)
returns date
language sql stable security definer set search_path = public as $$
  select (e.archive_le + duree_conservation())::date
  from enfants e where e.id = p_enfant and e.archive_le is not null;
$$;

-- La colonne survit, mais change de sens : elle n'est plus la date qui gouverne,
-- elle est la date **annoncée à la famille** au moment du masquage. Les deux
-- coïncident tant que la loi ne bouge pas ; si elle bouge, l'écart est
-- précisément ce qu'on veut pouvoir constater.
comment on column enfants.purge_prevue_le is
  'Date annoncée à la famille lors du masquage. Ne gouverne rien : la purge se décide sur purge_prevue(), recalculée depuis duree_conservation().';

-- ------------------------------------------------- la purge suit la durée

drop function if exists dossiers_a_purger();

create function dossiers_a_purger()
returns table (
  enfant_id uuid,
  prenom text,
  archive_le timestamptz,
  purge_due_le date,
  date_annoncee date,
  ecart_jours integer,
  jours_de_retard integer,
  sur_demande boolean
)
language sql stable security definer set search_path = public as $$
  select
    e.id, e.prenom, e.archive_le,
    (e.archive_le + duree_conservation())::date,
    e.purge_prevue_le,
    -- Non nul si la durée légale a changé depuis le masquage. C'est la colonne
    -- qu'on regarde le jour où quelqu'un demande pourquoi son dossier est
    -- toujours là — ou pourquoi il ne l'est plus.
    ((e.archive_le + duree_conservation())::date - e.purge_prevue_le)::integer,
    (current_date - (e.archive_le + duree_conservation())::date)::integer,
    exists (select 1 from demandes_suppression d
            where d.enfant_id = e.id and d.statut = 'masquee')
  from enfants e
  where e.archive_le is not null
    and (e.archive_le + duree_conservation())::date <= current_date
    and est_admin()
  order by 4;
$$;

create or replace function purger_le_dossier(p_enfant uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_prenom text;
  v_due date;
begin
  if not est_admin() then
    raise exception 'La purge revient à l''administration.';
  end if;

  select prenom into v_prenom from enfants
  where id = p_enfant and archive_le is not null;

  if v_prenom is null then
    raise exception 'Ce dossier n''existe pas, ou n''est pas masqué.';
  end if;

  v_due := purge_prevue(p_enfant);

  if v_due is null or v_due > current_date then
    raise exception 'Le terme de conservation n''est pas atteint : purge due le %.', v_due;
  end if;

  -- Consigner d'abord. Après les suppressions, il n'y aurait plus de quoi
  -- écrire, et une transaction qui échouerait entre les deux laisserait un
  -- dossier effacé sans justification.
  update suppressions_effectuees
    set purgee_le = now()
    where enfant_id = p_enfant and purgee_le is null;

  if not found then
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

  delete from intervenants_enfant where enfant_id = p_enfant;
  delete from enfants where id = p_enfant;
end;
$$;

-- ------------------------------------------- ce que la famille doit lire

-- Ce que l'écran de confirmation affiche avant que la personne décide. La durée
-- en clair, la date en indication — et le rappel que le retour en arrière reste
-- possible jusque-là.
create or replace function annonce_de_suppression()
returns table (
  duree_texte text,
  duree interval,
  effacement_le date
)
language sql stable as $$
  select
    case
      when duree_conservation() = interval '1 year' then 'un an'
      when extract(year from duree_conservation()) >= 1
        then extract(year from duree_conservation())::int || ' ans'
      else extract(month from duree_conservation())::int || ' mois'
    end,
    duree_conservation(),
    (now() + duree_conservation())::date;
$$;

comment on function annonce_de_suppression() is
  'Ce que l''écran de confirmation annonce : la durée d''abord, la date ensuite. La date est indicative et se recalcule ; c''est la durée qui engage.';
