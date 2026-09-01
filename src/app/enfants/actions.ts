"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  CLES_LEXIQUE,
  NIVEAUX_CLASSE,
  PROFILS_COMMUNICATION,
  UNIVERS_MOTEUR,
  type NiveauClasse,
  type ProfilCommunication,
  type UniversMoteur,
} from "@/lib/domaine";
export type EtatFormulaire = { erreur?: string; succes?: string };

async function utilisateurCourant() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getUser();
  return { supabase, utilisateur: data.user };
}

function lireEnum<T extends string>(
  valeur: FormDataEntryValue | null,
  valeurs: readonly T[],
): T | null {
  const texte = String(valeur ?? "");
  return (valeurs as readonly string[]).includes(texte) ? (texte as T) : null;
}

// ------------------------------------------------------------- création

export async function creerUnEnfant(
  _etatPrecedent: EtatFormulaire,
  formData: FormData,
): Promise<EtatFormulaire> {
  const { supabase, utilisateur } = await utilisateurCourant();
  if (!utilisateur) return { erreur: "Session expirée. Reconnectez-vous." };

  const prenom = String(formData.get("prenom") ?? "").trim();
  if (!prenom) return { erreur: "Le prénom est nécessaire." };
  const nom = String(formData.get("nom") ?? "").trim();

  const classe = lireEnum<NiveauClasse>(formData.get("classe"), NIVEAUX_CLASSE);

  // Ni date de naissance ni profil de communication ici. Le référent ouvre le
  // dossier avant que la famille l'ait rejoint : les lui demander maintenant,
  // c'est lui demander de supposer — et une supposition enregistrée ne se
  // distingue plus d'un fait. La colonne `communication` a un défaut en base
  // ('verbal', migration 0001) ; on le laisse s'appliquer plutôt que d'écrire
  // la même valeur en la faisant passer pour un choix.

  // Combien de personnes détiennent l'autorité parentale. Deux par défaut, et
  // le défaut compte : à un, l'oubli laisserait un parent valider seul un
  // objectif en garde alternée, sans que personne ne s'en aperçoive. À deux,
  // l'oubli bloque et se corrige. Voir la migration 0025.
  const titulairesBruts = Number(formData.get("titulaires") ?? 2);
  const titulaires = titulairesBruts === 1 ? 1 : 2;

  const { data: enfant, error: erreurEnfant } = await supabase
    .from("enfants")
    .insert({
      prenom,
      nom,
      classe,
      titulaires_autorite_parentale: titulaires,
      cree_par: utilisateur.id,
    })
    .select("id")
    .single();

  if (erreurEnfant || !enfant) {
    // Depuis 0026, seuls un référent habilité et l'administration peuvent
    // ouvrir un dossier. C'est la cause la plus probable d'un refus ici, et la
    // seule sur laquelle la personne peut agir.
    return {
      erreur:
        "Le dossier n'a pas pu être ouvert. L'ouverture d'un dossier est réservée aux référents habilités — demandez votre habilitation si ce n'est pas encore fait.",
    };
  }

  // L'ordre compte, et il est imposé par les politiques RLS : tant que la ligne
  // d'intervenant n'existe pas, le créateur n'a sur ce dossier que le droit que
  // lui donne `cree_par`, et rien de plus.
  //
  // Il se rattache comme *référent* et non comme parent : c'est lui qui suit
  // l'enfant, établit qui détient l'autorité parentale, et invitera la famille.
  // Le trigger de 0055 en fait automatiquement le référent principal.
  const { error: erreurRole } = await supabase.from("intervenants_enfant").insert({
    enfant_id: enfant.id,
    profil_id: utilisateur.id,
    role: "referent",
  });

  if (erreurRole) {
    // Le dossier existe mais personne n'y a accès : on le retire plutôt que de
    // laisser une ligne orpheline que même son créateur ne pourrait plus gérer.
    await supabase.from("enfants").delete().eq("id", enfant.id);
    return { erreur: "Le dossier n'a pas pu être ouvert. Réessayez dans un instant." };
  }

  // Ni ligne de santé, ni consentement ici. Les deux viendront après : depuis
  // 0051, écrire une donnée de santé exige un consentement actif, et celui-ci
  // se signe par chaque titulaire une fois qu'il a rejoint le dossier. Les
  // créer à vide échouerait, et les créer avant d'avoir demandé serait
  // précisément ce que le consentement doit empêcher.

  await supabase.from("journal_acces").insert({
    enfant_id: enfant.id,
    profil_id: utilisateur.id,
    action: "ouverture_dossier",
    table_cible: "enfants",
    ligne_id: enfant.id,
    detail: { titulaires_autorite_parentale: titulaires },
  });

  // Vers l'équipe, pas vers la fiche. L'ordre n'est pas cosmétique : presque
  // tout ce que la fiche demande — la date de naissance, le mode de
  // communication, les centres d'intérêt, les aménagements — appartient à la
  // famille. Ouvrir sur un formulaire que le référent ne peut pas remplir
  // l'invite à le remplir quand même.
  redirect(`/enfants/${enfant.id}/equipe`);
}

