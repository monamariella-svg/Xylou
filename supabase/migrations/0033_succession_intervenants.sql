-- 0033 — Quand un intervenant s'en va.
--
-- `mission_relevant_de_l_enseignant` (0013) exige un rattachement actif. Le jour
-- où le professeur de mathématiques quitte l'établissement, plus personne ne
-- peut lire les copies des examens qu'il a composés : le travail reste en base,
-- utile à personne. Un enfant qui change d'établissement en cours d'année
-- perdrait ainsi tout l'historique de sa matière.
--
-- La règle qui manquait :
--
--   tant que l'auteur est là     — son travail est à lui. Un collègue de la même
--                                  matière n'a pas à lire ses copies.
--   dès qu'il n'y est plus       — son successeur dans la matière hérite, et le
--                                  référent y accède en attendant qu'il y en ait
--                                  un. Sans cette seconde branche, un départ en
--                                  cours d'année laisserait le dossier muet
--                                  jusqu'au recrutement.
--
-- L'héritage n'est pas un transfert : rien n'est réécrit, `auteur_id` continue
-- de dire qui a composé quoi. C'est la lecture qui s'élargit, et seulement le
-- temps qu'il faut.

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
        -- Filiation directe : il l'a composée, elle vient de son document, ou
        -- elle est née de l'objectif qu'il a proposé.
        (
          moi.role = 'enseignant'
          and moi.matiere_code = m.matiere_code
          and (
            m.auteur_id = auth.uid()
            or s.depose_par = auth.uid()
            or o.propose_par = auth.uid()
          )
        )
        -- Succession : plus aucune des personnes dont ce travail relève n'est
        -- rattachée à l'enfant. Le successeur dans la matière hérite, et le
        -- référent assure l'intérim.
        or (
          not exists (
            select 1 from intervenants_enfant src
            where src.enfant_id = m.enfant_id
              and src.retire_le is null
              and src.profil_id in (m.auteur_id, s.depose_par, o.propose_par)
          )
          and (
            (moi.role = 'enseignant' and moi.matiere_code = m.matiere_code)
            or moi.role = 'referent'
          )
        )
      )
  );
$$;

-- Même raisonnement pour l'écriture, à une réserve près : l'héritier peut
-- reprendre un travail orphelin, mais il reste tenu par l'objectif validé — la
-- règle de 0009 ne bouge pas, c'est seulement la personne qui change.
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
      and i.matiere_code = m.matiere_code
      and o.statut in ('valide', 'atteint')
  );
$$;

-- ------------------------------------------------- passer la main proprement

-- Un départ annoncé vaut mieux qu'un départ constaté. La fonction retire
-- l'intervenant et consigne à qui il passe la main quand c'est connu — ce qui
-- permet à l'écran de dire « en attente du successeur » plutôt que d'afficher
-- un trou.
alter table intervenants_enfant
  add column succede_a uuid references profils on delete set null,
  add column motif_retrait text not null default '';

create index intervenants_succession_idx on intervenants_enfant (succede_a);

create or replace function retirer_l_intervenant(
  p_enfant uuid,
  p_profil uuid,
  p_motif text default ''
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_role role_intervenant;
begin
  select role into v_role
  from intervenants_enfant
  where enfant_id = p_enfant and profil_id = p_profil and retire_le is null;

  if v_role is null then
    raise exception 'Cette personne n''est pas rattachée à ce dossier.';
  end if;

  -- Le lien parental relève de 0024 et 0025 : il ne se défait pas par ici.
  if v_role = 'parent' then
    raise exception 'Le rattachement d''un titulaire de l''autorité parentale ne se retire pas de cette façon.';
  end if;

  if not (est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[])
          or est_admin()
          or p_profil = auth.uid()) then
    raise exception 'Retirer un intervenant appartient à la famille, au référent, ou à l''intéressé lui-même.';
  end if;

  update intervenants_enfant
    set retire_le = now(), motif_retrait = p_motif
    where enfant_id = p_enfant and profil_id = p_profil and retire_le is null;
end;
$$;

-- Ce qui attend un successeur : les matières où un enseignant s'est retiré sans
-- que personne n'ait pris le relais. C'est la liste que le référent relit à la
-- rentrée, et celle qui justifie son accès provisoire.
create or replace function matieres_sans_enseignant(p_enfant uuid)
returns table (matiere_code text, retire_le timestamptz)
language sql stable security definer set search_path = public as $$
  select partis.matiere_code, max(partis.retire_le)
  from intervenants_enfant partis
  where partis.enfant_id = p_enfant
    and partis.role = 'enseignant'
    and partis.retire_le is not null
    and est_intervenant(p_enfant)
    and not exists (
      select 1 from intervenants_enfant actifs
      where actifs.enfant_id = p_enfant
        and actifs.role = 'enseignant'
        and actifs.retire_le is null
        and actifs.matiere_code = partis.matiere_code
    )
  group by partis.matiere_code;
$$;
