"use server";

import { headers } from "next/headers";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type EtatInvitation = {
  erreur?: string;
  succes?: string;
  /** Le lien à transmettre, faute de service d'envoi. */
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
