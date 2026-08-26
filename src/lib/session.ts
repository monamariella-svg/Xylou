import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export function supabaseConfigure() {
  return Boolean(
    process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );
}

/**
 * Point d'entrée de toute page réservée. Renvoie le client et l'utilisateur, ou
 * sort par une redirection.
 *
 * Ce n'est pas une autorisation : ça vérifie qu'on sait qui parle, rien de plus.
 * Le droit de lire telle fiche se décide dans les politiques RLS (migration 0009),
 * jamais ici — une page qui oublierait ce garde-fou afficherait une liste vide,
 * pas les données d'un autre enfant.
 */
export async function exigerUtilisateur() {
  if (!supabaseConfigure()) redirect("/configuration-requise");

  const supabase = await createClient();
  const { data } = await supabase.auth.getUser();
  if (!data.user) redirect("/connexion");

  return { supabase, utilisateur: data.user };
}
