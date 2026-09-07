"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type EtatPreferences = { erreur?: string; succes?: string };

/**
 * Enregistre ce que la personne accepte de recevoir par courriel.
 *
 * La liste des types traités vient de `types_notifies_hors_application()`
 * (migration 0067), jamais du formulaire : une case absente du POST est
 * indiscernable d'une case décochée, et prendre le formulaire pour source
 * laisserait un client décider quels types existent.
 */
export async function enregistrerPreferences(
  _etatPrecedent: EtatPreferences,
  formData: FormData,
): Promise<EtatPreferences> {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Session expirée. Reconnectez-vous." };

  const { data: types, error: erreurTypes } = await supabase.rpc(
    "types_notifies_hors_application",
  );
  const liste = (types ?? []) as string[];

  if (erreurTypes || liste.length === 0) {
    return { erreur: "Impossible de lire la liste des notifications. Réessayez." };
  }

  // On écrit aussi les accords, pas seulement les refus. Le trigger de 0059 se
  // contente d'une ligne absente pour envoyer, mais une ligne explicite dit que
  // quelqu'un a vu cet écran et a tranché — ce qu'une absence ne dit pas.
  const lignes = liste.map((type) => ({
    profil_id: auth.user.id,
    type,
    canal: "courriel",
    actif: formData.get(`courriel:${type}`) === "on",
  }));

  const { error } = await supabase
    .from("preferences_notification")
    .upsert(lignes, { onConflict: "profil_id,type,canal" });

  if (error) return { erreur: error.message };

  revalidatePath("/notifications/preferences");
  return { succes: "Vos choix sont enregistrés." };
}
