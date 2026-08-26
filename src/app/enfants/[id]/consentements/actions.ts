"use server";

import { headers } from "next/headers";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { TypeConsentement } from "@/lib/consentements";

export type EtatSignature = { erreur?: string; succes?: string };

export async function signerLesConsentements(
  _etatPrecedent: EtatSignature,
  formData: FormData,
): Promise<EtatSignature> {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Session expirée. Reconnectez-vous." };

  const enfantId = String(formData.get("enfantId") ?? "");
  const signature = String(formData.get("signature") ?? "").trim();

  if (!enfantId) return { erreur: "Dossier introuvable." };

  if (signature.length < 2) {
    return { erreur: "Saisissez votre nom pour signer." };
  }

  // Chaque texte arrive sous la forme `choix_<type>` valant « accepte » ou
  // « refuse ». On sépare en deux listes plutôt que d'envoyer un seul tableau :
  // la base enregistre les refus au même titre que les acceptations, faute de
  // quoi « il a refusé » serait indiscernable de « on ne lui a jamais demandé ».
  const acceptes: TypeConsentement[] = [];
  const refuses: TypeConsentement[] = [];

  for (const [cle, valeur] of formData.entries()) {
    if (!cle.startsWith("choix_")) continue;
    const type = cle.slice("choix_".length) as TypeConsentement;
    if (valeur === "accepte") acceptes.push(type);
    else if (valeur === "refuse") refuses.push(type);
  }

  if (acceptes.length === 0 && refuses.length === 0) {
    return { erreur: "Indiquez votre choix pour chaque texte." };
  }

  // L'adresse et le navigateur accompagnent la signature : ce sont eux qui
  // rendent le geste attribuable, avec le nom saisi et l'horodatage.
  const entetes = await headers();
  const adresse =
    entetes.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    entetes.get("x-real-ip") ||
    null;

  const { error } = await supabase.rpc("signer_les_consentements", {
    p_enfant: enfantId,
    p_types: acceptes,
    p_signature: signature,
    p_refuses: refuses,
    p_ip: adresse,
    p_agent: entetes.get("user-agent") ?? "",
  });

  if (error) {
    // Les messages de la base sont écrits pour être lus par la personne — un
    // consentement obligatoire refusé, une signature trop courte. On les
    // remonte tels quels plutôt que de les remplacer par un générique.
    return { erreur: error.message };
  }

  revalidatePath(`/enfants/${enfantId}/consentements`);
  revalidatePath(`/enfants/${enfantId}`);
  return { succes: "Vos choix sont enregistrés." };
}
