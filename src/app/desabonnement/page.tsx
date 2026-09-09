import Link from "next/link";
import { profilDuJeton } from "@/lib/desabonnement";

/**
 * L'écran qu'atteint le lien du pied de page d'un courriel.
 *
 * Il ne coupe rien de lui-même : il vérifie le jeton et présente un bouton. Le
 * traitement vit dans `app/api/desabonnement`, seul endroit d'où le client à
 * privilèges s'importe — cette page n'a pas de session, donc pas de RLS pour la
 * tenir, et lui donner ce client reviendrait à écrire dans la base depuis un
 * paramètre d'URL.
 *
 * Aucune authentification, par construction : quelqu'un qui vient de recevoir
 * une invitation n'a pas encore de compte, et c'est précisément lui qui doit
 * pouvoir arrêter les envois.
 */
export default async function PageDesabonnement({
  searchParams,
}: {
  searchParams: Promise<{ jeton?: string; etat?: string }>;
}) {
  const { jeton = "", etat } = await searchParams;
  const profilId = profilDuJeton(jeton);

  return (
    <div className="mx-auto max-w-lg space-y-6">
      <h1 className="text-2xl font-semibold">Ne plus recevoir de courriels</h1>

      {etat === "fait" ? (
        <div className="rounded-lg border border-accent bg-accent-doux p-4">
          <p className="text-sm font-medium text-accent">C&apos;est fait.</p>
          <p className="mt-2 text-sm">
            Vous ne recevrez plus de courriel de Xylou. Rien n&apos;est perdu pour
            autant : les notifications continuent de vous attendre dans
            l&apos;application, et vous pouvez rétablir les courriels à tout
            moment depuis votre compte.
          </p>
        </div>
      ) : null}

      {etat === "erreur" ? (
        <p
          role="alert"
          className="rounded-md border border-alerte bg-alerte-douce px-3 py-2 text-sm text-alerte"
        >
          Le désabonnement n&apos;a pas pu être enregistré. Réessayez dans un
          instant — et si cela se reproduit, répondez simplement à l&apos;un de
          nos courriels.
        </p>
      ) : null}

      {etat === "invalide" || (!profilId && etat !== "fait") ? (
        <div className="rounded-lg border border-bordure bg-surface p-4">
          <p className="text-sm font-medium">Ce lien n&apos;est pas valable.</p>
          <p className="mt-2 text-sm text-texte-doux">
            Il a pu être tronqué en passant d&apos;une messagerie à l&apos;autre.
            Ouvrez plutôt le lien depuis le courriel d&apos;origine — ou, si vous
            avez un compte, réglez ce que vous recevez depuis{" "}
            <Link href="/notifications/preferences" className="text-accent underline">
              vos préférences
            </Link>
            .
          </p>
        </div>
      ) : null}

      {profilId && etat !== "fait" ? (
        <>
          <p className="text-sm text-texte-doux">
            Vous ne recevrez plus aucun courriel de Xylou — ni message, ni
            objectif à valider, ni alerte de blocage. Les notifications
            resteront consultables dans l&apos;application.
          </p>

          {/* Formulaire ordinaire vers la route, et non action serveur : la
              même adresse doit répondre au bouton « se désabonner » que les
              messageries affichent d'elles-mêmes, et celui-là n'exécute aucun
              JavaScript. Un seul chemin, donc un seul comportement à vérifier. */}
          <form method="post" action="/api/desabonnement">
            <input type="hidden" name="jeton" value={jeton} />
            <input type="hidden" name="depuis" value="formulaire" />
            <button
              type="submit"
              className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:opacity-90"
            >
              Confirmer le désabonnement
            </button>
          </form>

          <p className="text-xs text-texte-doux">
            Si vous vouliez seulement couper certains courriels, et que vous avez
            un compte,{" "}
            <Link href="/notifications/preferences" className="text-accent underline">
              choisissez type par type
            </Link>{" "}
            plutôt que de tout arrêter.
          </p>
        </>
      ) : null}
    </div>
  );
}
