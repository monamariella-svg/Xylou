"use server";

import { headers } from "next/headers";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type EtatInvitation = {
  erreur?: string;
  succes?: string;
  /**
   * Le lien, rendu au référent pour qu'il le transmette lui-même.
   *
   * Le service d'envoi existe désormais (0059, puis 0068 pour la promptitude) :
   * rien n'empêcherait techniquement d'expédier l'invitation d'ici. Ce qui
   * l'empêche est ailleurs.
   *
   * ------------------------------------------------------------------------
   * À LIRE AVANT DE FAIRE PARTIR CETTE INVITATION PAR COURRIEL
   *
   * Toutes les notifications sortantes vont aujourd'hui à des titulaires de
   * compte : la table `notifications` n'a de destinataire que parmi les
   * profils. C'est ce qui rend acceptable que le désabonnement passe par un
   * écran derrière une session — chacun peut l'atteindre.
   *
   * Une invitation romprait cela. Son destinataire n'a, par définition, pas
   * encore de compte : l'écran de préférences lui est inaccessible, et le seul
   * geste à sa portée pour ne plus rien recevoir serait de nous signaler comme
   * indésirable — ce qui abîme la réputation du domaine et finit par empêcher
   * les alertes de blocage d'arriver aux autres familles.
   *
   * Ce qu'il faut poser d'abord : un désabonnement sans session, par jeton
   * signé par destinataire, servant à la fois le lien du pied de page et
   * l'en-tête `List-Unsubscribe-Post` (un clic). Une demi-journée, sans
   * migration — un HMAC de l'identifiant de profil suffit.
   *
   * Voir docs/questions-juriste.md §9.3.
   * ------------------------------------------------------------------------
   */
  lien?: string;
};

const ROLES = ["parent", "referent", "enseignant", "accompagnant"] as const;
type Role = (typeof ROLES)[number];

export async function inviter(
  _etatPrecedent: EtatInvitation,
  formData: FormData,
): Promise<EtatInvitation> {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Session expirée. Reconnectez-vous." };

  const enfantId = String(formData.get("enfantId") ?? "");
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const roleBrut = String(formData.get("role") ?? "");
  const role = (ROLES as readonly string[]).includes(roleBrut) ? (roleBrut as Role) : null;

  if (!enfantId || !email || !role) {
    return { erreur: "Indiquez une adresse et un rôle." };
  }

  const toutesMatieres = formData.get("toutesMatieres") === "oui";
  const matieres = formData.getAll("matieres").map(String).filter(Boolean);

  // 0036 et 0053 : un enseignant couvre au moins une matière, ou toutes. Le
  // vérifier ici évite un aller-retour pour une erreur que le formulaire
  // connaît déjà.
  if (role === "enseignant" && !toutesMatieres && matieres.length === 0) {
    return {
      erreur:
        "Un enseignant couvre au moins une matière. Cochez celles qu'il enseigne, ou « toutes les matières » pour un professeur des écoles.",
    };
  }

  const { data, error } = await supabase
    .from("invitations")
    .insert({
      enfant_id: enfantId,
      email,
      role,
      fonction: String(formData.get("fonction") ?? "").trim(),
      matieres: role === "enseignant" ? matieres : [],
      toutes_matieres: role === "enseignant" && toutesMatieres,
      invite_par: auth.user.id,
    })
    .select("jeton")
    .single();

  if (error || !data) {
    // Le refus le plus probable vient de 0025 : inviter quelqu'un en qualité de
    // parent revient à établir l'autorité parentale, et cela n'appartient qu'au
    // référent. Le dire plutôt que de renvoyer un échec muet.
    return {
      erreur:
        role === "parent"
          ? "L'invitation n'a pas pu être créée. Inviter un titulaire de l'autorité parentale est réservé au référent du dossier."
          : "L'invitation n'a pas pu être créée. Vérifiez que vous avez les droits sur ce dossier.",
    };
  }

  const entetes = await headers();
  const hote = entetes.get("x-forwarded-host") ?? entetes.get("host") ?? "";
  const protocole = entetes.get("x-forwarded-proto") ?? "https";

  revalidatePath(`/enfants/${enfantId}/equipe`);

  return {
    succes: `Invitation créée pour ${email}.`,
    lien: `${protocole}://${hote}/invitation/${data.jeton}`,
  };
}

