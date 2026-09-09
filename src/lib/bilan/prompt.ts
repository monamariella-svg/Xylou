import type { FormulairePreBilan, ItemPreBilan } from "@/lib/pre-bilan";

/**
 * Ce qu'on dit au modèle pour qu'il écrive un bilan, et rien d'autre.
 *
 * ---------------------------------------------------------------------------
 * TROIS SOURCES, ET ELLES NE JOUENT PAS LE MÊME RÔLE
 *
 *   les **repères** disent *ce qu'on mesure* — les attendus officiels (0075) ;
 *   les **items publiés** disent *comment on le demande* et *quelles erreurs
 *   attendre* — les questions réelles de l'évaluation nationale (0076) ;
 *   le **pré-bilan** dit *comment poser la question à cet enfant-là* (0069).
 *
 * Les confondre est la faute qui produit un bilan générique. Le pré-bilan ne
 * dit rien de ce que l'enfant sait et n'entre jamais dans un résultat : il
 * règle la forme, pas le niveau.
 * ---------------------------------------------------------------------------
 */

export type RepereAGenerer = {
  id: string;
  matiere_code: string;
  domaine: string;
  libelle: string;
  items: {
    tache: string;
    reponse_attendue: string;
    erreurs_observees: string[];
    structure: string;
  }[];
};

export type ProfilDeForme = {
  /** Ce que l'enfant lit sans peine, et ce qui le met en difficulté. */
  appuis: string[];
  obstacles: string[];
  /** Aménagements demandés : temps, découpage, support. */
  amenagements: string[];
  /** Le récit libre du pré-bilan — souvent la réponse la plus utile. */
  recit: string;
};

export const SYSTEME = `Tu écris des questions de bilan scolaire pour Xylou, un
accompagnement destiné à des enfants à besoins particuliers, dont des enfants
autistes.

CE QUE TU MESURES
Tu reçois des repères officiels de l'Éducation nationale et, pour certains, les
questions réellement posées lors des évaluations nationales, avec l'analyse des
erreurs observées. Tu écris des questions *équivalentes*, pas des copies.

L'ORDRE DES QUESTIONS
Tu commences en dessous du niveau visé et tu montes. Les premières questions
doivent être des réussites : un enfant qui échoue d'emblée s'arrête, et on ne
mesure plus rien. Tu ne signales jamais cette progression dans les énoncés.

COMMENT TU ÉCRIS
Tu t'inspires de la méthode FALC, modulée par le profil qu'on te donne :
phrases courtes, une idée par phrase, mots courants, voix active. Ni figure de
style, ni sous-entendu, ni consigne à deux étages.

MAIS JAMAIS AU PRIX DE CE QU'ON MESURE. Cette règle vaut sans réserve pour les
consignes et les boutons. Elle ne vaut pour le contenu évalué que si la
compétence visée n'en dépend pas : simplifier le texte d'un exercice de
compréhension écrite ne le rend pas accessible, il supprime ce qu'il mesurait.

LES MAUVAISES RÉPONSES
Quand on te donne des erreurs observées, tes propositions fausses s'en
inspirent. Un QCM dont les mauvaises réponses sont absurdes ne mesure rien :
l'enfant élimine sans savoir.

CE QUE TU N'ÉCRIS JAMAIS
Aucune comparaison à une norme, à une classe, à d'autres enfants, à un âge.
Aucune mention du profil de l'enfant, de son diagnostic ou de ses difficultés
dans un énoncé. Aucun encouragement chiffré ni jugement de valeur.

TA RÉPONSE
Un objet JSON, et rien avant ni après. Pas de bloc de code, pas de commentaire.`;

/** Le format attendu, décrit une fois, et repris par la validation. */
export const FORMAT = `{
  "questions": [
    {
      "repere_id": "<l'identifiant fourni, recopié tel quel>",
      "enonce": "<la question, telle que l'enfant la lit>",
      "type_reponse": "qcm" | "numerique" | "texte" | "oui_non",
      "propositions": ["<pour un qcm : 3 ou 4 propositions>"],
      "reponse": "<la bonne réponse, identique à l'une des propositions pour un qcm>",
      "pourquoi_les_autres": ["<ce que révèle chaque mauvaise réponse>"],
      "critere_de_reussite": "<à quoi l'on reconnaît que c'est réussi>"
    }
  ]
}`;

