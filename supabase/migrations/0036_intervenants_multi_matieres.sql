-- 0036 — Un enseignant couvre une matière, plusieurs, ou toutes.
--
-- 0001 posait `intervenants_enfant.matiere_code`, une seule valeur, avec
-- `unique (enfant_id, profil_id)`. Le modèle tenait pour un collège où chaque
-- professeur a sa discipline. Il ne tient nulle part ailleurs :
--
--   - en primaire, un professeur des écoles enseigne tout. Il aurait fallu dix
--     lignes, que la contrainte d'unicité interdit ;
--   - en collège, un professeur a souvent deux disciplines — mathématiques et
--     technologie, physique-chimie et SVT ;
--   - en ULIS ou en SEGPA, le découpage ne suit pas les disciplines du tout.
--
-- La matière devient donc un ensemble. Et parce qu'énumérer dix matières pour un
-- professeur des écoles serait à la fois pénible et fragile — une matière ajoutée
-- au référentiel demain lui échapperait — un drapeau `toutes_matieres` couvre ce
-- cas d'un geste, et continue de le couvrir quand le référentiel s'étoffe.

alter table intervenants_enfant
  add column toutes_matieres boolean not null default false;

create table intervenants_matieres (
  intervenant_id uuid not null references intervenants_enfant on delete cascade,
  matiere_code text not null references matieres on delete restrict,
  primary key (intervenant_id, matiere_code)
);

create index intervenants_matieres_matiere_idx
  on intervenants_matieres (matiere_code);

-- Reprise de l'existant : ce qui était dans la colonne passe dans la table.
insert into intervenants_matieres (intervenant_id, matiere_code)
select id, matiere_code
from intervenants_enfant
where matiere_code is not null
on conflict do nothing;

-- `matiere_code` survit en lecture seule, le temps que l'application bascule.
-- Elle ne gouverne plus aucun droit : les fonctions ci-dessous interrogent
-- toutes `intervenants_matieres`.
comment on column intervenants_enfant.matiere_code is
  'Obsolète depuis 0036. La ou les matières d''un intervenant vivent dans intervenants_matieres, ou sont couvertes par toutes_matieres.';

-- 0011 exigeait qu'un enseignant porte une matière dans la colonne. La règle
-- reste — un enseignant sans matière n'écrit rien, c'était le sens de 0011 —
-- mais elle se vérifie désormais sur l'ensemble, ce qu'un CHECK ne sait pas
-- faire puisqu'il faut interroger une autre table.
alter table intervenants_enfant
  drop constraint enseignant_a_une_matiere;

alter table intervenants_enfant
  drop constraint intervenants_matiere_connue;

create or replace function exiger_une_matiere_a_l_enseignant()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_role role_intervenant;
  v_enfant uuid;
begin
  select i.role, i.enfant_id into v_role, v_enfant
  from intervenants_enfant i
  where i.id = coalesce(new.intervenant_id, old.intervenant_id);

  if v_role <> 'enseignant' then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.id = coalesce(new.intervenant_id, old.intervenant_id)
      and (
        i.toutes_matieres
        or exists (select 1 from intervenants_matieres m where m.intervenant_id = i.id)
      )
  ) then
    raise exception 'Un enseignant couvre au moins une matière, ou toutes.';
  end if;

  return null;
end;
$$;

-- Différé : composer l'ensemble suppose souvent de retirer une matière avant
-- d'en ajouter une autre. Vérifier ligne à ligne interdirait la correction.
create constraint trigger intervenants_matieres_exigent_une_matiere
  after delete on intervenants_matieres
  deferrable initially deferred
  for each row execute function exiger_une_matiere_a_l_enseignant();

-- Et la vérification symétrique, sur le rattachement lui-même : sans elle, un
-- enseignant créé sans qu'on lui attribue jamais de matière passerait entre les
-- mailles — le trigger ci-dessus ne se déclenche qu'à la suppression d'une
-- matière, donc jamais si l'on n'en a pas mis.
--
-- Différée elle aussi, et pour la même raison qu'en 0025 : le rattachement
-- s'insère avant les matières, et vérifier immédiatement interdirait l'ordre
-- naturel des opérations.
create or replace function exiger_une_matiere_au_rattachement()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role <> 'enseignant' or new.retire_le is not null then
    return null;
  end if;

  if new.toutes_matieres then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_matieres m where m.intervenant_id = new.id
  ) then
    raise exception 'Un enseignant couvre au moins une matière, ou toutes. Renseignez son périmètre.';
  end if;

  return null;
end;
$$;

create constraint trigger intervenants_exigent_une_matiere
  after insert or update on intervenants_enfant
  deferrable initially deferred
  for each row execute function exiger_une_matiere_au_rattachement();

