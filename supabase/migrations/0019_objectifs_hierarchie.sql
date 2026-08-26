-- 0019 — Objectifs larges, objectifs fins, et qui pilote quoi.
--
-- 0005 ne connaissait qu'un seul niveau d'objectif, et une seule dimension :
-- la matière. Deux manques :
--
--   1. Un objectif large — « gagner en autonomie dans la compréhension d'un
--      énoncé » — ne s'atteint pas d'un coup. Il se décompose en objectifs fins,
--      et ce sont ces derniers qui orientent les exercices.
--   2. Tout ne relève pas d'une matière. Le social, la communication, le
--      comportement sont des domaines à part entière, et leur pilote n'est pas
--      un enseignant mais le référent.
--
-- La famille valide toujours l'objectif — c'est le point de contrôle posé en
-- 0009 et il ne bouge pas. Ce que ce fichier ajoute est en dessous : une fois
-- l'objectif validé, le professionnel compétent règle le grain. Combien
-- d'exercices, sur quelle période, et à quelle condition on considère que c'est
-- acquis. Un élève peut avoir besoin de trois exercices sur une leçon et de
-- quinze sur la suivante ; personne ne peut le savoir à l'avance, et surtout pas
-- au moment où l'objectif est posé.

-- ------------------------------------------------- domaines non scolaires

create table domaines_transversaux (
  code text primary key,
  libelle text not null,
  ordre smallint not null default 0
);

insert into domaines_transversaux (code, libelle, ordre) values
  ('communication', 'Communication',                1),
  ('social',        'Relations sociales',           2),
  ('autonomie',     'Autonomie',                    3),
  ('comportement',  'Régulation et comportement',   4),
  ('societal',      'Vie sociale et citoyenneté',   5);

alter table domaines_transversaux enable row level security;
create policy domaines_lecture on domaines_transversaux
  for select to authenticated using (true);

-- --------------------------------------------------- un champ, pas deux

-- `matiere_code` cesse d'être obligatoire : un objectif relève soit d'une
-- matière, soit d'un domaine transversal, jamais des deux ni d'aucun.
alter table objectifs alter column matiere_code drop not null;

alter table objectifs
  add column domaine_code text references domaines_transversaux on delete restrict;

alter table objectifs
  add constraint objectif_releve_d_un_seul_champ
  check (num_nonnulls(matiere_code, domaine_code) = 1);

-- ------------------------------------------------------------- hiérarchie

create type granularite_objectif as enum ('large', 'fin');

alter table objectifs
  add column granularite granularite_objectif not null default 'large',
  add column objectif_parent_id uuid references objectifs on delete cascade;

alter table objectifs
  add constraint objectif_fin_a_un_parent
  check ((granularite = 'fin') = (objectif_parent_id is not null));

create index objectifs_enfants_de_idx on objectifs (objectif_parent_id);

-- ------------------------------------------- ce qui règle le grain, en aval

-- `critere_fin` répond à « à quoi verra-t-on que c'est acquis ». Sans lui, un
-- objectif fin resterait ouvert par défaut jusqu'à ce que quelqu'un décide
-- arbitrairement de le fermer.
--
-- Deux compteurs, à ne pas confondre.
--
-- `reussites_visees` est le critère d'acquisition : combien de fois l'enfant
-- doit refaire la chose avec succès pour qu'on la tienne pour apprise. Trois par
-- défaut — un enfant apprend en reproduisant, et une réussite isolée peut être
-- un coup de chance autant qu'un acquis. Modulable, parce que trois n'est pas
-- une loi : certaines notions demandent davantage, d'autres tombent du premier
-- coup et insister ferait de l'exercice une punition.
--
-- `exercices_vises` est le volume préparé, une intention et non un quota : on le
-- révise à la hausse quand l'enfant peine, à la baisse quand c'est acquis plus
-- vite que prévu. C'est ce que le professionnel ajuste en cours de route, et
-- c'est ce qui permet trois exercices sur une leçon et quinze sur la suivante.
alter table objectifs
  add column critere_fin text not null default '',
  add column reussites_visees smallint not null default 3
    check (reussites_visees > 0),
  add column exercices_vises smallint
    check (exercices_vises is null or exercices_vises > 0);

comment on column objectifs.reussites_visees is
  'Nombre de réussites avant de tenir la compétence pour acquise. N''a de sens que sur un objectif fin.';

-- Préparer moins d'exercices qu'il ne faut de réussites conduit l'enfant dans un
-- objectif qu'il ne peut pas clore.
alter table objectifs
  add constraint assez_d_exercices_pour_reussir
  check (exercices_vises is null or exercices_vises >= reussites_visees);

alter table objectifs
  add constraint seuls_les_objectifs_fins_se_chiffrent
  check (granularite = 'fin' or (exercices_vises is null and critere_fin = ''));

-- Un objectif fin appartient au même enfant que son parent, et se raccroche à un
-- objectif large — pas à un autre objectif fin. Deux règles impossibles à écrire
-- en CHECK, qui interroge la ligne et non la table.
create or replace function verifier_le_parent_de_l_objectif()
returns trigger language plpgsql as $$
declare
  v_parent objectifs%rowtype;
begin
  if new.objectif_parent_id is null then
    return new;
  end if;

  select * into v_parent from objectifs where id = new.objectif_parent_id;

  if v_parent.enfant_id <> new.enfant_id then
    raise exception 'Un objectif fin appartient au même enfant que son objectif large.';
  end if;

  if v_parent.granularite <> 'large' then
    raise exception 'Un objectif fin se rattache à un objectif large, pas à un autre objectif fin.';
  end if;

  return new;
end;
$$;

