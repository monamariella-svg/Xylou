import { createClient } from "@supabase/supabase-js";

/**
 * Client à privilèges, pour les traitements de fond qui n'ont pas d'utilisateur
 * connecté — la vidange de la file d'envoi, notamment.
 *
 * Il contourne toutes les politiques RLS. C'est nécessaire ici : un service qui
 * envoie des courriels doit lire des lignes destinées à d'autres personnes que
 * lui, ce qu'aucun compte ordinaire ne peut faire. Mais c'est aussi pourquoi il
 * ne doit jamais être appelé depuis une page ou une action déclenchée par un
 * utilisateur : le moindre paramètre venu du navigateur deviendrait une requête
 * sans garde-fou.
 *
 * Règle simple : ce fichier ne s'importe que depuis `app/api/`.
 */
export function createServiceClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const cle = process.env.SUPABASE_SERVICE_ROLE_KEY;

  // On échoue bruyamment plutôt que de laisser un client mal configuré partir
  // en silence : une file qui ne se vide pas sans rien dire est exactement le
  // défaut que la file devait supprimer.
  if (!url || !cle) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont nécessaires au service d'envoi.",
    );
  }

  return createClient(url, cle, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