// --------------------------------------------------------------- fiche

export async function majFicheEnfant(
  _etatPrecedent: EtatFormulaire,
  formData: FormData,
): Promise<EtatFormulaire> {
  const { supabase, utilisateur } = await utilisateurCourant();
  if (!utilisateur) return { erreur: "Session expirée. Reconnectez-vous." };

  const enfantId = String(formData.get("enfantId") ?? "");
  const prenom = String(formData.get("prenom") ?? "").trim();
  if (!enfantId || !prenom) return { erreur: "Le prénom est nécessaire." };

  const { error } = await supabase
    .from("enfants")
    .update({
      prenom,
      nom: String(formData.get("nom") ?? "").trim(),
      classe: lireEnum<NiveauClasse>(formData.get("classe"), NIVEAUX_CLASSE),
      communication:
        lireEnum<ProfilCommunication>(
          formData.get("communication"),
          PROFILS_COMMUNICATION,
        ) ?? "verbal",
      date_naissance: String(formData.get("dateNaissance") ?? "").trim() || null,
    })
    .eq("id", enfantId);

  if (error) return { erreur: "L'enregistrement a échoué." };

  revalidatePath(`/enfants/${enfantId}`);
  return { succes: "Fiche enregistrée." };
}

export async function majSante(
  _etatPrecedent: EtatFormulaire,
  formData: FormData,
): Promise<EtatFormulaire> {
  const { supabase, utilisateur } = await utilisateurCourant();
  if (!utilisateur) return { erreur: "Session expirée. Reconnectez-vous." };

  const enfantId = String(formData.get("enfantId") ?? "");
  if (!enfantId) return { erreur: "Fiche introuvable." };

  // upsert plutôt qu'update : la ligne n'existe pas tant que personne n'a rien
  // saisi — depuis 0051, on ne peut plus la créer à vide à l'ouverture du
  // dossier, faute de consentement.
  const { error } = await supabase.from("enfants_sante").upsert({
    enfant_id: enfantId,
    besoins_particuliers: String(formData.get("besoins") ?? "").trim(),
    amenagements: String(formData.get("amenagements") ?? "").trim(),
    suivis_exterieurs: String(formData.get("suivis") ?? "").trim(),
  });

  if (error) {
    // La cause la plus fréquente n'est pas une panne : c'est l'absence de
    // consentement au traitement des données de santé, exigé depuis 0051 et
    // signé par *tous* les titulaires. Un message générique enverrait chercher
    // un bug là où il n'y a qu'une étape non faite.
    return {
      erreur:
        "L'enregistrement a échoué. Les informations de santé ne peuvent être saisies qu'une fois l'autorisation correspondante signée par tous les titulaires de l'autorité parentale.",
    };
  }

  await supabase.from("journal_acces").insert({
    enfant_id: enfantId,
    profil_id: utilisateur.id,
    action: "modification_sante",
    table_cible: "enfants_sante",
  });

  revalidatePath(`/enfants/${enfantId}`);
  return { succes: "Enregistré." };
}

