import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// Next.js 16 : ce fichier s'appelait `middleware.ts` et exportait `middleware`.
// Les deux noms sont dépréciés. Le runtime est Node et n'est plus configurable.
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  // Sans configuration Supabase, l'application doit rester démarrable : c'est ce
  // qui permet de lancer `next dev` sur un poste neuf avant d'avoir la moindre clé.
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return response;
  }

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // Rafraîchit le jeton expiré et réécrit les cookies. Le contrôle d'accès, lui,
  // se joue dans les politiques RLS, pas ici : un proxy n'est pas une autorisation.
  await supabase.auth.getUser();

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
