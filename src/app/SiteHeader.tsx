import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

export default async function SiteHeader() {
  // Sans configuration Supabase, l'en-tête reste affichable : c'est ce qui rend
  // le projet démarrable sur un poste neuf avant la première clé.
  const configure = Boolean(
    process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );

  let connecte = false;
  if (configure) {
    const supabase = await createClient();
    const { data } = await supabase.auth.getUser();
    connecte = Boolean(data.user);
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
