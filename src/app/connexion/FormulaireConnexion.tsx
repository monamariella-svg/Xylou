"use client";

import { useActionState } from "react";
import { seConnecter } from "./actions";
import type { EtatAuth } from "../inscription/actions";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";

const ETAT_INITIAL: EtatAuth = {};

export function FormulaireConnexion({ invitation }: { invitation?: string }) {
  const [etat, action] = useActionState(seConnecter, ETAT_INITIAL);

  return (
    <form action={action} className="mt-6 space-y-4">
      <MessageErreur>{etat.erreur}</MessageErreur>

      {invitation ? <input type="hidden" name="invitation" value={invitation} /> : null}

      <Champ label="Email">
        <input name="email" type="email" required autoComplete="email" className={classesChamp} />
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
  );
}
