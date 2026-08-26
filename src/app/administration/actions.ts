"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// Ces actions ne vérifient pas les droits : les fonctions qu'elles appellent le
// font toutes, et lèvent une exception explicite si l'appelant n'est pas
// administrateur. Doubler la vérification ici donnerait l'illusion que c'est
// cette page qui protège, alors qu'un appel direct la contournerait.

async function client() {
  return createClient();
}

export async function accepterHabilitation(formData: FormData) {
  const supabase = await client();

  const echeance = String(formData.get("valableJusquAu") ?? "").trim();

  await supabase.rpc("accepter_l_habilitation", {
    p_demande: String(formData.get("demandeId") ?? ""),
    // Nul signifie « sans terme ». C'est possible, mais ce doit rester
    // l'exception : une habilitation sans échéance ne se revérifie jamais.
    p_valable_jusqu_au: echeance || null,
    p_motif: String(formData.get("motif") ?? "").trim(),
  });

  revalidatePath("/administration");
}

export async function refuserHabilitation(formData: FormData) {
  const supabase = await client();

  await supabase.rpc("refuser_l_habilitation", {
    p_demande: String(formData.get("demandeId") ?? ""),
    p_motif: String(formData.get("motif") ?? "").trim(),
  });

  revalidatePath("/administration");
}

export async function masquerLeDossier(formData: FormData) {
  const supabase = await client();

  await supabase.rpc("masquer_le_dossier", {
    p_demande: String(formData.get("demandeId") ?? ""),
  });

  revalidatePath("/administration");
}

export async function purgerLeDossier(formData: FormData) {
  const supabase = await client();

  await supabase.rpc("purger_le_dossier", {
    p_enfant: String(formData.get("enfantId") ?? ""),
  });

  revalidatePath("/administration");
}
