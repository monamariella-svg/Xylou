"use server";

/**
 * Recherche d'un établissement scolaire par son code UAI, dans l'annuaire de
 * l'Éducation nationale publié en données ouvertes.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI DEPUIS LE SERVEUR
 *
 * L'appel pourrait partir du navigateur — l'API est publique et sans clé. Le
 * faire ici évite deux ennuis : les restrictions d'origine, qui dépendent de la
 * configuration du fournisseur et peuvent changer sans prévenir ; et le fait
 * que le navigateur du référent contacterait alors un service tiers, ce qui
 * demanderait d'être annoncé.
 *
 * ---------------------------------------------------------------------------
 * ÉCHOUER SANS BLOQUER
 *
 * Cette recherche est un raccourci, jamais une condition. Le service peut être
 * indisponible, l'établissement absent du jeu de données, le format de réponse
 * avoir changé : dans tous ces cas on renvoie `null` et la personne saisit à la
 * main, comme avant. Une commodité qui empêcherait de continuer serait pire que
 * son absence.
 */

export type Etablissement = {
  nom: string;
  adresse: string;
  telephone: string;
  email: string;
};

const JEU_DE_DONNEES =
  "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-annuaire-education/records";

export async function chercherParUai(uai: string): Promise<Etablissement | null> {
  const code = uai.trim().toUpperCase();

  // On ne sollicite pas un service extérieur pour une saisie manifestement
  // incomplète : sept chiffres et une lettre, ou rien.
  if (!/^[0-9]{7}[A-Z]$/.test(code)) return null;

  try {
    const url = `${JEU_DE_DONNEES}?where=identifiant_de_l_etablissement%3D%22${code}%22&limit=1`;

    const reponse = await fetch(url, {
      // L'annuaire change au rythme des rentrées : un jour de cache est
      // largement suffisant, et épargne autant d'appels.
      next: { revalidate: 86400 },
      signal: AbortSignal.timeout(5000),
    });

    if (!reponse.ok) return null;

    const donnees = (await reponse.json()) as { results?: Record<string, unknown>[] };
    const ligne = donnees.results?.[0];
    if (!ligne) return null;

    const texte = (cle: string) => {
      const valeur = ligne[cle];
      return typeof valeur === "string" ? valeur.trim() : "";
    };

    const adresse = [
      texte("adresse_1"),
      texte("adresse_2"),
      [texte("code_postal"), texte("nom_commune")].filter(Boolean).join(" "),
    ]
      .filter(Boolean)
      .join("\n");

    const nom = texte("nom_etablissement");
    if (!nom && !adresse) return null;

    return {
      nom,
      adresse,
      telephone: texte("telephone"),
      email: texte("mail"),
    };
  } catch {
    // Réseau indisponible, délai dépassé, réponse illisible. Le formulaire
    // continue de fonctionner sans ce service.
    return null;
  }
}
