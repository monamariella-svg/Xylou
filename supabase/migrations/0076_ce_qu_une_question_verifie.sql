-- 0076 — Ce qu'une question vérifie : la tâche, la réponse, et les erreurs.
--
-- 0074 a posé qu'un repère ne suffit pas à générer une question : « accorder le
-- verbe avec son sujet » peut produire une dictée comme un QCM, et rien ne dit
-- lequel était attendu. 0075 a chargé les attendus officiels — ils disent ce
-- qui doit être acquis, pas comment on le demande.
--
-- Cette migration charge ce qui manquait : les questions réellement posées lors
-- de l'évaluation nationale de début de 4e, avec pour chacune la tâche
-- demandée, la réponse attendue, et l'analyse des erreurs.
--
-- Sources, toutes deux publiques et librement téléchargeables :
--   « Évaluation nationale — classe de quatrième — Mathématiques — Présentation
--   des exercices et des compétences évaluées » (DEPP / IGÉSR, septembre 2023) ;
--   « Exploitation des évaluations nationales de 4e — Compréhension de l'écrit —
--   Comprendre le sens global d'un texte » (éduscol, septembre 2023).
--
-- ---------------------------------------------------------------------------
-- POURQUOI UNE TABLE, ET NON DES COLONNES DE `reperes_competences`
--
-- 0074 avait ajouté `consigne_reference`, `critere_de_reussite` et
-- `erreurs_types` au repère lui-même, en supposant qu'une source officielle les
-- donnerait sous forme générale. Elle ne les donne pas ainsi : elle donne des
-- questions. « Réponse attendue : 8 » est vrai de la question 1, pas de
-- l'attendu « additionner des nombres entiers ».
--
-- Recopier ces valeurs dans le repère y ferait entrer un cas particulier sous
-- l'apparence d'une règle. Un modèle qui lirait « critère de réussite : 8 » pour
-- toute soustraction produirait n'importe quoi, et rien ne l'aurait signalé.
--
-- Une question est donc un objet distinct de l'attendu qu'elle vérifie. Les
-- colonnes de 0074 restent utiles pour ce qui, un jour, sera énoncé de façon
-- générale — le français de 0075 en donne d'ailleurs un exemple, ses sources
-- d'erreur étant décrites indépendamment de toute question.
--
-- ---------------------------------------------------------------------------
-- CE QUE CE CORPUS APPREND, ET QUI N'ÉTAIT PAS PRÉVU
--
-- Sur les 22 questions du test d'automatismes, la moitié environ ne se rattache
-- à aucun attendu de fin de 5e : elles portent sur des acquis du cycle 3 —
-- tables d'addition, moitié d'un entier, addition de nombres entiers.
--
-- Ce n'est pas un défaut du test, c'est sa construction : on commence en
-- dessous du niveau visé. C'est exactement la règle posée dans
-- `docs/pre-bilan-et-bilan.md` — commencer par des réussites, puis monter — et
-- la trouver dans l'évaluation officielle la confirme plutôt que nous.
-- ---------------------------------------------------------------------------

-- Le document de 2023 est une source à part entière, distincte de la
-- compilation de 0072 : celle-ci donnait la structure des domaines, celui-là
-- donne les questions. Les deux peuvent diverger, et il faut pouvoir le voir.
insert into versions_programme (source, edition, reference, publie_le, notes)
values (
  'eduscol',
  2023,
  'Évaluation nationale de début de 4e — documents à destination des équipes pédagogiques',
  '2023-09-01',
  'Mathématiques : présentation des exercices et des compétences évaluées (DEPP / IGÉSR). Français : fiche d''accompagnement « Comprendre le sens global d''un texte ».'
);

create table items_evaluation_nationale (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references versions_programme on delete restrict,

  -- Le domaine officiel dans lequel la question se range (0072). Toujours
  -- renseigné : c'est ce qui rattache la question à une classe.
  domaine_evaluation_id uuid not null references domaines_evaluation on delete restrict,

  -- L'attendu que la question vérifie, quand le rattachement est évident.
  -- Nul le reste du temps, et c'est une information : voir plus bas.
  repere_id uuid references reperes_competences on delete set null,

  test text not null,
  numero smallint not null,

  -- Le découpage tel que le document le donne. `sous_domaine` et
  -- `automatismes` pour les mathématiques, `structure` pour les problèmes
  -- (nature du problème, familiarité du contexte, nature des nombres) — c'est
  -- ce dernier qui permet d'écrire un problème équivalent plutôt que copié.
  sous_domaine text not null default '',
  automatismes text not null default '',
  structure text not null default '',

  -- Ce que l'élève doit faire, et par quels chemins il peut y arriver.
  tache text not null,
  reponse_attendue text not null,

  -- Les erreurs observées, avec ce qu'elles révèlent. C'est la matière des
  -- distracteurs : un QCM dont les mauvaises réponses sont absurdes ne mesure
  -- rien, l'enfant élimine sans savoir.
  erreurs_observees text[] not null default '{}',

  -- La calculatrice était-elle disponible. Nul quand le document ne le dit pas.
  calculatrice boolean,

  -- Le taux de réussite national, quand il est publié.
  --
  -- Il sert à ordonner les questions de la plus réussie à la moins réussie,
  -- donc à savoir par où commencer. Il ne dit rien de l'enfant et ne doit
  -- jamais lui être présenté, ni figurer dans un bilan : ce serait la
  -- comparaison à une norme que la convention du projet interdit.
  taux_reussite_national numeric(5,2),

  unique (version_id, test, numero)
);

create index items_evaluation_domaine_idx
  on items_evaluation_nationale (domaine_evaluation_id, test, numero);
create index items_evaluation_repere_idx
  on items_evaluation_nationale (repere_id);

alter table items_evaluation_nationale enable row level security;

-- Référentiel public, au même titre que les domaines et les repères : aucune
-- donnée d'enfant n'y figure.
create policy items_evaluation_lecture on items_evaluation_nationale
  for select to authenticated using (true);
create policy items_evaluation_administration on items_evaluation_nationale
  for all to authenticated using (est_admin()) with check (est_admin());

-- ------------------------------------------- mathématiques : 41 questions
--
-- 22 du test d'automatismes, 19 du test de résolution de problèmes.

insert into items_evaluation_nationale
  (version_id, domaine_evaluation_id, test, numero, sous_domaine, automatismes,
   structure, tache, reponse_attendue, erreurs_observees, calculatrice)
select v.id, de.id, i.test, i.numero, i.sous_domaine, i.automatismes,
       i.structure, i.tache, i.reponse, i.erreurs, i.calculatrice
