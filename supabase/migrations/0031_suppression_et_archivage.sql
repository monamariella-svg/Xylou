-- 0031 — Supprimer pour tous, conserver pour la loi.
--
-- `enfants.archive_le` existe depuis 0001 et ne fait rien : aucune politique ne
-- le lit. Une fiche « archivée » reste entièrement visible et modifiable, ce qui
-- est pire que de ne pas avoir la colonne — 0024 renvoie les parents vers
-- l'archivage comme alternative à la suppression, c'est-à-dire vers une porte
-- qui ne ferme pas.
--
-- Ce que les parents doivent obtenir : que le dossier disparaisse. Pour eux,
-- pour l'équipe, pour tout le monde. Ce que la loi impose par ailleurs : de
-- conserver certaines traces pendant une durée déterminée.
--
-- Les deux se concilient si l'on distingue conserver et accéder :
--
--   - l'archivage rend le dossier invisible à tous les comptes, sans exception,
--     y compris à l'administration ;
--   - les données restent en base jusqu'à la date de purge ;
--   - si un besoin légitime survient dans l'intervalle — réquisition, litige —
--     il passe par le mécanisme d'accès d'exception de 0028, motivé et tracé.
--
-- L'administration voit donc qu'un dossier archivé existe, et quand il sera
-- purgé. Elle n'en voit pas le contenu. C'est la seule lecture qui rende la
-- suppression réelle du point de vue de la famille tout en gardant la
-- conservation possible.
--
-- ---------------------------------------------------------------------------
-- LA DURÉE EST UN PLACEHOLDER
--
-- Cinq ans, faute de mieux. Ce n'est pas une durée établie : c'est la question
-- 5.1 du document juriste, et elle n'a pas encore de réponse. Elle se change en
-- une ligne, et il faudra la changer.
-- ---------------------------------------------------------------------------

alter table enfants
  add column archive_par uuid references profils on delete set null,
  add column motif_archivage text not null default '',
  add column purge_prevue_le date;

alter table enfants
  add constraint archivage_signe
  check (
    (archive_le is null and archive_par is null and purge_prevue_le is null)
    or (archive_le is not null and archive_par is not null and purge_prevue_le is not null)
  );

create index enfants_a_purger_idx
  on enfants (purge_prevue_le)
  where archive_le is not null;

-- --------------------------------------------------------- le geste d'archiver

-- Personne ne pose ces colonnes à la main : elles sortent des deux fonctions
-- définies plus bas, qui vérifient les droits et écrivent au journal. Le
-- réglage de session leur sert de laissez-passer le temps de leur écriture.
create or replace function proteger_l_archivage()
returns trigger language plpgsql as $$
begin
  if (new.archive_le is distinct from old.archive_le
   or new.purge_prevue_le is distinct from old.purge_prevue_le
   or new.archive_par is distinct from old.archive_par)
   and current_setting('xylou.archivage', true) is distinct from 'en_cours' then
    raise exception 'Passez par archiver_le_dossier() ou desarchiver_le_dossier().';
  end if;
  return new;
end;
$$;

create or replace function archiver_le_dossier(p_enfant uuid, p_motif text default '')
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not peut_valider(p_enfant) then
    raise exception 'Seuls les titulaires de l''autorité parentale et le référent archivent un dossier.';
  end if;

  if exists (select 1 from enfants where id = p_enfant and archive_le is not null) then
    raise exception 'Ce dossier est déjà archivé.';
  end if;

  perform set_config('xylou.archivage', 'en_cours', true);

  update enfants
    set archive_le = now(),
        archive_par = auth.uid(),
        motif_archivage = p_motif,
        purge_prevue_le = (now() + interval '5 years')::date
    where id = p_enfant;

  perform set_config('xylou.archivage', '', true);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'dossier_archive', 'enfants', p_enfant,
          jsonb_build_object('motif', p_motif));
end;
$$;

