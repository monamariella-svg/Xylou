"use client";

import { useActionState } from "react";
import { majSante, type EtatFormulaire } from "../actions";
import {
  BoutonSoumettre,
  Champ,
  MessageErreur,
  MessageSucces,
  classesChamp,
} from "@/components/ui";

const ETAT_INITIAL: EtatFormulaire = {};

export default function SanteForm({
  enfantId,
  besoins,
  amenagements,
  suivis,
}: {
  enfantId: string;
  besoins: string;
  amenagements: string;
  suivis: string;
}) {
  const [etat, action] = useActionState(majSante, ETAT_INITIAL);

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="enfantId" value={enfantId} />
      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      <Champ
        label="Besoins particuliers"
        aide="Ce qui aide à comprendre comment votre enfant apprend. Aucun diagnostic n'est obligatoire."
      >
        <textarea
          name="besoins"
          rows={3}
          defaultValue={besoins}
          className={classesChamp}
        />
      </Champ>

      <Champ
        label="Aménagements en place"
        aide="PPS, PAP, tiers-temps, supports adaptés, présence d'un AESH…"
      >
        <textarea
          name="amenagements"
          rows={3}
          defaultValue={amenagements}
          className={classesChamp}
        />
      </Champ>

      <Champ
        label="Suivis extérieurs"
        aide="Orthophonie, psychomotricité, ergothérapie… À titre indicatif : Xylou ne gère pas les rendez-vous."
      >
        <textarea name="suivis" rows={2} defaultValue={suivis} className={classesChamp} />
      </Champ>

      <BoutonSoumettre>Enregistrer</BoutonSoumettre>
    </form>
  );
}
