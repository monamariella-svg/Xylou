"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function marquerToutCommeLu() {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return;

  // Pas de filtre sur le destinataire : la politique de 0014 ne laisse écrire
  // que ses propres notifications. L'ajouter ici donnerait l'illusion que c'est
  // le code qui protège.
  await supabase
    .from("notifications")
    .update({ lue_le: new Date().toISOString() })
    .is("lue_le", null);

  revalidatePath("/tableau-de-bord");
}
