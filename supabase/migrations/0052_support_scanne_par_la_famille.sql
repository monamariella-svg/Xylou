-- 0052 — Le document scanné à la maison reste celui de l'enseignant.
--
-- 0050 a rendu au professeur les copies des devoirs qu'il donne, même saisis par
-- un parent, grâce à `missions.fourni_par`. Le raisonnement s'arrêtait à
-- mi-chemin : il existe un second parcours, et il est le plus fréquent.
--
--   parcours 1  le parent recopie l'énoncé  → mission de nature « devoir »
--               → couvert par 0050.
--
--   parcours 2  le parent photographie la feuille  → `supports`
--               → l'IA en tire une adaptation  → une mission
--               → NON couvert : `mission_relevant_de_l_enseignant()` remonte à
--                 `supports.depose_par`, qui est le parent.
--
-- Le second est celui qu'une famille utilisera vraiment. Recopier vingt lignes
-- d'énoncé le soir, personne ne le fait ; prendre une photo du cahier, tout le
-- monde. Et c'est précisément là que le professeur devenait invisible.
--
-- La correction est la même, appliquée au bon endroit : distinguer qui a fourni
-- le document de qui l'a versé dans l'outil.

alter table supports
  add column fourni_par uuid references profils on delete set null;

comment on column supports.fourni_par is
  'L''enseignant dont émane le document. Distinct de depose_par, qui dit qui l''a versé : une feuille photographiée par un parent reste le support du professeur.';

create index supports_fourni_par_idx on supports (fourni_par);

-- Même garde qu'en 0050 : le fournisseur désigné doit être un enseignant de
-- cette matière, rattaché à l'enfant. Sans elle, une saisie approximative
-- ouvrirait les copies à quelqu'un qui n'a rien à en connaître.
create or replace function verifier_le_fournisseur_du_support()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.fourni_par is null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.profil_id = new.fourni_par
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, new.matiere_code)
  ) then
    raise exception 'Le document doit être attribué à un enseignant de cette matière, rattaché à l''enfant.';
  end if;

  return new;
end;
$$;

create trigger supports_verifient_leur_fournisseur
  before insert or update on supports
  for each row execute function verifier_le_fournisseur_du_support();

-- --------------------------------------------- la cinquième filiation

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
            or m.fourni_par = auth.uid()
            or s.depose_par = auth.uid()
            or s.fourni_par = auth.uid()
            or o.propose_par = auth.uid()
          )
        )
        or (
          not exists (
            select 1 from intervenants_enfant src
            where src.enfant_id = m.enfant_id
              and src.retire_le is null
              and src.profil_id in (m.auteur_id, m.fourni_par,
                                    s.depose_par, s.fourni_par, o.propose_par)
          )
          and (
            (moi.role = 'enseignant' and intervenant_couvre(moi.id, m.matiere_code))
            or moi.role = 'referent'
          )
        )
      )
  );
$$;

-- Le support lui-même se lit par toute l'équipe depuis 0009, donc rien à
-- changer de ce côté. Ce qui manquait n'était pas la lecture du document, mais
-- la lecture de ce que l'enfant en a fait.

-- --------------------------------------------- les documents sans provenance

-- La panne silencieuse, jumelle de `devoirs_a_rattacher()` : un support versé
-- sans attribution produit des missions dont l'enseignant ne verra jamais les
-- résultats. Rien ne signale l'anomalie — tout fonctionne, sauf pour lui.
create or replace function supports_sans_provenance(p_enfant uuid)
returns table (
  support_id uuid,
  titre text,
  matiere_code text,
  type_support type_support,
  depose_par_prenom text,
  cree_le timestamptz,
  missions_issues bigint
)
language sql stable security definer set search_path = public as $$
  select
    s.id, s.titre, s.matiere_code, s.type_support,
    coalesce(p.prenom, ''), s.cree_le,
    (select count(*) from missions m
     join adaptations a on a.id = m.adaptation_id
     where a.support_id = s.id)
  from supports s
  left join profils p on p.id = s.depose_par
  where s.enfant_id = p_enfant
    and s.fourni_par is null
    -- Déposé par quelqu'un qui n'enseigne pas la matière : c'est le cas d'une
    -- famille qui scanne. Un enseignant qui dépose son propre cours n'a rien à
    -- attribuer, il est déjà la provenance.
    and not exists (
      select 1 from intervenants_enfant i
      where i.enfant_id = p_enfant
        and i.profil_id = s.depose_par
        and i.retire_le is null
        and i.role = 'enseignant'
        and intervenant_couvre(i.id, s.matiere_code)
    )
    and est_intervenant(p_enfant)
  group by s.id, s.titre, s.matiere_code, s.type_support, p.prenom, s.cree_le
  order by s.cree_le desc;
$$;
