import Link from "next/link";

export default function PageConfirmation() {
  return (
    <div className="mx-auto max-w-md">
      <h1 className="text-2xl font-semibold">Vérifiez votre boîte mail</h1>
      <p className="mt-3 text-sm text-texte-doux">
        Un lien de confirmation vient de vous être envoyé. Il faut l&apos;ouvrir
        avant de pouvoir vous connecter.
      </p>
      <p className="mt-6 text-sm">
        <Link href="/connexion" className="text-accent hover:underline">
          Aller à la page de connexion
        </Link>
      </p>
    </div>
  );
}
