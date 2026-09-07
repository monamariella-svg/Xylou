# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all
differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/`
before writing any code. Heed deprecation notices.

Two that already bit this project:

- `middleware.ts` is deprecated. The file is `src/proxy.ts`, exporting `proxy`.
  Runtime is Node, and it cannot be set to edge.
- `cookies()`, `headers()`, `params` and `searchParams` are async. There is no
  synchronous fallback left in 16.

# Xylou

Accompagnement scolaire personnalisé pour enfants à besoins particuliers. Né du
cas de Xylan (4e, profil autiste). Voir `docs/projet.md` pour le dossier complet.

## Conventions

- **Le domaine s'écrit en français.** Tables, colonnes, routes, noms de composants :
  `enfants`, `projets_moteurs`, `/tableau-de-bord`. Le code d'infrastructure
  (hooks, utilitaires) reste en anglais. On ne traduit jamais un terme métier :
  un « projet moteur » n'est pas un « engine project ».
- **Migrations numérotées, jamais modifiées.** `supabase/migrations/00NN_sujet.sql`.
  Une migration appliquée est figée ; toute correction passe par une nouvelle.
- **RLS sur toute table contenant une donnée d'enfant.** Sans exception. Les
  données traitées relèvent du handicap, donc de la catégorie « donnée de santé »
  au sens RGPD. L'accès se décide dans `est_intervenant()`, pas dans le code React.
- **Aucune suggestion IA n'est appliquée sans validation humaine.** Toute ligne
  générée par un modèle porte `genere_par_ia`, `statut`, `valide_par`, `valide_le`.
  Un contenu non validé ne doit jamais être présenté à l'enfant.
- **Jamais de comparaison à une norme neurotypique** dans les libellés affichés.
  On mesure un niveau et une progression, on ne note pas un écart.
- **Aucun courriel vers quelqu'un qui n'a pas de compte** tant qu'il n'existe pas
  de désabonnement sans session. Toutes les notifications sortantes vont
  aujourd'hui à des titulaires de compte — `notifications.destinataire_id`
  référence `profils` — et c'est ce qui rend acceptable que le seul moyen de les
  couper soit un écran derrière une session : chacun peut l'atteindre.
  L'invitation d'un enseignant est le premier envoi qui romprait cela, puisque
  son destinataire n'a par définition pas encore de compte. Son seul recours
  serait alors de nous signaler comme indésirable, ce qui dégrade la
  délivrabilité pour toutes les familles — y compris pour l'alerte de blocage.
  **L'ordre n'est pas négociable :** le désabonnement par jeton signé
  (pied de page et `List-Unsubscribe-Post`) précède le premier envoi
  d'invitation, il ne le suit pas. Voir `docs/questions-juriste.md` §9.

## Stack

Next.js 16 (App Router, Server Components, Server Actions), React 19, Supabase
(Postgres + Auth + Storage), Tailwind 4. Pas d'ORM : requêtes via `supabase-js`.