from versions_programme v,
  (values
  ('automatismes', 1::smallint, 'nombres_calculs',
   'Additionner ou soustraire des nombres entiers',
   'Automatisme procédural (principal) : savoir soustraire sans poser l’opération. Automatisme déclaratif (secondaire) : connaissance des tables d’addition.',
   '',
   'L’élève doit trouver la différence de 14 et de 6. Pour cela il peut se référer aux tables d’addition 6 + 8 = 14 donc 14 – 6 = 8. il peut aussi décomposer la soustraction : 14 – 6 = 14 – 4 – 2 = 10 – 2 = 8. Enfin, il peut tester les propositions une à une en appui avec les tables d’addition : 6 + 6 = 12 ; 6 + 7 = 13 ; 6 + 8 = 14 ; 6 + 9 = 15.',
   '8',
   array['6 → moitié de 12. L’élève ne maitrise pas les tables d’addition, les moitiés ou fait une erreur de calcul.', '7 → moitié de 14 L’élève ne maitrise pas les tables d’addition ou fait une erreur de calcul.', '9 → 14 – 5 L’élève ne maitrise pas les tables d’addition ou fait une erreur de calcul.']::text[], false),
  ('automatismes', 2::smallint, 'nombres_calculs',
   'Trouver la moitié d’un entier pair inférieur à 100.',
   'Automatisme procédural (principal) : savoir diviser un nombre entier par 2 en s’appuyant sur la numération décimale. Automatismes déclaratifs (secondaires) : connaissance des tables de multiplication ; connaissance des moitiés de nombres entiers inférieurs à 20 ou des dizaines paires.',
   '',
   'L’élève doit déterminer la moitié de 70. Pour cela il peut décomposer 70 en 60 + 10 ; puis chercher la moitié de chacun de ces deux termes : 30 et 5 ; et enfin les additionner 30 + 5 = 35. Il peut aussi faire le même raisonnement en considérant que : 70 unités = 7 dizaines ; puis que la moitié de 7 dizaines est 3 dizaines et une demi-dizaine ; pour enfin aboutir à 35 unités. Il peut aussi tester les propositions : 30 × 2 = 60 et 40 × 2 = 80 ; et ainsi conclure que seul 35 peut être la réponse correcte.',
   '35',
   array['30 → L’élève confond avec la moitié de 60.', '40 → L’élève confond avec la moitié de 80.', '45 → L’élève confond avec la moitié de 90.']::text[], false),
  ('automatismes', 3::smallint, 'grandeurs_mesures',
   'Utiliser des fractions pour partager ou mesurer des grandeurs. Fractionner une aire.',
   'Automatisme Automatisme procédural : associer une fraction à un partage d’aire.',
   '',
   'L’élève doit déterminer la fraction d’une surface. Pour cela il doit établir la rapport entre le nombre de secteurs angulaires coloriés – numérateur 5 – et le nombre total de secteurs – dénominateur 8.',
   '5/8',
   array['3 8 → L’élève interprète mal le mot « coloriée ». Il indique la proportion de secteurs blancs par rapport au nombre total de secteurs.', '3 5 → L’élève confond la proportion par rapport au total et par rapport au complémentaire. Il indique la proportion de secteurs blancs par rapport au nombre de secteurs bleus.', '5 3 → L’élève confond proportion par rapport au total et par rapport au complémentaire. Il indique la proportion de secteurs bleus par rapport au nombre de secteurs blancs.']::text[], false),
  ('automatismes', 4::smallint, 'nombres_calculs',
   'Additionner des nombres entiers.',
   'Automatisme procédural (principal) : savoir additionner sans poser l’opération. Automatisme déclaratif (secondaire) : connaissance des tables d’addition.',
   '',
   'L’élève doit calculer la somme de 168 et 18. Pour cela il peut utiliser plusieurs procédures : ajouter 10 puis 2 puis 6 ; ajouter 20 puis soustraire 2 ; etc.',
   '186',
   array['188 → 168 + 20 L’élève fait une erreur de calcul ou a une méconnaissance des tables d’addition. Il peut aussi débuter la procédure « Ajouter 20 puis soustraire 2 » et oublier la seconde étape.', '190 → 168 + 22 L’élève fait une erreur de calcul ou a une méconnaissance des tables d’addition. Il fait aussi faire une erreur dans la procédure « Ajouter 20 et soustraire 2 » en additionnant 2 au lieu de le soustraire.', '176 → 168 + 8 L’élève fait une erreur de retenue ou oublie d‘ajouter 10 dans la procédure « Ajouter 10 puis 2 puis 6 ».']::text[], false),
  ('automatismes', 5::smallint, 'nombres_calculs',
   'Additionner des nombres entiers relatifs.',
   'Automatisme procédural (principal) : savoir additionner des nombres relatifs ou des sommes algébriques. Automatisme déclaratif (secondaire) : connaissance des tables d’addition.',
   '',
   'L’élève doit calculer la somme de –5 et 7 Pour cela il peut utiliser plusieurs procédures : utilisation d’une règle pour additionner deux nombres relatifs : –5 + 7 = +(7 – 5) = +2 = 2 ; commutation des termes : –5 + 7 = 7 + (– 5) = 7 – 5 = 2 ; décomposition de 7 en 5 + 2 : –5 + 7 = –5 + 5 + 2 = 0 + 2 = 2 ; etc.',
   '2',
   array['Les trois distracteurs relèvent d’une méconnaissance des règles de calcul de la somme de deux nombres relatifs – en particulier de la gestion du signe.', '–12 → – (5 + 7)', '12 → 5 + 7', '–2 → – (7 – 5)']::text[], false),
  ('automatismes', 6::smallint, 'nombres_calculs',
   'Réduire une expression littérale.',
   'Automatisme procédural (principal) : réduire une expression littérale. Automatisme déclaratif (secondaire) : connaissance des tables d’addition.',
   '',
   'L’élève doit réduire l’expression 2n + 3n. Pour cela il peut repérer le facteur commun n, le mettre en facteur et additionner 2 et 3.',
   '5n',
   array['5n2 → (2 + 3)n × n L’élève repère le facteur commun et additionne correctement 2 et 3 mais met n2 en facteur et non n .', '6n2 → 2n × 6n L’élève confond somme et produit.', '6n → (2 × 3)n L’élève met bien n en facteur mais multiplie les termes 2 et 3 au lieu de les additionner.']::text[], false),
  ('automatismes', 7::smallint, 'grandeurs_mesures',
   'Convertir des durées en heures et minutes.',
   'Automatisme procédural (principal) : savoir trouver le quotient et le reste de la division euclidienne d’un nombre entier par 60, pour effectuer la conversion d’une durée en minutes, en heures et minutes. Automatisme déclaratif (secondaire) : connaissance de l’égalité 60 min = 1 h.',
   '',
   'L’élève doit convertir 135 min en 2 h 15 min. Pour cela il peut décomposer 135 min en 120 min + 15 min ou en 60 min + 60 min + 15 min ; puis convertir 120 min en 2 h ; et enfin aboutir à 2 h 15 min.',
   '2 h 15 min',
   array['1 h 35 min → L’élève convertit 1h en 100 min. Il confond avec le système décimal.', '1 h 15 min → L’élève décompose 135 min en 120 min + 15 min, mais il oublie de convertir 120 min en 2h.', '2 h 35 min → L’élève repère bien que 135 min est supérieur à 120 min, donc à 2h, mais reprend les 35 minutes dans le résultat.']::text[], false),
  ('automatismes', 8::smallint, 'nombres_calculs',
   'Factoriser une expression numérique pour la calculer mentalement',
   'Automatismes procéduraux (principaux) : repérer un facteur commun dans une expression et le mettre en facteur ; savoir multiplier un nombre entier par 10. déclaratif (secondaire) : connaissance des compléments à 10.',
   '',
   'L’élève doit calculer 12 × 7 + 12 × 3. Pour cela il peut repérer le facteur commun 12 et le mettre en facteur, mais aussi les nombres 7 et 3 qui donneront 10 une fois additionnés. Il devra ensuite calculer 12 × 10.',
   '120',
   array['240 → (12 + 12) × (7 + 3) L’élève a une connaissance partielle de la factorisation. Il met autant de fois 12 en facteur qu’il apparait dans l’expression de départ.', '84 → 12 × 7 L’élève ne factorise pas. Les priorités de calcul sont respectées mais seul le premier calcul a été effectué. L’élève ne calcule que le premier terme de l’expression.', '36 → 12 × 3 L’élève ne factorise pas. Les priorités de calcul sont respectées mais seul le second calcul a été effectué. L’élève ne calcule que le second terme de l’expression.']::text[], false),
  ('automatismes', 9::smallint, 'espace_geometrie',
   'Calculer un angle dans un triangle connaissant les deux autres.',
   'Automatismes procéduraux (principaux) : savoir utiliser la règle ci-dessus ; savoir additionner et soustraire des nombres entiers en s’appuyant sur la numération décimale – dizaines entières. déclaratif (secondaire) : savoir que la somme des mesures des angles d’un triangle est égale à 180°.',
   '',
   'L’élève doit déterminer la mesure de l’angle IJK. Pour cela il peut additionner 50° et 20°, puis soustraire le résultat à 180°.',
   '110°',
   array['20° → L’élève associe la notation IJK à l’angle de sommet K et non celui de sommet J.', '50° → L’élève associe la notation IJK à l’angle de sommet I et non celui de sommet J.', '70° → L’élève effectue le calcul intermédiaire 20° + 50° mais oublie de soustraire le résultat à 180°.']::text[], false),
  ('automatismes', 10::smallint, 'nombres_calculs',
   'Associer différentes écriture d’un nombre décimal.',
   'Automatismes procéduraux : savoir recomposer un nombre en écriture décimale à partir de sa décomposition additive en fractions décimales ; associer le dénominateur d’une fraction décimale au rang d’un chiffre dans l’écriture décimale correspondante (aspect positionnel).',
   '',
   'L’élève doit déterminer le nombre décimal à associer à la décomposition additive 14 + 6 10 + 2 1000 Pour cela, il peut positionner la partie entière 14, ; puis associer chaque dénominateur des fractions décimales au rang du chiffre correspondant dans l’écriture décimale ; puis placer chaque numérateur à cette position : 6 pour le chiffre des dixièmes et 2 pour celui des millièmes ; et enfin compléter en plaçant 0 pour les centièmes.',
   '14,602',
   array['14,62 → L’élève ne tient pas compte du dénominateur de 2 1000. Il place 2 à la suite de 6.', '140,62 → 14 × 10 + 6 10 + 2 100. L’élève ne tient pas compte du dénominateur de 2 1000. Il place 2 à la suite de 6. De plus il voit 14 comme 14 dizaines et non 14 unités.', '1462 → L’élève écrit simplement 14 suivi des numérateurs 6 et 2 dans l’ordre et sans tenir compte des dénominateurs des fractions. Il ne place pas de virgule.']::text[], false),
  ('automatismes', 11::smallint, 'donnees_fonctions',
   'Calculer une distance à partir d’une vitesse et d’un temps.',
   'Automatisme procédural (principal) : savoir calculer une distance à partir d’une vitesse et d’un temps en utilisant la proportionnalité simple. Automatisme déclaratif (secondaire) : savoir que 30 minutes correspondent à une demi-heure ou la moitié d’une heure.',
   '',
   'L’élève doit déterminer la distance parcourue en 30 minutes en roulant à 18 km/h. Pour cela il peut considérer que 30 minutes sont égales à la moitié d’une heure ; puis diviser 18 km par 2 en utilisant la linéarité multiplicative.',
   '9 km',
   array['5,4 km → L’élève calcule 18 km × 0,3 en considérant que 30 min = 0,3 h. Il confond avec le système décimal.', '18 km → L’élève reprend simplement 18 km dans 18 km/h.', '36 km → L’élève sait que 30 minutes sont égales à la moitié de 1 heure, mais multiplie 18 km par 2 au lieu de diviser.']::text[], false),
  ('automatismes', 12::smallint, 'nombres_calculs',
   'Unités de numération décimale.',
   'Automatismes procéduraux (principaux) : savoir multiplier un nombre décimal par 100 ou placer correctement un nombre dans un tableau de conversion et le convertir dans une autre unité de numération. Automatismes déclaratifs (secondaires) : savoir que deux unités de numération décimale successives sont dans un rapport 10 ; connaitre l’ordre des unités de numération décimale.',
   '',
   'L’élève doit compléter l’égalité 43 milliers = … dizaines. Pour cela il peut repérer que les milliers sont séparés de deux rangs des dizaines ; puis multiplier 43 par 10 × 10 = 100 ou par 10 et puis encore par 10. Il peut aussi mentaliser un tableau de conversion ; puis y placer 43 milliers ; et enfin les convertir en dizaines.',
   '4300',
   array['4,3 → L’élève considère 43 unités. Il divise 43 par 10.', '43 → L’élève reprend simplement le nombre 43 de l’énoncé.', '430 → L’élève place le chiffre 4 dans la colonne des unités de mille. Il multiplie 43 par 10.']::text[], false),
  ('automatismes', 13::smallint, 'grandeurs_mesures',
   'Utiliser des fractions pour partager ou mesurer des grandeurs. Fractionner une aire.',
   'Automatismes procéduraux : associer un partage d’aire à une fraction ; savoir reconnaitre deux fractions égales.',
   '',
   'L’élève doit déterminer le partage d’une aire correspondant à la fraction 3/4. Pour cela il doit repérer que seule la deuxième figure comporte un fractionnement pour lequel toutes les parts sont de même taille ; puis repérer ce fractionnement – dénominateur 8 – et le nombre de parts coloriées – numérateur 6 – ; il doit enfin vérifier que la fraction 6/8 est bien égale à 3/4.',
   '(figure : le partage correspondant à 3/4 — la deuxième figure)',
   array['Pour les trois distracteurs, l’élève compare le nombre de parts bleues au nombre total de parts sans tenir compte de la taille des parts.']::text[], false),
  ('automatismes', 14::smallint, 'nombres_calculs',
   'Soustraire deux nombres relatifs.',
   'Automatisme procédural (principal) : savoir soustraire deux nombres relatifs. Automatisme déclaratif (secondaire) : connaissance des tables d’addition.',
   '',
   'L’élève doit compléter l’égalité 7 − (−5) = ⋯ Pour cela il peut commencer par transformer 7 − (−5) en 7 + (+5) = 7 + 5 ; puis calculer cette addition.',
   '12',
   array['Les trois distracteurs relèvent d’une méconnaissance des règles de calcul de la différence de deux nombres relatifs.', '– 12 → – (7 + 5)', '2 → 7 – 5', '– 2 → – (7 – 5)']::text[], false),
  ('automatismes', 15::smallint, 'nombres_calculs',
   'Placer et repérer une fraction sur droite graduée.',
   'Automatisme Automatisme procédural : repérer l’abscisse d’un point sur un droite graduée.',
   '',
   'L’élève doit déterminer quel nombre est l’abscisse du point A sur une droite graduée. Pour cela il doit repérer la position de l’unité et en combien de parts égales on l’a fractionnée – dénominateur 4 ; puis compter le nombre de parts séparant l’origine du point A – numérateur 3 ; il doit alors rechercher la fraction sous la forme « numérateur/dénominateur ».',
   '3/4',
   array['0,3 → L’élève ne compte que le nombre de parts séparant l’origine du point A et répond en base 10 sans tenir compte du fractionnement de l’unité.', '4 3 → La procédure de détermination du numérateur et du dénominateur est certainement correcte, mais l’élève inverse l’écriture de la fraction.', '3 → L’élève ne compte que le nombre de parts séparant l’origine du point A et répond comme si la droite était graduée de 1 en 1.']::text[], null),
  ('automatismes', 16::smallint, 'nombres_calculs',
   'Passer de l''écriture (représentation) d''un nombre décimal à une autre.',
   'Automatisme Automatisme procédural : savoir faire le lien entre l’écriture chiffrée d’un nombre décimal et la fraction décimale correspondante.',
   '',
   'L’élève doit déterminer une fraction décimale égale à l’écriture chiffrée d’un nombre décimal. Pour cela, il doit repérer le rang du chiffre 3 – dixième – ; puis associer ce chiffre au numérateur et dixième au dénominateur 10.',
   '3/10',
   array['1 3 → L’élève associe 0,3 à « tiers » ou une valeur approchée. Il peut aussi penser que le 3 est le dénominateur et que le 1 indique qu’il est en première position après la virgule.', '3 100 → La procédure de l’élève est peut-être correcte mais il fait une erreur de rang du chiffre 3 dans 0,3 : « centième » à la place de « dixième ».', '0 3 → L’élève remplace la virgule par la barre de fraction.']::text[], false),
  ('automatismes', 17::smallint, 'nombres_calculs',
   'Calcul littéral : substituer dans une expression littérale.',
   'Automatisme procédural (principal) : savoir substituer une lettre par un nombre dans une expression littérale afin d’effectuer un calcul ; savoir effectuer un calcul simple en respectant les priorités de calcul. Automatismes déclaratifs (secondaires) : connaissance des notations en calcul littéral ; connaissance des tables d’addition et de multiplication.',
   '',
   'L’élève doit déterminer la valeur de l’expression littérale 1 + 3x en remplaçant x par le nombre 8. Pour cela il doit interpréter 3x comme le produit de 3 par x ; puis remplacer x par le nombre 8 ; et enfin effectuer le calcul 1 + 3 × 8 en respectant les priorités de calcul.',
   '25',
   array['32 → L’élève substitue correctement mais ne respecte pas les priorités de calcul. Il calcule de gauche à droite. 1 + 3 × 8 = 4 × 8 = 32 39 → L’élève voit 3x est comme le nombre composé des chiffres 3 et x et non comme le produit de 3 par x. 1 + 38 = 39 48 → L’élève ne respecte pas les priorités de calcul et voit 4x comme le nombre composé des chiffres 4 et x. 1 + 3 x = 4 x = 48']::text[], false),
  ('automatismes', 18::smallint, 'grandeurs_mesures',
   'Conversion d’une capacité d’une unité dans une autre.',
   'Automatismes procéduraux (principaux) : savoir multiplier un nombre décimal par 100 ou savoir placer correctement un nombre dans un tableau de conversion et le convertir dans une autre unité de capacité. Automatismes déclaratifs (secondaires) : savoir que deux unités de capacité successives sont dans un rapport 10 ; connaitre l’ordre des unités de capacité ; connaitre les préfixes permettant d’identifier le rang des unités.',
   '',
   'L’élève doit convertir 75 L en cL. Pour cela il peut repérer que les litres sont séparés de deux rangs des centilitres et qu’il faudra donc multiplier 75 par 10 × 10 = 100 ; puis multiplier effectivement 75 par 100 ou par 10 puis encore par 10. Il peut aussi mentaliser un tableau de conversion ; y placer 75 L ; puis les convertir en centilitre.',
   '7 500 cL',
   array['750 → conversion en dL (× 10)', '7,5 → conversion en daL ( : 10)', '0,75 → conversion en hL ( : 100)']::text[], false),
  ('automatismes', 19::smallint, 'donnees_fonctions',
   'Compléter un tableau de proportionnalité.',
   'Automatisme procédural (principal) : savoir calculer une quatrième proportionnelle en utilisant la proportionnalité simple – linéarité multiplicative. Automatisme déclaratif (secondaire) : connaissance des tables de multiplication.',
   '',
   'L’élève doit compléter un tableau de proportionnalité. Pour cela il peut repérer que l’on peut passer de la 2e à la 1re cellule de la première ligne en multipliant 4 par 3 ; Puis, en utilisant la propriété d’homogénéité, multiplier 9 par 3 dans la deuxième ligne pour trouver la valeur de la 1re cellule de cette même ligne.',
   '27',
   array['3 → L’élève n’ordonne pas correctement ses calculs. 9 × 4 : 12 = 3 ou 12 : 3 = 4 donc 9 : 3 = 3.', '17 → Au lieu de chercher un coefficient multiplicateur, l’élève cherche à passer d’une cellule à une autre en ajoutant un nombre constant. 4 + 5 = 9 donc 12 + 5 = 17 ou 4 + 8 = 12 donc 9 + 8 = 17.', '30 → L’élève raisonne par arrondi mais les propriétés utilisées ne sont pas incorrectes. Dans la 2e colonne, 9 est proche de « 4×2 plus la moitié de 4 », donc l’élève calcule dans la 1re colonne « 12×2 plus la moitié de 12 ».']::text[], false),
  ('automatismes', 20::smallint, 'espace_geometrie',
   'Repérer un point dans un repère orthonormé.',
   'Automatisme Automatisme procédural : repérer un point dans un repère orthonormé.',
   '',
   'L’élève doit trouver quel point a pour coordonnées (3 ; 5) dans un repère orthonormé. Pour cela il doit comprendre le sens de (3 ; 5) : que 3 représente l’abscisse du point et 5 son ordonnée. Il doit ensuite repérer le point correspondant à ces deux nombres dans le repère.',
   'Le point D.',
   array['le point A → L’élève inverse l’abscisse et l’ordonnée.', 'le point B → l’élève confond 3 ; 5 et le nombre 3,5 et positionne ce nombre sur l’axe des abscisses.', 'le point C → l’élève confond 3 ; 5 et le nombre 3,5 et positionne ce nombre sur l’axe des ordonnées.']::text[], false),
  ('automatismes', 21::smallint, 'grandeurs_mesures',
   'Calculer l’aire d’un triangle.',
   'Automatisme Automatisme procédural : savoir appliquer la formule de l’aire d’un triangle dans une situation donnée.',
   '',
   'L’élève doit trouver le calcul donnant la mesure de l’aire d’un triangle. Pour cela il peut commencer par rechercher les formules comportant une division par 2 ; puis identifier quel couple de valeurs au numérateur correspond à un côté et à la hauteur associée à ce côté. Le cheminement inverse est aussi possible.',
   '(14 × 12) / 2',
   array['14 × 12 → L’élève repère bien le côté et la hauteur qui lui est associée, mais oublie de la division par 2.', '15×12 2 → L’élève recherche bien la division par 2 mais ne repère pas correctement le côté et la hauteur qui lui sont associés.', '13 × 14 × 15 → L’élève confond avec le périmètre, mais peut-être aussi recherche-t-il simplement un produit comme pour calculer le volume d’une pavé à partir de la mesure de ses trois côtés.']::text[], false),
  ('automatismes', 22::smallint, 'nombres_calculs',
   'Encadrer un nombre décimal entre deux nombres entiers consécutifs.',
   'Automatismes procéduraux : savoir recomposer un nombre en écriture décimale à partir de son écriture en fraction décimale ; comprendre et utiliser l’aspect positionnel de l’écriture décimale ou fractionnaire d’un nombre décimal.',
   '',
   'L’élève doit déterminer un encadrement correct du nombre 56 10. Pour cela il peut repérer que 6 est le chiffre des dixièmes dans l’écriture fractionnaire 56 10 et donc que 5 est celui des unités ; Ainsi ce nombre est supérieur à 5 et inférieur à 6. Certains élèves passeront par l’écriture 5,6 mais cela n’est pas obligatoire.',
   '5 < 56/10 < 6',
   array['55 < 56 10 < 57 → L’élève ne raisonne qu’à partir du numérateur 56 sans tenir compte du dénominateur 10.', '0 < 56 10 < 1 → L’élève considère le nombre 56 10 comme étant égal à 0,56. Dès lors il l’encadre entre 0 et 1.', '4 < 56 10 < 5 → L’élève considère 5 comme une borne supérieure et non inférieure. Dès lors il encadre 56 10 entre 4 et 5 et non entre 5 et 6. 12. Résolution de problèmes (test spécifique)']::text[], false),
  ('resolution_problemes', 1::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à une étape. Problème multiplicatif – proportionnalité simple avec référence à l’unité. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. | Nombres : Les nombres en jeu sont entiers.',
   'L’élève doit déterminer un prix en euros. Pour cela il doit multiplier le prix à l’unité par la masse. Sont donnés le prix à l’unité et la masse achetée dans l’unité correspondant à ce prix.',
   '10 €',
   array['5 € → L’élève reprend uniquement le 5 de 5 kg sans calculer.', '6 € → L’élève considère que la masse augmentant de 4, le prix augmente aussi de 4. 1 kg + 4 kg = 5 kg donc 2 € + 4 € = 6 €.', '7 € → L’élève reprend des nombres de l’énoncé et les additionne. 2 + 5 = 7.']::text[], true),
  ('resolution_problemes', 2::smallint, 'grandeurs_mesures',
   '',
   '',
   'Structure : Problème à une ou deux étapes. Problème additif – recherche d’une partie d’un tout. | Énoncé : Le contexte est familier. L’énoncé nécessite la mise en relation d’un texte et d’une figure. Le scénario facilite la perception des relations mathématiques en jeu. | Grandeurs mesures : Les mesures en jeu sont entières. Aucune conversion n’est nécessaire. Il faut connaitre la notion de périmètre d’un polygone comme somme des longueurs des côtés.',
   'L’élève doit déterminer une longueur en mètre. Pour cela il peut calculer la somme des longueurs connues ; puis la soustraire au périmètre. Il peut aussi soustraire les côtés connus un à un au périmètre. Sont donnés le périmètre d’un polygone et les longueurs de ses côtés à l’exception d’un.',
   '40 m',
   array['30 m → Les trois premiers côtés étant égaux à 50 m, l’élève pense que la somme des deux derniers doit aussi être égale à 50 m. Il soustrait donc 20 m à 50 m.', '170 m → L’élève calcule la somme des longueurs des côtés indiqués. Il oublie de soustraire ce résultat au périmètre. 50 m + 50 m + 50 m + 20 m.', '210 m → L’élève reprend uniquement le périmètre du terrain.']::text[], true),
  ('resolution_problemes', 3::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à une étape. Problème multiplicatif – comparaison multiplicative de grandeurs « fois plus » avec recherche du résultat. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. | Nombres : Les nombres en jeu sont des entiers.',
   'L’élève doit déterminer la durée d’un trajet. Pour cela il peut diviser par 3 la durée du trajet effectué le plus lentement pour trouver celui parcouru le plus rapidement. Sont donnés la durée du trajet effectué le plus lentement, combien de fois roule plus rapidement le plus rapide et la vitesse du plus lent – donnée inutile.',
   '4 minutes.',
   array['3 minutes → L’élève déduit de manière incorrectement une durée de 3 minutes de l’information « trois fois plus rapide ».', '15 minutes → L’élève additionne les données 12 min et le 3 de l’information « trois fois plus rapide ». Il traduit « trois fois plus » comme étant « trois de plus » et effectue une addition.', '36 minutes → L’élève comprend bien que 3 est un coefficient mais l’utilise en multipliant au lieu de diviser. 12 min × 3.']::text[], true),
  ('resolution_problemes', 4::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à deux étapes. Problème multiplicatif – proportionnalité simple sans référence à l’unité. | Énoncé : Le contexte est familier. Le scénario ne facilite pas la perception des relations mathématiques en jeu. | Nombres : Les nombres en jeu sont des décimaux.',
   'L’élève doit déterminer le prix de 8 pains au chocolat. Pour cela il peut calculer le prix d’un pain ; puis en déduire celui de 8 en multipliant par 8. Sont donnés les prix de 7 et de 9 pains au chocolat.',
   '7,20 €',
   array['0,90 € → L’élève calcule correctement le prix d’un pain au chocolat et s’arrête à cette première étape.', '7,10 € → L’élève remarque qu’on demande le prix de 9 – 1 = 8 pains et en déduit que ce prix est 8,10 € – 1 € = 7,10 €', '7,30 € → L’élève remarque qu’on demande le prix de 7 + 1 = 8 pains et en déduit que le prix est 6,30 € + 1 € = 7,30 €']::text[], true),
  ('resolution_problemes', 5::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à une ou deux étapes. Problème multiplicatif – proportionnalité simple sans référence à l’unité. | Énoncé : Le contexte est familier. Le scénario ne facilite pas la perception des relations mathématiques en jeu. | Nombres : Les nombres en jeu sont des décimaux.',
   'L’élève doit déterminer le prix de 15 objets connaissant celui de 10. Pour cela il peut déterminer le prix de 5 objets – ou de 1 – ; puis en déduire celui de 15 objets en multipliant par 3 – ou par 15. Il peut aussi multiplier directement le prix de 10 objets par 1,5 – ou ajouter la moitié du prix de 10 objets. Est donné le prix de 10 objets.',
   '33',
   array['27 € → L’élève remarque qu’on demande le prix pour 5 objets supplémentaires et ajoute donc 5 € au prix initial 22 € + 5 €', '15 € → L’élève reprend le nombre d’objets pour lequel il faut calculer le prix et en déduit que ce prix est de 15 €. Il n’utilise pas le prix de 10 objets.', '47 € → L’élève additionne simplement les trois nombres de l’énoncé : 10 + 22 + 15']::text[], true),
  ('resolution_problemes', 6::smallint, 'nombres_calculs',
   '',
   '',
   'Structure : Problème à une étape. Problème multiplicatif – fraction d’une grandeur. | Énoncé : Le contexte est familier. Le scénario facilite la perception de l’opération en jeu. | Nombres : Les nombres en jeu sont une fraction et un entier.',
   'L’élève doit calculer le tiers d’une distance. Pour cela il doit traduire « tiers de ce parcours » par « diviser par 3 » ou par « multiplier par 1 3 » ; puis effectuer l’opération correspondante. Sont donnés le nombre total de kilomètres parcourus et la fraction de la distance à calculer.',
   '20 km',
   array['10 km → L’élève divise par 6 et non par 3. Il calcule le sixième.', '12 km → L’élève divise par 5 et non par 3. Il calcule le cinquième.', '15 km → L’élève divise par 4 et non par 3. Il calcule le quart.']::text[], true),
  ('resolution_problemes', 7::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à deux étapes. Problème mixte : additif – recherche d’une partie – et multiplicatif – proportionnalité simple : déterminer un pourcentage. | Énoncé : Le contexte est familier. Le scénario ne facilite pas la perception de l’opération en jeu. | Nombres : Les nombres en jeu sont des entiers ou des fractions.',
   'L’élève doit trouver le pourcentage d’enfants droitiers connaissant le nombre total d’enfants et le nombre de gauchers. Pour cela, il peut déterminer le nombre d’enfants droitiers – 4 – qu’il doit rapporter aux nombre total d’enfants – 5 – ; il peut ensuite ramener ce rapport 4 5 à 80 100 c’est-à-dire 80 %. Il peut aussi calculer le pourcentage d’enfants gauchers – 20 % – ; Puis déterminer le complémentaire à 100 %, soit 80 %. Sont donnés dans l’énoncé le nombre total d’enfants et le nombre de gauchers.',
   '80 %',
   array['4 % → L’élève confond le nombre d’enfants droitiers et le pourcentage.', '20 % → L’élève calcule correctement le pourcentage d’élèves gauchers. En ce sens il fait une erreur de lecture d’énoncé, mais montre une bonne maitrise des pourcentages.', '75 % → L’élève compare le nombre de gauchers par rapport au nombre de droitiers et aboutit à un quart, soit 25%. Il en déduit que le pourcentage de droitiers est de 75% en calculant le complémentaire à 100 %.']::text[], true),
  ('resolution_problemes', 8::smallint, 'grandeurs_mesures',
   '',
   '',
   'Structure : Problème à plusieurs étapes. Problème mixte : additif – recherche d’une partie – et multiplicatif – comparaison multiplicative de grandeurs. | Énoncé : Le contexte est familier L’énoncé nécessite la mise en relation d’un texte et d’une figure. Le scénario facilite la perception de l’opération en jeu. Grandeurs Mesures Les mesures font intervenir des entiers. Aucune connaissance sur la grandeur n’est nécessaire.',
   'L’élève doit trouver une superficie à partir d’un plan et d’une légende. Pour cela il peut compter le nombre de carreaux correspondant à la zone boisée ; il doit ensuite utiliser la légende lui indiquant que 1 m2 correspond non pas à 1 mais à 4 carreaux ; puis diviser le nombre de carreaux trouvé à la première étape par 4.',
   '9 km²',
   array['36 → L’élève compte correctement les 36 carreaux de la zone boisée mais ne prend pas en compte la légende.', '60 → L’élève ne prend en compte aucun élément de la légende et compte tous les carreaux dans le rectangle de la figure.', '4 → L’élève indique l’unité dans la légende.']::text[], true),
  ('resolution_problemes', 9::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à deux étapes. Champ multiplicatif – proportionnalité simple : déterminer un pourcentage. | Énoncé : Le contexte est familier. Le scénario ne facilite pas la perception de l’opération en jeu. | Nombres : Les nombres en jeu sont des entiers ou des fractions.',
   'L’élève doit déterminer quel parfum a une probabilité de 25 % d’être choisi. Pour cela il doit commencer par déterminer le nombre total de macarons ; il peut ensuite déterminer la quantité correspondant à 25 % de ce nombre ; et enfin trouver le parfum correspondant à cette quantité. Est donné le nombre de macarons pour chacun des parfums.',
   'à la pomme.',
   array['au chocolat → L’élève indique le parfum le plus représenté. Il peut aussi associer 25 % à une chance sur 4, confondre modalité et fréquence, puis choisir ce parfum.', 'à la fraise → L’élève associe 25 % à une chance sur 4. Il confond modalité et fréquence, puis choisit ce parfum.', 'au café → L’élève associe 25 % à une chance sur 4. Il confond modalité et fréquence, puis choisit ce parfum.']::text[], true),
  ('resolution_problemes', 10::smallint, 'grandeurs_mesures',
   '',
   '',
   'Structure : Problème à une étape. Problème additif et multiplicatif | Énoncé : Le contexte est familier. Le scénario ne facilite pas la perception de l’opération en jeu. Grandeurs Mesures Les nombres sont des entiers.',
   'L’élève doit déterminer la largeur d’un jardin rectangulaire connaissant son périmètre et sa longueur. Pour cela il doit soustraire deux fois la longueur au périmètre ; puis diviser le résultat trouvé par 2. Sont donnés le périmètre et la longueur du jardin rectangulaire.',
   '20 m',
   array['25 m → L’élève raisonne comme si la figure était un carré de périmètre 100 m et calcule 100 m : 4.', '35 m → L’élève oublie qu’il y a deux côtés de longueur 30 m et calcule 100 m – 30 m. Le reste du calcul est correct (100 m – 70 m) : 2', '40 m → L’élève oublie qu’il y a deux largeurs dans un rectangle. Il manque donc une division par 2 dans son calcul 100 m – 2 × 30 m.']::text[], true),
  ('resolution_problemes', 11::smallint, 'nombres_calculs',
   '',
   '',
   'Structure : Problème à une étape. Problème additif – recherche d’un tout. | Énoncé : Le contexte n’est pas intra-mathématique et peut être familier à certains élèves. Le scénario facilite la perception des relations mathématiques en jeu. | Nombres : Les nombres sont des fractions.',
   'L’élève doit déterminer le fractionnement correspondant à la somme de deux autres. Pour cela il doit additionner les fractions 1 2 et 1 4. Il peut aussi visualiser les parts et trouver mentalement la fraction correspondant au tout en transformant 1 2 en 2 4 ; puis en ajoutant 2 4 et 1 4 La calculatrice n’est pas intégrée à la question.',
   '3/4',
   array['Tous les distracteurs correspondent à des erreurs dans la technique de calcul de la somme de deux fractions. • 2 6 = 1 + 1 2 + 4 • 2 4 = 1 + 1 4 • 1 6 = 1 2 + 4']::text[], null),
  ('resolution_problemes', 12::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à une étape. Problème multiplicatif – proportionnalité simple nécessitant une conversion. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. Une difficulté réside dans le changement d’ordre d’apparition du volume de lait et de la masse de beurre entre la première phrase et la seconde. Grandeurs Mesures Les mesures de longueur en jeu sont des entiers. Une conversion est nécessaire.',
   'L’élève doit déterminer une quantité de lait. Pour cela il doit comparer la masse de départ de beurre 1 kg et celle d’arrivée 100 g et établir qu’il faut diviser 1 kg = 1 000 g par 10 pour obtenir 100 g ; Il doit ensuite diviser 20 L par 10 pour trouver 2 L. Sont donnés le nombre de litres de lait qu’il faut pour obtenir 1 kg de beurre et la quantité de beurre que l’on veut obtenir.',
   '2 L',
   array['200 L → L’élève multiplie 20 L par 10 au lieu de diviser.', '20 cL → L’élève divise 20 L par 100 puis convertit en cL.', '2000 L → L’élève multiplie 20 L par 100.']::text[], true),
  ('resolution_problemes', 13::smallint, 'nombres_calculs',
   '',
   '',
   'Structure : Problème à deux étapes. Il s’agit plus d’une première étape utile à la résolution d’un problème qu’un problème à part entière. Problème mixte : additif et multiplicatif. | Énoncé : Le contexte est intra-mathématique. L’énoncé nécessite la mise en relation d’un texte et d’une figure. | Nombres : Le nombre en écriture chiffrée est entier, les autres sont représentés par des lettres.',
   'L’élève doit exprimer l’aire d’une surface en fonction des lettres a et b. Pour cela, il peut exprimer la largeur du rectangle hachuré en fonction de a et b ; puis multiplier cette longueur par la largeur 3 afin de trouver l’expression de l’aire du rectangle. Est donnée une figure avec des éléments de codage représentant la situation et indiquant quelle est l’aire considérée. mais elle est inutile.',
   '3(b − a)',
   array['3(b + a) → L’élève n’exprime pas correctement la longueur du rectangle mais calcule correctement l’aire en la multipliant par la largeur 3.', '3a → L’élève n’exprime pas correctement la longueur du rectangle mais calcule correctement l’aire en la multipliant par la largeur 3.', '3b → L’élève n’exprime pas correctement la longueur du rectangle mais calcule correctement l’aire en la multipliant par la largeur 3.']::text[], true),
  ('resolution_problemes', 14::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à deux étapes. Problème mixte : additif – comparaison d’états (recherche de la comparaison) – et multiplicatif – proportionnalité simple sans référence à l’unité. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. Grandeurs Mesures Les mesures en jeu sont des nombres entiers.',
   'L’élève doit déterminer une quantité d’eau économisée. Pour cela il peut calculer la quantité d’eau pour prendre un bain en utilisant la proportionnalité ; puis calculer la différence entre la quantité d’eau utilisée pour un bain et celle pour une douche. Il peut aussi commencer par calculer l’écart de durée entre un bain et une douche ; puis calculer la quantité d’eau écoulée lors de cette durée en utilisant la proportionnalité. Sont données la durée et la quantité d’eau utilisée pour prendre une douche et la durée d’écoulement d’eau pour un bain.',
   '40 L',
   array['160 L → 80 L × 2', '120 L → L’élève calcule la quantité d’eau utilisée pour un bain.', '10 L → L’élève calcule le débit du robinet : 10 L/min']::text[], true),
  ('resolution_problemes', 15::smallint, 'grandeurs_mesures',
   '',
   '',
   'Structure : Problème à une étape. Problème multiplicatif – recherche d’un facteur. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. Grandeurs Mesures Les mesures en jeu sont des entiers.',
   'L’élève doit déterminer la largeur d’un salon rectangulaire. Pour cela il doit considérer la formule de l’aire d’un rectangle ; puis diviser l’aire par la longueur. Sont données l’aire et la longueur du rectangle.',
   '7 m',
   array['14 m → L’élève effectue les calculs avec la formule de l’aire d’un triangle et non celle d’un rectangle 56 × 2 : 8', '64 m → 56 + 8 Raisonnement additif (addition).', '48 m → 56 – 8 Raisonnement additif (soustraction).']::text[], true),
  ('resolution_problemes', 16::smallint, 'grandeurs_mesures',
   '',
   '',
   'Structure : Problème à deux étapes. Problème multiplicatif – proportionnalité simple avec référence à l’unité. Comparaison de durée avec conversion. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. Grandeurs Mesures Les mesures en jeu sont des nombres entiers.',
   'L’élève doit déterminer la largeur d’un salon rectangulaire. Pour cela il peut calculer la durée nécessaire pour réaliser 11 figures ; puis comparer ce temps avec 3h qu’il aura converties en 180 minutes. Sont donnés le temps pour réaliser une figure, le nombre de figures à réaliser et le temps maximal pour les réaliser.',
   'NON. Il lui manquera sept minutes.',
   array['OUI. Il lui faudra moins de deux heures. → L’élève calcule une 4e proportionnelle de manière erronée 17 × 11 : 3 ≈ 62. Il en déduit que la seule réponse possible est : « … moins de 2h ».', 'OUI. Il pourra fabriquer douze figurines. → L’élève considère le temps de 17 min pour réaliser une figurine. Il en déduit qu’il peut donc en réaliser environ 4 en 1h et donc 12 figurines en 3h.', 'NON. Il pourra fabriquer seulement neuf figurines. → L’élève considère le temps de 17 min pour réaliser une figurine. Il en déduit qu’il ne peut réaliser que 3 figurines en 1h et donc 9 figurines en 3h.']::text[], true),
  ('resolution_problemes', 17::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à étapes. Problème multiplicatif – proportionnalité simple composée avec recherche de la valeur finale. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. | Nombres : Les nombres en jeu sont des entiers.',
   'L’élève doit déterminer le nombre de pages lues en 7 jours. Pour cela il peut calculer le nombre de pages en un jour – 10% de 110 – ; puis multiplier ce nombre par 7 pour trouver le nombre en 7 jours. Sont donnés le nombre total de pages dans le livre, le pourcentage des pages lues par jour et le nombre de jours de lecture.',
   '77 pages',
   array['10 pages → L’élève confond 10 % et 10 pages et n’indique que le nombre de pages lues en un jour.', '70 pages → L’élève confond 10 % et 10 pages puis calcule le nombre de pages lues en 7 jours de manière correcte.', '11 pages → L’élève ne calcule que le nombre de pages lues en un jour : 10 % de 110 pages.']::text[], true),
  ('resolution_problemes', 18::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à plusieurs étapes. Problème multiplicatif – proportionnalité simple sans référence à l’unité. Mise en relations de plusieurs modes de représentation de données. | Énoncé : Le contexte est familier. Le scénario ne facilite pas la perception des relations mathématiques en jeu. | Nombres : Les nombres en jeu sont des entiers.',
   'L’élève doit déterminer quel tableau correspond à la situation et au diagramme circulaire proposés. Pour cela il doit associer la masse totale de l’œuf à 100 % ; puis par linéarité multiplicative associer chacun des autres pourcentages à la masse adéquate.',
   'Œuf 60 g / 100 % ; coquille 6 g / 10 % ; blanc 36 g / 60 % ; jaune 18 g / 30 %',
   array['Œuf Coquille Blanc Jaune Masse 60 10 36 18 % 100 10 60 10 Erreur pour la masse de la coquille. Œuf Coquille Blanc Jaune Masse 60 6 60 30 % 100 10 60 30 Erreur pour les masses du blanc et du jaune. Œuf Coquille Blanc Jaune Masse 60 10 60 30 % 60 10 60 30 L’élève reprend les valeurs de l’énoncé à l’identique.']::text[], true),
  ('resolution_problemes', 19::smallint, 'donnees_fonctions',
   '',
   '',
   'Structure : Problème à une étape. Problème multiplicatif – proportionnalité simple nécessitant une conversion. | Énoncé : Le contexte est familier. Le scénario facilite la perception des relations mathématiques en jeu. Une difficulté réside dans le changement d’ordre d’apparition de la masse de fleurs de crocus et de safran entre la première phrase et la seconde. Cette difficulté est d‘autant plus grande qu’il s’agit de deux masses – la lecture seule des grandeurs et de leur unité ne permet donc pas de savoir ce à quoi elles correspondent. Grandeurs Mesures Les mesures en jeu sont des entiers.',
   'L’élève doit déterminer une masse de safran. Pour cela il doit comprendre que ce sont des fleurs de crocus que l’on extrait le safran « 80 g de fleurs de crocus pour produire 1 g de safran » ; il doit ensuite analyser la seconde phrase afin de comprendre que l’on a 1 kg de fleurs de crocus – cette masse est donc à mettre en relation avec les 80 g et non avec le 1 g de la première phrase – ; il peut ensuite trouver la ou les multiplications ou divisions à effectuer pour passer de 80 g à 1 kg = 1000 g – par exemple 80 g : 8 × 100 = 1000 g ; enfin, par linéarité multiplicative, il peut déterminer la masse de crocus obtenue 1 g : 8 × 100 = 12,5 g. Sont données la masse de fleurs de crocus permettant d’obtenir 1 g de crocus et la masse réelle de crocus que l’on considère.',
   '12,5 g',
   array['80 kg → L’élève commet une erreur d’analyse de la seconde phrase et associe 1 g avec 1 kg. Il en déduit donc qu’il suffit de transformer les 80 g en 80 kg pour répondre à la question.', '12,5 kg → L’élève a une démarche correcte mais commet une erreur d’unité. Il considère que comme l’unité de masse dans la seconde phrase est le kilogramme, celle de la valeur obtenue doit l’être aussi.', '80 g → L’élève commet une erreur d’analyse de la seconde phrase et associe 1 g avec 1 kg sans tenir compte des unités. Il reprend donc simplement les 80 g disponibles dans l’énoncé.']::text[], true)
  ) as i(test, numero, domaine_code, sous_domaine, automatismes, structure,
         tache, reponse, erreurs, calculatrice)
