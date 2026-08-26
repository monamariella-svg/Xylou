import Link from "next/link";
import { FormulaireInscription } from "./FormulaireInscription";

export default async function PageInscription({
  searchParams,
}: {
  searchParams: Promise<{ invitation?: string }>;
}) {
  const { invitation } = await searchParams;

  return (
    <div className="mx-auto max-w-md">
      <h1 className="text-2xl font-semibold">Créer un compte</h1>

      {/* Deux situations qui n'appellent pas le même mot. Quelqu'un qui arrive
          par un lien d'invitation sait déjà pourquoi il est là ; quelqu'un qui
          arrive de lui-même a besoin qu'on lui dise ce qui se passe ensuite —
          et notamment qu'il n'a aucun rôle à choisir. */}
      {invitation ? (
        <p className="mt-2 rounded-md border border-accent bg-accent-doux px-4 py-3 text-sm text-accent">
          Vous avez été invité à rejoindre le dossier d’un enfant. Créez votre compte, et
          vous serez ramené à l’invitation aussitôt après.
        </p>
      ) : (
        <p className="mt-2 text-sm text-texte-doux">
          Le compte est celui de l’adulte, et il ne donne accès à rien par lui-même. Votre
          rôle — parent, enseignant, accompagnant — vous vient de l’invitation du référent
          qui suit l’enfant. Si vous accompagnez des enfants à titre professionnel et
          devez pouvoir ouvrir des dossiers, vous demanderez votre habilitation après
          l’inscription.
        </p>
      )}

      <FormulaireInscription invitation={invitation} />

      <p className="mt-6 text-sm text-texte-doux">
        Déjà un compte ?{" "}
        <Link
          href={invitation ? `/connexion?invitation=${invitation}` : "/connexion"}
          className="text-accent hover:underline"
        >
          Se connecter
        </Link>
      </p>
    </div>
  );
}
