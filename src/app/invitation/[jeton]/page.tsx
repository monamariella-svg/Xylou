import Link from "next/link";
import { redirect } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";

/**
 * L'acceptation d'une invitation.
 *
 * Tout se joue dans `accepter_l_invitation()` (migration 0024), et rien ici :
 * la fonction vérifie que le jeton existe, qu'il n'est ni expiré ni annulé, et
 * surtout que l'adresse du compte connecté est bien celle de l'invitation. Le
 * jeton seul ne suffit pas — il circule par courriel, et un courriel se
 * transfère.
 *
 * La page ne fait donc que connecter la personne, appeler, et traduire.
 */
export default async function PageInvitation({
  params,
}: {
  params: Promise<{ jeton: string }>;
}) {
  const { jeton } = await params;

  // `exigerUtilisateur` redirige vers la connexion si le compte n'existe pas
  // encore. La personne devra s'inscrire avec l'adresse qui a reçu le lien,
  // puis revenir : c'est la contrainte de la fonction, pas un oubli.
  const { supabase } = await exigerUtilisateur();

  const { data: enfantId, error } = await supabase.rpc("accepter_l_invitation", {
    p_jeton: jeton,
  });

  if (!error && enfantId) {
    redirect(`/enfants/${enfantId}/consentements`);
  }

  return (
    <main className="mx-auto max-w-lg space-y-4 px-4 py-12">
      <h1 className="text-2xl font-semibold">Cette invitation n’a pas pu être acceptée</h1>

      {/* Le message de la base est écrit pour être lu : invitation expirée,
          déjà acceptée, ou adressée à une autre adresse. Le remplacer par un
          générique ferait perdre la seule information utile. */}
      <p className="rounded-md border border-alerte bg-alerte-douce px-4 py-3 text-sm text-alerte">
        {error?.message ?? "Ce lien n’est plus valable."}
      </p>

      <p className="text-sm text-texte-doux">
        Si vous venez de créer votre compte, vérifiez qu’il utilise bien l’adresse à
        laquelle l’invitation a été envoyée. Sinon, demandez qu’on vous en adresse une
        nouvelle : elles valent trente jours.
      </p>

      <Link href="/tableau-de-bord" className="text-sm text-accent hover:underline">
        Retour au tableau de bord
      </Link>
    </main>
  );
}