// ---------------------------------------------------- centres d'intérêt

export async function ajouterCentreInteret(
  _etatPrecedent: EtatFormulaire,
  formData: FormData,
): Promise<EtatFormulaire> {
  const { supabase } = await utilisateurCourant();

  const enfantId = String(formData.get("enfantId") ?? "");
  const libelle = String(formData.get("libelle") ?? "").trim();
  if (!enfantId || !libelle) return { erreur: "Indiquez un centre d'intérêt." };

  const intensiteBrute = Number(formData.get("intensite") ?? 3);
  const intensite = Number.isFinite(intensiteBrute)
    ? Math.min(5, Math.max(1, Math.round(intensiteBrute)))
    : 3;

  const { error } = await supabase.from("centres_interet").insert({
    enfant_id: enfantId,
    libelle,
    intensite,
    note: String(formData.get("note") ?? "").trim(),
  });

  if (error) return { erreur: "L'ajout a échoué." };

  revalidatePath(`/enfants/${enfantId}`);
  return { succes: `« ${libelle} » ajouté.` };
}

export async function supprimerCentreInteret(formData: FormData) {
  const { supabase } = await utilisateurCourant();
  const id = String(formData.get("id") ?? "");
  const enfantId = String(formData.get("enfantId") ?? "");
  if (!id) return;

  await supabase.from("centres_interet").delete().eq("id", id);
  revalidatePath(`/enfants/${enfantId}`);
}

// -------------------------------------------------------- projet moteur

export async function enregistrerProjetMoteur(
  _etatPrecedent: EtatFormulaire,
  formData: FormData,
): Promise<EtatFormulaire> {
  const { supabase, utilisateur } = await utilisateurCourant();
  if (!utilisateur) return { erreur: "Session expirée. Reconnectez-vous." };

  const enfantId = String(formData.get("enfantId") ?? "");
  const titre = String(formData.get("titre") ?? "").trim();
  if (!enfantId || !titre) return { erreur: "Donnez un titre au projet moteur." };

  const univers = lireEnum<UniversMoteur>(formData.get("univers"), UNIVERS_MOTEUR) ?? "autre";
  const description = String(formData.get("description") ?? "").trim();

  // Seules les clés connues sont retenues : le lexique part vers l'IA, il ne doit
  // pas pouvoir se transformer en champ libre non maîtrisé.
  const lexique: Record<string, string> = {};
  for (const cle of CLES_LEXIQUE) {
    const valeur = String(formData.get(`lexique_${cle}`) ?? "").trim();
    if (valeur) lexique[cle] = valeur;
  }

  const projetId = String(formData.get("projetId") ?? "");

  if (projetId) {
    const { error } = await supabase
      .from("projets_moteurs")
      .update({ titre, univers, description, lexique })
      .eq("id", projetId);
    if (error) return { erreur: "L'enregistrement a échoué." };
  } else {
    // L'index unique projets_moteurs_un_seul_actif impose de désactiver l'univers
    // en cours avant d'en ouvrir un autre.
    await supabase
      .from("projets_moteurs")
      .update({ actif: false })
      .eq("enfant_id", enfantId)
      .eq("actif", true);

    const { error } = await supabase.from("projets_moteurs").insert({
      enfant_id: enfantId,
      titre,
      univers,
      description,
      lexique,
      actif: true,
      cree_par: utilisateur.id,
    });
    if (error) return { erreur: "L'enregistrement a échoué." };
  }

  revalidatePath(`/enfants/${enfantId}`);
  return { succes: "Projet moteur enregistré." };
}
