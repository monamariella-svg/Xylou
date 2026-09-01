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

  // Le jeton d'invitation traverse l'inscription. Sans ce renvoi, quelqu'un qui
  // suit un lien d'invitation sans compte s'inscrit, atterrit sur un tableau de
  // bord vide, et n'a plus aucun moyen de retrouver le lien — sinon en
  // retournant dans ses messages.
  const invitation = String(formData.get("invitation") ?? "").trim();
  if (invitation) {
    redirect(`/invitation/${invitation}`);
  }

  // La demande d'habilitation part dans la foulée, sur les champs du même
  // formulaire. C'est une seule déclaration — « je m'inscris, je veux être
  // référent pour tel établissement, voici de qui je le tiens » — et la couper
  // en deux obligerait la personne à retrouver où la poursuivre.
  //
  // Le compte reste « membre » : rien ici n'accorde de droit. Seule
  // l'administration transforme la demande en habilitation.
  if (String(formData.get("destination") ?? "") === "habilitation") {
    const { error: erreurDemande } = await supabase.rpc("demander_l_habilitation", {
      p_fonction: String(formData.get("fonction") ?? "").trim(),
      p_organisation: String(formData.get("organisation") ?? "").trim(),
      p_numero: String(formData.get("numero") ?? "").trim(),
      p_motivation: String(formData.get("motivation") ?? "").trim(),
      p_directeur_nom: String(formData.get("directeurNom") ?? "").trim(),
      p_directeur_contact: String(formData.get("directeurContact") ?? "").trim(),
      p_etablissement_adresse: String(formData.get("etablissementAdresse") ?? "").trim(),
    });

    // Qu'elle ait abouti ou non, on renvoie au même endroit — et c'est
    // volontaire. Le compte existe désormais : signaler un échec ici donnerait
    // à croire que l'inscription elle-même a raté. La page d'habilitation
    // représentera simplement le formulaire, prérempli de rien, et la personne
    // recommencera cette partie-là seulement.
    //
    // Le cas le plus probable n'est d'ailleurs pas une faute de saisie mais
    // l'absence de session : si la confirmation par courriel est active,
    // `signUp` ne connecte pas, et l'appel part sans utilisateur. La demande se
    // fera après la première connexion.
    void erreurDemande;

    redirect("/habilitation");
  }

  redirect("/inscription/confirmez-votre-email");
}
