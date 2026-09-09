-- 0075 — Les attendus officiels, à la place des formulations d'amorce.
--
-- 0003 a semé huit repères de mathématiques et sept de français, écrits à la
-- main pour que l'application tourne : `source = 'amorce'`, et 0003 le disait.
-- Un bilan construit dessus mesurerait ce que nous avons inventé.
--
-- Ceux-ci sont les attendus de fin de 5e, recopiés du « Document à destination
-- des équipes pédagogiques » de l'évaluation nationale de début de 4e
-- (DEPP et IGÉSR, septembre 2023), qui les tient du Bulletin officiel n° 31 du
-- 30 juillet 2020. Ce sont eux que l'évaluation nationale vérifie en début de
-- 4e, donc eux contre lesquels un bilan de 4e situe un enfant.
--
-- ---------------------------------------------------------------------------
-- POURQUOI « FIN DE 5e » DANS UNE ÉVALUATION DE 4e
--
-- Ce n'est pas une erreur de recopie : on évalue en septembre ce qui devait
-- être acquis en juin. La conséquence vaut d'être retenue — un enfant de 4e
-- n'est pas en retard parce qu'il ne sait pas ce qu'on enseignera cette
-- année-là ; le référentiel de départ est celui de l'année précédente.
--
-- ---------------------------------------------------------------------------
-- CE QUI N'EST PAS TOUCHÉ
--
-- Les repères d'amorce de 0003 restent en base, `actif = true`. Les désactiver
-- ici casserait tout bilan ou objectif déjà écrit contre eux — 0034 pose déjà
-- qu'on ne recommence pas à zéro. Ils portent `source = 'amorce'`, ce qui suffit
-- à les distinguer, et l'écran de génération pourra préférer 'eduscol'.
--
-- Les autres matières (SVT, physique-chimie, technologie) gardent leurs
-- formulations d'amorce : l'évaluation nationale ne porte que sur le français
-- et les mathématiques, et nous n'avons pas de source officielle pour le reste.
-- ---------------------------------------------------------------------------

-- ------------------------------------------------- mathématiques, cycle 4
--
-- Rattachés au domaine d'évaluation de 4e (0072) : c'est lui qui porte la
-- classe. `reperes_competences` ne connaît que le cycle, et le cycle 4 est trop
-- grossier — la 5e évalue deux domaines de mathématiques, la 4e en évalue
-- quatre.

insert into reperes_competences
  (matiere_code, cycle, domaine, libelle, source, ordre, domaine_evaluation_id)
select v.matiere, 'cycle4'::cycle_scolaire, v.grand, v.libelle, 'eduscol'::source_repere,
       v.ordre, de.id
