import type { Metadata } from "next";
import "./globals.css";
import SiteHeader from "./SiteHeader";

export const metadata: Metadata = {
  title: "Xylou — accompagnement scolaire personnalisé",
  description:
    "Un accompagnement scolaire qui part du centre d'intérêt de l'enfant, mesure son niveau réel matière par matière et prépare le bilan trimestriel.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr">
      <body className="min-h-screen">
        <SiteHeader />
        <main className="mx-auto w-full max-w-4xl px-4 py-8">{children}</main>
      </body>
    </html>
  );
}
