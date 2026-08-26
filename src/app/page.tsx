import Link from "next/link";

export default function PageAccueil() {
  return (
    <div className="space-y-10">
      <section>
        <h1 className="text-3xl font-semibold tracking-tight">
          Partir de ce qui l&apos;intéresse déjà.
        </h1>
        <p className="mt-4 max-w-2xl text-texte-doux">
          Xylou prend ce qui passionne votre enfant — un jeu vidéo, un dessin
          animé, les oiseaux, les trains, un livre — et en fait le fil rouge de
          ses apprentissages. Un bilan mesure son niveau réel matière par matière,
          sans jamais le comparer à un enfant neurotypique.
        </p>
        <div className="mt-6 flex gap-3">
          <Link
            href="/inscription"
            className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:opacity-90"
          >
            Créer un compte
          </Link>
          <Link
            href="/connexion"
            className="rounded-md border border-bordure bg-surface px-4 py-2 text-sm font-medium hover:bg-fond"
          >
            Se connecter
          </Link>
        </div>
      </section>

      <section className="grid gap-4 sm:grid-cols-3">
        <Bloc titre="Un fil rouge, pas une contrainte">
          Les exercices deviennent des missions écrites dans l&apos;univers de
          votre enfant, avec ses mots à lui.
        </Bloc>
        <Bloc titre="Un niveau, pas une note">
          Le bilan situe où votre enfant travaille réellement, matière par
          matière, et ce sur quoi il s&apos;appuie.
        </Bloc>
        <Bloc titre="Un bilan trimestriel prêt">
          De quoi arriver à la réunion avec l&apos;école sans avoir rien
          reconstruit la veille.
        </Bloc>
      </section>

      <section className="rounded-lg border border-bordure bg-surface p-5">
        <h2 className="font-medium">Ce que Xylou ne fait pas</h2>
        <p className="mt-2 text-sm text-texte-doux">
          Xylou ne remplace ni l&apos;école, ni les professionnels qui
          accompagnent votre enfant, et ne décide rien à votre place : toute
          proposition faite par l&apos;intelligence artificielle passe par votre
          validation, ou par celle du référent que vous désignez, avant
          d&apos;être présentée à l&apos;enfant.
        </p>
      </section>
    </div>
  );
}

function Bloc({ titre, children }: { titre: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border border-bordure bg-surface p-4">
      <h2 className="font-medium">{titre}</h2>
      <p className="mt-2 text-sm text-texte-doux">{children}</p>
    </div>
  );
}
