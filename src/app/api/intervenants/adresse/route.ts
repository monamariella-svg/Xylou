import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createServiceClient } from "@/lib/supabase/service";

/**
 * Corriger l'adresse de connexion d'une personne rattachée à un dossier.
 *
 * Cette route existe à contre-courant d'une règle qui reste vraie ailleurs :
 * l'adresse d'un compte appartient à son titulaire, et un tiers qui la change
 * déplace un accès. C'est pourquoi tout ce qui pouvait rester fermé l'est.
 *
 *  - Elle passe par `app/api/` : la clé de service ne s'importe pas depuis une
 *    action serveur, et changer une adresse dans `auth.users` l'exige.
 *  - Elle vérifie `peut_composer_l_equipe` côté base, pas côté écran.
 *  - Elle refuse de toucher au compte de qui appelle : on corrige le sien
 *    depuis ses propres réglages, où l'on prouve qu'on en est le titulaire.
 *  - Elle écrit dans `journal_acces`. Une correction faite de bonne foi et une
 *    reprise de compte se ressemblent trop pour qu'on se passe de trace.
 *
 * Ce qu'elle ne fait pas : prévenir la personne. Aucun canal ne le permet
 * aujourd'hui — la file d'envoi de 0059 n'est branchée sur rien. L'écran le dit
 * au référent, à qui il revient d'avertir.
 */
export async function POST(requete: Request) {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) {
    return NextResponse.json({ erreur: "Session expirée." }, { status: 401 });
  }

  let corps: { enfantId?: string; profilId?: string; email?: string };
  try {
    corps = await requete.json();
  } catch {
    return NextResponse.json({ erreur: "Requête illisible." }, { status: 400 });
  }

  const enfantId = String(corps.enfantId ?? "");
  const profilId = String(corps.profilId ?? "");
  const email = String(corps.email ?? "").trim().toLowerCase();

  if (!enfantId || !profilId || !email) {
    return NextResponse.json({ erreur: "Indiquez la nouvelle adresse." }, { status: 400 });
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return NextResponse.json({ erreur: "Cette adresse n'est pas valide." }, { status: 400 });
  }
  if (profilId === auth.user.id) {
    return NextResponse.json(
      { erreur: "Votre propre adresse se corrige depuis vos réglages de compte." },
      { status: 403 },
    );
  }

  // La base décide, comme partout ailleurs. Depuis 0062, composer l'équipe
  // revient au référent du dossier et à l'administration.
  const { data: peutComposer } = await supabase.rpc("peut_composer_l_equipe", {
    p_enfant: enfantId,
  });
  if (!peutComposer) {
    return NextResponse.json(
      { erreur: "Composer l'équipe de ce dossier ne vous revient pas." },
      { status: 403 },
    );
  }

  // La personne doit être rattachée à *ce* dossier. Sans ce test, un référent
  // corrigerait l'adresse de n'importe quel compte dont il devine
  // l'identifiant.
  const { data: rattachement } = await supabase
    .from("intervenants_enfant")
    .select("id")
    .eq("enfant_id", enfantId)
    .eq("profil_id", profilId)
    .is("retire_le", null)
    .maybeSingle();

  if (!rattachement) {
    return NextResponse.json(
      { erreur: "Cette personne n'est pas rattachée à ce dossier." },
      { status: 404 },
    );
  }

  const service = createServiceClient();

  const { data: avant } = await service
    .from("profils")
    .select("email")
    .eq("id", profilId)
    .maybeSingle();

  const ancienne = avant?.email ?? "";
  if (ancienne === email) {
    return NextResponse.json({ erreur: "C'est déjà l'adresse enregistrée." }, { status: 400 });
  }

  // `email_confirm` évite d'attendre une confirmation qui ne partirait nulle
  // part : sans service de courriel, laisser l'adresse « en attente » rendrait
  // le compte inaccessible des deux côtés.
  const { error: erreurAuth } = await service.auth.admin.updateUserById(profilId, {
    email,
    email_confirm: true,
  });

  if (erreurAuth) {
    // Le cas courant : l'adresse sert déjà à un autre compte.
    return NextResponse.json(
      { erreur: `La correction a échoué : ${erreurAuth.message}` },
      { status: 400 },
    );
  }

  // `profils.email` est une copie de travail — c'est elle que lisent les écrans
  // et la file d'envoi. La laisser derrière ferait diverger ce qu'on affiche de
  // ce qui ouvre la session.
  await service.from("profils").update({ email }).eq("id", profilId);

  await service.from("journal_acces").insert({
    enfant_id: enfantId,
    profil_id: auth.user.id,
    action: "correction_adresse",
    table_cible: "profils",
    ligne_id: profilId,
    detail: { ancienne, nouvelle: email },
  });

  return NextResponse.json({ succes: `Adresse corrigée : ${email}.` });
}
