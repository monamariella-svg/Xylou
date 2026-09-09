import type { SupabaseClient } from "@supabase/supabase-js";
import { demander } from "@/lib/ia";
import type { FormulairePreBilan } from "@/lib/pre-bilan";
import { assezDeQuestions, lireQuestions } from "./lecture";
import {
  messageDeGeneration,
  profilDeForme,
  SYSTEME,
  type RepereAGenerer,
} from "./prompt";

/**
 * Générer un bilan pour un enfant : une demande de la file (0077), un brouillon.
 *
 * ---------------------------------------------------------------------------
 * CE QUE CETTE FONCTION NE FAIT PAS
 *
 * Elle ne publie rien. Le bilan produit est un brouillon, `statut = 'en_cours'`,
 * sans validateur — la contrainte `bilan_valide_a_un_validateur` (0004) empêche
 * qu'il puisse être marqué validé sans que quelqu'un l'ait relu.
 *
 * Elle ne juge rien non plus : `maitrise` reste `non_evaluee` partout. Ce sont
 * les réponses de l'enfant qui produiront une mesure, pas la génération.
 * ---------------------------------------------------------------------------
 */

/** Les matières pour lesquelles un référentiel officiel est chargé (0075). */
const MATIERES_PAR_DEFAUT = ["francais", "maths"];

/**
 * Combien de repères, donc au moins autant de questions.
 *
 * Douze est un compromis assumé : assez pour couvrir plusieurs domaines,
 * assez peu pour tenir dans une séance qu'on peut interrompre. Le pré-bilan
 * dira, dans une prochaine version, s'il faut découper en plusieurs passages.
 */
const REPERES_PAR_BILAN = 12;

export type Demande = {
  id: string;
  enfant_id: string;
  classe_reference: string | null;
  matieres: string[];
  demande_par: string;
};

export type Resultat =
  | { ok: true; bilanId: string; questions: number; coutCentimes: number; rejets: string[] }
  | { ok: false; raison: string };

/**
 * Les repères à couvrir, du plus accessible au plus exigeant.
 *
 * L'ordre est le point délicat. On ne dispose d'aucune mesure de difficulté par
 * repère — l'Éducation nationale n'en publie pas. On approche donc par ce qu'on
 * a : un repère dont les questions officielles sont les mieux réussies passe en
 * premier, et un repère sans question publiée passe après ceux qui en ont,
 * puisqu'on saura moins bien comment le demander.
 *
 * C'est une approximation, et il faut le dire : la vraie montée en difficulté
 * viendra des repères des classes inférieures, quand leurs documents seront
 * chargés. En attendant, c'est le modèle qui commence en dessous de l'attendu,
 * sur consigne du prompt système.
 */
async function reperesDuBilan(
  supabase: SupabaseClient,
  classe: string,
  matieres: string[],
): Promise<RepereAGenerer[]> {
  const { data: domaines } = await supabase
    .from("domaines_evaluation")
    .select("id")
    .eq("classe", classe)
    .in("matiere_code", matieres);

  const ids = (domaines ?? []).map((d: { id: string }) => d.id);
  if (ids.length === 0) return [];

  const { data: reperes } = await supabase
    .from("reperes_competences")
    .select("id, matiere_code, domaine, libelle, ordre")
    .eq("source", "eduscol")
    .eq("actif", true)
    .in("domaine_evaluation_id", ids)
    .order("ordre");

  if (!reperes || reperes.length === 0) return [];

  const { data: items } = await supabase
    .from("items_evaluation_nationale")
    .select("repere_id, tache, reponse_attendue, erreurs_observees, structure, taux_reussite_national")
    .in("repere_id", reperes.map((r: { id: string }) => r.id));

  const parRepere = new Map<string, RepereAGenerer["items"]>();
  const tauxMoyen = new Map<string, number>();

  for (const i of items ?? []) {
    const liste = parRepere.get(i.repere_id) ?? [];
    liste.push({
      tache: i.tache,
      reponse_attendue: i.reponse_attendue,
      erreurs_observees: i.erreurs_observees ?? [],
      structure: i.structure ?? "",
    });
    parRepere.set(i.repere_id, liste);
    if (typeof i.taux_reussite_national === "number") {
      tauxMoyen.set(i.repere_id, i.taux_reussite_national);
    }
  }

  const classes = reperes.map((r) => ({
    id: r.id,
    matiere_code: r.matiere_code,
    domaine: r.domaine,
    libelle: r.libelle,
    items: parRepere.get(r.id) ?? [],
    ordre: r.ordre ?? 0,
    taux: tauxMoyen.get(r.id) ?? null,
  }));

  classes.sort((a, b) => {
    const aDesItems = a.items.length > 0 ? 0 : 1;
    const bDesItems = b.items.length > 0 ? 0 : 1;
    if (aDesItems !== bDesItems) return aDesItems - bDesItems;
    // Le mieux réussi d'abord : l'enfant commence par des questions qu'il a
    // des chances de réussir, ce qui est tout l'objet de l'ordre.
    if (a.taux !== null && b.taux !== null) return b.taux - a.taux;
    if (a.taux !== null) return -1;
    if (b.taux !== null) return 1;
    return a.ordre - b.ordre;
  });

  return classes
    .slice(0, REPERES_PAR_BILAN)
    .map((r) => ({
      id: r.id,
      matiere_code: r.matiere_code,
      domaine: r.domaine,
      libelle: r.libelle,
      items: r.items,
    }));
}

