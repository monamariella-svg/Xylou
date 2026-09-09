import { createServiceClient } from "@/lib/supabase/service";
import { genererUnBilan, type Demande } from "@/lib/bilan/generation";

/**
 * Vide la file de génération de bilans (migration 0077).
 *
 * Appelée par la sonnette de la base au dépôt d'une demande, par le balayeur
 * `pg_cron`, ou à la main. Jamais depuis l'interface : une génération dure des
 * dizaines de secondes et une action utilisateur serait coupée au milieu — ce
 * que la file existe précisément pour éviter.
 */

// Cinq générations séquentielles. Le plafond de Vercel est la vraie contrainte :
// au-delà, la fonction est coupée et laisse des lignes réservées que seule
// l'expiration de vingt minutes (0077) libérera.
export const maxDuration = 300;

const LOT = 5;
const TENTATIVES_MAX = 3;

function autorise(request: Request): boolean {
  const attendu = process.env.CRON_SECRET;

  // Même règle que la file d'envoi : sans secret configuré, la route reste
  // fermée. Une route de génération ouverte, c'est une facture ouverte.
  if (!attendu) return false;

  return (request.headers.get("authorization") ?? "") === `Bearer ${attendu}`;
}

async function viderLaFile(request: Request) {
  if (!autorise(request)) {
    return Response.json({ erreur: "non autorisé" }, { status: 401 });
  }

  const supabase = createServiceClient();

  const { data, error } = await supabase.rpc("reserver_generations", {
    p_lot: LOT,
    p_tentatives_max: TENTATIVES_MAX,
  });

  if (error) {
    return Response.json({ erreur: error.message }, { status: 500 });
  }

  const demandes = (data ?? []) as Demande[];
  let reussies = 0;
  let echouees = 0;

  for (const demande of demandes) {
    // Une génération qui lève ne doit pas emporter les suivantes : le référent
    // a demandé douze bilans, pas un tout ou rien.
    let resultat;
    try {
      resultat = await genererUnBilan(supabase, demande);
    } catch (e) {
      resultat = {
        ok: false as const,
        raison: e instanceof Error ? e.message : String(e),
      };
    }

    if (resultat.ok) {
      reussies += 1;
      await supabase
        .from("generations_bilan")
        .update({
          statut: "terminee",
          bilan_id: resultat.bilanId,
          cout_centimes: resultat.coutCentimes,
          terminee_le: new Date().toISOString(),
          // Les questions écartées à la lecture sont gardées ici : une
          // génération réussie qui a rejeté trois questions sur douze est un
          // signal de qualité, et il se perdrait sans trace.
          derniere_erreur: resultat.rejets.slice(0, 3).join(" ; "),
        })
        .eq("id", demande.id);
    } else {
      echouees += 1;
      await supabase
        .from("generations_bilan")
        .update({
          statut: "echec",
          derniere_erreur: resultat.raison.slice(0, 500),
        })
        .eq("id", demande.id);
    }
  }

  return Response.json({ traitees: demandes.length, reussies, echouees });
}

// La sonnette de 0077 et `pg_cron` postent ; un appel manuel utilise GET.
export const GET = viderLaFile;
export const POST = viderLaFile;
