# Xylou — dossier projet

> Transcription du document source `Presentation_Projet.docx`. C'est la référence
> métier du projet : toute décision de code doit pouvoir s'y rattacher.

Un accompagnement scolaire personnalisé, construit à partir du cas de Xylan.

## 1. Pitch — équipe pédagogique

Xylan a un bon niveau en mathématiques, en SVT, en physique-chimie et en
technologie, mais des difficultés pour aborder un problème, et un niveau de
français encore fragile. Comme beaucoup d'enfants autistes, il peut suivre le
contenu du cours — mais le format des supports et des évaluations ne correspond
pas toujours à la façon dont il apprend, ce qui fausse ses résultats même quand
la leçon est sue.

Nous mettons en place un outil qui part de son propre centre d'intérêt (le jeu
vidéo) pour transformer ses apprentissages en missions concrètes. Ce que ça
change pour l'équipe : rien à construire. On dépose un support de cours ou le
sujet du devoir, l'outil l'adapte visuellement et le transforme, pour Xylan, en
énigme de jeu.

L'implication peut rester minimale — valider un objectif proposé, quelques
minutes par trimestre — ou aller plus loin. La coordinatrice ULIS reste le point
de passage central en cas de manque de temps. L'objectif n'est jamais de comparer
Xylan à une norme, mais de lui donner un repère de progression qui a du sens pour
lui, et de donner à l'équipe une photographie claire de son niveau réel,
trimestre après trimestre, sans travail de préparation supplémentaire.

## 2. Pitch — parents

Coordonner l'école, les rééducations, les bilans, tout en essayant de donner à
son enfant l'envie d'apprendre, sans jamais le comparer à une norme qui ne lui
correspond pas : c'est la charge que l'outil vise à alléger.

Principe : prendre ce qui intéresse déjà l'enfant — un jeu vidéo, un dessin
animé, les oiseaux, les trains, un livre — et en faire le fil rouge de ses
apprentissages. Un bilan assisté par IA mesure son niveau réel matière par
matière, sans jamais le comparer à un enfant neurotypique, et propose des
exercices adaptés à ses objectifs scolaires. Un bilan trimestriel prêt à l'emploi
évite de tout reconstruire avant chaque réunion avec l'école.

Ça ne remplace ni l'école ni les professionnels — ça redonne de la visibilité et
allège la coordination, dès le premier jour, même si l'école n'a pas encore
adopté l'outil de son côté.

## 3. Présentation détaillée

### 3.1 Contexte et origine

Le projet est né du cas concret de Xylan (4e, profil autiste, bon niveau
scientifique, difficultés en français et en résolution de problème), avec
l'objectif de construire un outil réutilisable pour d'autres enfants à besoins
particuliers, quel que soit leur profil de communication (verbal ou non-verbal)
et leur centre d'intérêt.

### 3.2 Comment ça fonctionne

- Une fiche enfant enregistre le profil, les centres d'intérêt et un « projet
  moteur » personnalisé (jeu vidéo, dessin animé, univers thématique, livre…)
- Un bilan de positionnement scolaire assisté par IA mesure le niveau réel de
  l'enfant matière par matière, selon les repères de l'Éducation nationale, sans
  comparaison à une norme neurotypique
- Des exercices sont générés et ajustés par IA à partir des objectifs définis par
  les enseignants et du niveau mesuré
- Les enseignants déposent leurs supports de cours et sujets de devoirs ; l'outil
  les adapte visuellement et les transforme en missions ou énigmes intégrées au
  projet moteur de l'enfant
- Un bilan trimestriel exportable en PDF est prêt à l'emploi pour les réunions
  parents-professeurs
- **Toute suggestion générée par l'IA reste supervisée par les parents et le
  référent de l'enfant**

### 3.3 Avantages

