import Link from "next/link";
import { FormulaireConnexion } from "./FormulaireConnexion";

export default async function PageConnexion({
  searchParams,
}: {
  searchParams: Promise<{ invitation?: string }>;
}) {
  const { invitation } = await searchParams;

  return (
    <div className="mx-auto max-w-md">
      <h1 className="text-2xl font-semibold">Se connecter</h1>

      {invitation ? (
        <p className="mt-2 rounded-md border border-accent bg-accent-doux px-4 py-3 text-sm text-accent">
          Connectez-vous avec le compte dont l’adresse a reçu l’invitation. Vous y serez
          ramené aussitôt après.
        </p>
      ) : null}

      <FormulaireConnexion invitation={invitation} />

      <p className="mt-6 text-sm text-texte-doux">
        Pas encore de compte ?{" "}
        <Link
          href={invitation ? `/inscription?invitation=${invitation}` : "/inscription"}
          className="text-accent hover:underline"
        >
          En créer un
        </Link>
      </p>
    </div>
  );
}
