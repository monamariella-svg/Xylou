"use client";

import Link from "next/link";
import { useActionState } from "react";
import { seConnecter } from "./actions";
import type { EtatAuth } from "../inscription/actions";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";

const ETAT_INITIAL: EtatAuth = {};

export default function PageConnexion() {
  const [etat, action] = useActionState(seConnecter, ETAT_INITIAL);

  return (
    <div className="mx-auto max-w-md">
      <h1 className="text-2xl font-semibold">Se connecter</h1>

      <form action={action} className="mt-6 space-y-4">
        <MessageErreur>{etat.erreur}</MessageErreur>

        <Champ label="Email">
          <input
            name="email"
            type="email"
            required
            autoComplete="email"
            className={classesChamp}
          />
        </Champ>

        <Champ label="Mot de passe">
          <input
            name="motDePasse"
            type="password"
            required
            autoComplete="current-password"
            className={classesChamp}
          />
        </Champ>

        <BoutonSoumettre>Se connecter</BoutonSoumettre>
      </form>

      <p className="mt-6 text-sm text-texte-doux">
        Pas encore de compte ?{" "}
        <Link href="/inscription" className="text-accent hover:underline">
          En créer un
        </Link>
      </p>
    </div>
  );
}