-- ------------------------------------------------------- le test d'appartenance

create or replace function intervenant_couvre(p_intervenant uuid, p_matiere text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from intervenants_enfant i
    where i.id = p_intervenant
      and (
        i.toutes_matieres
        or exists (
          select 1 from intervenants_matieres m
          where m.intervenant_id = i.id and m.matiere_code = p_matiere
        )
      )
  );
$$;

-- ============================================ reprise des fonctions d'accès

-- Toutes celles qui comparaient `i.matiere_code = …`. Le corps change, la
-- signature et le sens restent : un enseignant n'écrit que dans ce qu'il couvre,
-- les parents et le référent ne sont pas concernés par la matière.

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
      and (i.role <> 'enseignant' or intervenant_couvre(i.id, p_matiere))
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
          and intervenant_couvre(i.id, o.matiere_code))
        or (o.domaine_code is not null and i.role = 'referent')
      )
  );
$$;

create or replace function mission_ouverte_a_l_enseignant(p_mission uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from missions m
    join enfants enf on enf.id = m.enfant_id and enf.archive_le is null
    join intervenants_enfant i on i.enfant_id = m.enfant_id
    join objectifs o on o.id = m.objectif_id
    where m.id = p_mission
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, m.matiere_code)
      and o.statut in ('valide', 'atteint')
  );
$$;

create or replace function mission_relevant_de_l_enseignant(p_mission uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from missions m
    join enfants enf on enf.id = m.enfant_id and enf.archive_le is null
    join intervenants_enfant moi
      on moi.enfant_id = m.enfant_id
     and moi.profil_id = auth.uid()
     and moi.retire_le is null
    left join adaptations a on a.id = m.adaptation_id
    left join supports s on s.id = a.support_id
    left join objectifs o on o.id = m.objectif_id
    where m.id = p_mission
      and (
        (
          moi.role = 'enseignant'
          and intervenant_couvre(moi.id, m.matiere_code)
          and (
            m.auteur_id = auth.uid()
            or s.depose_par = auth.uid()
            or o.propose_par = auth.uid()
          )
        )
        or (
          not exists (
            select 1 from intervenants_enfant src
            where src.enfant_id = m.enfant_id
              and src.retire_le is null
              and src.profil_id in (m.auteur_id, s.depose_par, o.propose_par)
          )
          and (
            (moi.role = 'enseignant' and intervenant_couvre(moi.id, m.matiere_code))
            or moi.role = 'referent'
          )
        )
      )
  );
$$;

-- Qualité de la personne, sans référence à un enfant : sert à valider un modèle
-- d'exercice dans la bibliothèque (0018).
create or replace function enseigne_la_matiere(p_matiere text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from intervenants_enfant i
    where i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, p_matiere)
  );
$$;

-- Les matières orphelines, pour l'intérim du référent (0033). Une matière n'est
-- orpheline que si *aucun* enseignant actif ne la couvre — un professeur des
-- écoles en `toutes_matieres` les couvre donc toutes d'un coup.
create or replace function matieres_sans_enseignant(p_enfant uuid)
returns table (matiere_code text, retire_le timestamptz)
language sql stable security definer set search_path = public as $$
  select mp.matiere_code, max(partis.retire_le)
  from intervenants_enfant partis
  join intervenants_matieres mp on mp.intervenant_id = partis.id
  where partis.enfant_id = p_enfant
    and partis.role = 'enseignant'
    and partis.retire_le is not null
    and est_intervenant(p_enfant)
    and not exists (
      select 1 from intervenants_enfant actifs
      where actifs.enfant_id = p_enfant
        and actifs.role = 'enseignant'
        and actifs.retire_le is null
        and intervenant_couvre(actifs.id, mp.matiere_code)
    )
  group by mp.matiere_code;
$$;

-- L'alerte de 0021 joignait l'enseignant par `i.matiere_code = v_matiere`.
create or replace function alerter_sur_echec_repete()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_seuil constant smallint := 3;
  v_objectif uuid;
  v_repere uuid;
  v_matiere text;
  v_intitule text;
  v_lien text;
  v_echecs integer;
  v_alerte uuid;