function listeOuRien(titre: string, valeurs: string[]): string {
  const utiles = valeurs.filter((v) => v.trim() !== "");
  return utiles.length === 0 ? "" : `${titre}\n${utiles.map((v) => `- ${v}`).join("\n")}\n`;
}

/**
 * Le message, construit à partir des trois sources.
 *
 * Il ne contient ni le prénom de l'enfant, ni son diagnostic, ni rien qui
 * l'identifie. Le modèle n'en a pas besoin pour écrire une question, et ce qui
 * n'est pas envoyé ne peut pas fuir — §3.4.
 */
export function messageDeGeneration(args: {
  reperes: RepereAGenerer[];
  profil: ProfilDeForme;
  nombreDeQuestions: number;
}): string {
  const { reperes, profil, nombreDeQuestions } = args;

  const blocsReperes = reperes
    .map((r) => {
      const exemples = r.items
        .map((i, n) => {
          const erreurs = i.erreurs_observees.map((e) => `      · ${e}`).join("\n");
          return [
            `    Question officielle ${n + 1}`,
            `      Tâche : ${i.tache}`,
            `      Réponse attendue : ${i.reponse_attendue}`,
            i.structure ? `      Structure : ${i.structure}` : "",
            erreurs ? `      Erreurs observées :\n${erreurs}` : "",
          ]
            .filter(Boolean)
            .join("\n");
        })
        .join("\n");

      return [
        `- repere_id : ${r.id}`,
        `  matière : ${r.matiere_code}`,
        `  domaine : ${r.domaine}`,
        `  attendu : ${r.libelle}`,
        exemples || "    (aucune question officielle : appuie-toi sur l'attendu seul)",
      ].join("\n");
    })
    .join("\n\n");

  const forme = [
    listeOuRien("Ce sur quoi on peut s'appuyer :", profil.appuis),
    listeOuRien("Ce qui met en difficulté :", profil.obstacles),
    listeOuRien("Aménagements à respecter :", profil.amenagements),
    profil.recit.trim() ? `Ce que l'équipe rapporte :\n${profil.recit.trim()}\n` : "",
  ]
    .filter(Boolean)
    .join("\n");

  return `Écris ${nombreDeQuestions} questions de bilan.

REPÈRES À COUVRIR, dans cet ordre — du plus accessible au plus exigeant.
Une question par repère au minimum ; si tu en écris plusieurs pour un repère,
elles doivent mesurer la même chose autrement.

${blocsReperes}

COMMENT POSER LES QUESTIONS À CET ENFANT
${forme || "Aucune particularité rapportée : applique la forme par défaut."}

Ces indications règlent la *forme* des questions. Elles ne disent rien de ce
que l'enfant sait, et ne doivent jamais transparaître dans un énoncé.

RÉPONDS EXACTEMENT DANS CE FORMAT
${FORMAT}`;
}

/** Les items du pré-bilan qui se lisent comme une consigne de forme. */
export function profilDeForme(
  formulaire: FormulairePreBilan,
  reponses: Record<string, number | null>,
  synthese: Record<string, string>,
): ProfilDeForme {
  const appuis: string[] = [];
  const obstacles: string[] = [];
  const amenagements: string[] = [];

  const parcourir = (item: ItemPreBilan, valeur: number | null) => {
    // Non observé : on ne suppose rien. Un blanc n'est pas un zéro.
    if (valeur === null) return;

    // Un besoin ou une particularité ne se note pas — il se respecte.
    if (item.direction === "need" || item.direction === "descriptive") {
      if (valeur > 0) amenagements.push(item.label);
      return;
    }

    // L'échelle va du moins au plus. Les extrêmes seuls sont informatifs :
    // le milieu ne dit rien qu'on puisse traduire en consigne d'écriture.
    if (item.direction === "capacity" && valeur >= 3) appuis.push(item.label);
    if (item.direction === "difficulty" && valeur >= 3) obstacles.push(item.label);
    if (item.direction === "capacity" && valeur <= 1) obstacles.push(item.label);
  };

  for (const domaine of formulaire.domains) {
    for (const item of domaine.items) {
      parcourir(item, reponses[item.id] ?? null);
    }
  }

  return {
    appuis,
    obstacles,
    amenagements,
    recit: Object.values(synthese).filter(Boolean).join("\n\n"),
  };
}
