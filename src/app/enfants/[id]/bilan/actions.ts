"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type EtatGeneration = { erreur?: string; succes?: string };

/**
 * Déposer une demande de génération. Le bouton ne génère pas : il commande.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI CETTE ACTION NE PARLE PAS AU MODÈLE
 *
 * Une génération prend des dizaines de secondes. Une Server Action qui
 * l'attendrait serait coupée par la limite d'exécution, et le référent verrait
 * une erreur sans savoir si son bilan est parti ou non.
 *
 * L'action écrit donc une ligne dans la file (0077) et rend la main tout de
 * suite. La base sonne la route de traitement, qui travaille de son côté.
 * ---------------------------------------------------------------------------
 */
export async function demanderUnBilan(
  _etat: EtatGeneration,
  formData: FormData,
): Promise<EtatGeneration> {
  const enfantId = String(formData.get("enfantId") ?? "");
  if (!enfantId) return { erreur: "Enfant introuvable." };

  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Vous devez être connecté." };

  // La décision se prend en base, jamais ici : la règle qui autorise une
  // dépense sur des données de santé ne doit pas dépendre d'un écran qu'on
  // peut oublier de mettre à jour.
  const { data: raisons, error: erreurRaisons } = await supabase.rpc(
    "raisons_de_ne_pas_generer",
    { p_enfant: enfantId },
  );

  if (erreurRaisons) return { erreur: erreurRaisons.message };
  if (Array.isArray(raisons) && raisons.length > 0) {
    return { erreur: raisons.join(" ") };
  }

  const { data: enfant } = await supabase
    .from("enfants")
    .select("classe")
    .eq("id", enfantId)
    .maybeSingle();

  const { error } = await supabase.from("generations_bilan").insert({
    enfant_id: enfantId,
    demande_par: auth.user.id,
    // Recopiée : la classe peut changer entre la demande et le traitement.
    // Elle sert à choisir les domaines à explorer, jamais la difficulté.
    classe_reference: enfant?.classe ?? null,
    matieres: ["francais", "maths"],
  });

  if (error) {
    // L'index unique de 0077 tient même si deux clics passent la vérification
    // ci-dessus en même temps. Le message dit ce qui s'est passé plutôt que de
    // laisser remonter une contrainte Postgres.
    if (error.code === "23505") {
      return { erreur: "Une génération est déjà en cours pour cet enfant." };
    }
    return { erreur: error.message };
  }

  revalidatePath(`/enfants/${enfantId}/bilan`);
  return { succes: "Demande enregistrée. Le bilan se prépare." };
}

/** Renoncer avant que le traitement ne parte. Rien n'a été facturé. */
export async function annulerLaDemande(formData: FormData) {
  const enfantId = String(formData.get("enfantId") ?? "");
  const demandeId = String(formData.get("demandeId") ?? "");
  if (!enfantId || !demandeId) return;

  const supabase = await createClient();

  // `en_attente` seulement : une génération commencée est déjà payée, et
  // l'annuler laisserait un bilan orphelin.
  await supabase
    .from("generations_bilan")
    .update({ statut: "annulee", terminee_le: new Date().toISOString() })
    .eq("id", demandeId)
    .eq("statut", "en_attente");

  revalidatePath(`/enfants/${enfantId}/bilan`);
}
