import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

/**
 * Suivre une notification : la marquer lue, puis mener où elle mène.
 *
 * ---------------------------------------------------------------------------
 * POURQUOI PASSER PAR UNE ROUTE PLUTÔT QUE DE LIER DIRECTEMENT
 *
 * Une notification qui reste non lue après qu'on l'a ouverte ne s'efface
 * jamais : la liste ne décroît que par un « tout marquer comme lu », qui efface
 * aussi ce qu'on n'a pas regardé. C'est le geste par lequel on finit par ne
 * plus rien lire du tout.
 *
 * Le détour garde un vrai lien — ouverture dans un nouvel onglet, clic milieu,
 * copie de l'adresse continuent de fonctionner, ce qu'un <form> déguisé en
 * ligne cliquable perdrait.
 * ---------------------------------------------------------------------------
 */

// Le chemin vient d'un trigger, pas d'un formulaire. On le vérifie quand même :
// une notification est la seule donnée que l'application redirige sans que
// personne ne l'ait relue, et un « //ailleurs.example » y suffirait à emmener
// une famille hors du site depuis un lien qui porte notre nom.
function cheminInterne(lien: string): string {
  return /^\/(?![/\\])/.test(lien) ? lien : "/notifications";
}

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const supabase = await createClient();

  const { data } = await supabase
    .from("notifications")
    .select("lien")
    .eq("id", id)
    .maybeSingle();

  // Ligne inexistante et ligne d'un autre destinataire se ressemblent ici, et
  // c'est volontaire : la politique de 0014 renvoie zéro ligne dans les deux
  // cas, et distinguer les deux dirait qu'une notification existe.
  if (!data) {
    return Response.redirect(new URL("/notifications", request.url), 302);
  }

  await supabase
    .from("notifications")
    .update({ lue_le: new Date().toISOString() })
    .eq("id", id)
    .is("lue_le", null);

  revalidatePath("/", "layout");

  return Response.redirect(
    new URL(cheminInterne((data as { lien: string }).lien), request.url),
    302,
  );
}
