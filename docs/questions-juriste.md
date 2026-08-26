# Questions à poser à un juriste — Xylou

Document de travail, tenu au fil de la conception. Chaque question indique ce qui
l'a fait surgir, ce qui a été implémenté **à titre provisoire**, et ce qui reste
à trancher.

Rien de ce qui suit ne constitue un avis juridique. Les arbitrages provisoires
ont été pris pour ne pas bloquer le développement ; plusieurs sont réversibles à
peu de frais, quelques-uns ne le sont pas — ils sont signalés.

Dernière mise à jour : 25 août 2026.

---

## 1. Données de santé et fondement du traitement

**1.1** Le handicap et les aménagements scolaires relèvent-ils de l'article 9 du
RGPD (données de santé) dans notre cas précis, ou d'une qualification plus
souple dès lors qu'ils sont saisis par la famille elle-même et non par un
soignant ?

**1.2** Quel est le fondement licite du traitement : le consentement, ou
l'intérêt légitime ? Le consentement d'un parent pour un enfant mineur
est-il révocable à tout moment, et que devient l'historique s'il l'est ?

**1.3** Une analyse d'impact (AIPD) est-elle obligatoire ? Le dossier de projet
la budgète, mais il faut confirmer le déclenchement et le périmètre.

**1.4** À partir de quel âge le consentement propre de l'enfant compte-t-il, et
faut-il l'articuler avec celui des titulaires de l'autorité parentale ?

**1.5** Quelle forme de signature électronique est suffisante pour un
consentement de ce type ? Nous conservons le texte exact présenté (figé, non
réécrivable), un nom saisi par la personne, l'horodatage, l'adresse IP et le
navigateur — et facultativement une signature manuscrite tracée à l'écran.
Est-ce assez, ou faut-il un procédé qualifié ?

**1.6** Une signature manuscrite tracée à l'écran est-elle une donnée
biométrique appelant un régime particulier ? Nous la traitons comme telle par
précaution : lisible par son seul auteur, jamais partagée.

**1.7** Lorsqu'un texte de consentement est republié, faut-il **re-signer** ?
Nous avons choisi que oui — un consentement porte sur un texte, pas sur un
sujet. Est-ce exigé, ou peut-on ne redemander qu'en cas de changement
substantiel ?

*Provisoire dans le schéma* : table `textes_consentement` versionnée et figée
après publication ; `consentements` porte le texte signé, la signature, l'IP et
l'agent ; aucune modification possible après coup, seule la révocation s'écrit.
Les refus sont enregistrés au même titre que les acceptations — sans quoi
« il a refusé » serait indiscernable de « on ne lui a jamais demandé ».

---

## 2. Autorité parentale

**2.1** Un référent — professionnel de l'accompagnement, pas officier public —
peut-il légalement **établir** qui détient l'autorité parentale ? Sur quelles
pièces doit-il se fonder, et quelle est sa responsabilité s'il se trompe ?

**2.2** Le consentement d'**un seul** titulaire suffit-il pour un traitement de
données de santé, ou faut-il celui des deux ? La distinction acte usuel / acte
important s'applique-t-elle ici, et de quel côté tombe notre cas ?

**2.3** En garde alternée, un parent peut-il valider seul un objectif
pédagogique ? Nous avons choisi d'exiger les deux — est-ce juridiquement requis,
ou est-ce une prudence qui risque de bloquer des familles en conflit ?

**2.4** Quel statut pour un beau-parent très impliqué mais sans autorité
parentale ? Peut-il accéder au dossier avec l'accord des titulaires ?

**2.5** Que faire lorsqu'un titulaire refuse durablement de signer, alors que
l'accompagnement est en cours ? Existe-t-il une voie de passage outre ?

*Provisoire dans le schéma* : `enfants.titulaires_autorite_parentale`, valant 1
ou 2, établi par le référent, **2 par défaut**. Aucun objectif ne se valide tant
que tous les titulaires déclarés n'ont pas rejoint et signé.

---

## 3. Accès d'exception au dossier

**3.1** En cas de **réquisition judiciaire**, la famille doit-elle être informée
de l'accès ? Si le secret de l'enquête l'interdit, l'information devient-elle due
à la levée du secret, et sous quel délai ?

**3.2** Qui, dans une petite structure, a qualité pour répondre à une réquisition
et pour en apprécier la régularité ?

**3.3** La famille peut-elle exiger **copie** de la réquisition une fois le secret
levé ? Nous avons choisi de lui communiquer le motif mais pas la pièce, qui peut
concerner des tiers. Cet arbitrage tient-il ?

**3.4** Une durée d'accès de 72 heures non prolongeable est-elle défendable, ou
faut-il prévoir une prolongation motivée ?

