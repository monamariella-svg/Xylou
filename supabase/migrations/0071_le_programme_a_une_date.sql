-- 0071 — Le programme scolaire a une date, et elle n'est pas la même partout.
--
-- 0003 a posé `reperes_competences` sans dire de quand ils datent. Or le
-- programme change, et un bilan passé en 2026 doit rester lisible contre le
-- programme de 2026 — pas contre celui de 2028. Sans cette date, relire un
-- ancien bilan reviendrait à le juger sur des attendus qui n'existaient pas
-- quand l'enfant l'a passé.
--
-- ---------------------------------------------------------------------------
-- LE PIÈGE : LE PROGRAMME NE BASCULE PAS D'UN BLOC
--
-- On s'attendait à dater le référentiel entier : une édition, une date de
-- début, une date de fin. C'est faux. La synthèse de la rentrée 2026 le montre
-- clairement — au sein du même cycle 4, la 5e reçoit les nouveaux programmes en
-- 2026, la 4e en 2027, la 3e en 2028.
--
-- Deux élèves du même cycle, la même année, ne sont donc pas évalués contre le
-- même texte. La validité se joue par **classe** et par **rentrée**, jamais par
-- cycle ni globalement.
--
-- C'est aussi ce qui rend la mise à jour annuelle tenable : on publie une
-- édition, on déclare à quelles classes elle s'applique et à partir de quand,
-- et les repères d'avant restent attachés à la leur.
-- ---------------------------------------------------------------------------

create table versions_programme (
  id uuid primary key default gen_random_uuid(),

  -- D'où vient ce qu'on a enregistré. `eduscol` est le seul qui fasse foi ;
  -- `synthese` dit qu'on s'est appuyé sur un document de seconde main, ce qui
  -- se voit et se corrige ; `local` couvre ce qu'une équipe formule elle-même.
  source text not null default 'synthese'
    check (source in ('eduscol', 'synthese', 'local')),

  -- L'année de la rentrée : « 2026 » pour la rentrée de septembre 2026.
  edition smallint not null,
  reference text not null default '',
  publie_le date,
  notes text not null default '',

  cree_le timestamptz not null default now(),
  unique (source, edition, reference)
);

-- Quelle édition s'applique à quelle classe, à partir de quelle rentrée.
-- `rentree_fin` nul = toujours en vigueur ; on le renseigne le jour où une
-- édition suivante prend le relais pour cette classe-là.
create table programme_applicable (
  version_id uuid not null references versions_programme on delete cascade,
  classe niveau_classe not null,
  rentree_debut smallint not null,
  rentree_fin smallint,

  primary key (version_id, classe),
  constraint programme_fin_apres_debut
    check (rentree_fin is null or rentree_fin >= rentree_debut)
);

create index programme_applicable_classe_idx
  on programme_applicable (classe, rentree_debut desc);

-- Les repères disent désormais de quelle édition ils viennent. Nul pour ceux de
-- 0003, qui portent `source = 'amorce'` : des formulations de travail, qui ne
-- relèvent d'aucune édition et doivent être remplacées avant qu'un enfant passe
-- un bilan.
alter table reperes_competences
  add column version_programme_id uuid references versions_programme on delete restrict;

create index reperes_version_idx on reperes_competences (version_programme_id);

-- Le programme en vigueur pour une classe à une rentrée donnée. Une seule
-- réponse : c'est ce qui permet de dire contre quoi un bilan a été calibré.
create or replace function programme_en_vigueur(
  p_classe niveau_classe,
  p_rentree smallint default extract(year from current_date)::smallint
)
returns uuid
language sql
stable
as $$
  select a.version_id
  from programme_applicable a
  where a.classe = p_classe
    and a.rentree_debut <= p_rentree
    and (a.rentree_fin is null or a.rentree_fin >= p_rentree)
  order by a.rentree_debut desc
  limit 1;
$$;

-- ==================================================================== RLS

-- Le programme scolaire est public : il ne porte aucune donnée d'enfant, et
-- toute l'équipe doit pouvoir savoir contre quoi un bilan a été construit.
-- Seule l'administration le fait évoluer.
alter table versions_programme    enable row level security;
alter table programme_applicable  enable row level security;

create policy versions_programme_lecture on versions_programme
  for select to authenticated using (true);
create policy versions_programme_administration on versions_programme
  for all to authenticated using (est_admin()) with check (est_admin());

create policy programme_applicable_lecture on programme_applicable
  for select to authenticated using (true);
create policy programme_applicable_administration on programme_applicable
  for all to authenticated using (est_admin()) with check (est_admin());

-- ------------------------------------------------- ce que l'on sait à ce jour

-- Source : « Synthèse Globale des Programmes de l'Éducation Nationale —
-- Édition Rentrée Scolaire 2026 », document d'orientation fourni par la
-- porteuse du projet. Ce n'est pas le Bulletin officiel : `source = 'synthese'`
-- le dit, et l'édition devra être reprise en `eduscol` quand les textes eux-
-- mêmes auront été versés.
--
-- Aucun repère n'est rattaché ici. Ce document décrit l'architecture des
-- cycles et le calendrier des réformes ; il ne contient pas un seul attendu
-- de compétence, et il annonce lui-même que les textes complets dépassent
-- 3 500 pages.
insert into versions_programme (source, edition, reference, notes)
values (
  'synthese',
  2026,
  'Synthèse Globale des Programmes — Rentrée 2026',
  'Architecture des cycles et calendrier des réformes. Ne contient aucun repère de compétence : à compléter par les textes officiels avant qu''un enfant passe un bilan.'
);

-- Le calendrier tel que la synthèse l'établit. Ce qui compte ici n'est pas la
-- liste, c'est qu'elle ne soit pas uniforme : au sein du cycle 4, trois classes
-- basculent à trois rentrées différentes.
insert into programme_applicable (version_id, classe, rentree_debut)
select v.id, c.classe, c.rentree
from versions_programme v,
  (values
    -- Cycle 2 : cadre consolidé, en vigueur.
    ('cp'::niveau_classe, 2026::smallint),
    ('ce1', 2026),
    ('ce2', 2026),
    -- Cycle 3 : refonte du CM2 active à la rentrée 2026.
    ('cm1', 2026),
    ('cm2', 2026),
    ('6e', 2026),
    -- Cycle 4 : la 5e bascule en 2026, la 4e en 2027, la 3e en 2028.
    ('5e', 2026),
    ('4e', 2027),
    ('3e', 2028),
    -- Lycée : ajustements, pas de refonte annoncée.
    ('2nde', 2026),
    ('1ere', 2026),
    ('terminale', 2026)
  ) as c(classe, rentree)
where v.edition = 2026 and v.source = 'synthese';
