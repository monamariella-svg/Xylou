"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { EtatAuth } from "../inscription/actions";

export async function seConnecter(
  _etatPrecedent: EtatAuth,
  formData: FormData,
): Promise<EtatAuth> {
  const email = String(formData.get("email") ?? "").trim();
  const motDePasse = String(formData.get("motDePasse") ?? "");

  if (!email || !motDePasse) {
    return { erreur: "Email et mot de passe sont nécessaires." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({
    email,
    password: motDePasse,
  });

  // Message volontairement identique quel que soit le motif : distinguer
  // « compte inconnu » de « mot de passe faux » révélerait quels emails ont un
  // compte, sur un service qui traite des données de santé d'enfants.
  if (error) {
    return { erreur: "Email ou mot de passe incorrect." };
  }

  // Même renvoi qu'à l'inscription : quelqu'un qui suit un lien d'invitation
  // alors qu'il a déjà un compte passe par ici, et doit retrouver l'invitation
  // plutôt qu'un tableau de bord.
  const invitation = String(formData.get("invitation") ?? "").trim();
  if (invitation) {
    redirect(`/invitation/${invitation}`);
  }

  redirect("/tableau-de-bord");
}
