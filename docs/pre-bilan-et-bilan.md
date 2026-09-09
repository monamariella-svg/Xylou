# Le pré-bilan, puis le bilan

Deux étapes, dans cet ordre, et on ne les confond pas.

## 1. Le pré-bilan

**Qui répond :** la famille et l'équipe. Jamais l'enfant — on ne teste pas un
enfant pour savoir comment le tester.

**Ce qu'il dit :** comment l'enfant fonctionne. Ce qu'il comprend d'une
consigne, comment il peut répondre, ce qui le fatigue, ce qui le met en échec
alors qu'il sait.

**Ce qu'il ne dit pas :** son niveau scolaire. Rien de ce qui est recueilli ici
n'entre jamais dans le résultat du bilan. Si « rédiger est coûteux » se
retrouvait dans une note de français, on aurait enregistré le handicap comme un
résultat scolaire.

72 questions, 11 domaines, une seule échelle — jamais / parfois / souvent /
toujours, et « pas encore observé » partout. Dix domaines viennent du GEVA-Sco
et du PPS ; le onzième, `passation`, est propre à Xylou : le GEVA-Sco décrit un
élève, il ne dit pas comment lui faire passer une évaluation.

Le formulaire vit en base (`questionnaires_capacites`), versionné : une version
publiée ne se modifie jamais, sinon un item reformulé changerait rétroactivement
le sens de ce qu'une famille a répondu il y a six mois. Le contenu relisible est
dans `supabase/formulaires/`.

Une seconde source peut l'alimenter : un diagnostic déposé par la famille. Plus
riche, mais figé à sa date, là où le pré-bilan se refait. Il n'est visible que
des titulaires de l'autorité parentale et du référent — pas de l'équipe, pas de
l'administration.

## 2. Le bilan

**Qui répond :** l'enfant.

**Ce qu'il mesure :** son niveau scolaire, matière par matière, contre les
repères de l'Éducation nationale.

Le pré-bilan ne change pas ce qui est mesuré. Il change **la façon de le
demander** : format des questions, nombre, formulation, longueur des séances,
quand s'arrêter.

Exemple. Le pré-bilan dit « rédiger est coûteux », « une seule question à
l'écran », « mis en difficulté par le chronomètre ». Le bilan de français ne
demandera donc pas d'écrire un paragraphe pour montrer que l'accord du verbe est
acquis : il fera choisir la bonne forme, une question à la fois, sans minuteur.
Le savoir mesuré est le même.

Sans pré-bilan, la génération produirait un bilan standard — et mesurerait la
difficulté à écrire au lieu de la maîtrise de l'accord. C'est le risque nommé au
§3.4 du dossier projet, et il ne se rattrape pas après coup : l'enfant, lui, en
aura conclu qu'il est nul.

## Comment l'IA écrit les questions

Elle s'inspire de la **méthode FALC** — Facile À Lire et à Comprendre. Phrases
courtes, une idée par phrase, mots courants, voix active ; ni figure de style,
ni sous-entendu, ni consigne à deux étages.

**Avec une limite qui n'est pas négociable.** FALC s'applique sans réserve aux
consignes, aux boutons, aux messages. Il ne s'applique au *contenu évalué* que
si la compétence visée n'en dépend pas — simplifier le texte d'un exercice de
compréhension écrite ne rend pas l'exercice accessible, il supprime ce qu'il
mesurait. C'est le pré-bilan qui dit jusqu'où aller pour cet enfant-là.

Et l'on écrit « s'inspire de FALC », jamais « conforme FALC » : la méthode
suppose une validation par des personnes concernées, que nous ne faisons pas.

*Les règles FALC retenues ici sont écrites de mémoire — les sources officielles
n'étaient pas accessibles au moment de la rédaction. À confronter aux
recommandations européennes avant qu'elles pilotent une génération réelle.*

## Contre quoi le bilan situe l'enfant

Deux niveaux, et il ne faut pas les confondre.

**Les domaines évalués** — la structure officielle des évaluations nationales,
classe par classe (migration 0072). « Étude de la langue », « Nombres et
calculs », « Fluence ». Ils sont posés et utilisables.