join domaines_evaluation de
  on de.matiere_code = 'maths' and de.classe = '4e' and de.code = i.domaine_code
where v.source = 'eduscol' and v.edition = 2023
  and v.reference = 'Évaluation nationale de début de 4e — documents à destination des équipes pédagogiques';

-- ------------------------------------------------ français : 4 items libérés
--
-- La fiche éduscol publie quatre items de compréhension de l'écrit, avec leur
-- taux de réussite. Les mathématiques n'en publient aucun : la colonne restera
-- nulle pour elles, et c'est la source qui en décide, pas nous.

insert into items_evaluation_nationale
  (version_id, domaine_evaluation_id, repere_id, test, numero,
   sous_domaine, tache, reponse_attendue, erreurs_observees, taux_reussite_national)
select v.id, de.id, r.id, 'comprehension_ecrit', i.numero,
       'Comprendre le sens global d’un texte', i.tache, i.reponse, i.erreurs, i.taux
from versions_programme v,
  (values
  (1::smallint,
   'L’élève doit choisir, parmi quatre propositions, l’expression qui résume le mieux l’extrait d’un texte narratif. Le paratexte donne l’identité du narrateur.',
   'Entrée en fonction d’un jeune maître d’étude',
   array['« Journée de rentrée au collège de Sarlande » → l’élève choisit une expression contenant une information saillante du texte (première ligne), mais commet un contresens sur le rôle du narrateur, ou utilise le mot « rentrée » de manière approximative.', '« Première nuit dans une petite ville des Cévennes » → l’élève choisit une information saillante mais n’arrive pas à hiérarchiser les informations : il ne corrige pas son hypothèse initiale avec ce qu’il lit ensuite.', '« Arrivée du nouveau principal au collège » → l’élève a potentiellement compris les enjeux de l’extrait, mais se trompe sur l’identité du narrateur, faute d’avoir tenu compte du paratexte.']::text[], 47.12),
  (2::smallint,
   'L’élève doit choisir, parmi quatre adjectifs, celui qui caractérise l’atmosphère du texte narratif.',
   'angoissante',
   array['« fantastique » → l’élève peut ne pas maîtriser le terme, ou associer à tort ce texte à des lectures relevant d’un univers irréel.', '« familière » → l’élève s’est identifié au narrateur et s’est appuyé sur ses représentations personnelles et sa propre familiarité avec un établissement scolaire.', '« accueillante » → choix contradictoire avec le texte : l’élève ne s’est pas appuyé sur l’attitude des personnages et a pu se fonder uniquement sur l’issue heureuse de l’entretien.']::text[], 75.22),
  (3::smallint,
   'À partir d’un groupement de trois textes documentaires, l’élève doit associer chaque document à sa visée, dans un tableau où une seule réponse est possible par ligne et par colonne.',
   'Document 1 → promouvoir la politique générale menée contre le gaspillage alimentaire ; document 2 → illustrer la lutte par une mise en œuvre concrète ; document 3 → faire prendre conscience de l’ampleur des mécanismes du gaspillage.',
   array['L’élève ne distingue pas les visées des différents documents, ou ne perçoit pas la différence entre les visées proposées dans la consigne.', 'L’élève ne détermine pas les informations essentielles de chaque document, ou ne tient pas compte des caractéristiques génériques des documents.', 'Le tableau n’autorisant qu’une réponse par ligne et par colonne, une erreur en entraîne nécessairement une autre : la dernière association peut se faire par élimination.']::text[], 27.35),
  (4::smallint,
   'À partir du groupement de textes documentaires, l’élève doit identifier qui est concerné par le gaspillage alimentaire, en tenant compte de l’ensemble des documents.',
   'vraiment tout le monde',
   array['« d’abord les industriels » → l’élève s’appuie sur un prélèvement d’informations explicites dans un seul document, sans tenir compte de tous, ou tente d’élaborer une chronologie des responsabilités.', '« surtout les agriculteurs » → l’élève s’appuie sur une information explicite d’un seul document et hiérarchise les responsables sans que rien dans les textes ne le fonde.', '« seulement les enfants » → l’élève s’est appuyé sur un seul document, sans tenir compte des autres.']::text[], 85.7)
  ) as i(numero, tache, reponse, erreurs, taux)
