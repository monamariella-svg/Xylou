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

    // Le message de Supabase est remonté tel quel. C'est délibéré, et ça ne vaut
    // que pour l'inscription : la connexion, elle, reste volontairement muette
    // pour ne pas révéler quelles adresses ont un compte.
    //
    // À l'inscription, cette précaution n'a pas d'objet — le cas « un compte
    // existe déjà » est traité juste au-dessus et dit exactement cela. Le reste
    // relève de la configuration : quota d'envoi atteint, mot de passe refusé
    // par la politique du projet, trigger de création de profil en échec. Trois
    // causes qu'un message générique rend indiscernables, et qu'on ne peut
    // diagnostiquer qu'en lisant les journaux — ce qui suppose d'y avoir accès.
    return { erreur: `La création du compte a échoué : ${error.message}` };
  }

  redirect("/inscription/confirmez-votre-email");
}
