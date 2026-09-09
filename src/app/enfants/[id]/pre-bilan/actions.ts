"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { FormulairePreBilan } from "@/lib/pre-bilan";
import { nomChampItem, nomChampNote, nomChampSynthese } from "@/lib/pre-bilan";

export type EtatPreBilan = { erreur?: string; succes?: string };

/**
 * Ouvrir un pré-bilan pour cet enfant, avec le formulaire courant.
 *
 * Le formulaire est figé à l'ouverture, pas à l'enregistrement : si une
 * nouvelle version paraît pendant qu'on remplit, les réponses déjà saisies
 * continuent de correspondre aux questions qui étaient posées.
 */
export async function ouvrirPreBilan(formData: FormData) {
  const enfantId = String(formData.get("enfantId") ?? "");
  if (!enfantId) return;

  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return;

  const { data: questionnaire } = await supabase
    .from("questionnaires_capacites")
    .select("id")
    .eq("courant", true)
    .maybeSingle();

  if (!questionnaire) return;

  // Le rôle est recopié : quelqu'un peut quitter l'équipe ou changer de
  // fonction, et « qui a observé ça » doit rester lisible ensuite.
  const { data: lien } = await supabase
    .from("intervenants_enfant")
    .select("role")
    .eq("enfant_id", enfantId)
    .eq("profil_id", auth.user.id)
    .is("retire_le", null)
    .maybeSingle();

  const { data: observation } = await supabase
    .from("observations_capacites")
    .insert({
      enfant_id: enfantId,
      questionnaire_id: questionnaire.id,
      rempli_par: auth.user.id,
      role_au_moment: lien?.role ?? null,
    })
    .select("id")
    .maybeSingle();

  if (!observation) return;

  redirect(`/enfants/${enfantId}/pre-bilan/${observation.id}`);
}

/**
 * Enregistrer les réponses.
 *
 * Deux boutons mènent ici : « Enregistrer » laisse en brouillon, « Terminer »
 * marque complet. Le brouillon n'est pas un détail de confort — 72 questions ne
 * se remplissent pas d'une traite, et une personne obligée d'aller au bout d'un
 * coup répondra au hasard vers la fin.
 */
export async function enregistrerPreBilan(
  _etatPrecedent: EtatPreBilan,
  formData: FormData,
): Promise<EtatPreBilan> {
  const observationId = String(formData.get("observationId") ?? "");
  const enfantId = String(formData.get("enfantId") ?? "");
  const terminer = formData.get("terminer") === "1";
  if (!observationId || !enfantId) return { erreur: "Pré-bilan introuvable." };

  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { erreur: "Session expirée. Reconnectez-vous." };

  // La liste des items vient du formulaire figé à l'ouverture, jamais du POST :
  // un champ absent du formulaire envoyé est indiscernable d'un champ décoché,
  // et prendre le navigateur pour source laisserait un client décider quelles
  // questions existent.
  const { data: observation } = await supabase
    .from("observations_capacites")
    .select("id, questionnaires_capacites(contenu)")
    .eq("id", observationId)
    .maybeSingle();

  const brut = observation as unknown as {
    questionnaires_capacites: { contenu: FormulairePreBilan } | { contenu: FormulairePreBilan }[];
  } | null;

  if (!brut) return { erreur: "Pré-bilan introuvable." };

  const lien = Array.isArray(brut.questionnaires_capacites)
    ? brut.questionnaires_capacites[0]
    : brut.questionnaires_capacites;
  const formulaire = lien?.contenu;
  if (!formulaire) return { erreur: "Formulaire introuvable." };

  const lignes: {
    observation_id: string;
    item_code: string;
    valeur: number | null;
    note: string;
  }[] = [];

  for (const domaine of formulaire.domains) {
    for (const item of domaine.items) {
      const brute = String(formData.get(nomChampItem(item.id)) ?? "");
      // Vide = « pas encore observé », et c'est une réponse. On l'enregistre
      // comme absence de valeur, jamais comme zéro : « on ne l'a pas vu faire »
      // et « il ne le fait jamais » ne disent pas la même chose, et c'est sur
      // cette différence que le bilan sera calibré.
      const valeur = brute === "" ? null : Number(brute);
      if (valeur !== null && (!Number.isInteger(valeur) || valeur < 0 || valeur > 3)) {
        return { erreur: "Une réponse est hors de l'échelle attendue." };
      }

      const note = item.note_field
        ? String(formData.get(nomChampNote(item.id)) ?? "").trim()
        : "";

      if (valeur !== null || note) {
        lignes.push({ observation_id: observationId, item_code: item.id, valeur, note });
      }
    }
  }

  const synthese: Record<string, string> = {};
  for (const champ of formulaire.synthesis_fields) {
    const texte = String(formData.get(nomChampSynthese(champ.id)) ?? "").trim();
    if (texte) synthese[champ.id] = texte;
  }

  if (lignes.length > 0) {
    const { error } = await supabase
      .from("observations_reponses")
      .upsert(lignes, { onConflict: "observation_id,item_code" });
    if (error) return { erreur: error.message };
  }

  const { error: erreurEntete } = await supabase
    .from("observations_capacites")
    .update({ synthese, statut: terminer ? "complete" : "brouillon" })
    .eq("id", observationId);

  if (erreurEntete) return { erreur: erreurEntete.message };

  revalidatePath(`/enfants/${enfantId}/pre-bilan`);

  return {
    succes: terminer
      ? "Pré-bilan terminé. Il reste modifiable."
      : "Enregistré. Vous pouvez reprendre plus tard.",
  };
}
