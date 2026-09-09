/** Les valeurs de `type_reponse` (migration 0004) que la génération produit. */
export type TypeReponse = "qcm" | "texte" | "numerique" | "oui_non";

/** Les valeurs de `statut_generation` (migration 0077). */
export type StatutGeneration =
  | "en_attente"
  | "en_cours"
  | "terminee"
  | "echec"
  | "annulee";