join domaines_evaluation de
  on de.matiere_code = 'francais' and de.classe = '4e' and de.code = 'lecture_comprehension'
join reperes_competences r
  on r.matiere_code = 'francais' and r.source = 'eduscol'
 and r.libelle = 'Comprendre le sens global d’un texte'
where v.source = 'eduscol' and v.edition = 2023
  and v.reference = 'Évaluation nationale de début de 4e — documents à destination des équipes pédagogiques';

-- ------------------------------------- rattacher les questions aux attendus
--
-- Seulement quand la correspondance est explicite : le sous-domaine de la
-- question reprend l'attendu, ou en est une reformulation immédiate.
--
-- Le reste est laissé nul **à dessein**. Rattacher « additionner ou soustraire
-- des nombres entiers » à l'attendu « additionner et soustraire des nombres
-- décimaux relatifs » serait faux — et surtout, un rattachement forcé cacherait
-- ce que ce corpus a de plus intéressant : la moitié du test porte en dessous
-- du niveau visé. Un `repere_id` nul dit « question d'échauffement », et c'est
-- utile à la génération.

update items_evaluation_nationale i
set repere_id = r.id
from (values
  ('automatismes', 5::smallint,
   'Additionner et soustraire des nombres décimaux relatifs.'),
  ('automatismes', 6::smallint,
   'Utiliser la distributivité simple pour réduire une expression littérale de la forme ax + bx où a et b sont des nombres décimaux.'),
  ('automatismes', 7::smallint,
   'Effectuer des conversions d’unités de longueurs, d’aires, de volumes et de durées.'),
  ('automatismes', 9::smallint,
   'La somme des angles d’un triangle.'),
  ('automatismes', 10::smallint,
   'Utiliser, dans le cas des nombres décimaux, les écritures décimales et fractionnaires et passer de l’une à l’autre, en particulier dans le cadre de la résolution de problèmes.'),
  ('automatismes', 11::smallint,
   'Résoudre des problèmes de proportionnalité dans diverses situations pouvant faire intervenir des pourcentages ou des échelles, en mettant en œuvre des procédures variées (additivité, homogénéité, passage à l’unité, coefficient de proportionnalité).'),
  ('automatismes', 14::smallint,
   'Additionner et soustraire des nombres décimaux relatifs.'),
  ('automatismes', 16::smallint,
   'Utiliser, dans le cas des nombres décimaux, les écritures décimales et fractionnaires et passer de l’une à l’autre, en particulier dans le cadre de la résolution de problèmes.'),
  ('automatismes', 17::smallint,
   'Substituer une valeur numérique à une lettre pour calculer la valeur d’une expression littérale, tester si une égalité où figurent une ou deux indéterminées est vraie quand on leur attribue des valeurs numériques, et contrôler son résultat.'),
  ('automatismes', 18::smallint,
   'Utiliser la correspondance entre les unités de volume et de contenance (1 L = 1 dm³, 1 000 L = 1 m³) pour effectuer des conversions.'),
  ('automatismes', 19::smallint,
   'Résoudre des problèmes de proportionnalité dans diverses situations pouvant faire intervenir des pourcentages ou des échelles, en mettant en œuvre des procédures variées (additivité, homogénéité, passage à l’unité, coefficient de proportionnalité).'),
  ('automatismes', 20::smallint,
   'Se repérer sur une droite graduée et dans le plan muni d’un repère orthogonal.'),
  ('automatismes', 21::smallint,
   'Calculer le périmètre et l’aire des figures usuelles (rectangle, parallélogramme, triangle, disque).')
) as m(test, numero, libelle)
join reperes_competences r
  on r.matiere_code = 'maths' and r.source = 'eduscol' and r.libelle = m.libelle