**3.5** Nous excluons les données de santé (`enfants_sante`) de tout accès
d'exception, y compris sous réquisition. Est-ce tenable si une réquisition les
vise explicitement ?

**3.6** **Point technique à porter à la connaissance du juriste** : PostgreSQL ne
permet pas de journaliser chaque lecture. Nous traçons l'ouverture de l'accès —
qui, quand, pourquoi, sur quel fondement — mais pas les lignes effectivement
consultées. Cette granularité est-elle suffisante au regard de l'obligation de
traçabilité ? *Cette limite est structurelle, pas un choix : la lever supposerait
une autre architecture.*

*Provisoire dans le schéma* : table `acces_exceptionnels`, quatre natures
(litige, réquisition, demande famille, demande équipe), motif écrit obligatoire,
pièce justificative exigée avant toute lecture, expiration à 72 h, information de
la famille immédiate sauf réquisition.

---

## 4. Demandes d'accès émanant des personnes

**4.1** Lorsqu'un parent demande l'ouverture du dossier, faut-il l'accord écrit
des **deux** titulaires quand ils sont deux, ou la demande de l'un suffit-elle
puisqu'il agit dans l'intérêt de l'enfant ?

**4.2** Lorsque l'**équipe pédagogique** demande l'accès, un courrier d'un seul
titulaire suffit-il, ou faut-il celui de chacun ?

**4.3** Quelle forme doit prendre ce courrier pour être opposable : signature
manuscrite scannée, courriel depuis l'adresse déclarée, formulaire signé dans
l'application ?

**4.4** Combien de temps conserver ces courriers, et que faire à l'expiration ?

**4.5** Une pièce versée **par erreur** — mauvais dossier, donc courrier
concernant un autre enfant, ou scan comportant des informations non demandées —
doit-elle être conservée au titre de la traçabilité, ou effacée au titre de la
minimisation ? Les deux principes se contredisent ici, et nous avons tranché
pour la traçabilité.

*Provisoire dans le schéma* : un courrier par titulaire est exigé dans les deux
cas (4.1 et 4.2), l'accès restant inerte tant que le compte n'y est pas.
C'est l'hypothèse la plus stricte ; elle se relâche facilement si vous confirmez
qu'un seul suffit.

*Provisoire pour 4.5* : une pièce erronée s'**écarte** — geste signé, motivé,
horodaté — mais ne s'efface jamais. Elle cesse de compter dans les
autorisations, et reste visible. Le raisonnement : un dossier où ne figurerait
que la bonne pièce ne dirait pas qu'il y en a eu une mauvaise, et c'est
précisément ce qu'un contrôle a besoin de voir. Si la minimisation doit primer,
il faudra une purge sur critère, et savoir ce qu'on inscrit à la place.

---

## 5. Conservation, portabilité, effacement

**5.1** Durées de conservation : dossier actif, dossier archivé, journal d'accès,
pièces justificatives d'accès d'exception, échanges de messagerie.

**5.2** Le dossier doit-il suivre l'enfant lors d'un changement d'établissement,
et sous quelle forme ? Le projet promet une portabilité lors des transitions.

**5.3** Un parent peut-il exiger l'effacement de contenus produits par un
professionnel — appréciations, comptes rendus d'alerte — ou seulement des données
qu'il a lui-même fournies ?

**5.4** Que devient le dossier à la majorité de l'enfant ? Bascule-t-il sous son
propre contrôle, et qu'advient-il de l'accès des parents ?

**5.5 — QUESTION DEVENUE BLOQUANTE.** Supprimer un dossier se fait en deux
temps : masquage immédiat dès l'accord de tous les titulaires de l'autorité
parentale, puis effacement physique au terme de la durée légale de conservation.

Entre les deux, personne ne lit rien — ni la famille, ni l'équipe, ni
l'administration. Seul un accès d'exception motivé (§3) pourrait rouvrir.

**Quelle est cette durée ?** Le schéma applique cinq ans, faute de mieux, et ce
n'est plus une politique interne : c'est ce qu'on écrit à une famille qui
demande l'effacement. Lui annoncer cinq ans puis découvrir qu'il en fallait dix
— ou trois — nous mettrait en défaut dans les deux sens.

Sous-questions qui en découlent :

- la durée est-elle la même pour un dossier abandonné en cours d'année et pour
  un accompagnement mené à son terme ?
- l'effacement doit-il emporter les pièces d'accès d'exception (§3.4) et les
  journaux, ou ceux-ci relèvent-ils d'une durée propre ?
- que devient le registre des suppressions lui-même — `suppressions_effectuees`
  — qui porte le prénom de l'enfant et le motif ? Il survit à la purge par
  construction ; combien de temps a-t-il le droit de survivre ?

