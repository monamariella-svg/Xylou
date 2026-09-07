"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

/**
 * Marquer comme lu, et rien d'autre. C'est la seule écriture que la politique
 * `notifications_maj` de 0014 laisse passer sur ses propres lignes.
 *
 * Aucun filtre sur le destinataire dans les requêtes ci-dessous : la politique
 * s'en charge, et l'ajouter ici donnerait l'illusion que c'est le code qui
 * protège.
 */

export async function marquerToutCommeLu() {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return;

  await supabase
    .from("notifications")
    .update({ lue_le: new Date().toISOString() })
    .is("lue_le", null);

  // L'en-tête porte la pastille sur toutes les pages : ne rafraîchir que
  // l'écran d'où part le clic la laisserait afficher un compte périmé partout
  // ailleurs jusqu'à la prochaine navigation complète.
  revalidatePath("/", "layout");
}

export async function marquerCommeLue(formData: FormData) {
  const id = String(formData.get("id") ?? "");
  if (!id) return;

  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return;

  await supabase
    .from("notifications")
    .update({ lue_le: new Date().toISOString() })
    .eq("id", id)
    .is("lue_le", null);

  revalidatePath("/", "layout");
}
