-- 0050 — Le devoir vient de l'enseignant, quelle que soit la main qui l'a saisi.
--
-- 0049 traitait le devoir comme un objet de la famille : saisi par elle, non
-- noté, hors du décompte des badges. C'était une erreur de cadrage, et elle
-- avait deux conséquences qui n'auraient pas pardonné.
--
-- ---------------------------------------------------------------------------
-- 1. LE PROFESSEUR NE VOYAIT PAS LES COPIES DE SES PROPRES DEVOIRS
--
-- `mission_relevant_de_l_enseignant()` remonte à trois filiations : l'auteur de
-- la mission, le déposant du support, le proposant de l'objectif. Un devoir tapé
-- le soir par un parent porte le parent comme auteur — donc le professeur qui
-- l'avait donné n'en voyait ni les réponses, ni les erreurs.
--
-- Il donne un exercice, l'enfant le fait, et lui n'en sait rien. C'est
-- exactement l'inverse de ce que le §3.1 lui promet.
--
-- 2. LE DEVOIR NE COMPTAIT PAS POUR LE BADGE
--
-- Écrit noir sur blanc dans un commentaire de 0049. C'était faux dans le code —
-- rien ne l'excluait — et faux dans le principe : un devoir fait partie des
-- exercices de l'objectif, au même titre que le reste. Un enfant qui progresse
-- par ses devoirs progresse.
-- ---------------------------------------------------------------------------

-- Qui a donné le travail, par opposition à qui l'a saisi. Les deux coïncident
-- quand l'enseignant utilise l'outil ; ils divergent le soir, quand le parent
-- recopie le cahier de textes.
alter table missions
  add column fourni_par uuid references profils on delete set null;

comment on column missions.fourni_par is
  'L''enseignant dont émane le travail. Distinct de auteur_id, qui dit qui l''a saisi : un devoir transcrit par un parent reste le devoir du professeur.';

create index missions_fourni_par_idx on missions (fourni_par);

-- --------------------------------------------- la quatrième filiation

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
            or o.propose_par = auth.uid()
          )
        )
        or (
          not exists (
            select 1 from intervenants_enfant src
            where src.enfant_id = m.enfant_id
              and src.retire_le is null
              and src.profil_id in (m.auteur_id, m.fourni_par, s.depose_par, o.propose_par)
          )
          and (
            (moi.role = 'enseignant' and intervenant_couvre(moi.id, m.matiere_code))
            or moi.role = 'referent'
          )
        )
      )
  );
$$;

-- `fourni_par` désigne un enseignant de la matière, et personne d'autre. Sans
-- cette vérification, une saisie maladroite ouvrirait les copies d'un enfant à
-- quelqu'un qui n'a rien à en faire — et ce serait une fuite créée par un
-- parent de bonne foi, ce qui est le pire cas à diagnostiquer.
create or replace function verifier_le_fournisseur()
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
      and (new.matiere_code is null or intervenant_couvre(i.id, new.matiere_code))
  ) then
    raise exception 'Le travail doit être attribué à un enseignant de cette matière, rattaché à l''enfant.';
  end if;

  return new;
end;
$$;

create trigger missions_verifient_leur_fournisseur
  before insert or update on missions
  for each row execute function verifier_le_fournisseur();

-- ------------------------------------------------- le devoir dans l'objectif

-- Un devoir se rattache à un objectif comme n'importe quel travail, et compte
-- comme lui : pour les pièces, pour les réussites de l'objectif, donc pour le
-- badge. Rien à coder — c'était déjà le cas, seul le commentaire de 0049
-- prétendait le contraire.
comment on type nature_travail is
  'entrainement : libre et répétable. evaluation : composée et notée par l''enseignant. devoir : donné par l''école, saisi par l''enseignant ou par la famille. Les trois comptent pour l''objectif auquel ils se rattachent.';

-- Ce qui n'est rattaché à rien ne compte pour rien, et personne ne s'en aperçoit
-- — c'est la panne silencieuse de ce dispositif. Un devoir saisi le soir sans
-- objectif produit des pièces et aucune progression, et l'enfant travaille pour
-- une jauge qui n'avance pas.
--
-- La liste que le référent relit, et qui doit rester courte.
create or replace function devoirs_a_rattacher(p_enfant uuid)
returns table (
  mission_id uuid,
  titre text,
  matiere_code text,
  saisi_par text,
  cree_le timestamptz,
  exercices bigint
)
language sql stable security definer set search_path = public as $$
  select m.id, m.titre, m.matiere_code, coalesce(p.prenom, ''), m.cree_le,
         count(e.id)
  from missions m
  left join profils p on p.id = m.auteur_id
  left join exercices e on e.mission_id = m.id
  where m.enfant_id = p_enfant
    and m.nature::text = 'devoir'
    and m.objectif_id is null
    and m.statut <> 'abandonnee'
    and est_intervenant(p_enfant)
  group by m.id, m.titre, m.matiere_code, p.prenom, m.cree_le
  order by m.cree_le desc;
$$;

-- ------------------------------------------------------------- la notation

-- 0049 interdisait à la famille de noter un devoir. La règle reste — noter est
-- un geste de professionnel — mais elle se formule mieux : ce n'est pas que le
-- devoir échappe à la note, c'est que la note appartient à l'enseignant. Et
-- puisque le devoir est le sien, il peut parfaitement le noter.
create or replace function refuser_la_note_sur_un_devoir()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if not (
    mission_relevant_de_l_enseignant(new.mission_id)
    or est_intervenant(enfant_de_la_mission(new.mission_id),
                       array['referent']::role_intervenant[])
  ) then
    raise exception 'La note est portée par l''enseignant de la matière, ou par le référent.';
  end if;

  return new;
end;
$$;
