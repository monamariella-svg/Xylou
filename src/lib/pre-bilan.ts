/**
 * Le formulaire du pré-bilan, tel qu'il vit en base (migration 0069).
 *
 * Rien n'est codé en dur ici : la structure est lue depuis
 * `questionnaires_capacites.contenu`, ce qui permet d'ajouter ou de reformuler
 * un item sans redéploiement. Ce fichier ne décrit que la forme attendue de ce
 * jsonb, et les quelques règles de lecture qui en découlent.
 */

export type DirectionItem = "capacity" | "difficulty" | "need" | "descriptive";

export type ItemPreBilan = {
  id: string;
  label: string;
  direction: DirectionItem;
  weight?: number;
  note_field?: boolean;
  xylou_link?: string;
};

export type DomainePreBilan = {
  id: string;
  title: string;
  subtitle?: string;
  weight?: number;
  items: ItemPreBilan[];
};

export type ChampSynthese = {
  id: string;
  label: string;
  type: string;
};

export type FormulairePreBilan = {
  schema_version: string;
  title: string;
  description?: string;
  scale: { options: { value: number; label: string }[]; allow_not_observed?: boolean };
  domains: DomainePreBilan[];
  synthesis_fields: ChampSynthese[];
};

/**
 * Un domaine dont aucun item n'est `capacity` ni `difficulty` n'a pas de score
 * — et ne doit pas en afficher un. `sensoriel` et `environnement_amenagements`
 * sont dans ce cas : ils ne contiennent que des particularités neutres et des
 * besoins d'aménagement.
 *
 * Y montrer « 0 » se lirait comme un jugement sur l'enfant, alors que c'est
 * justement ce que la distinction `direction` existe pour empêcher. Ces
 * domaines se présentent comme du contexte.
 */
export function domaineSansScore(domaine: DomainePreBilan): boolean {
  return !domaine.items.some(
    (i) => i.direction === "capacity" || i.direction === "difficulty",
  );
}

/** Le nom affiché d'un domaine sans score, pour l'expliquer sans jargon. */
export const MENTION_SANS_SCORE =
  "Ce domaine décrit des particularités, pas des difficultés. Rien n'y est noté.";

/**
 * Ce que chaque direction veut dire, en clair, pour la personne qui remplit.
 * Le vocabulaire du fichier JSON est anglais et technique ; ces phrases-là sont
 * ce qu'on montre.
 */
export const AIDE_DIRECTION: Record<DirectionItem, string> = {
  capacity: "",
  difficulty: "",
  need: "Besoin d'aménagement — n'est pas noté.",
  descriptive: "Particularité — n'est pas notée.",
};

export function nomChampItem(itemId: string): string {
  return `item:${itemId}`;
}

export function nomChampNote(itemId: string): string {
  return `note:${itemId}`;
}

export function nomChampSynthese(champId: string): string {
  return `synthese:${champId}`;
}

/** Valeur d'un bouton radio signifiant « pas encore observé ». */
export const NON_OBSERVE = "";