/**
 * Corriger l'adresse d'une invitation en attente.
 *
 * On n'écrit pas la nouvelle adresse sur la ligne existante. Le premier lien
 * est parti quelque part — dans la mauvaise boîte, justement — et modifier
 * l'adresse enregistrée sans toucher au jeton laisserait ce lien-là valable :
 * la personne qui l'a reçu par erreur entrerait dans le dossier, et l'écran
 * afficherait la bonne adresse pendant ce temps.
 *
 * L'ancienne invitation est donc annulée et une nouvelle émise, avec le même
 * rôle et les mêmes matières pour ne rien faire ressaisir. Le jeton précédent
 * meurt avec elle.
 */
export async function corrigerAdresse(
  _etatPrecedent: EtatInvitation,
  formData: FormData,
): Promise<EtatInvitation> {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Session expirée. Reconnectez-vous." };

  const id = String(formData.get("id") ?? "");
  const enfantId = String(formData.get("enfantId") ?? "");
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  if (!id || !enfantId || !email) return { erreur: "Indiquez la nouvelle adresse." };

  const { data: ancienne } = await supabase
    .from("invitations")
    .select("email, role, fonction, matieres, toutes_matieres, acceptee_le, annulee_le")
    .eq("id", id)
    .maybeSingle();

  if (!ancienne) return { erreur: "Invitation introuvable." };

  // Une invitation acceptée ne se corrige plus : la personne a un compte, et
  // son adresse lui appartient. La rediriger d'ici reviendrait à déplacer
  // l'accès de quelqu'un sans qu'il le sache.
  if (ancienne.acceptee_le) {
    return {
      erreur:
        "Cette invitation a déjà été acceptée. L'adresse est désormais celle d'un compte, et seule la personne concernée peut la modifier.",
    };
  }
  if (ancienne.annulee_le) return { erreur: "Cette invitation est déjà annulée." };
  if (ancienne.email === email) return { erreur: "C'est déjà l'adresse enregistrée." };

  const { data, error } = await supabase
    .from("invitations")
    .insert({
      enfant_id: enfantId,
      email,
      role: ancienne.role,
      fonction: ancienne.fonction ?? "",
      matieres: ancienne.matieres ?? [],
      toutes_matieres: ancienne.toutes_matieres ?? false,
      invite_par: auth.user.id,
    })
    .select("jeton")
    .single();

  if (error || !data) {
    return { erreur: "La nouvelle invitation n'a pas pu être créée. Vérifiez l'adresse." };
  }

  // Après, pas avant : si l'insertion échoue, l'invitation d'origine reste
  // debout et le lien déjà transmis continue de fonctionner. L'ordre inverse
  // laisserait le dossier sans aucune invitation valable.
  await supabase
    .from("invitations")
    .update({ annulee_le: new Date().toISOString() })
    .eq("id", id);

  const entetes = await headers();
  const hote = entetes.get("x-forwarded-host") ?? entetes.get("host") ?? "";
  const protocole = entetes.get("x-forwarded-proto") ?? "https";

  revalidatePath(`/enfants/${enfantId}/equipe`);

  return {
    succes: `Invitation réémise pour ${email}. L'ancien lien ne fonctionne plus.`,
    lien: `${protocole}://${hote}/invitation/${data.jeton}`,
  };
}

export async function annulerInvitation(formData: FormData) {
  const supabase = await createClient();
  const id = String(formData.get("id") ?? "");
  const enfantId = String(formData.get("enfantId") ?? "");
  if (!id) return;

  // Annulée et non supprimée : une invitation partie à la mauvaise adresse doit
  // rester lisible, sinon personne ne peut expliquer pourquoi quelqu'un a reçu
  // un lien vers le dossier d'un enfant.
  await supabase
    .from("invitations")
    .update({ annulee_le: new Date().toISOString() })
    .eq("id", id);

  revalidatePath(`/enfants/${enfantId}/equipe`);
}

export async function retirerDuDossier(formData: FormData) {
  const supabase = await createClient();
  const enfantId = String(formData.get("enfantId") ?? "");
  const profilId = String(formData.get("profilId") ?? "");
  const motif = String(formData.get("motif") ?? "").trim();
  if (!enfantId || !profilId) return;

  // Passe par la fonction de 0033 plutôt que par un update direct : elle refuse
  // de retirer un titulaire de l'autorité parentale, vérifie les droits, et
  // consigne le motif.
  await supabase.rpc("retirer_l_intervenant", {
    p_enfant: enfantId,
    p_profil: profilId,
    p_motif: motif,
  });

  revalidatePath(`/enfants/${enfantId}/equipe`);
}
