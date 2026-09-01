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
import { ChampsEtablissement } from "./ChampsEtablissement";

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

      <ChampsEtablissement />

      {/* Le directeur n'est pas une formalité : c'est la personne que
          l'administration appellera pour vérifier. Une attestation qu'on ne
          peut pas recouper ne vaut que la confiance qu'on accorde à celui qui
          la présente — et il s'agit d'ouvrir des dossiers d'enfants. */}
      <fieldset className="space-y-4 rounded-md border border-bordure bg-surface p-4">
        <legend className="px-1 text-sm font-medium">Direction de l’établissement</legend>
        <p className="text-xs text-texte-doux">
          C’est elle qui atteste de votre fonction. L’administration peut la contacter
          pour vérifier avant d’accorder l’habilitation.
        </p>

        <Champ label="Nom du directeur ou de la directrice">
          <input name="directeurNom" required minLength={2} className={classesChamp} />
        </Champ>

        <Champ
          label="Comment le joindre"
          aide="Adresse électronique ou téléphone de l'établissement."
        >
          <input name="directeurContact" required minLength={5} className={classesChamp} />
        </Champ>
      </fieldset>

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
