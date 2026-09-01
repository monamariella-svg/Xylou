-- 0065 — Distinguer deux enfants du même prénom.
--
-- 0001 ne demandait que le prénom, par minimisation : le nom de famille est plus
-- identifiant, et un outil qui traite des données de santé n'a pas à collecter
-- ce dont il peut se passer.
--
-- Le raisonnement tenait pour un parent qui suit son enfant. Il ne tient plus
-- depuis 0026, où c'est un référent qui ouvre les dossiers : il en suivra
-- plusieurs dizaines, et deux « Lucas » dans la même liste ne se distinguent
-- pas. Le risque n'est pas théorique — se tromper de dossier, c'est écrire une
-- observation de santé dans celui d'un autre enfant.
--
-- ---------------------------------------------------------------------------
-- CE QUE ÇA N'EXPOSE PAS
--
-- Personne ne découvre le nom de l'enfant en le lisant ici : le référent le
-- connaît, les enseignants aussi, les parents évidemment. Le masquer dans
-- l'outil pendant qu'il s'écrit sur le cahier de liaison ne protégeait rien.
--
-- Il reste facultatif. Certains contextes s'en passent, et l'exiger obligerait
-- à le saisir là où le prénom suffit.
-- ---------------------------------------------------------------------------

alter table enfants
  add column nom text not null default '';

comment on column enfants.nom is
  'Facultatif. Sert à distinguer deux enfants du même prénom dans la liste d''un référent — pas à identifier plus finement.';

-- Le nom affiché, en un seul endroit. Sans cela, chaque écran recomposerait
-- « prénom + nom » à sa façon, et l'un d'eux oublierait le cas du nom vide.
create or replace function nom_affiche(p_prenom text, p_nom text)
returns text
language sql immutable as $$
  select btrim(coalesce(p_prenom, '') || ' ' || coalesce(p_nom, ''));
$$;

-- ---------------------------------------------------------------------------
-- LÀ OÙ LA CONFUSION COÛTE LE PLUS CHER
--
-- L'administration voit deux listes de dossiers : ceux dont la suppression est
-- demandée, et ceux dont la purge est due. Toutes deux n'affichaient que le
-- prénom. Se tromper de ligne ici n'ouvre pas la mauvaise fiche — ça efface le
-- mauvais dossier, définitivement.
--
-- La colonne change de nom en même temps que de contenu : `prenom` qui
-- contiendrait « Lucas Martin » serait un piège pour le prochain qui la lira.
-- ---------------------------------------------------------------------------

drop function if exists suppressions_en_cours();

create function suppressions_en_cours()
returns table (
  demande_id uuid,
  enfant_id uuid,
  enfant text,
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
    d.id, d.enfant_id, nom_affiche(coalesce(e.prenom, ''), e.nom), d.motif, d.statut,
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

drop function if exists dossiers_a_purger();

create function dossiers_a_purger()
returns table (
  enfant_id uuid,
  enfant text,
  archive_le timestamptz,
  purge_due_le date,
  date_annoncee date,
  ecart_jours integer,
  jours_de_retard integer,
  sur_demande boolean
)
language sql stable security definer set search_path = public as $$
  select
    e.id, nom_affiche(e.prenom, e.nom), e.archive_le,
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
  order by (e.archive_le + duree_conservation())::date;
$$;