**Les repères de compétences** — les attendus vérifiables qui se rangent dans
ces domaines : « accorder le verbe avec son sujet ». Ceux en base sont des
formulations de travail (`source = 'amorce'`) et restent à écrire.

Le bilan peut donc déjà se structurer correctement pendant que les attendus se
remplissent.

**Deux fois le même piège, et il vaut d'être retenu :** ni le programme en
vigueur (0071), ni ce qui est évalué (0072) ne changent à l'échelle d'un cycle.
En cycle 4, la 5e a deux domaines de mathématiques, la 4e en a quatre. Tout ce
qui est rangé par cycle sera un jour trop grossier.

**Ce qui n'est pas couvert :** la 3e, la 1re et la terminale n'ont pas
d'évaluation nationale de positionnement — pour elles, il faudra s'appuyer sur
le programme. Le CAP en a une, mais ce niveau n'existe pas dans Xylou.

## Générer un bilan : un geste, jamais un automatisme

**Un bouton « Générer un bilan », à la main du référent, enfant par enfant.**
Rien ne se génère tout seul : une génération coûte de l'argent, et un bilan
produit pour un enfant qui ne le passera pas est une dépense pour rien.

### Ce que le bouton doit vérifier avant de s'activer

Un bilan généré sans ce qu'il faut n'est pas un bilan raté, c'est un bilan
générique — donc exactement ce que tout ce travail cherche à éviter. Le bouton
reste donc inactif, **en disant pourquoi**, tant que :

- aucun **pré-bilan** n'a été rempli — sans lui, la génération produirait un
  bilan standard et mesurerait le handicap de l'enfant plutôt que ses savoirs ;
- les **autorisations** ne sont pas signées, `generation_ia` en particulier.

Et c'est tout. Un bouton grisé sans explication produit un appel au référent :
le message doit dire ce qui manque et mener à l'écran qui le règle.

### La classe n'est pas un bloquant, et ne fixe pas le niveau de départ

Deux usages de la classe se confondent facilement, et le second est nocif :

- **quels domaines explorer.** La 4e évalue « étude de la langue »,
  « compréhension de l'oral »… C'est une carte du territoire, et elle est utile.
- **à quelle difficulté commencer.** Là, partir du niveau de la classe est une
  faute : un enfant inscrit en 4e qui travaille le français au niveau CM1 se
  planterait aux premières questions. C'est le découragement du §3.4, provoqué
  par l'outil censé l'éviter.

La classe donne donc, au plus, une carte par défaut — corrigeable. Elle ne
conditionne pas la génération, et elle ne fixe jamais la difficulté.

**D'où vient alors le niveau de départ ?** Pas du pré-bilan non plus : celui-ci
dit *comment poser les questions*, pas ce que l'enfant sait, et rien de ce qu'il
contient n'entre dans un résultat.

Il vient du bilan lui-même : **on commence délibérément en dessous, et on
monte.** C'est ce que font les tests de positionnement, et la vertu est précise
ici — les premières questions sont des réussites. L'enfant commence par
réussir, puis on monte jusqu'à ce que ça bloque. Là où l'on s'arrête est la
mesure.

Le schéma l'avait anticipé : `bilan_niveaux_matiere.niveau_estime` est distinct
de `classe_reference`, et `0004` le dit déjà — *« Il peut être au-dessus comme
en dessous de sa classe d'inscription, et les deux sont des informations
utiles, pas des jugements. »*

Quand un bilan de l'année précédente existe, il vaut mieux que n'importe quelle
estimation : `annees_enfant.bilan_anterieur_id` (0034) est là pour ça, et
`0034` pose déjà la règle — on ne recommence pas à zéro chaque rentrée.

### Plusieurs enfants à la fois

Un référent prépare une séance pour son groupe, pas pour un enfant. Le besoin
est réel — mais il change la nature du problème.

**Douze générations ne tiennent pas dans une requête.** Chacune prend des
dizaines de secondes ; une boucle synchrone dépasserait la limite d'exécution
d'une fonction serverless, et le référent verrait une page d'erreur au milieu,
sans savoir lesquels sont partis.

