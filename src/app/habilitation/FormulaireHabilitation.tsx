"use client";

import { useActionState } from "react";
import {
  BoutonSoumettre,
  Champ,
  MessageErreur,
  MessageSucces,
  classesChamp,
} from "@/components/ui";
import { demanderLHabilitation, type EtatHabilitation } from "./actions";

export function FormulaireHabilitation() {
  const [etat, action] = useActionState<EtatHabilitation, FormData>(
    demanderLHabilitation,
    {},
  );

  return (
    <form action={action} className="space-y-5">
      <Champ
        label="Votre fonction"
        aide="Coordinatrice ULIS, éducatrice spécialisée, enseignante référente… C'est ce que l'administration lira en premier."
      >
        <input name="fonction" required minLength={3} className={classesChamp} />
      </Champ>

      <Champ label="Structure ou établissement" aide="Facultatif.">
        <input name="organisation" className={classesChamp} />
      </Champ>

      <Champ
        label="Numéro professionnel"
        aide="ADELI, RPPS, ou tout identifiant qui permet de vous vérifier. Facultatif."
      >
        <input name="numero" className={classesChamp} />
      </Champ>

      <Champ
        label="Quelques mots"
        aide="Ce que vous accompagnez, et pourquoi vous avez besoin d'ouvrir des dossiers."
      >
        <textarea name="motivation" rows={4} className={classesChamp} />
      </Champ>

      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      <BoutonSoumettre>Envoyer la demande</BoutonSoumettre>
    </form>
  );
}
