-- 0003 — Le référentiel scolaire contre lequel on situe l'enfant.
--
-- Le bilan mesure « le niveau réel matière par matière, selon les repères de
-- l'Éducation nationale » (§3.2). Ce fichier crée les tables et amorce un jeu de
-- repères de départ.
--
-- ATTENTION : les repères insérés ici portent source = 'amorce'. Ce sont des
-- formulations de travail, pas les attendus officiels. Avant le pilote, ils
-- doivent être remplacés par les repères Éduscol correspondants, avec
-- source = 'eduscol'. Un bilan calibré sur des repères approximatifs découragerait
-- l'enfant au lieu de le motiver — c'est le risque nommé au §3.4.

create table matieres (
  code text primary key,
  libelle text not null,
  ordre smallint not null default 0
);

insert into matieres (code, libelle, ordre) values
  ('francais',        'Français',                 1),
  ('maths',           'Mathématiques',            2),
  ('histoire_geo',    'Histoire-Géographie',      3),
  ('langues',         'Langues vivantes',         4),
  ('svt',             'Sciences de la vie et de la Terre', 5),
  ('physique_chimie', 'Physique-Chimie',          6),
  ('technologie',     'Technologie',              7),
  ('arts',            'Arts',                     8),
  ('emc',             'Enseignement moral et civique', 9),
  ('eps',             'Éducation physique et sportive', 10);

create type cycle_scolaire as enum ('cycle2', 'cycle3', 'cycle4', 'lycee');

-- Le cycle d'une classe, utilisé pour proposer les bons repères au bilan.
create or replace function cycle_de_la_classe(p_classe niveau_classe)
returns cycle_scolaire
language sql
immutable
as $$
  select case
    when p_classe in ('cp', 'ce1', 'ce2') then 'cycle2'
    when p_classe in ('cm1', 'cm2', '6e') then 'cycle3'
    when p_classe in ('5e', '4e', '3e') then 'cycle4'
    else 'lycee'
  end::cycle_scolaire;
$$;

create type source_repere as enum ('eduscol', 'amorce', 'local');

create table reperes_competences (
  id uuid primary key default gen_random_uuid(),
  matiere_code text not null references matieres on delete cascade,
  cycle cycle_scolaire not null,
  -- Regroupement lisible : « Comprendre un texte », « Résoudre un problème »…
  domaine text not null,
  libelle text not null,
  code text,
  source source_repere not null default 'amorce',
  ordre smallint not null default 0,
  actif boolean not null default true
);

create index reperes_matiere_cycle_idx
  on reperes_competences (matiere_code, cycle) where actif;

-- ------------------------------------------------------- amorce, cycle 4
--
-- Volontairement resserrée sur le profil de départ (Xylan, 4e) : français et
-- résolution de problème fragiles, sciences solides. Les autres cycles et
-- matières se chargeront au fur et à mesure des enfants accueillis.

insert into reperes_competences (matiere_code, cycle, domaine, libelle, ordre) values
  ('francais', 'cycle4', 'Lecture et compréhension', 'Repérer l''information explicite demandée dans un texte', 1),
  ('francais', 'cycle4', 'Lecture et compréhension', 'Déduire une information qui n''est pas écrite littéralement', 2),
  ('francais', 'cycle4', 'Lecture et compréhension', 'Identifier ce qu''une consigne demande de produire', 3),
  ('francais', 'cycle4', 'Écriture', 'Écrire une phrase complète et ponctuée', 4),
  ('francais', 'cycle4', 'Écriture', 'Organiser un texte court en paragraphes suivis', 5),
  ('francais', 'cycle4', 'Langue', 'Accorder le verbe avec son sujet', 6),
  ('francais', 'cycle4', 'Langue', 'Accorder en genre et en nombre dans le groupe nominal', 7),

  ('maths', 'cycle4', 'Nombres et calculs', 'Calculer avec des nombres relatifs', 1),
  ('maths', 'cycle4', 'Nombres et calculs', 'Calculer avec des fractions', 2),
  ('maths', 'cycle4', 'Calcul littéral', 'Développer et réduire une expression littérale', 3),
  ('maths', 'cycle4', 'Résolution de problèmes', 'Extraire d''un énoncé les données utiles', 4),
  ('maths', 'cycle4', 'Résolution de problèmes', 'Choisir l''opération adaptée à une situation', 5),
  ('maths', 'cycle4', 'Résolution de problèmes', 'Contrôler la vraisemblance d''un résultat', 6),
  ('maths', 'cycle4', 'Géométrie', 'Utiliser le théorème de Pythagore', 7),
  ('maths', 'cycle4', 'Proportionnalité', 'Reconnaître et traiter une situation de proportionnalité', 8),

  ('svt', 'cycle4', 'Le vivant', 'Décrire l''organisation d''un être vivant du niveau cellulaire à l''organisme', 1),
  ('svt', 'cycle4', 'Démarche scientifique', 'Formuler une hypothèse à partir d''une observation', 2),
  ('svt', 'cycle4', 'Démarche scientifique', 'Interpréter un graphique ou un tableau de résultats', 3),

  ('physique_chimie', 'cycle4', 'Matière', 'Distinguer un mélange homogène d''un mélange hétérogène', 1),
  ('physique_chimie', 'cycle4', 'Énergie', 'Identifier les formes d''énergie et leurs conversions', 2),
  ('physique_chimie', 'cycle4', 'Démarche scientifique', 'Exploiter une mesure et son unité', 3),

  ('technologie', 'cycle4', 'Objets techniques', 'Décrire la fonction d''usage d''un objet technique', 1),
  ('technologie', 'cycle4', 'Programmation', 'Écrire et corriger un programme simple', 2),
  ('technologie', 'cycle4', 'Programmation', 'Décomposer un problème en étapes exécutables', 3);
