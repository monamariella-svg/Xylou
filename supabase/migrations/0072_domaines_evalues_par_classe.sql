-- 0072 — Ce que l'Éducation nationale évalue, classe par classe.
--
-- 0003 range les repères de compétences par **cycle**. La compilation des
-- évaluations nationales montre que c'est trop grossier : au sein du même
-- cycle 4, les mathématiques sont évaluées sur deux domaines en 5e, quatre en
-- 4e — dont « organisation et gestion de données, fonctions », qui n'existe
-- qu'en 4e et annonce le brevet. Un référentiel par cycle ne sait pas dire ça.
--
-- C'est le pendant exact de ce que 0071 a établi pour le programme : ni le
-- texte en vigueur, ni ce qui est évalué ne changent d'un bloc à l'échelle d'un
-- cycle. Les deux se jouent par classe.
--
-- ---------------------------------------------------------------------------
-- POURQUOI UNE TABLE À PART, ET NON DES LIGNES DE `reperes_competences`
--
-- Un repère de 0003 est un attendu vérifiable — « accorder le verbe avec son
-- sujet ». Un domaine est le regroupement officiel dans lequel il se range —
-- « étude de la langue ». Les mélanger dans la même table produirait un
-- référentiel où l'on ne saurait plus ce qu'on lit.
--
-- La distinction a une conséquence pratique : les domaines sont officiels et
-- stables, les repères restent à écrire. Le bilan peut donc déjà se structurer
-- correctement pendant que les attendus se remplissent.
-- ---------------------------------------------------------------------------

create table domaines_evaluation (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references versions_programme on delete restrict,

  matiere_code text not null references matieres on delete restrict,
  classe niveau_classe not null,

  code text not null,
  libelle text not null,
  ordre smallint not null default 0,

  unique (version_id, matiere_code, classe, code)
);

create index domaines_evaluation_classe_idx
  on domaines_evaluation (classe, matiere_code, ordre);

-- Un repère se range dans un domaine officiel. Nul pour ceux de 0003, qui sont
-- des formulations de travail rangées dans un domaine écrit à la main.
alter table reperes_competences
  add column domaine_evaluation_id uuid references domaines_evaluation on delete set null;

create index reperes_domaine_idx on reperes_competences (domaine_evaluation_id);

alter table domaines_evaluation enable row level security;

-- Public au même titre que le programme : aucune donnée d'enfant, et toute
-- l'équipe doit pouvoir savoir contre quelle structure un bilan est construit.
create policy domaines_evaluation_lecture on domaines_evaluation
  for select to authenticated using (true);
create policy domaines_evaluation_administration on domaines_evaluation
  for all to authenticated using (est_admin()) with check (est_admin());

-- ------------------------------------------------------- l'édition 2026

-- Source : compilation des pages éduscol « Évaluations nationales et tests de
-- positionnement », rentrée 2026, fournie par la porteuse du projet.
--
-- `source = 'synthese'` et non `'eduscol'` : les domaines ci-dessous sont
-- attribués à éduscol par ce document, mais n'ont pas été relus sur les pages
-- officielles. La distinction n'est pas une précaution de style — elle dit à
-- qui viendra ensuite que la vérification reste à faire.
insert into versions_programme (source, edition, reference, notes)
values (
  'synthese',
  2026,
  'Compilation — Évaluations nationales et tests de positionnement',
  'Domaines évalués par classe, d''après les pages éduscol des évaluations nationales. Les évaluations classent en groupes de maîtrise par domaine, sans note. À relire sur les pages officielles avant usage en production.'
);

