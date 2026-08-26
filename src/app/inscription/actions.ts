"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type EtatAuth = { erreur?: string };

export async function creerUnCompte(
  _etatPrecedent: EtatAuth,
  formData: FormData,
): Promise<EtatAuth> {
  const prenom = String(formData.get("prenom") ?? "").trim();
  const nom = String(formData.get("nom") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const motDePasse = String(formData.get("motDePasse") ?? "");

  if (!prenom || !email || !motDePasse) {
    return { erreur: "Prénom, email et mot de passe sont nécessaires." };
  }
  if (motDePasse.length < 8) {
    return { erreur: "Le mot de passe doit faire au moins 8 caractères." };
  }

  const supabase = await createClient();
  // `prenom` et `nom` transitent par les métadonnées : le trigger
  // creer_profil_a_l_inscription (migration 0001) les recopie dans `profils`.
  const { error } = await supabase.auth.signUp({
    email,
    password: motDePasse,
    options: { data: { prenom, nom } },
  });

  if (error) {
    if (error.message.toLowerCase().includes("already")) {
      return { erreur: "Un compte existe déjà avec cet email." };
    }
    return { erreur: "La création du compte a échoué. Réessayez dans un instant." };
  }

  redirect("/inscription/confirmez-votre-email");
}