- Apporte de la valeur dès le premier jour, sans attendre l'adoption par l'école
- Réduit la charge de coordination et de préparation des réunions pour les parents
- Motivation intrinsèque, ancrée sur le centre d'intérêt de l'enfant
- Approche individualisée : jamais de comparaison à une norme neurotypique
- Ne demande quasiment aucun temps aux enseignants (validation plutôt que création)
- Profil et historique portables lors des transitions scolaires
- Généralisable à d'autres enfants, centres d'intérêt et profils de communication
- Synergies techniques avec le projet Liams (fiches profils, droits d'accès)

### 3.4 Inconvénients et points de vigilance

- Coût à la charge des familles : reproduit d'abord une partie de l'inégalité
  d'accès que le projet cherche à réduire
- L'IA nécessite une supervision humaine continue (parents + référent) pour éviter
  les biais ou une trajectoire figée — ce n'est pas un outil « zéro effort »
- Risque d'usine à gaz si la coordination multi-intervenants (v2) arrive trop tôt
- Portée limitée du planning partagé et des profils pro tant que l'école et les
  professionnels extérieurs n'ont pas rejoint l'outil
- Portée par une seule personne en parallèle de Liams : risque de dispersion
- **Données sensibles liées au handicap (« donnée de santé » au sens RGPD) :
  obligations de conformité renforcées, à sécuriser dès la conception**
- Adoption par les enseignants non garantie, même à coût d'entrée très faible
- Pas d'intégration Doctolib à ce stade (API réservée aux partenaires accrédités)
- **La qualité du bilan de positionnement initial est déterminante : un mauvais
  calibrage pourrait décourager l'enfant plutôt que le motiver**

### 3.5 Périmètre MVP

Dans le MVP : fiche enfant, bilan de positionnement par IA, exercices adaptés,
suivi de progression, missions/récompenses simplifiées, bilan trimestriel PDF.

Reporté en v2 : planning partagé, profils pro extérieurs, espaces de commentaires
— toute la coordination multi-intervenants.

### 3.6 Modèle économique

Financement par les familles dans un premier temps ; prise en charge publique
(État, MDPH) à rechercher une fois la valeur démontrée.

- Coûts variables par famille active : hébergement faible (Supabase/Vercel),
  appels IA (poste principal), frais de paiement (~1,5 % + 0,25 € via Stripe)
- Comparables EdTech premium France : 15 à 30 €/mois
- Piste : gratuit pour les familles pilotes, puis 19 à 29 €/mois (190–290 €/an)
- Marge brute sur coûts variables : 70 à 85 %, hors temps de développement

### 3.7 Modèle IA et budget classe pilote (12 enfants)

Approche hybride plutôt qu'un modèle unique :

- **Modèle rapide et économique** pour les tâches fréquentes et peu critiques :
  check-in quotidien, validations rapides, interactions courtes dans le jeu
- **Modèle plus capable** pour les tâches à jugement : bilan de positionnement
  initial, adaptation d'un support ou d'un devoir, bilan trimestriel
- **Mise en cache** des contenus réutilisés (programmes officiels, profil enfant)
  pour réduire fortement le coût des appels répétés

Estimations sur un an pour 12 enfants : usage léger 400–500 €, usage mixte
réaliste 1 000–1 200 €, usage intensif 1 800–2 000 €. Tarifs à revérifier avant
mise en production.

### 3.8 Budget de lancement — année 1

| Poste | Fourchette | Détail |
| --- | --- | --- |
| Validation juridique CGU/CGV/confidentialité | 1 500 – 3 500 € | Relecture par avocat des brouillons existants |
| AIPD (analyse d'impact RGPD) | 800 – 2 500 € | Quasi indispensable : mineurs + données de santé |
| **Sous-total lancement** | **2 300 – 6 000 €** | |

| Poste | Fourchette /an | Détail |
| --- | --- | --- |
| Assurance (RC Pro + protection juridique + cyber) | 500 – 1 500 € | Haut de fourchette justifié par le profil de risque |
| Nom de domaine (.fr) | ~15 € | |
| Hébergement au-delà du tier gratuit | 0 – 300 € | Probablement 0 pendant le pilote |
| IA (12 enfants, cf. §3.7) | 400 – 2 000 € | |
| Expert-comptable (optionnel) | 0 – 800 € | Non obligatoire en auto-entreprise |
| **Sous-total récurrent** | **915 – 4 615 €** | |

**Total réaliste année 1 : environ 3 200 € à 10 600 €.** Principal levier pour
rester en bas de fourchette : demander à l'avocat un devis de relecture plutôt
que de rédaction complète.
