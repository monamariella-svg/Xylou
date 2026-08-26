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

Reporté en v2, conformément au §3.5 : planning partagé, profils de
professionnels extérieurs, espaces de commentaires.
