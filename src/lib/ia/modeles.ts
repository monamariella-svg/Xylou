/**
 * Quel modèle pour quelle tâche, et ce que ça coûte.
 *
 * Le §3.7 du dossier projet pose une approche hybride : un modèle économique
 * pour ce qui est fréquent et peu critique, un modèle capable pour ce qui
 * demande du jugement. Le budget de la classe pilote — 400 à 2 000 € pour douze
 * enfants sur un an — n'est tenable que si ce partage est tenu.
 */

/**
 * Les identifiants sont complets tels quels. On n'y ajoute jamais de suffixe de
 * date : `claude-haiku-4-5`, jamais `claude-haiku-4-5-20251001`.
 */
export const MODELE_RAPIDE_DEFAUT = "claude-haiku-4-5";
export const MODELE_CAPABLE_DEFAUT = "claude-opus-5";

/**
 * Tarifs en dollars par million de jetons, à la date d'écriture.
 *
 * Recopiés ici parce qu'il faut bien calculer un coût quelque part, mais ce
 * sont des prix : ils changent sans prévenir, et un chiffre faux ici produit un
 * budget faux sans que rien ne le signale. À revérifier avant la mise en
 * production, comme le §3.7 le demande déjà.
 */
const TARIFS: Record<string, { entree: number; sortie: number }> = {
  "claude-opus-5": { entree: 5, sortie: 25 },
  "claude-sonnet-5": { entree: 2, sortie: 10 },
  "claude-haiku-4-5": { entree: 1, sortie: 5 },
};

// Un dollar vaut à peu près un euro à ± 15 % près, et `journal_ia.cout_centimes`
// veut des centimes. On ne convertit pas : mélanger un taux de change dans un
// suivi de budget rendrait deux mois incomparables. Ce sont donc des centimes
// de dollar, et la colonne le dit ici plutôt que dans une note perdue.
const CENTIMES_PAR_JETON_MILLION = 100;

export type Tache = "rapide" | "capable";

export function modelePour(tache: Tache): string {
  const configure =
    tache === "rapide"
      ? process.env.XYLOU_MODELE_RAPIDE
      : process.env.XYLOU_MODELE_CAPABLE;

  return (
    configure?.trim() ||
    (tache === "rapide" ? MODELE_RAPIDE_DEFAUT : MODELE_CAPABLE_DEFAUT)
  );
}

/**
 * Le coût d'un appel, en centimes.
 *
 * Les jetons lus depuis le cache coûtent une fraction du plein tarif ; les
 * ignorer surestimerait la dépense et ferait renoncer à la mise en cache, qui
 * est justement ce qui rend le budget du §3.7 atteignable.
 */
export function coutCentimes(
  modele: string,
  jetons: { entree: number; sortie: number; cacheLus: number },
): number {
  const tarif = TARIFS[modele];

  // Modèle inconnu : on ne devine pas un prix. Zéro se voit dans le suivi de
  // budget comme une anomalie, là où un tarif inventé passerait inaperçu.
  if (!tarif) return 0;

  const centimes =
    (jetons.entree * tarif.entree +
      jetons.sortie * tarif.sortie +
      // Une lecture de cache est facturée environ un dixième de l'entrée.
      jetons.cacheLus * tarif.entree * 0.1) *
    (CENTIMES_PAR_JETON_MILLION / 1_000_000);

  return Math.round(centimes * 10_000) / 10_000;
}

export function tarifConnu(modele: string): boolean {
  return modele in TARIFS;
}