from (values
  ('maths', 'espace_geometrie', 'Représenter l’espace',
   'Se repérer sur une droite graduée et dans le plan muni d’un repère orthogonal.', 1),
  ('maths', 'espace_geometrie', 'Représenter l’espace',
   'Reconnaitre des solides (pavé droit, cube, cylindre, prisme droit, pyramide, cône, boule) à partir d’un objet réel, d’une image, d’une représentation en perspective cavalière.', 2),
  ('maths', 'espace_geometrie', 'Représenter l’espace',
   'Mettre en relation une représentation en perspective cavalière et un patron d’un pavé droit, d’un cylindre.', 3),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Le codage des figures.', 4),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Les caractérisations angulaires du parallélisme (angles alternes internes, angles correspondants).', 5),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'La somme des angles d’un triangle.', 6),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'L’inégalité triangulaire.', 7),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Une définition et une propriété caractéristique du parallélogramme.', 8),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'La définition de la médiatrice.', 9),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'La définition des hauteurs d’un triangle.', 10),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Mettre en œuvre et écrire un protocole de construction de triangles, de parallélogrammes et d’un assemblage de figures.', 11),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Transformer une figure par symétrie centrale.', 12),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Comprendre l’effet des symétries (axiale et centrale) sur des figures : conservation du parallélisme, des longueurs et des angles.', 13),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Mobiliser les connaissances des figures, des configurations et des symétries pour déterminer des grandeurs géométriques.', 14),
  ('maths', 'espace_geometrie', 'Utiliser les notions de géométrie plane pour démontrer',
   'Mener des raisonnements en utilisant des propriétés des figures, des configurations et des symétries.', 15),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Effectuer des calculs de durées et d’horaires.', 16),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Calculer le périmètre et l’aire des figures usuelles (rectangle, parallélogramme, triangle, disque).', 17),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Calculer le périmètre et l’aire d’un assemblage de figures.', 18),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Calculer le volume d’un pavé droit, d’un prisme droit, d’un cylindre.', 19),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Exprimer les résultats dans l’unité adaptée.', 20),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Vérifier la cohérence des résultats du point de vue des unités pour les calculs de durées, de longueurs, d’aires ou de volumes.', 21),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Effectuer des conversions d’unités de longueurs, d’aires, de volumes et de durées.', 22),
  ('maths', 'grandeurs_mesures', 'Calculer avec des grandeurs mesurables ; exprimer les résultats dans les unités adaptées',
   'Utiliser la correspondance entre les unités de volume et de contenance (1 L = 1 dm³, 1 000 L = 1 m³) pour effectuer des conversions.', 23),
  ('maths', 'grandeurs_mesures', 'Comprendre l’effet de quelques transformations sur les figures géométriques',
   'Comprendre l’effet des symétries (axiale et centrale) : conservation du parallélisme, des longueurs et des angles.', 24),
  ('maths', 'grandeurs_mesures', 'Comprendre l’effet de quelques transformations sur les figures géométriques',
   'Utiliser l’échelle d’une carte.', 25),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Utiliser, dans le cas des nombres décimaux, les écritures décimales et fractionnaires et passer de l’une à l’autre, en particulier dans le cadre de la résolution de problèmes.', 26),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Relier fractions, proportions et pourcentages.', 27),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Décomposer une fraction sous la forme d’une somme (ou d’une différence), d’un entier et d’une fraction.', 28),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Utiliser la notion d’opposé.', 29),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Comparer, ranger, encadrer des fractions dont les dénominateurs sont égaux ou multiples l’un de l’autre.', 30),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Repérer sur une droite graduée les nombres décimaux relatifs.', 31),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Traduire un enchainement d’opérations à l’aide d’une expression avec des parenthèses.', 32),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Effectuer mentalement, à la main ou à l’aide d’une calculatrice un enchainement d’opérations en respectant les priorités opératoires.', 33),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Additionner et soustraire des nombres décimaux relatifs.', 34),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Additionner ou soustraire des fractions dont les dénominateurs sont égaux ou multiples l’un de l’autre.', 35),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Contrôler la vraisemblance d’un résultat.', 36),
  ('maths', 'nombres_calculs', 'Utiliser les nombres pour comparer, calculer et résoudre des problèmes',
   'Résoudre des problèmes faisant intervenir des nombres décimaux relatifs et des fractions.', 37),
  ('maths', 'nombres_calculs', 'Comprendre et utiliser les notions de divisibilité et de nombres premiers',
   'Calculer le quotient et le reste dans une division euclidienne.', 38),
  ('maths', 'nombres_calculs', 'Comprendre et utiliser les notions de divisibilité et de nombres premiers',
   'Déterminer si un nombre entier est ou n’est pas multiple ou diviseur d’un autre nombre entier.', 39),
  ('maths', 'nombres_calculs', 'Comprendre et utiliser les notions de divisibilité et de nombres premiers',
   'Utiliser les critères de divisibilité par 2, 3, 5, 9 et 10.', 40),
  ('maths', 'nombres_calculs', 'Comprendre et utiliser les notions de divisibilité et de nombres premiers',
   'Résoudre des problèmes faisant intervenir les notions de multiple, de diviseur, de quotient et de reste.', 41),
  ('maths', 'nombres_calculs', 'Utiliser le calcul littéral',
   'Utiliser les notations 2a pour a × 2 ou 2 × a et ab pour a × b, a² pour a × a et a³ pour a × a × a.', 42),
  ('maths', 'nombres_calculs', 'Utiliser le calcul littéral',
   'Utiliser la distributivité simple pour réduire une expression littérale de la forme ax + bx où a et b sont des nombres décimaux.', 43),
  ('maths', 'nombres_calculs', 'Utiliser le calcul littéral',
   'Produire une expression littérale pour élaborer une formule ou traduire un programme de calcul.', 44),
  ('maths', 'nombres_calculs', 'Utiliser le calcul littéral',
   'Utiliser une lettre pour traduire des propriétés générales.', 45),
  ('maths', 'nombres_calculs', 'Utiliser le calcul littéral',
   'Substituer une valeur numérique à une lettre pour calculer la valeur d’une expression littérale, tester si une égalité où figurent une ou deux indéterminées est vraie quand on leur attribue des valeurs numériques, et contrôler son résultat.', 46),
  ('maths', 'donnees_fonctions', 'Interpréter, représenter et traiter des données',
   'Recueillir et organiser des données.', 47),
  ('maths', 'donnees_fonctions', 'Interpréter, représenter et traiter des données',
   'Lire et interpréter des données brutes ou présentées sous forme de tableaux, de diagrammes et de graphiques.', 48),
  ('maths', 'donnees_fonctions', 'Interpréter, représenter et traiter des données',
   'Calculer des effectifs et des fréquences.', 49),
  ('maths', 'donnees_fonctions', 'Interpréter, représenter et traiter des données',
   'Calculer et interpréter la moyenne d’une série de données.', 50),
  ('maths', 'donnees_fonctions', 'Comprendre et utiliser des notions élémentaires de probabilités',
   'Calculer des probabilités dans des situations simples d’équiprobabilité.', 51),
  ('maths', 'donnees_fonctions', 'Résoudre des problèmes de proportionnalité',
   'Reconnaitre une situation de proportionnalité ou de non proportionnalité entre deux grandeurs.', 52),
  ('maths', 'donnees_fonctions', 'Résoudre des problèmes de proportionnalité',
   'Résoudre des problèmes de proportionnalité dans diverses situations pouvant faire intervenir des pourcentages ou des échelles, en mettant en œuvre des procédures variées (additivité, homogénéité, passage à l’unité, coefficient de proportionnalité).', 53),
  ('maths', 'donnees_fonctions', 'Comprendre et utiliser la notion de fonction',
   'Traduire la relation de dépendance entre deux grandeurs par un tableau de valeur.', 54),
  ('maths', 'donnees_fonctions', 'Comprendre et utiliser la notion de fonction',
   'Produire une formule représentant la dépendance de deux grandeurs.', 55)
) as v(matiere, dom_code, grand, libelle, ordre)
join domaines_evaluation de
  on de.matiere_code = v.matiere
 and de.classe = '4e'
 and de.code = v.dom_code;

