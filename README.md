# Xylou

Accompagnement scolaire personnalisé pour enfants à besoins particuliers. Le
dossier projet complet est dans [`docs/projet.md`](docs/projet.md) ; c'est la
référence métier, et tout choix technique doit pouvoir s'y rattacher.

## Démarrer

```bash
npm install
cp .env.local.example .env.local   # puis renseigner les valeurs
npm run dev
```

Les clés se trouvent dans Supabase &rsaquo; Project Settings &rsaquo; API. Next.js
ne relit pas `.env.local` à chaud : relancer `npm run dev` après chaque
modification.

## Appliquer le schéma

Les migrations de `supabase/migrations/` s'appliquent **dans l'ordre numérique**,
via le SQL Editor de Supabase (copier-coller le contenu de chaque fichier, une
migration à la fois, en vérifiant qu'elle passe avant de lancer la suivante).

| Migration | Contenu |
| --- | --- |
| `0001` | Profils, enfants, données de santé, intervenants, invitations, fonctions d'accès |
| `0002` | Centres d'intérêt, projet moteur, récompenses |
| `0003` | Référentiel scolaire et repères de compétences |
| `0004` | Bilan de positionnement |
| `0005` | Objectifs, supports déposés, adaptations |
| `0006` | Missions, exercices, tentatives, points |
| `0007` | Bilan trimestriel |
| `0008` | Journal IA, consentements, journal d'accès |
| `0009` | Row Level Security sur l'ensemble du schéma |
| `0010` | Buckets de stockage et leurs politiques |

Une migration appliquée ne se modifie jamais : toute correction passe par un
nouveau fichier numéroté.

> **À faire avant le pilote.** Les repères de compétences insérés en `0003`
> portent `source = 'amorce'`. Ce sont des formulations de travail, pas les
> attendus officiels de l'Éducation nationale. Le §3.4 du dossier identifie le
> calibrage du bilan comme le principal risque produit : ces repères doivent être
> remplacés par les repères Éduscol correspondants avant qu'un enfant passe un
> bilan.

## Envoyer les notifications

Une notification naît en base — un objectif à valider, un message, une
habilitation traitée — et un trigger la met en file (`envois`). Rien ne sort
tant que la file n'est pas vidée : `POST` ou `GET /api/envois` s'en charge,
protégé par `CRON_SECRET`.

Trois déclencheurs la vident, du plus rapide au plus sûr (migration `0068`) :

| Déclencheur | Délai | Rôle |
| --- | --- | --- |
| Sonnette `pg_net` sur `envois` | quelques secondes | le cas normal |
| `pg_cron`, toutes les 5 min | 5 min | rattrape les échecs et ce que la sonnette a perdu |
| Tâche Vercel, quotidienne | 24 h | dernier filet si les extensions sont tombées |

Le plan Hobby de Vercel ne déclenche de toute façon qu'une fois par jour : c'est
pourquoi `vercel.json` n'est plus la cadence principale mais le filet extérieur.

**Trois choses à faire une fois, côté Supabase**, sans quoi seul le filet
quotidien fonctionne :

1. activer `pg_net` et `pg_cron` (Database &rsaquo; Extensions) ;
2. créer deux secrets dans Vault — `xylou_url_envois` (l'adresse complète de
   `/api/envois`) et `xylou_cron_secret` (la même valeur que `CRON_SECRET`) ;
3. planifier le balayage : la commande `cron.schedule` est donnée en fin de
   migration `0068`, à copier telle quelle.

Un envoi n'est jamais expédié deux fois même si les trois déclencheurs se
recouvrent : `reserver_envois()` réserve les lignes avant l'appel à Resend, et
deux passages simultanés se partagent le travail au lieu de le refaire.

En local, sans tâche planifiée :

```bash
curl -X POST localhost:3000/api/envois -H "Authorization: Bearer $CRON_SECRET"
```

Les envois qui échouent restent visibles dans `/administration`, ce qui est le
seul endroit où l'on s'aperçoit qu'une clé a expiré avant qu'une famille le
signale.

## Architecture

```
src/
  app/                    routes (App Router)
    enfants/actions.ts    Server Actions du domaine enfant
    enfants/[id]/         fiche, santé, centres d'intérêt, projet moteur
  components/ui.tsx       champs, boutons, messages
  lib/
    domaine.ts            énumérations et libellés affichés
    consentements.ts      textes de consentement et leur version
    session.ts            garde-fou d'authentification des pages réservées
    supabase/             clients serveur et navigateur
  proxy.ts                rafraîchissement de session (ex-`middleware.ts`)
supabase/migrations/      schéma, RLS, storage
```

## Ce qui n'est pas encore là

Le MVP décrit au §3.5 comporte six briques. Deux sont posées :

- [x] Fiche enfant, centres d'intérêt, projet moteur
- [ ] Bilan de positionnement assisté par IA
- [ ] Exercices adaptés et génération de missions
- [ ] Suivi de progression
- [ ] Missions et récompenses côté enfant
- [ ] Bilan trimestriel PDF

Le schéma de base de données couvre les six : les tables des briques restantes
existent déjà, avec leurs politiques RLS. Ce qui manque est l'interface et les
appels au modèle.

> **Condition avant de faire partir une invitation par courriel.** Toutes les
> notifications sortantes vont aujourd'hui à des titulaires de compte, et c'est
> ce qui rend acceptable que le désabonnement passe par un écran derrière une
> session. Une invitation romprait cela : son destinataire n'a pas encore de
> compte, donc aucun accès à cet écran, et son seul recours pour ne plus rien
> recevoir serait de nous signaler comme indésirable. Il faut donc poser
> d'abord un désabonnement sans session — jeton signé par destinataire, servant
> le lien du pied de page et l'en-tête `List-Unsubscribe-Post`. Une demi-journée,
> sans migration. Voir `docs/questions-juriste.md` §9.

Reporté en v2, conformément au §3.5 : planning partagé, profils de
professionnels extérieurs, espaces de commentaires.