where i.test = m.test and i.numero = m.numero;

-- --------------------------------------------- ce qui rend un repère générable
--
-- 0074 posait qu'un repère est générable s'il porte lui-même son critère de
-- réussite. Ce corpus ouvre une seconde voie, et c'est même la plus fréquente :
-- un repère est utilisable dès qu'une question publiée montre ce qu'on demande
-- et quelles erreurs attendre. La vue doit distinguer les deux, sans quoi elle
-- déclarerait ingénérable tout ce que 0076 vient de rendre générable.

create or replace view reperes_generables
with (security_invoker = true) as
  select
    r.id,
    r.matiere_code,
    r.cycle,
    r.domaine,
    r.libelle,
    r.source,
    r.critere_de_reussite <> '' as a_un_critere,
    cardinality(r.erreurs_types) > 0 as a_des_erreurs_types,
    r.domaine_evaluation_id is not null as rattache_a_un_domaine,
    count(i.id) as items_publies,
    -- Générable par l'une ou l'autre voie : son propre critère, ou au moins
    -- une question officielle qui montre comment on le vérifie.
    (r.critere_de_reussite <> '' or count(i.id) > 0) as generable
  from reperes_competences r
  left join items_evaluation_nationale i on i.repere_id = r.id
  where r.actif
  group by r.id;

