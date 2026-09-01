"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type EtatHabilitation = { erreur?: string; succes?: string };

export async function demanderLHabilitation(
  _etatPrecedent: EtatHabilitation,
  formData: FormData,
): Promise<EtatHabilitation> {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Session expirée. Reconnectez-vous." };

  const { error } = await supabase.rpc("demander_l_habilitation", {
    p_fonction: String(formData.get("fonction") ?? "").trim(),
    p_organisation: String(formData.get("organisation") ?? "").trim(),
    p_numero: String(formData.get("numero") ?? "").trim(),
    p_motivation: String(formData.get("motivation") ?? "").trim(),
    p_directeur_nom: String(formData.get("directeurNom") ?? "").trim(),
    p_directeur_contact: String(formData.get("directeurContact") ?? "").trim(),
    p_etablissement_adresse: String(formData.get("etablissementAdresse") ?? "").trim(),
    p_uai: String(formData.get("uai") ?? "").trim(),
  });

  // Les messages de la fonction sont écrits pour être lus : « votre compte a
  // déjà cette habilitation », « indiquez votre fonction ». Les remplacer par un
  // générique ferait perdre la seule information utile.
  if (error) return { erreur: error.message };

  revalidatePath("/habilitation");
  return {
    succes:
      "Votre demande est enregistrée. L'administration l'instruira et vous serez prévenu de sa décision.",
  };
}
