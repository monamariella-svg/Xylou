import { createServiceClient } from "@/lib/supabase/service";
import { jetonDesabonnement, secretDesabonnementConfigure } from "@/lib/desabonnement";

/**
 * Vide la file d'envoi de la migration 0059.
 *
 * Appelé par la tâche planifiée de `vercel.json`, ou à la main. Rien ne
 * l'appelle depuis l'interface : un envoi déclenché par une action utilisateur
 * échouerait en silence, ce que la file existe précisément pour éviter.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI RESEND EN HTTP DIRECT, SANS DÉPENDANCE
 *
 * Le SDK n'apporte rien qu'un `fetch` ne fasse, et il ajoute une dépendance à
 * tenir à jour dans un projet qui en a déjà peu. L'API tient en une requête.
 * ---------------------------------------------------------------------------
 */

// Un passage traite jusqu'à LOT courriels, séquentiellement. Le défaut de 10 s
// d'une fonction Vercel les couperait au milieu — et un envoi coupé après
// l'appel à Resend mais avant la mise à jour de la ligne repart au passage
// suivant, c'est-à-dire arrive deux fois.
export const maxDuration = 60;

// Au-delà, on cesse de réessayer. Cinq tentatives couvrent une panne passagère ;
// s'il en faut plus, c'est que la configuration est en cause, et réessayer
// indéfiniment masquerait le problème au lieu de le signaler.
const TENTATIVES_MAX = 5;

// Par passage. Assez pour rattraper un retard, assez peu pour qu'un appel ne
// dure pas plus longtemps que la limite d'exécution d'une fonction serverless.
const LOT = 50;

// Le pied de page annonçait qu'on peut choisir ce qu'on reçoit sans dire où.
// Une promesse sans lien est une promesse qu'on ne tient pas : c'est le
// destinataire qui doit pouvoir arrêter un courriel, pas nous.
const CHEMIN_PREFERENCES = "/notifications/preferences";

// Et l'arrêt complet, lui, ne suppose aucune session : c'est ce qui permettra
// d'écrire à quelqu'un qui n'a pas encore de compte.
const CHEMIN_DESABONNEMENT = "/desabonnement";
const CHEMIN_DESABONNEMENT_UN_CLIC = "/api/desabonnement";

type Envoi = {
  id: string;
  destinataire_id: string;
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

function corpsHtml(envoi: Envoi, base: string, jeton: string): string {
  const lien = envoi.lien
    ? `<p style="margin:24px 0"><a href="${base}${envoi.lien}" style="background:#1B6C78;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none;display:inline-block">Ouvrir dans Xylou</a></p>`
    : "";

  return `<div style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;font-size:15px;line-height:1.55;color:#1A2129;max-width:34em">
<h1 style="font-size:18px;margin:0 0 12px">${echapper(envoi.sujet)}</h1>
${envoi.corps ? `<p style="margin:0">${echapper(envoi.corps)}</p>` : ""}
${lien}
<p style="font-size:13px;color:#5E6B78;margin-top:28px;border-top:1px solid #DFE5EB;padding-top:12px">
Vous recevez ce message parce que vous accompagnez un enfant suivi dans Xylou.
<a href="${base}${CHEMIN_PREFERENCES}" style="color:#5E6B78">Choisir ce qui vous est notifié</a>
&nbsp;·&nbsp;
<a href="${base}${CHEMIN_DESABONNEMENT}?jeton=${jeton}" style="color:#5E6B78">Ne plus rien recevoir</a>.</p>
</div>`;
}

function echapper(texte: string): string {
  return texte
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

async function viderLaFile(request: Request) {
  if (!autorise(request)) {
    return new Response("Non autorisé", { status: 401 });
  }

  const cleResend = process.env.RESEND_API_KEY;
  const expediteur = process.env.RESEND_FROM;

  // Les liens d'une notification sont des chemins applicatifs — « /enfants/…/
  // echanges/… ». Sans origine devant, le bouton du courriel ne mène nulle
  // part. On refuse de partir plutôt que d'expédier un lot de messages dont
  // aucun n'est cliquable : un courriel envoyé ne se rattrape pas.
  const base = (process.env.NEXT_PUBLIC_SITE_URL ?? "").replace(/\/+$/, "");

  // Le secret de désabonnement est au même rang que les autres : sans lui, les
  // liens du pied de page ne se signent pas, et le courriel partirait en
  // promettant un arrêt qu'il ne permet pas. Voir AGENTS.md, « Aucun courriel
  // vers quelqu'un qui n'a pas de compte ».
  if (!cleResend || !expediteur || !base || !secretDesabonnementConfigure()) {
    return Response.json(
      {
        erreur:
          "RESEND_API_KEY, RESEND_FROM, NEXT_PUBLIC_SITE_URL et " +
          "XYLOU_SECRET_DESABONNEMENT sont nécessaires.",
      },
      { status: 500 },
    );
  }

  const supabase = createServiceClient();

  // Réserver, et non lire : depuis 0068, trois déclencheurs peuvent appeler
  // cette route — la sonnette à l'insertion, pg_cron, la tâche quotidienne. Un
  // simple SELECT laisserait deux passages simultanés expédier le même
  // courriel. `reserver_envois()` marque les lignes et les rend d'un seul
  // geste ; deux passages qui se recouvrent se partagent alors le travail.
  //
  // Les seuils restent ici et voyagent en paramètres : la règle « cinq
  // tentatives » appartient à ce fichier, pas à la base.
  const { data, error } = await supabase.rpc("reserver_envois", {
    p_lot: LOT,
    p_tentatives_max: TENTATIVES_MAX,
  });

  if (error) {
    return Response.json({ erreur: error.message }, { status: 500 });
  }

  const envois = (data ?? []) as Envoi[];
  let envoyes = 0;
  let echoues = 0;

  for (const envoi of envois) {
    try {
      const jeton = jetonDesabonnement(envoi.destinataire_id);

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
          html: corpsHtml(envoi, base, jeton),
          headers: {
            // Le bouton « se désabonner » que la messagerie affiche elle-même.
            // Sans lui, qui ne veut plus de ces courriels n'a qu'un geste à sa
            // portée : les signaler comme indésirables — ce qui abîme la
            // réputation du domaine, et finit par empêcher les alertes
            // d'arriver aux autres familles.
            "List-Unsubscribe": `<${base}${CHEMIN_DESABONNEMENT_UN_CLIC}?jeton=${jeton}>`,
            // RFC 8058 : la messagerie appelle l'adresse ci-dessus en POST, et
            // rien ne s'ouvre pour le destinataire. Les deux en-têtes vont
            // ensemble — celui-ci seul ne veut rien dire.
            "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
          },
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

// Vercel Cron n'appelle qu'en GET : n'exposer que POST rendait la tâche
// planifiée impossible à brancher, et l'erreur serait passée pour une panne
// d'envoi plutôt que pour un 405. Les deux verbes font la même chose — POST
// reste le bon choix pour un appel à la main ou depuis un autre ordonnanceur.
export const GET = viderLaFile;
export const POST = viderLaFile;
