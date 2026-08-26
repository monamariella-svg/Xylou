import { createServiceClient } from "@/lib/supabase/service";

/**
 * Vide la file d'envoi de la migration 0059.
 *
 * Appelé par une tâche planifiée, ou à la main. Rien ne l'appelle depuis
 * l'interface : un envoi déclenché par une action utilisateur échouerait en
 * silence, ce que la file existe précisément pour éviter.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI RESEND EN HTTP DIRECT, SANS DÉPENDANCE
 *
 * Le SDK n'apporte rien qu'un `fetch` ne fasse, et il ajoute une dépendance à
 * tenir à jour dans un projet qui en a déjà peu. L'API tient en une requête.
 * ---------------------------------------------------------------------------
 */

// Au-delà, on cesse de réessayer. Cinq tentatives couvrent une panne passagère ;
// s'il en faut plus, c'est que la configuration est en cause, et réessayer
// indéfiniment masquerait le problème au lieu de le signaler.
const TENTATIVES_MAX = 5;

// Par passage. Assez pour rattraper un retard, assez peu pour qu'un appel ne
// dure pas plus longtemps que la limite d'exécution d'une fonction serverless.
const LOT = 50;

type Envoi = {
  id: string;
  canal: string;
  adresse: string;
  sujet: string;
  corps: string;
  lien: string;
  tentatives: number;
};

function autorise(request: Request): boolean {
  const attendu = process.env.CRON_SECRET;

  // Sans secret configuré, la route reste fermée. L'ouvrir « en attendant »
  // exposerait la file à qui connaît son adresse.
  if (!attendu) return false;

  const entete = request.headers.get("authorization") ?? "";
  return entete === `Bearer ${attendu}`;
}

function corpsHtml(envoi: Envoi, base: string): string {
  const lien = envoi.lien
    ? `<p style="margin:24px 0"><a href="${base}${envoi.lien}" style="background:#1B6C78;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none;display:inline-block">Ouvrir dans Xylou</a></p>`
    : "";

  return `<div style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;font-size:15px;line-height:1.55;color:#1A2129;max-width:34em">
<h1 style="font-size:18px;margin:0 0 12px">${echapper(envoi.sujet)}</h1>
${envoi.corps ? `<p style="margin:0">${echapper(envoi.corps)}</p>` : ""}
${lien}
<p style="font-size:13px;color:#5E6B78;margin-top:28px;border-top:1px solid #DFE5EB;padding-top:12px">
Vous recevez ce message parce que vous accompagnez un enfant suivi dans Xylou.
Vous pouvez choisir ce qui vous est notifié depuis votre compte.</p>
</div>`;
}

function echapper(texte: string): string {
  return texte
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

export async function POST(request: Request) {
  if (!autorise(request)) {
    return new Response("Non autorisé", { status: 401 });
  }

  const cleResend = process.env.RESEND_API_KEY;
  const expediteur = process.env.RESEND_FROM;
  const base = process.env.XYLOU_URL_PUBLIQUE ?? "";

  if (!cleResend || !expediteur) {
    return Response.json(
      { erreur: "RESEND_API_KEY et RESEND_FROM sont nécessaires." },
      { status: 500 },
    );
  }

  const supabase = createServiceClient();

  // On reprend aussi les échecs récupérables : un envoi raté une fois doit
  // repartir au passage suivant, sinon la file se remplit d'attentes que rien
  // ne relance.
  const { data, error } = await supabase
    .from("envois")
    .select("id, canal, adresse, sujet, corps, lien, tentatives")
    .eq("canal", "courriel")
    .or(`statut.eq.a_envoyer,and(statut.eq.echec,tentatives.lt.${TENTATIVES_MAX})`)
    .order("cree_le", { ascending: true })
    .limit(LOT);

  if (error) {
    return Response.json({ erreur: error.message }, { status: 500 });
  }

  const envois = (data ?? []) as Envoi[];
  let envoyes = 0;
  let echoues = 0;

  for (const envoi of envois) {
    try {
      const reponse = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${cleResend}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: expediteur,
          to: [envoi.adresse],
          subject: envoi.sujet,
          html: corpsHtml(envoi, base),
        }),
      });

      if (!reponse.ok) {
        // Le corps de la réponse porte la raison — domaine non vérifié, clé
        // révoquée, adresse invalide. La conserver telle quelle est ce qui
        // permettra de diagnostiquer sans reproduire.
        const detail = (await reponse.text()).slice(0, 500);
        throw new Error(`Resend ${reponse.status} : ${detail}`);
      }

      await supabase
        .from("envois")
        .update({
          statut: "envoye",
          envoye_le: new Date().toISOString(),
          tentatives: envoi.tentatives + 1,
          derniere_erreur: "",
        })
        .eq("id", envoi.id);

      envoyes++;
    } catch (e) {
      const tentatives = envoi.tentatives + 1;

      await supabase
        .from("envois")
        .update({
          statut: tentatives >= TENTATIVES_MAX ? "abandonne" : "echec",
          tentatives,
          derniere_erreur: e instanceof Error ? e.message : String(e),
        })
        .eq("id", envoi.id);

      echoues++;
    }
  }

  // Le résultat est lisible dans les journaux de la tâche planifiée. Les échecs
  // restent visibles dans l'écran d'administration, qui est le bon endroit pour
  // s'en apercevoir sans lire de journal.
  return Response.json({ traites: envois.length, envoyes, echoues });
}