*Provisoire dans le schéma* : masquage sur accord unanime, purge manuelle à
l'échéance, et un registre sans clé étrangère vers l'enfant qui conserve qui a
demandé, qui a consenti, qui a exécuté, et quand. Aucune donnée du dossier — la
preuve qu'on avait le droit, pas une copie de ce qu'on a effacé.

**5.6** L'accord de suppression est exigé de **tous** les titulaires, et un seul
suffit à l'arrêter. Est-ce le bon équilibre ? Un parent qui refuse indéfiniment
bloque l'exercice du droit à l'effacement de l'autre — situation prévisible en
cas de séparation conflictuelle. Existe-t-il une voie de recours ?

*Provisoire dans le schéma* : suppression douce (`archive_le`) sur la fiche
enfant, suppression définitive interdite dès que deux titulaires sont rattachés.

---

## 6. Intelligence artificielle et sous-traitance

**6.1** Le recours à un modèle d'IA sur des données relatives au handicap d'un
enfant impose-t-il des mentions ou des garanties particulières ? Faut-il un
consentement distinct de celui du traitement principal ?

**6.2** Le fournisseur du modèle est un sous-traitant au sens du RGPD : quelles
clauses, et quel encadrement du transfert hors Union européenne ?

**6.3** L'article 22 (décision automatisée) s'applique-t-il à un bilan de
positionnement produit par l'IA, dès lors qu'un humain le valide ? La validation
humaine que nous imposons suffit-elle à sortir du champ ?

**6.4** Nous n'enregistrons pas le contenu des prompts, seulement leur empreinte
et leur longueur, pour éviter de reconstituer des données de santé depuis les
journaux. Cette précaution est-elle attendue, ou insuffisante ?

*Provisoire dans le schéma* : table `journal_ia` sans contenu de prompt,
consentement `generation_ia` distinct, validation humaine imposée par contrainte
de base.

---

## 7. Rôles et responsabilité

**7.1** Qui est responsable de traitement : la structure qui édite Xylou, la
famille, l'établissement scolaire ? Y a-t-il responsabilité conjointe ?

**7.2** Un enseignant qui dépose un support scolaire dans l'outil engage-t-il son
établissement ? Faut-il une convention avec les établissements ?

**7.3** L'administrateur de la plateforme peut corriger des rattachements sans
voir le contenu des dossiers. Cette séparation est-elle suffisante pour écarter
sa responsabilité sur le contenu ?

**7.4 — À TRANCHER AVANT LA PRODUCTION.** Pendant le pilote, une habilitation de
référent peut être accordée sans aucune pièce justificative, sur la seule
connaissance personnelle de l'administratrice — la première équipe est composée
de gens qu'elle connaît, et leur imposer une procédure avant même d'avoir montré
l'outil serait le meilleur moyen de ne jamais le leur montrer.

Ce réglage ne peut pas survivre au pilote. Un référent ouvre des dossiers
d'enfants handicapés, établit qui détient l'autorité parentale, accède aux
données de santé.

Questions : **quelles pièces exiger** au minimum ? L'attestation du directeur
d'établissement suffit-elle, ou faut-il une pièce d'identité ? Une vérification
d'identité s'impose-t-elle avant d'ouvrir l'accès à des données de santé
d'enfants — et si oui, sous quelle forme ?

*Provisoire dans le schéma* : une fonction `pieces_exigees()`, vide pendant le
pilote, qui bloque l'acceptation dès qu'on la remplit. La bascule tient en une
ligne, et l'écran d'instruction affiche déjà ce qui manquerait.

---

## 8. Ce que les CGU doivent couvrir

Points identifiés au fil de la conception, à rédiger avec le juriste. Plusieurs
décrivent un comportement du produit qui surprendra s'il n'est pas annoncé.

**8.1 La suppression du dossier — à décrire en entier, pas seulement à
mentionner.** C'est le point des CGU le plus susceptible d'être reproché plus
tard, parce que le mot « supprimer » promet autre chose que ce qui se passe.

> **Ce n'est pas une suppression dans un premier temps, mais un masquage.**
> Cette phrase doit figurer telle quelle, en tête du paragraphe, et non se
> déduire de la lecture des cinq points qui suivent.

**Et elle doit être dite ailleurs que dans les CGU.** Des conditions générales
que personne ne lit ne rendent rien « ouvert » : l'information doit apparaître
**au moment du clic**, dans l'écran de confirmation, avant que la personne
décide. Une famille qui découvre six mois plus tard, en relisant les CGU, que
ses données existaient encore aura été informée au sens juridique et trompée au
sens ordinaire.

Trois conséquences pour l'interface, qui relèvent du produit et non du juriste
mais qui découlent de la même exigence :