C'est exactement la situation de la file d'envoi (`0059`), et la réponse est la
même : **une file, pas une boucle.** Le bouton dépose des demandes, un
traitement de fond les prend une par une, l'écran montre l'avancement. Une
génération qui échoue se rejoue sans refaire les onze autres.

Et la même précaution qu'en `0068` s'appliquera : réserver avant de traiter.
Deux passages simultanés sur la même demande, ce sont deux factures pour un
seul bilan.

### Un seul bilan ouvert par enfant — ce que ça protège, et ce que ça n'empêche pas

`bilans_positionnement` porte depuis `0004` un index unique
`bilans_un_seul_en_cours`. Deux clics successifs ne peuvent pas ouvrir deux
bilans : la base refuse le second. Écrit pour éviter deux niveaux
contradictoires, il protège aussi le budget.

**Il n'empêche pas de recommencer.** Un enfant fatigué, un jour qui se passe
mal : le bilan s'abandonne (`statut_bilan` a la valeur `abandonne` depuis 0004)
et un nouveau s'ouvre.

Mais recommencer est le second choix. Le pré-bilan demande déjà *« a besoin de
pouvoir interrompre l'évaluation et la reprendre plus tard »* et *« des signes
annoncent qu'il faut interrompre »* : **le bilan doit donc savoir se mettre en
pause et reprendre**, et l'abandon ne sert qu'au cas où reprendre n'a plus de
sens.

> **Un bilan interrompu par la fatigue ne produit aucun niveau.**

Si l'on gardait ses réponses partielles comme une mesure, on enregistrerait la
fatigue comme de l'incompétence — exactement ce que tout ce travail combat. Les
réponses restent au dossier pour comprendre ce qui s'est passé ; elles
n'alimentent jamais un résultat. `bilan_reponses` porte `duree_secondes` et
`aide_utilisee` : de quoi voir la fatigue arriver, pas de quoi la noter.

### Plusieurs référents à la fois

Une file n'est pas un guichet unique. `for update skip locked` — le mécanisme
vérifié en `0068` — sert précisément à ce que plusieurs traitements avancent en
parallèle sur des lignes différentes. Deux référents d'établissements
différents ne se voient pas, ne s'attendent pas, ne se ralentissent pas.

La seule chose sérialisée est **deux générations pour le même enfant**, et
c'est voulu.

La vraie limite à grande échelle est ailleurs : les quotas du fournisseur d'IA,
partagés par toute l'application. Invisible à douze familles ; à deux cents,
c'est un problème d'étalement et de priorités, pas d'architecture.

### Dire ce que ça coûte avant de cliquer

Puisque le but est de ne pas générer pour rien, l'écran doit annoncer l'ordre de
grandeur — durée, et coût si on le suit. `journal_ia` et la vue
`cout_ia_mensuel` (0008) ont tout ce qu'il faut.

### Générer n'est pas publier

La génération produit un brouillon. Rien n'est présenté à l'enfant avant
relecture humaine — `valide_par` et `valide_le` de `0004` sont là pour ça, et la
contrainte `bilan_valide_a_un_validateur` l'impose en base.

## Ce qui reste à faire

- L'écran de saisie du pré-bilan.
- Le dépôt du diagnostic, sa lecture par le modèle, sa relecture humaine
  obligatoire.
- La fusion des deux sources. Règle posée d'avance : une divergence entre
  diagnostic et observation **se signale, elle ne se lisse pas**.
- La génération du bilan, qui attend les **repères officiels** de l'Éducation
  nationale. Ceux en base sont des formulations de travail (`source = 'amorce'`).
  La synthèse des programmes 2026 fournie décrit l'architecture des cycles et le
  calendrier des réformes, pas les attendus eux-mêmes — elle annonce d'ailleurs
  que les textes complets dépassent 3 500 pages.

  Ce qu'elle a tout de même appris : **le programme ne bascule pas d'un bloc.**
  Au sein du cycle 4, la 5e passe aux nouveaux programmes en 2026, la 4e en
  2027, la 3e en 2028. La validité se joue donc par classe et par rentrée, ce
  que la migration 0071 enregistre. Un bilan reste ainsi lisible contre le
  programme qui s'appliquait à cet enfant-là, cette année-là.
