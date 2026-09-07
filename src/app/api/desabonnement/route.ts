import { createServiceClient } from "@/lib/supabase/service";
import { profilDuJeton } from "@/lib/desabonnement";

/**
 * Couper tous les courriels d'un destinataire, sans session.
 *
 * Deux appelants, un seul traitement :
 *
 *   la messagerie du destinataire — bouton « se désabonner » affiché par Gmail
 *   ou Outlook, qui appelle cette adresse en POST sans ouvrir de page
 *   (RFC 8058, en-tête `List-Unsubscribe-Post`) ;
 *
 *   le formulaire de /desabonnement, pour qui clique le lien du pied de page.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI POST, ET JAMAIS GET
 *
 * Un GET qui modifie se déclenche tout seul : les messageries préchargent les
 * liens pour les prévisualiser, les antivirus les visitent pour les inspecter.
 * Le désabonnement se produirait sans que personne n'ait rien demandé, et la
 * personne cesserait de recevoir ce qu'elle attendait.
 * ---------------------------------------------------------------------------
 */

// Ce que « se désabonner » veut dire ici : plus aucun courriel, quel que soit
// le type. C'est le seul sens acceptable pour un bouton unique — proposer un
// tri à quelqu'un qui vient de demander l'arrêt reviendrait à ne pas l'écouter.
// Le réglage fin reste sur /notifications/preferences, pour qui a un compte.
async function couperLesCourriels(profilId: string): Promise<string | null> {
  const supabase = createServiceClient();

  const { data: types, error: erreurTypes } = await supabase.rpc(
    "types_notifies_hors_application",
  );
  const liste = (types ?? []) as string[];

  if (erreurTypes || liste.length === 0) {
    return erreurTypes?.message ?? "Liste des types indisponible.";
  }

  const { error } = await supabase.from("preferences_notification").upsert(
    liste.map((type) => ({
      profil_id: profilId,
      type,
      canal: "courriel",
      actif: false,
    })),
    { onConflict: "profil_id,type,canal" },
  );

  return error?.message ?? null;
}

export async function POST(request: Request) {
  const url = new URL(request.url);

  // Le jeton arrive par l'adresse quand c'est la messagerie qui appelle, et par
  // le formulaire quand c'est une personne. On accepte les deux.
  let jeton = url.searchParams.get("jeton") ?? "";
  let depuisLeFormulaire = false;

  if (!jeton || request.headers.get("content-type")?.includes("form")) {
    try {
      const corps = await request.formData();
      jeton = String(corps.get("jeton") ?? jeton);
      depuisLeFormulaire = corps.get("depuis") === "formulaire";
    } catch {
      // Un POST sans corps lisible reste valable si l'adresse porte le jeton :
      // c'est le cas du désabonnement en un clic de certaines messageries.
    }
  }

  const profilId = profilDuJeton(jeton);

  if (!profilId) {
    if (depuisLeFormulaire) {
      return Response.redirect(new URL("/desabonnement?etat=invalide", request.url), 303);
    }
    return new Response("Lien de désabonnement invalide.", { status: 400 });
  }

  const erreur = await couperLesCourriels(profilId);

  if (erreur) {
    if (depuisLeFormulaire) {
      return Response.redirect(new URL("/desabonnement?etat=erreur", request.url), 303);
    }
    return new Response("Le désabonnement a échoué.", { status: 500 });
  }

  // 303 : la réponse au POST est une page à consulter, pas le résultat à
  // rejouer. Un rafraîchissement ne redemande pas l'envoi du formulaire.
  if (depuisLeFormulaire) {
    return Response.redirect(new URL("/desabonnement?etat=fait", request.url), 303);
  }

  // La messagerie n'affiche pas ce corps ; seul le code compte pour elle.
  return new Response("Désabonnement enregistré.", { status: 200 });
}
