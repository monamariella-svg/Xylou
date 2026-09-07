import { createHmac, timingSafeEqual } from "crypto";

/**
 * Le jeton qui permet de couper les courriels sans se connecter.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI UN JETON, ET PAS SIMPLEMENT UN LIEN VERS LES PRÉFÉRENCES
 *
 * L'écran de préférences est derrière une session. Tant que tout destinataire
 * possède un compte, cela suffit : chacun peut l'atteindre. Une invitation
 * rompt cela — son destinataire n'a par définition pas encore de compte, et son
 * seul recours pour ne plus rien recevoir serait de nous signaler comme
 * indésirable, ce qui dégrade la délivrabilité pour toutes les familles, y
 * compris pour l'alerte de blocage.
 *
 * Le jeton sert aussi le désabonnement en un clic (RFC 8058) : le bouton que
 * les messageries affichent elles-mêmes, et qui appelle l'adresse en POST sans
 * qu'aucune page ne s'ouvre.
 *
 * ---------------------------------------------------------------------------
 * CE QU'IL EST, ET CE QU'IL N'EST PAS
 *
 * Une signature de l'identifiant de profil, rien de plus. Il ne porte aucune
 * donnée, n'ouvre aucune session, et ne permet qu'une seule chose : couper les
 * courriels de ce destinataire. Il ne donne accès à aucun dossier.
 *
 * Il n'expire pas. Un lien de désabonnement doit fonctionner tant que le
 * courriel qui le porte existe, et un courriel se garde des années. Le risque
 * qu'on accepte en échange : qui intercepte un jeton peut couper les courriels
 * de cette personne — qui les rétablit depuis son compte. C'est sans commune
 * mesure avec le fait de ne pas pouvoir se désabonner.
 * ---------------------------------------------------------------------------
 */

// Tronquée à 32 caractères hexadécimaux, soit 128 bits : hors de portée d'une
// recherche exhaustive, et assez court pour qu'une adresse reste lisible dans
// un pied de page de courriel.
const LONGUEUR_SIGNATURE = 32;

function secret(): string {
  const valeur = process.env.XYLOU_SECRET_DESABONNEMENT;

  // On échoue bruyamment. Signer avec une valeur par défaut produirait des
  // jetons que n'importe qui pourrait forger, et le défaut ne se verrait nulle
  // part : les liens fonctionneraient.
  if (!valeur) {
    throw new Error(
      "XYLOU_SECRET_DESABONNEMENT est nécessaire pour signer les liens de désabonnement.",
    );
  }

  return valeur;
}

function signature(profilId: string): string {
  return createHmac("sha256", secret())
    .update(profilId)
    .digest("hex")
    .slice(0, LONGUEUR_SIGNATURE);
}

export function jetonDesabonnement(profilId: string): string {
  return `${profilId}.${signature(profilId)}`;
}

/**
 * Rend l'identifiant de profil si le jeton est authentique, `null` sinon.
 */
export function profilDuJeton(jeton: string): string | null {
  const separateur = jeton.lastIndexOf(".");
  if (separateur <= 0) return null;

  const profilId = jeton.slice(0, separateur);
  const fournie = jeton.slice(separateur + 1);

  let attendue: string;
  try {
    attendue = signature(profilId);
  } catch {
    // Secret absent : aucun jeton n'est vérifiable, donc aucun n'est valable.
    return null;
  }

  // Comparaison à durée constante : une comparaison ordinaire s'arrête au
  // premier caractère qui diffère, et le temps qu'elle met révèle combien de
  // caractères étaient justes — de quoi reconstituer la signature octet par
  // octet.
  const a = Buffer.from(fournie);
  const b = Buffer.from(attendue);
  if (a.length !== b.length) return null;

  return timingSafeEqual(a, b) ? profilId : null;
}

export function secretDesabonnementConfigure(): boolean {
  return Boolean(process.env.XYLOU_SECRET_DESABONNEMENT);
}