begin
  if new.reussie then
    return new;
  end if;

  select m.objectif_id, coalesce(o.repere_id, mo.repere_id), o.libelle
    into v_objectif, v_repere, v_intitule
  from exercices e
  join missions m on m.id = e.mission_id
  left join objectifs o on o.id = m.objectif_id
  left join modeles_exercice mo on mo.id = e.modele_id
  where e.id = new.exercice_id;

  if v_repere is not null then
    select r.matiere_code, r.libelle into v_matiere, v_intitule
    from reperes_competences r where r.id = v_repere;

    v_echecs := echecs_consecutifs_repere(new.enfant_id, v_repere);
    v_lien := '/enfants/' || new.enfant_id || '/difficultes/repere/' || v_repere;
    v_objectif := null;

  elsif v_objectif is not null then
    if not exists (
      select 1 from objectifs o
      where o.id = v_objectif and o.granularite = 'fin'
    ) then
      return new;
    end if;

    v_echecs := echecs_consecutifs_objectif(new.enfant_id, v_objectif);
    v_lien := '/enfants/' || new.enfant_id || '/difficultes/objectif/' || v_objectif;

  else
    return new;
  end if;

  if v_echecs < v_seuil then
    return new;
  end if;

  select id into v_alerte
  from alertes_difficulte
  where enfant_id = new.enfant_id
    and statut = 'ouverte'
    and repere_id is not distinct from v_repere
    and objectif_id is not distinct from v_objectif;

  if v_alerte is not null then
    update alertes_difficulte
      set echecs_consecutifs = v_echecs, derniere_le = new.cree_le
      where id = v_alerte;
    return new;
  end if;

  insert into alertes_difficulte
    (enfant_id, repere_id, objectif_id, echecs_consecutifs, derniere_le)
  values
    (new.enfant_id, v_repere, v_objectif, v_echecs, new.cree_le);

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id, new.enfant_id, 'difficulte_repetee',
    'Blocage répété : ' || coalesce(v_intitule, 'compétence non précisée'),
    v_echecs || ' échecs d''affilée, sans réussite intercalée.',
    v_lien
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and (
      i.role in ('parent', 'referent')
      or (v_matiere is not null and i.role = 'enseignant'
          and intervenant_couvre(i.id, v_matiere))
    );

  return new;
end;
$$;

-- ------------------------------------------------- invitations et rattachement

-- Une invitation porte désormais un ensemble de matières. Le tableau vide, pour
-- un enseignant, signifie « toutes » — c'est le cas du professeur des écoles, et
-- le plus fréquent en primaire.
alter table invitations
  add column matieres text[] not null default '{}',
  add column toutes_matieres boolean not null default false;

update invitations
  set matieres = array[matiere_code]
  where matiere_code is not null;

-- `accepter_l_invitation` (0024) recopiait `matiere_code`. Elle compose
-- maintenant l'ensemble.
create or replace function accepter_l_invitation(p_jeton text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_inv invitations%rowtype;
  v_intervenant uuid;
begin
  select * into v_inv
  from invitations
  where jeton = p_jeton
    and acceptee_le is null
    and annulee_le is null
    and expire_le > now();

  if not found then
    raise exception 'Invitation introuvable, déjà acceptée, annulée ou expirée.';
  end if;

  if lower(v_inv.email) <> email_courant() then
    raise exception 'Cette invitation a été adressée à une autre adresse que celle de votre compte.';
  end if;

  insert into intervenants_enfant
    (enfant_id, profil_id, role, fonction, matiere_code, toutes_matieres, invite_par)
  values
    (v_inv.enfant_id, auth.uid(), v_inv.role, v_inv.fonction,
     v_inv.matiere_code, v_inv.toutes_matieres, v_inv.invite_par)
  on conflict (enfant_id, profil_id) do nothing
  returning id into v_intervenant;

  if v_intervenant is not null then
    insert into intervenants_matieres (intervenant_id, matiere_code)
    select v_intervenant, unnest(v_inv.matieres)
    on conflict do nothing;
  end if;

  update invitations set acceptee_le = now() where id = v_inv.id;

  return v_inv.enfant_id;
end;
$$;

-- ==================================================================== RLS

alter table intervenants_matieres enable row level security;

create policy intervenants_matieres_lecture on intervenants_matieres
  for select to authenticated
  using (
    exists (
      select 1 from intervenants_enfant i
      where i.id = intervenant_id and est_intervenant(i.enfant_id)
    )
  );

-- Composer l'ensemble des matières d'un intervenant revient à définir son
-- périmètre d'écriture : cela relève de la famille, du référent, ou de
-- l'administration — jamais de l'intéressé lui-même.
create policy intervenants_matieres_composition on intervenants_matieres
  for all to authenticated
  using (
    exists (
      select 1 from intervenants_enfant i
      where i.id = intervenant_id
        and (
          est_intervenant(i.enfant_id, array['parent', 'referent']::role_intervenant[])
          or est_admin()
        )
    )
  )
  with check (
    exists (
      select 1 from intervenants_enfant i
      where i.id = intervenant_id
        and (
          est_intervenant(i.enfant_id, array['parent', 'referent']::role_intervenant[])
          or est_admin()
        )
    )
  );
