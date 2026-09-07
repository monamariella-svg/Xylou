import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

// Au-delà, le compte exact n'apprend plus rien : ce qui compte est qu'il y en a
// beaucoup. Et une pastille à trois chiffres déforme l'en-tête.
const PLAFOND = 20;

export default async function SiteHeader() {
  // Sans configuration Supabase, l'en-tête reste affichable : c'est ce qui rend
  // le projet démarrable sur un poste neuf avant la première clé.
  const configure = Boolean(
    process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );

  let connecte = false;
  let nonLues = 0;

  if (configure) {
    const supabase = await createClient();
    const { data } = await supabase.auth.getUser();
    connecte = Boolean(data.user);

    if (connecte) {
      // `head: true` : on ne rapatrie aucune ligne, seulement le compte.
      // C'est l'index partiel `notifications_non_lues_idx` de 0014 qui répond,
      // et il a été créé pour cette pastille-ci.
      const { count } = await supabase
        .from("notifications")
        .select("id", { count: "exact", head: true })
        .is("lue_le", null);

      nonLues = count ?? 0;
    }
  }

  return (
    <header className="border-b border-bordure bg-surface">
      <div className="mx-auto flex w-full max-w-4xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-semibold tracking-tight">
          Xylou
        </Link>

        <nav className="flex items-center gap-4 text-sm">
          {connecte ? (
            <>
              <Link href="/tableau-de-bord" className="hover:underline">
                Tableau de bord
              </Link>

              {/* Le compte est dans le libellé, pas seulement dans la couleur :
                  une pastille muette n'est lue par aucun lecteur d'écran, et
                  c'est précisément ce lien qu'il ne faut pas manquer. */}
              <Link href="/notifications" className="flex items-center gap-1.5 hover:underline">
                Notifications
                {nonLues > 0 ? (
                  <span className="rounded-full bg-accent px-1.5 py-0.5 text-xs font-medium text-white">
                    {nonLues > PLAFOND ? `${PLAFOND}+` : nonLues}
                    <span className="sr-only">
                      {nonLues > 1 ? " non lues" : " non lue"}
                    </span>
                  </span>
                ) : null}
              </Link>

              <form action="/deconnexion" method="post">
                <button type="submit" className="text-texte-doux hover:underline">
                  Se déconnecter
                </button>
              </form>
            </>
          ) : (
            <>
              <Link href="/connexion" className="hover:underline">
                Se connecter
              </Link>
              <Link
                href="/inscription"
                className="rounded-md bg-accent px-3 py-1.5 text-white hover:opacity-90"
              >
                Créer un compte
              </Link>
            </>
          )}
        </nav>
      </div>
    </header>
  );
}