-- ==================================================== ce qu'il faut savoir
--
-- LES SEUILS OFFICIELS, TOUJOURS PAS REPRIS
--
-- Le document publie les seuils qui rangent un élève en groupe « à besoins »,
-- « fragile » ou « satisfaisant » — par exemple, en Espace et géométrie,
-- 6 réponses correctes ou moins, 7 à 9, 10 ou plus sur 15 questions.
--
-- 0074 avait décidé de ne pas les reprendre, parce qu'ils sont calibrés sur la
-- passation nationale — même consigne, même durée, même format, en classe — et
-- qu'un bilan Xylou change précisément cela. Le document confirme cette
-- lecture : les seuils sont donnés par test complet, pas par question.
--
-- LES LIBELLÉS OFFICIELS DES GROUPES SONT MAINTENANT VÉRIFIÉS
--
-- 0073 numérotait les groupes en expliquant que les libellés officiels
-- n'avaient pas pu être vérifiés, et qu'inventer « fragile » les ferait passer
-- pour officiels. Ils le sont : « à besoins », « fragile », « satisfaisant »,
-- écrits ainsi dans les deux documents.
--
-- 0073 ne change pas pour autant, et pas seulement parce qu'une migration
-- appliquée est figée : sa seconde raison tenait toute seule. Ces libellés sont
-- de registre comparatif, la convention du projet les interdit à l'écran, et
-- c'est cette raison-là qui décide.

-- ---------------------------------------------------------------------------
-- Même garde qu'en 0075, et pour la même raison : ces trois insertions passent
-- par des jointures sur des libellés. Une seule qui ne rapproche rien produit
-- une migration verte et un corpus amputé — ce qui ne se verrait qu'au moment
-- où une génération manquerait de matière.
do $$
declare n_maths int; n_fr int; n_rattaches int;
begin
  select count(*) into n_maths from items_evaluation_nationale
    where test in ('automatismes', 'resolution_problemes');
  select count(*) into n_fr from items_evaluation_nationale
    where test = 'comprehension_ecrit';
  select count(*) into n_rattaches from items_evaluation_nationale where repere_id is not null;
  if n_maths <> 41 or n_fr <> 4 then
    raise exception '0076 : % questions de mathématiques et % de français chargées, 41 et 4 attendues', n_maths, n_fr;
  end if;
  -- 13 rattachements de mathématiques (voir plus haut) et les 4 items de
  -- français, qui portent tous sur la même compétence.
  if n_rattaches <> 17 then
    raise exception '0076 : % questions rattachées à un attendu, 17 attendues', n_rattaches;
  end if;
end $$;
