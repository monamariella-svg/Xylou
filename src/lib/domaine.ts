// Vocabulaire du domaine, aligné sur les types Postgres de `supabase/migrations`.
// Les libellés affichés vivent ici et nulle part ailleurs : c'est ce qui garantit
// qu'on ne laissera pas passer un « en retard » dans un coin d'interface.

export const NIVEAUX_CLASSE = [
  "cp", "ce1", "ce2", "cm1", "cm2",
  "6e", "5e", "4e", "3e",
  "2nde", "1ere", "terminale",
] as const;
export type NiveauClasse = (typeof NIVEAUX_CLASSE)[number];

export const LIBELLE_CLASSE: Record<NiveauClasse, string> = {
  cp: "CP", ce1: "CE1", ce2: "CE2", cm1: "CM1", cm2: "CM2",
  "6e": "6e", "5e": "5e", "4e": "4e", "3e": "3e",
  "2nde": "2nde", "1ere": "1re", terminale: "Terminale",
};

export const PROFILS_COMMUNICATION = ["verbal", "non_verbal", "mixte"] as const;
export type ProfilCommunication = (typeof PROFILS_COMMUNICATION)[number];

export const LIBELLE_COMMUNICATION: Record<ProfilCommunication, string> = {
  verbal: "Verbale",
  non_verbal: "Non verbale",
  mixte: "Mixte",
};

export const AIDE_COMMUNICATION: Record<ProfilCommunication, string> = {
  verbal: "L'enfant s'exprime à l'oral. Les consignes peuvent être lues ou dites.",
  non_verbal:
    "L'enfant ne s'exprime pas à l'oral. Les exercices privilégieront le choix, l'appariement et l'image plutôt que la réponse rédigée.",
  mixte:
    "L'enfant s'exprime à l'oral dans certaines situations seulement. Les deux formats resteront disponibles.",
};

export const UNIVERS_MOTEUR = [
  "jeu_video", "dessin_anime", "livre", "animaux",
  "transports", "espace", "sport", "musique", "autre",
] as const;
export type UniversMoteur = (typeof UNIVERS_MOTEUR)[number];

export const LIBELLE_UNIVERS: Record<UniversMoteur, string> = {
  jeu_video: "Jeu vidéo",
  dessin_anime: "Dessin animé, série",
  livre: "Livre, bande dessinée",
  animaux: "Animaux",
  transports: "Trains, voitures, avions",
  espace: "Espace, astronomie",
  sport: "Sport",
  musique: "Musique",
  autre: "Autre univers",
};

// Le lexique du projet moteur. Ces clés sont celles que l'IA recevra pour
// formuler une mission dans les mots de l'enfant. Les valeurs par défaut sont
// neutres : elles ne servent qu'à ce que l'interface reste lisible tant que la
// famille n'a rien personnalisé.
export const CLES_LEXIQUE = [
  "mission", "missions", "recompense", "recompenses",
  "point", "points", "niveau", "indice", "reussite",
] as const;
export type CleLexique = (typeof CLES_LEXIQUE)[number];

export const LEXIQUE_PAR_DEFAUT: Record<CleLexique, string> = {
  mission: "mission",
  missions: "missions",
  recompense: "récompense",
  recompenses: "récompenses",
  point: "point",
  points: "points",
  niveau: "niveau",
  indice: "indice",
  reussite: "réussite",
};

export const AIDE_LEXIQUE: Record<CleLexique, string> = {
  mission: "Comment appeler une tâche à accomplir ? (quête, défi, épreuve…)",
  missions: "Le pluriel du mot précédent.",
  recompense: "Comment appeler ce qu'on gagne ? (trophée, badge, wagon…)",
  recompenses: "Le pluriel du mot précédent.",
  point: "Comment appeler l'unité gagnée ? (pièce, étoile, cristal…)",
  points: "Le pluriel du mot précédent.",
  niveau: "Comment appeler une étape franchie ? (palier, monde, station…)",
  indice: "Comment appeler l'aide disponible ? (carte, boussole, joker…)",
  reussite: "Comment annoncer une réussite ? (victoire, mission accomplie…)",
};

export function lireLexique(lexique: unknown): Record<CleLexique, string> {
  const source = (lexique ?? {}) as Record<string, unknown>;
  const resultat = { ...LEXIQUE_PAR_DEFAUT };
  for (const cle of CLES_LEXIQUE) {
    const valeur = source[cle];
    if (typeof valeur === "string" && valeur.trim()) {
      resultat[cle] = valeur.trim();
    }
  }
  return resultat;
}

export const ROLES_INTERVENANT = ["parent", "referent", "enseignant"] as const;
export type RoleIntervenant = (typeof ROLES_INTERVENANT)[number];

export const LIBELLE_ROLE: Record<RoleIntervenant, string> = {
  parent: "Parent",
  referent: "Référent",
  enseignant: "Enseignant",
};

// Le nom affiché d'un enfant, composé en un seul endroit. Le nom de famille est
// facultatif : chaque écran qui le recomposerait à sa façon finirait par afficher
// un prénom suivi d'une espace. Pendant du `nom_affiche()` de la migration 0065.
export function nomAffiche(prenom: string, nom?: string | null): string {
  return `${prenom} ${nom ?? ""}`.trim();
}

export const MAITRISES = [
  "non_evaluee", "a_travailler", "en_cours", "acquise", "point_fort",
] as const;
export type Maitrise = (typeof MAITRISES)[number];

// Formulations descriptives, jamais comparatives (§3.3). « À travailler » dit où
// en est l'enfant ; « en retard » dirait où en sont les autres.
export const LIBELLE_MAITRISE: Record<Maitrise, string> = {
  non_evaluee: "Pas encore évalué",
  a_travailler: "À travailler",
  en_cours: "En cours d'acquisition",
  acquise: "Acquis",
  point_fort: "Point fort",
};
