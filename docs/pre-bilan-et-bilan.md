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

## Ce qui reste à faire

- L'écran de saisie du pré-bilan.
- Le dépôt du diagnostic, sa lecture par le modèle, sa relecture humaine
  obligatoire.
- La fusion des deux sources. Règle posée d'avance : une divergence entre
  diagnostic et observation **se signale, elle ne se lisse pas**.
- La génération du bilan, qui attend aussi les repères officiels de
  l'Éducation nationale — ceux en base sont des formulations de travail.
