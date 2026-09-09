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
- les **autorisations** ne sont pas signées, `generation_ia` en particulier ;
- la **classe** n'est pas renseignée : elle décide des domaines évalués, et
  ceux-ci diffèrent d'une classe à l'autre au sein d'un même cycle (0072).

Un bouton grisé sans explication produit un appel au référent. Le message doit
dire ce qui manque et mener à l'écran qui le règle.

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

### Ce qui protège déjà contre le double clic

`bilans_positionnement` porte depuis `0004` un index unique
`bilans_un_seul_en_cours` : un seul bilan ouvert par enfant. Deux clics
successifs ne peuvent donc pas ouvrir deux bilans — la base refuse le second.
C'était écrit pour éviter deux niveaux contradictoires ; ça protège aussi le
budget.

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