/** Le pré-bilan le plus récent qui soit complet, réduit à des consignes de forme. */
async function formeDesQuestions(supabase: SupabaseClient, enfantId: string) {
  const { data: observation } = await supabase
    .from("observations_capacites")
    .select("id, questionnaire_id, synthese")
    .eq("enfant_id", enfantId)
    .eq("statut", "complete")
    .order("rempli_le", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!observation) return null;

  const [{ data: questionnaire }, { data: reponses }] = await Promise.all([
    supabase
      .from("questionnaires_capacites")
      .select("contenu")
      .eq("id", observation.questionnaire_id)
      .single(),
    supabase
      .from("observations_reponses")
      .select("item_code, valeur")
      .eq("observation_id", observation.id),
  ]);

  if (!questionnaire) return null;

  const valeurs: Record<string, number | null> = {};
  for (const r of reponses ?? []) valeurs[r.item_code] = r.valeur;

  return profilDeForme(
    questionnaire.contenu as FormulairePreBilan,
    valeurs,
    (observation.synthese ?? {}) as Record<string, string>,
  );
}

export async function genererUnBilan(
  supabase: SupabaseClient,
  demande: Demande,
): Promise<Resultat> {
  const matieres = demande.matieres.length > 0 ? demande.matieres : MATIERES_PAR_DEFAUT;

  // La classe sert à choisir les domaines à explorer — une carte, pas un
  // niveau de départ. Sans elle on ne sait pas quoi explorer, et c'est le seul
  // usage pour lequel elle est légitime.
  if (!demande.classe_reference) {
    return { ok: false, raison: "aucune classe de référence : impossible de choisir les domaines à explorer" };
  }

  const profil = await formeDesQuestions(supabase, demande.enfant_id);
  if (!profil) {
    return { ok: false, raison: "aucun pré-bilan complet pour cet enfant" };
  }

  const reperes = await reperesDuBilan(supabase, demande.classe_reference, matieres);
  if (reperes.length === 0) {
    return {
      ok: false,
      raison: `aucun repère officiel chargé pour la classe ${demande.classe_reference}`,
    };
  }

  const reponse = await demander({
    operation: "bilan_questions",
    tache: "capable",
    systeme: SYSTEME,
    message: messageDeGeneration({
      reperes,
      profil,
      nombreDeQuestions: reperes.length,
    }),
    enfantId: demande.enfant_id,
    declenchePar: demande.demande_par,
  });

  if (!reponse.ok) return { ok: false, raison: reponse.message };

  const { questions, rejets } = lireQuestions(
    reponse.texte,
    reperes.map((r) => r.id),
  );

  if (!assezDeQuestions(questions.length, reperes.length)) {
    return {
      ok: false,
      raison: `${questions.length} question(s) exploitable(s) sur ${reperes.length} demandées — ${rejets.slice(0, 3).join(" ; ")}`,
    };
  }

  const { data: bilan, error: erreurBilan } = await supabase
    .from("bilans_positionnement")
    .insert({
      enfant_id: demande.enfant_id,
      statut: "en_cours",
      classe_reference: demande.classe_reference,
      matieres,
      modele_ia: reponse.modele,
      cree_par: demande.demande_par,
    })
    .select("id")
    .single();

  if (erreurBilan || !bilan) {
    return { ok: false, raison: erreurBilan?.message ?? "le bilan n'a pas pu être créé" };
  }

  const { error: erreurQuestions } = await supabase.from("bilan_questions").insert(
    questions.map((q, index) => ({
      bilan_id: bilan.id,
      repere_id: q.repereId,
      ordre: index + 1,
      enonce: q.enonce,
      type_reponse: q.typeReponse,
      contenu: { propositions: q.propositions },
      // La correction ne part pas au navigateur : c'est le serveur qui compare.
      correction: {
        reponse: q.reponse,
        critere_de_reussite: q.critereDeReussite,
        pourquoi_les_autres: q.pourquoiLesAutres,
      },
      genere_par_ia: true,
      modele_ia: reponse.modele,
    })),
  );

  if (erreurQuestions) {
    // Un bilan sans question est pire qu'aucun bilan : il occupe l'unique place
    // ouverte de l'enfant et bloquerait la génération suivante.
    await supabase.from("bilans_positionnement").delete().eq("id", bilan.id);
    return { ok: false, raison: erreurQuestions.message };
  }

  return {
    ok: true,
    bilanId: bilan.id,
    questions: questions.length,
    coutCentimes: reponse.coutCentimes,
    rejets,
  };
}