-- ---------------------------------------------------- français, cycle 4
--
-- La fiche d'accompagnement « Compréhension de l'écrit — Comprendre le sens
-- global d'un texte » (éduscol, septembre 2023) ne décrit qu'une compétence,
-- mais elle la décrit complètement : elle nomme les deux capacités qui la
-- composent et, pour chacune, les sources d'erreur observées.
--
-- Ces sources d'erreur entrent directement dans `erreurs_types` — c'est le seul
-- endroit du corpus officiel où elles sont énoncées de façon générale, et non
-- attachées à une question particulière.

insert into reperes_competences
  (matiere_code, cycle, domaine, libelle, source, ordre, erreurs_types, domaine_evaluation_id)
select 'francais', 'cycle4'::cycle_scolaire, v.dom, v.libelle, 'eduscol'::source_repere,
       v.ordre, v.erreurs, de.id
from (values
  ('lecture_comprehension', 'Compréhension de l’écrit',
   'Comprendre le sens global d’un texte', 1, array['Difficulté à prendre en compte l’univers de référence et le genre du texte.']::text[]),
  ('lecture_comprehension', 'Compréhension de l’écrit',
   'Construire des représentations mentales cohérentes avec le contenu du texte.', 2, array['Représentation mentale erronée des éléments du texte.', 'Difficulté à rectifier ses représentations initiales.', 'Difficulté à prendre en compte l’univers de référence et le genre du texte.']::text[]),
  ('lecture_comprehension', 'Compréhension de l’écrit',
   'Prendre en compte le contenu du texte dans son ensemble, pour en comprendre le sens.', 3, array['Difficulté à mettre en relation des éléments contenus dans un même texte mais éloignés, ou contenus dans des documents différents.', 'Méconnaissance des moyens de contrôler sa compréhension.', 'Difficulté à prendre en compte l’univers de référence et le genre du texte.']::text[])
) as v(dom_code, dom, libelle, ordre, erreurs)
join domaines_evaluation de
  on de.matiere_code = 'francais'
 and de.classe = '4e'
 and de.code = v.dom_code;

-- ==================================================== ce qu'il faut savoir
--
-- CE QUE CETTE MIGRATION NE FAIT PAS
--
-- Elle ne remplit ni `consigne_reference` ni `critere_de_reussite`. Un attendu
-- officiel dit ce qui doit être acquis, pas comment on le demande ni à quoi
-- l'on reconnaît que c'est réussi. C'est 0076 qui apporte cette matière, en
-- chargeant les questions publiées et leur analyse.
--
-- `reperes_generables` (0074) rapportera donc, après cette migration :
-- rattachés à un domaine, mais sans critère. C'est exact, et c'est le but de
-- cette vue de le dire.
--
-- LES CLASSES AUTRES QUE LA 4e
--
-- Rien ici pour la 6e, la 5e ou la 2nde. Les documents équivalents existent —
-- « Guides pour le professeur » au premier degré, « Documents à destination des
-- équipes pédagogiques » au collège — et se chargeront de la même façon. La 4e
-- d'abord parce que c'est la classe de l'enfant à l'origine du projet.

-- ---------------------------------------------------------------------------
-- Une jointure qui ne rapproche rien n'insère rien, sans rien dire. Les
-- libellés de domaine ci-dessus viennent de 0072 : si l'un change ou disparaît,
-- cette migration passerait au vert en ayant chargé la moitié du référentiel.
do $$
declare n_maths int; n_fr int;
begin
  select count(*) into n_maths from reperes_competences
    where source = 'eduscol' and matiere_code = 'maths';
  select count(*) into n_fr from reperes_competences
    where source = 'eduscol' and matiere_code = 'francais';
  if n_maths <> 55 or n_fr <> 3 then
    raise exception '0075 : % attendus de mathématiques et % de français chargés, 55 et 3 attendus', n_maths, n_fr;
  end if;
end $$;