create trigger objectifs_verifient_leur_parent
  before insert or update on objectifs
  for each row execute function verifier_le_parent_de_l_objectif();

-- Les missions suivent le même partage : sans cela, un objectif fin de
-- communication ne pourrait porter aucun exercice, et la moitié du dispositif
-- resterait décorative. Les politiques de 0009 se dégradent correctement d'
-- elles-mêmes — `matiere_ouverte_a_l_ecriture()` écarte tout enseignant dès que
-- la matière est nulle, et `peut_valider()` couvre le référent.
alter table missions alter column matiere_code drop not null;

alter table missions
  add column domaine_code text references domaines_transversaux on delete restrict;

alter table missions
  add constraint mission_releve_d_un_seul_champ
  check (num_nonnulls(matiere_code, domaine_code) = 1);

-- Où en est l'enfant sur un objectif fin : combien d'exercices lui ont été
-- proposés, combien il en a réussi, et si le seuil est franchi.
--
-- Une fonction SECURITY DEFINER et non une vue, pour une raison qui compte. Une
-- vue en `security_invoker` appliquerait la RLS de `tentatives`, dont l'accès est
-- restreint : un professionnel qui n'y a pas droit ne verrait pas une erreur, il
-- verrait zéro réussite. Un compteur qui se trompe en silence est pire qu'un
-- compteur absent — celui-ci ferait conclure que l'enfant n'y arrive pas.
--
-- Le contrôle d'accès est donc explicite : qui accompagne l'enfant obtient les
-- totaux. C'est le chiffre qu'on affiche dans une liste d'objectifs, rien de
-- plus. Le détail — quelle réponse, quel exercice, où ça a bloqué — est ouvert
-- en 0020 à ceux qui pilotent l'objectif, parce qu'un compteur ne dit pas quoi
-- corriger.
create or replace function progression_objectif(p_objectif uuid)
returns table (
  exercices_proposes bigint,
  reussites bigint,
  reussites_visees smallint,
  seuil_atteint boolean
)
language sql stable security definer set search_path = public as $$
  select
    count(distinct e.id),
    count(distinct e.id) filter (where t.reussie),
    o.reussites_visees,
    count(distinct e.id) filter (where t.reussie) >= o.reussites_visees
  from objectifs o
  left join missions m on m.objectif_id = o.id
  left join exercices e on e.mission_id = m.id
  left join tentatives t on t.exercice_id = e.id and t.enfant_id = o.enfant_id
  where o.id = p_objectif
    and est_intervenant(o.enfant_id)
  group by o.id, o.reussites_visees;
$$;

-- ================================================== qui pilote un objectif

-- L'enseignant pour sa matière, le référent pour les domaines transversaux.
-- La symétrie est voulue : dans les deux cas c'est le professionnel compétent
-- sur le champ, et dans aucun des deux ce n'est « celui qui a le temps ».
create or replace function pilote_l_objectif(p_objectif uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from objectifs o
    join intervenants_enfant i on i.enfant_id = o.enfant_id
    where o.id = p_objectif
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and (
        (o.matiere_code is not null
          and i.role = 'enseignant'
          and i.matiere_code = o.matiere_code)
        or (o.domaine_code is not null and i.role = 'referent')
      )
  );
$$;

-- Le pilote règle le grain, il ne rouvre pas la décision. Sans cette barrière,
-- lui ouvrir la ligne pour qu'il ajuste un nombre d'exercices lui donnerait
-- aussi `libelle` et `statut` — c'est-à-dire le pouvoir de réécrire l'objectif
-- que la famille a validé, ou de le déclarer atteint tout seul. RLS filtre des
-- lignes ; c'est donc à un trigger de tenir les colonnes.
create or replace function restreindre_le_pilotage()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if peut_valider(new.enfant_id) then
    return new;
  end if;

  if new.libelle           is distinct from old.libelle
  or new.description       is distinct from old.description
  or new.statut            is distinct from old.statut
  or new.valide_par        is distinct from old.valide_par
  or new.valide_le         is distinct from old.valide_le
  or new.granularite       is distinct from old.granularite
  or new.objectif_parent_id is distinct from old.objectif_parent_id
  or new.matiere_code      is distinct from old.matiere_code
  or new.domaine_code      is distinct from old.domaine_code
  or new.enfant_id         is distinct from old.enfant_id then
    raise exception 'Seuls la famille et le référent modifient un objectif validé. Le pilote ajuste la période, le nombre d''exercices et le critère de fin — pour le reste, passez par une demande de modification.';
  end if;

  return new;
end;
$$;

create trigger objectifs_restreignent_le_pilotage
  before update on objectifs
  for each row execute function restreindre_le_pilotage();

-- ==================================================================== RLS

-- La proposition s'ouvre aux domaines transversaux : jusqu'ici la politique de
-- 0009 passait `matiere_code` à `matiere_ouverte_a_l_ecriture()`, qui renvoie
-- faux pour un enseignant dès que la matière est nulle. C'est le bon
-- comportement — un professeur ne propose pas d'objectif de communication —
-- mais il fallait que le référent, lui, puisse le faire.
drop policy objectifs_maj on objectifs;

create policy objectifs_maj on objectifs for update to authenticated
  using (
    peut_valider(enfant_id)
    or (propose_par = auth.uid() and statut = 'propose')
    -- Le pilote agit sur un objectif validé ; les colonnes qu'il peut toucher
    -- sont tenues par `restreindre_le_pilotage()`.
    or (granularite = 'fin' and pilote_l_objectif(id))
  )
  with check (
    peut_valider(enfant_id)
    or (propose_par = auth.uid() and statut = 'propose')
    or (granularite = 'fin' and pilote_l_objectif(id))
  );