insert into domaines_evaluation (version_id, matiere_code, classe, code, libelle, ordre)
select v.id, d.matiere, d.classe, d.code, d.libelle, d.ordre
from versions_programme v,
  (values
    -- ---------------------------------------------------------- CP
    ('francais','cp'::niveau_classe,'connaissance_lettres','Connaissance des lettres',1::smallint),
    ('francais','cp','syllabes_phonemes','Manipulation de syllabes et de phonèmes',2),
    ('francais','cp','comprehension_orale','Compréhension de la langue orale',3),
    ('maths','cp','nombres_jusqu_10','Nombres jusqu''à 10 — lire, écrire, dénombrer, comparer, situer',1),
    ('maths','cp','problemes','Résolution de problèmes',2),

    -- ---------------------------------------------------------- CE1
    ('francais','ce1','lecture','Lecture',1),
    ('francais','ce1','ecriture','Écriture',2),
    ('francais','ce1','vocabulaire','Vocabulaire',3),
    ('francais','ce1','oral','Oral',4),
    ('maths','ce1','nombres_entiers','Nombres entiers',1),
    ('maths','ce1','calcul_mental','Calcul mental',2),
    ('maths','ce1','problemes','Résolution de problèmes',3),

    -- ---------------------------------------------------------- CE2
    ('francais','ce2','lecture','Lecture',1),
    ('francais','ce2','orthographe','Orthographe',2),
    ('francais','ce2','grammaire','Grammaire',3),
    ('francais','ce2','vocabulaire','Vocabulaire',4),
    ('francais','ce2','oral','Oral',5),
    ('maths','ce2','nombres_entiers','Nombres entiers',1),
    ('maths','ce2','fractions','Fractions',2),
    ('maths','ce2','calcul_mental','Calcul mental',3),
    ('maths','ce2','calcul_pose','Calcul posé',4),
    ('maths','ce2','problemes','Résolution de problèmes',5),

    -- ---------------------------------------------------------- CM1
    ('francais','cm1','lecture','Lecture',1),
    ('francais','cm1','orthographe','Orthographe',2),
    ('francais','cm1','grammaire','Grammaire',3),
    ('francais','cm1','vocabulaire','Vocabulaire',4),
    ('francais','cm1','oral','Oral',5),
    ('maths','cm1','nombres_entiers','Nombres entiers',1),
    ('maths','cm1','calcul_mental','Calcul mental',2),
    ('maths','cm1','calcul_pose','Calcul posé',3),
    ('maths','cm1','problemes','Résolution de problèmes',4),

    -- ---------------------------------------------------------- CM2
    ('francais','cm2','lecture','Lecture',1),
    ('francais','cm2','grammaire_orthographe','Grammaire et orthographe grammaticale',2),
    ('francais','cm2','vocabulaire','Vocabulaire',3),
    ('francais','cm2','oral','Oral',4),
    ('maths','cm2','nombres_entiers','Nombres entiers',1),
    ('maths','cm2','fractions_decimaux','Fractions et décimaux',2),
    ('maths','cm2','calcul_mental','Calcul mental',3),
    ('maths','cm2','calcul_pose','Calcul posé',4),
    ('maths','cm2','problemes','Résolution de problèmes',5),

    -- ---------------------------------------------------------- 6e
    ('francais','6e','fluence','Fluence — lecture à voix haute',1),
    ('francais','6e','langage_oral','Langage oral',2),
    ('francais','6e','lecture_comprehension','Lecture et compréhension de l''écrit',3),
    ('francais','6e','etude_langue','Étude de la langue',4),
    ('maths','6e','nombres_calculs','Nombres et calculs',1),
    ('maths','6e','grandeurs_mesures','Grandeurs et mesures',2),
    ('maths','6e','espace_geometrie','Espace et géométrie',3),

    -- ------------------------------------------- 5e : le plus resserré
    ('francais','5e','fluence','Fluence — lecture à voix haute',1),
    ('francais','5e','etude_langue','Étude de la langue',2),
    ('maths','5e','nombres_calculs','Nombres et calculs',1),
    ('maths','5e','grandeurs_mesures','Grandeurs et mesures',2),

    -- --------- 4e : quatre domaines en maths, dont un propre à ce niveau
    ('francais','4e','fluence','Fluence — lecture à voix haute',1),
    ('francais','4e','comprehension_oral','Compréhension de l''oral',2),
    ('francais','4e','lecture_comprehension','Lecture et compréhension de l''écrit',3),
    ('francais','4e','etude_langue','Étude de la langue',4),
    ('maths','4e','nombres_calculs','Nombres et calculs',1),
    ('maths','4e','grandeurs_mesures','Grandeurs et mesures',2),
    ('maths','4e','espace_geometrie','Espace et géométrie',3),
    ('maths','4e','donnees_fonctions','Organisation et gestion de données, fonctions',4),

    -- ------------------------------------------------------- 2nde
    ('francais','2nde','litteratie','Littératie',1),
    ('maths','2nde','numeratie','Numératie',1)
  ) as d(matiere, classe, code, libelle, ordre)
where v.source = 'synthese'
  and v.reference = 'Compilation — Évaluations nationales et tests de positionnement';

-- ==================================================== ce qu'il faut savoir
--
-- CE QUI N'EST PAS COUVERT, ET POURQUOI
--
-- La 3e n'a pas d'évaluation nationale de positionnement — le brevet joue ce
-- rôle en fin d'année. La 1re et la terminale non plus. Ces classes n'ont donc
-- aucune ligne ici, et ce n'est pas un oubli : il faudra, pour elles, s'appuyer
-- sur le programme plutôt que sur une structure d'évaluation officielle.
--
-- La 1re année de CAP en a une, mais `niveau_classe` ne connaît pas ce niveau.
-- À trancher si Xylou accueille des élèves de la voie professionnelle.
--
-- LES GROUPES DE MAÎTRISE
--
-- Les évaluations nationales classent chaque élève en trois groupes de maîtrise
-- par domaine, sans note. `maitrise` (0004) en compte cinq — plus fin, et
-- délibérément non comparatif. Les deux échelles peuvent coexister : la nôtre
-- dit où en est l'enfant, celle de l'Éducation nationale est le vocabulaire que
-- les enseignants connaissent déjà. Reste à décider si un bilan Xylou doit
-- savoir se traduire dans la seconde pour être lisible d'une équipe.