-- Désarchiver n'appartient pas à la famille : une fiche rendue invisible puis
-- rendue visible à nouveau ferait réapparaître dans l'équipe pédagogique un
-- dossier que chacun croyait clos. C'est une correction d'erreur, donc un geste
-- administratif, motivé et tracé.
create or replace function desarchiver_le_dossier(p_enfant uuid, p_motif text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not est_admin() then
    raise exception 'Le désarchivage est un geste administratif.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Le désarchivage se motive.';
  end if;

  perform set_config('xylou.archivage', 'en_cours', true);

  update enfants
    set archive_le = null, archive_par = null,
        motif_archivage = '', purge_prevue_le = null
    where id = p_enfant;

  perform set_config('xylou.archivage', '', true);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'dossier_desarchive', 'enfants', p_enfant,
          jsonb_build_object('motif', p_motif));
end;
$$;

create trigger enfants_protegent_leur_archivage
  before update on enfants
  for each row execute function proteger_l_archivage();

-- ============================================ rendre l'archivage effectif

-- Le point d'étranglement : `est_intervenant()` est la fonction par laquelle
-- passe l'écrasante majorité des politiques du schéma, directement ou via
-- `peut_valider()`. Lui ajouter la condition d'archivage la propage partout
-- d'un coup — c'est la seule façon de couvrir une trentaine de tables sans en
-- oublier une.
create or replace function est_intervenant(p_enfant uuid, p_roles role_intervenant[] default null)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from intervenants_enfant i
    join enfants e on e.id = i.enfant_id
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (p_roles is null or i.role = any (p_roles))
  );
$$;

-- Restent les fonctions qui interrogent `intervenants_enfant` sans passer par
-- elle. Elles gouvernent des écritures, et écrire dans un dossier archivé n'a
-- pas plus de sens que le lire.
create or replace function matiere_ouverte_a_l_ecriture(p_enfant uuid, p_matiere text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from intervenants_enfant i
    join enfants e on e.id = i.enfant_id
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (i.role <> 'enseignant' or i.matiere_code = p_matiere)
  );
$$;

create or replace function pilote_l_objectif(p_objectif uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from objectifs o
    join enfants e on e.id = o.enfant_id
    join intervenants_enfant i on i.enfant_id = o.enfant_id
    where o.id = p_objectif
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (
        (o.matiere_code is not null
          and i.role = 'enseignant'
          and i.matiere_code = o.matiere_code)
        or (o.domaine_code is not null and i.role = 'referent')
      )
  );
$$;

create or replace function acces_au_fil(p_fil uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from fils f
    join enfants e on e.id = f.enfant_id
    where f.id = p_fil
      and e.archive_le is null
      and (
        (f.portee = 'equipe' and est_intervenant(f.enfant_id))
        or exists (
          select 1 from fils_participants p
          where p.fil_id = f.id and p.profil_id = auth.uid()
        )
      )
  );
$$;

-- `mission_ouverte_a_l_enseignant` et `mission_relevant_de_l_enseignant`
-- (0009 et 0013) passent par `objectifs` et `intervenants_enfant`. Elles sont
-- couvertes indirectement dès lors que les politiques qui les appellent
-- combinent toujours `est_intervenant()` ou `peut_valider()` en amont — et pour
-- celles qui ne le font pas, l'archivage bloque déjà la lecture du parent, donc
-- la ligne n'est de toute façon plus atteignable.

-- ------------------------------------------------- ce que voit l'administration

-- La liste des dossiers archivés et leur date de purge. Pas leur contenu :
-- `enfants_lecture_admin` (0026) donne déjà la fiche, et aucune politique de ce
-- fichier n'ouvre quoi que ce soit d'autre à `est_admin()`.
--
-- Conserver n'est pas accéder. Si un besoin légitime survient avant la purge,
-- il passe par 0028 — motivé, tracé, borné dans le temps.
create or replace function dossiers_a_purger()
returns table (enfant_id uuid, archive_le timestamptz, purge_prevue_le date)
language sql stable security definer set search_path = public as $$
  select e.id, e.archive_le, e.purge_prevue_le
  from enfants e
  where e.archive_le is not null
    and est_admin()
  order by e.purge_prevue_le;
$$;
