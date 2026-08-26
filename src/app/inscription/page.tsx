"use client";

import Link from "next/link";
import { useActionState } from "react";
import { creerUnCompte, type EtatAuth } from "./actions";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";

const ETAT_INITIAL: EtatAuth = {};

export default function PageInscription() {
  const [etat, action] = useActionState(creerUnCompte, ETAT_INITIAL);

  return (
    <div className="mx-auto max-w-md">
      <h1 className="text-2xl font-semibold">Créer un compte</h1>
      <p className="mt-2 text-sm text-texte-doux">
        Le compte est celui de l&apos;adulte. Vous créerez ensuite la fiche de
        votre enfant, et vous seul déciderez qui d&apos;autre y a accès.
      </p>

      <form action={action} className="mt-6 space-y-4">
        <MessageErreur>{etat.erreur}</MessageErreur>

        <div className="grid grid-cols-2 gap-3">
          <Champ label="Prénom">
            <input name="prenom" required autoComplete="given-name" className={classesChamp} />
          </Champ>
          <Champ label="Nom">
            <input name="nom" autoComplete="family-name" className={classesChamp} />
          </Champ>
        </div>

        <Champ label="Email">
          <input
            name="email"
            type="email"
            required
            autoComplete="email"
            className={classesChamp}
          />
        </Champ>

        <Champ label="Mot de passe" aide="8 caractères au minimum.">
          <input
            name="motDePasse"
            type="password"
            required
            minLength={8}
            autoComplete="new-password"
            className={classesChamp}
          />
        </Champ>

        <BoutonSoumettre>Créer mon compte</BoutonSoumettre>
      </form>

      <p className="mt-6 text-sm text-texte-doux">
        Déjà un compte ?{" "}
        <Link href="/connexion" className="text-accent hover:underline">
          Se connecter
        </Link>
      </p>
    </div>
  );
}
