import { createHash } from "crypto";
import Anthropic from "@anthropic-ai/sdk";
import { createServiceClient } from "@/lib/supabase/service";
import { coutCentimes, modelePour, tarifConnu, type Tache } from "./modeles";

/**
 * Le seul endroit d'où Xylou parle à un modèle.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI UN SEUL ENDROIT
 *
 * Trois obligations pèsent sur chaque appel, et aucune ne survit à sa
 * dispersion dans le code :
 *
 *   §3.4 — les données relèvent du handicap. Le contenu d'un prompt ne doit
 *   jamais atterrir dans un journal, d'où l'empreinte plutôt que le texte ;
 *
 *   §3.7 — le budget du pilote n'est tenable que mesuré, et on ne mesure pas
 *   ce qu'on n'enregistre pas ;
 *
 *   §3.2 — toute suggestion reste supervisée. Ce fichier ne valide rien : il
 *   rend une sortie brute, que l'appelant devra faire relire.
 *
 * Un appel écrit ailleurs échapperait aux trois d'un coup.
 * ---------------------------------------------------------------------------
 */

/** Les opérations de `operation_ia` (migration 0008). */
export type OperationIA =
  | "bilan_questions"
  | "bilan_evaluation"
  | "bilan_synthese"
  | "adaptation_visuelle"
  | "adaptation_mission"
  | "generation_mission"
  | "generation_exercices"
  | "bilan_trimestriel"
  | "interaction_courte";

export type DemandeIA = {
  operation: OperationIA;
  tache: Tache;
  systeme: string;
  message: string;
  /** Pour rattacher la dépense à un dossier. Nul pour un appel hors enfant. */
  enfantId?: string | null;
  /** Qui a déclenché. Le journal doit pouvoir dire qui a décidé quoi. */
  declenchePar?: string | null;
  jetonsMax?: number;
  effort?: "low" | "medium" | "high" | "xhigh" | "max";
};

export type ReponseIA =
  | { ok: true; texte: string; modele: string; coutCentimes: number }
  | { ok: false; raison: "non_configure" | "refus" | "erreur"; message: string };

export function iaConfiguree(): boolean {
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

/**
 * L'empreinte du prompt, jamais son contenu.
 *
 * Elle suffit à voir que deux appels ont porté sur la même entrée, donc à
 * diagnostiquer une régression de qualité. Elle ne permet pas de reconstituer
 * ce qui a été envoyé — ce qui est le but : un journal d'exploitation ne doit
 * pas devenir un second entrepôt de données de santé.
 */
function empreinte(systeme: string, message: string): string {
  return createHash("sha256").update(`${systeme}\n${message}`).digest("hex").slice(0, 32);
}

async function journaliser(ligne: Record<string, unknown>): Promise<void> {
  try {
    await createServiceClient().from("journal_ia").insert(ligne);
  } catch {
    // Un journal qui échoue ne doit pas faire échouer l'appel qu'il observe.
    // La perte est réelle — une ligne de budget manquante — mais moindre que
    // celle d'un bilan interrompu parce qu'on n'a pas pu écrire une trace.
  }
}

/**
 * Appelle le modèle et journalise. Ne lève pas : les échecs sont des réponses.
 *
 * Un appel IA rate pour des raisons ordinaires — quota, réseau, refus. Les
 * transformer en exceptions obligerait chaque écran à les rattraper, et le
 * premier qui l'oublierait afficherait une page d'erreur à une famille au
 * milieu d'un bilan.
 */
export async function demander(demande: DemandeIA): Promise<ReponseIA> {
  const cle = process.env.ANTHROPIC_API_KEY;

  // Sans clé, l'application reste utilisable en saisie manuelle — c'est la
  // promesse du fichier d'exemple, et elle vaut mieux qu'un écran cassé.
  if (!cle) {
    return {
      ok: false,
      raison: "non_configure",
      message: "La génération assistée n'est pas configurée sur cette instance.",
    };
  }

  const modele = modelePour(demande.tache);
  const debut = Date.now();
  const base = {
    enfant_id: demande.enfantId ?? null,
    operation: demande.operation,
    modele,
    empreinte_prompt: empreinte(demande.systeme, demande.message),
    declenche_par: demande.declenchePar ?? null,
  };

  try {
    const client = new Anthropic({ apiKey: cle });

    const reponse = await client.messages.create({
      model: modele,
      max_tokens: demande.jetonsMax ?? 16000,
      system: [
        // Le prompt système est la partie stable d'un appel à l'autre : le
        // mettre en cache est ce qui rend le budget du §3.7 atteignable, et
        // c'est la seule optimisation qui ne coûte rien en qualité.
        { type: "text", text: demande.systeme, cache_control: { type: "ephemeral" } },
      ],
      messages: [{ role: "user", content: demande.message }],
      output_config: { effort: demande.effort ?? "high" },
    });

    const usage = reponse.usage;
    const jetons = {
      entree: usage.input_tokens ?? 0,
      sortie: usage.output_tokens ?? 0,
      cacheLus: usage.cache_read_input_tokens ?? 0,
    };
    const cout = coutCentimes(modele, jetons);

    // Un refus arrive en HTTP 200 : lire `content` sans vérifier `stop_reason`
    // rendrait une chaîne vide en faisant croire à un succès.
    if (reponse.stop_reason === "refusal") {
      await journaliser({
        ...base,
        tokens_entree: jetons.entree,
        tokens_sortie: jetons.sortie,
        tokens_cache_lus: jetons.cacheLus,
        cout_centimes: cout,
        duree_ms: Date.now() - debut,
        succes: false,
        erreur: `refus : ${reponse.stop_details?.category ?? "sans catégorie"}`,
      });
      return {
        ok: false,
        raison: "refus",
        message: "Le modèle a refusé de traiter cette demande.",
      };
    }

    const texte = reponse.content
      .filter((bloc): bloc is Anthropic.TextBlock => bloc.type === "text")
      .map((bloc) => bloc.text)
      .join("\n")
      .trim();

    await journaliser({
      ...base,
      tokens_entree: jetons.entree,
      tokens_sortie: jetons.sortie,
      tokens_cache_lus: jetons.cacheLus,
      cout_centimes: cout,
      duree_ms: Date.now() - debut,
      succes: true,
      // Un tarif inconnu produit un coût nul : on le dit, sinon le budget
      // paraîtrait tenu alors qu'il n'est plus mesuré.
      erreur: tarifConnu(modele) ? "" : `tarif inconnu pour ${modele}, coût non calculé`,
    });

    return { ok: true, texte, modele, coutCentimes: cout };
  } catch (e) {
    const message =
      e instanceof Anthropic.RateLimitError
        ? "Trop de demandes en même temps. Réessayez dans un instant."
        : e instanceof Anthropic.AuthenticationError
          ? "La clé de génération est refusée."
          : e instanceof Anthropic.APIError
            ? `Erreur ${e.status} du service de génération.`
            : "Le service de génération est injoignable.";

    await journaliser({
      ...base,
      duree_ms: Date.now() - debut,
      succes: false,
      // Le détail technique dans le journal, une phrase lisible à l'écran.
      erreur: (e instanceof Error ? e.message : String(e)).slice(0, 500),
    });

    return { ok: false, raison: "erreur", message };
  }
}