- le bouton ne dit pas « Supprimer » seul. Il dit ce qu'il fait — masquer
  d'abord, effacer au terme ;
- l'écran de confirmation annonce **la durée** — « cinq ans après le masquage »
  — et non une date figée. Une date calculée aujourd'hui devient fausse si la
  durée légale change, et personne ne la reprendra : elle aura l'air juste. La
  date peut s'afficher en indication, à condition d'être recalculée à chaque
  affichage ;
- après le masquage, l'accusé de réception rappelle que le retour en arrière
  reste possible jusqu'au terme.

Cinq choses doivent figurer dans les CGU :

*Qui peut demander.* Un titulaire de l'autorité parentale, ou l'administration
de la plateforme — un dossier ouvert par erreur doit pouvoir se refermer.

*Qui doit accepter.* **Tous** les titulaires, chacun signant pour lui-même. Une
demande faite par l'un n'engage pas l'autre. Un seul refus suffit à arrêter la
procédure, et il n'a pas à se motiver.

*Ce qui se passe immédiatement.* Le dossier disparaît pour tout le monde — la
famille, l'équipe pédagogique, l'administration. Plus personne n'y accède, et
aucune donnée n'y est plus traitée.

*Ce qui se passe ensuite.* Les données sont conservées, hors de toute
consultation, pendant la durée légale applicable — puis effacées
définitivement. **Il faut annoncer cette durée en clair.** *(Dépend de 5.5, non
tranché.)*

*Ce qui reste après l'effacement.* Un enregistrement de la suppression
elle-même : la date, le motif, l'identité des personnes qui l'ont demandée et
acceptée. Aucune donnée du dossier. C'est la preuve que la suppression a été
faite dans les règles, et elle protège la famille autant que la plateforme.

Deux points qui jouent en faveur des familles et méritent d'être dits
explicitement, parce qu'ils ne se devinent pas :

*Le retour en arrière reste possible* tant que l'effacement définitif n'a pas eu
lieu. Une famille qui se ravise retrouve son dossier intact.

*Aucun accès n'est possible dans l'intervalle*, sauf réquisition judiciaire ou
litige — auquel cas la procédure du point 8.4 s'applique, avec information de la
famille.

**8.2 La différence entre supprimer et se retirer.** Un intervenant qui quitte
un dossier n'en efface rien : ce qu'il a écrit reste, sous son nom. Les familles
doivent le savoir avant d'inviter quelqu'un — c'est une des rares choses de cet
outil qui ne se défait pas.

**8.3 Que personne ne lit l'archive.** L'administration voit qu'un dossier
archivé existe et quand il sera purgé ; elle n'en voit pas le contenu. Un accès
reste possible en cas de réquisition ou de litige, par le mécanisme du 8.4.

**8.4 L'accès d'exception.** Ses quatre cas d'ouverture, l'obligation de motif
écrit et de pièce justificative, la durée limitée, et l'information de la famille
— immédiate, sauf réquisition judiciaire où elle peut être différée. Ce dernier
point doit figurer, faute de quoi le différé serait une surprise déloyale.

**8.5 Les rôles et qui décide quoi.** Que le dossier est ouvert par un référent
ou l'administration ; que le référent établit qui détient l'autorité parentale et
combien ils sont ; que les objectifs sont validés par tous les titulaires ; que
les exercices et évaluations relèvent de l'enseignant de la matière.

**8.6 Le recours à l'IA**, la supervision humaine, et le fait que le contenu du
prompt n'est pas conservé.

**8.7 Les points et la boutique.** Ils sont purement virtuels, sans aucune
contrepartie monétaire, non transférables entre enfants, non remboursables, et
ne s'achètent pas. Rien dans la boutique ne s'obtient contre de l'argent réel.
*Question au juriste* : cette mécanique de monnaie virtuelle dans un produit
destiné à des mineurs appelle-t-elle des mentions particulières, ou relève-t-elle
d'un encadrement spécifique dès lors qu'aucun paiement n'intervient ?

**8.8 Ce qu'un enfant ne voit pas de son propre dossier**, si nous lui ouvrons un
compte — voir la question ouverte sur les comptes enfants.

---

## À rapporter au juriste en une phrase

Le schéma applique partout l'hypothèse la plus protectrice quand le droit est
incertain — deux titulaires par défaut, accès fermés par défaut, information
immédiate sauf obligation contraire. **Nous cherchons à savoir où nous pouvons
relâcher sans risque**, pas seulement où il faut resserrer : plusieurs de ces
choix rendent l'outil plus lourd qu'il ne doit l'être, et une famille bloquée
n'est pas mieux protégée qu'une famille servie.
