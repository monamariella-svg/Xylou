import type { TypeReponse } from "./types";

/**
 * Lire ce que le modèle a répondu, sans jamais lui faire confiance.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI UNE VALIDATION AUSSI STRICTE
 *
 * Une sortie de modèle est une chaîne de caractères, pas une structure. Elle
 * peut être tronquée, enrobée d'un bloc de code, contenir un `repere_id` inventé
 * ou un QCM dont la bonne réponse ne figure pas parmi les propositions.
 *
 * Rien de tout cela n'est une panne : c'est le fonctionnement normal d'un
 * modèle, et c'est à l'appelant de trier. Une question mal formée qui passerait
 * ici arriverait devant un enfant — un QCM sans bonne réponse, une consigne
 * coupée en deux. C'est le genre de défaut qu'on ne découvre qu'en séance.
 * ---------------------------------------------------------------------------
 */

export type QuestionGeneree = {
  repereId: string;
  enonce: string;
  typeReponse: TypeReponse;
  propositions: string[];
  reponse: string;
  pourquoiLesAutres: string[];
  critereDeReussite: string;
};

export type LectureQuestions = {
  questions: QuestionGeneree[];
  /** Ce qui a été écarté, et pourquoi. Journalisé, jamais silencieux. */
  rejets: string[];
};

const TYPES_ACCEPTES: TypeReponse[] = ["qcm", "numerique", "texte", "oui_non"];

/**
 * Le modèle enrobe parfois sa réponse dans un bloc de code malgré la consigne.
 * On le retire plutôt que d'échouer : la donnée est là, seule la présentation
 * diffère, et refuser coûterait une seconde facturation pour rien.
 */
function deballer(texte: string): string {
  const bloc = texte.match(/```(?:json)?\s*([\s\S]*?)```/);
  return (bloc ? bloc[1] : texte).trim();
}

function texteNonVide(valeur: unknown): string {
  return typeof valeur === "string" ? valeur.trim() : "";
}

function listeDeTextes(valeur: unknown): string[] {
  return Array.isArray(valeur)
    ? valeur.map(texteNonVide).filter((v) => v !== "")
    : [];
}

export function lireQuestions(
  texte: string,
  reperesAttendus: string[],
): LectureQuestions {
  const rejets: string[] = [];
  const attendus = new Set(reperesAttendus);

  let brut: unknown;
  try {
    brut = JSON.parse(deballer(texte));
  } catch {
    return { questions: [], rejets: ["la réponse n'est pas du JSON lisible"] };
  }

  const liste = (brut as { questions?: unknown })?.questions;
  if (!Array.isArray(liste)) {
    return { questions: [], rejets: ["la réponse ne contient pas de liste `questions`"] };
  }

  const questions: QuestionGeneree[] = [];

  liste.forEach((element, index) => {
    const q = element as Record<string, unknown>;
    const rejeter = (raison: string) => rejets.push(`question ${index + 1} : ${raison}`);

    const repereId = texteNonVide(q.repere_id);
    if (!attendus.has(repereId)) {
      // Un repère qu'on n'a pas demandé rattacherait une question à un attendu
      // qu'elle ne mesure pas — et le bilan mentirait sur ce qu'il a mesuré.
      rejeter("le repère cité n'est pas de ceux qu'on a demandés");
      return;
    }

    const enonce = texteNonVide(q.enonce);
    if (enonce === "") {
      rejeter("énoncé vide");
      return;
    }

    const type = texteNonVide(q.type_reponse) as TypeReponse;
    if (!TYPES_ACCEPTES.includes(type)) {
      rejeter(`type de réponse inconnu (${type || "absent"})`);
      return;
    }

    const propositions = listeDeTextes(q.propositions);
    const reponse = texteNonVide(q.reponse);
    if (reponse === "") {
      rejeter("aucune réponse attendue");
      return;
    }

    if (type === "qcm") {
      if (propositions.length < 3) {
        // Deux propositions, c'est une question à cinquante pour cent de
        // réussite au hasard : on ne mesurerait pas grand-chose.
        rejeter("un QCM demande au moins trois propositions");
        return;
      }
      if (!propositions.includes(reponse)) {
        rejeter("la bonne réponse ne figure pas parmi les propositions");
        return;
      }
      if (new Set(propositions).size !== propositions.length) {
        rejeter("deux propositions identiques");
        return;
      }
    }

    questions.push({
      repereId,
      enonce,
      typeReponse: type,
      propositions,
      reponse,
      pourquoiLesAutres: listeDeTextes(q.pourquoi_les_autres),
      critereDeReussite: texteNonVide(q.critere_de_reussite),
    });
  });

  return { questions, rejets };
}

/**
 * Un bilan amputé n'est pas un bilan.
 *
 * Si le tri a écarté trop de questions, on préfère échouer et rejouer plutôt
 * que de déposer un brouillon qui ne couvre plus ce qu'on voulait mesurer. Le
 * référent relit ce qu'on lui donne ; il ne peut pas deviner ce qui manque.
 */
export const PART_MINIMALE_RETENUE = 0.7;

export function assezDeQuestions(retenues: number, demandees: number): boolean {
  return demandees > 0 && retenues / demandees >= PART_MINIMALE_RETENUE;
}
