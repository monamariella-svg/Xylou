"use client";

import { useActionState } from "react";
import {
  ajouterCentreInteret,
  supprimerCentreInteret,
  type EtatFormulaire,
} from "../actions";
import {
  BoutonSoumettre,
  Champ,
  MessageErreur,
  MessageSucces,
  classesChamp,
} from "@/components/ui";

const ETAT_INITIAL: EtatFormulaire = {};

export type CentreInteret = {
  id: string;
  libelle: string;
  intensite: number;
  note: string;
};

export default function CentresInteretSection({
  enfantId,
  centres,
}: {
  enfantId: string;
  centres: CentreInteret[];
}) {
  const [etat, action] = useActionState(ajouterCentreInteret, ETAT_INITIAL);

  return (
    <div className="space-y-5">
      {centres.length > 0 ? (
        <ul className="space-y-2">
          {centres.map((centre) => (
            <li
              key={centre.id}
              className="flex items-start justify-between gap-4 rounded-md border border-bordure bg-surface p-3"
            >
              <div>
                <span className="text-sm font-medium">{centre.libelle}</span>
                {/* L'intensité se lit d'un coup d'œil ; elle dit à quel point le
                    sujet accroche, pas à quel point l'enfant en « fait trop ». */}
                <span className="ml-2 text-xs text-texte-doux" aria-label={`Intensité ${centre.intensite} sur 5`}>
                  {"●".repeat(centre.intensite)}
                  {"○".repeat(5 - centre.intensite)}
                </span>
                {centre.note ? (
                  <p className="mt-1 text-xs text-texte-doux">{centre.note}</p>
                ) : null}
              </div>

              <form action={supprimerCentreInteret}>
                <input type="hidden" name="id" value={centre.id} />
                <input type="hidden" name="enfantId" value={enfantId} />
                <button
                  type="submit"
                  className="text-xs text-texte-doux hover:text-alerte hover:underline"
                >
                  Retirer
                </button>
              </form>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-texte-doux">
          Rien encore. Un seul sujet suffit pour démarrer — celui vers lequel votre
          enfant revient toujours.
        </p>
      )}

      <form action={action} className="space-y-3 border-t border-bordure pt-4">
        <input type="hidden" name="enfantId" value={enfantId} />
        <MessageErreur>{etat.erreur}</MessageErreur>
        <MessageSucces>{etat.succes}</MessageSucces>

        <div className="grid gap-3 sm:grid-cols-[2fr_1fr]">
          <Champ label="Centre d'intérêt">
            <input
              name="libelle"
              required
              placeholder="Les trains, Minecraft, les rapaces…"
              className={classesChamp}
            />
          </Champ>

          <Champ label="Intensité" aide="1 : ça lui plaît. 5 : c'est son sujet.">
            <input
              name="intensite"
              type="number"
              min={1}
              max={5}
              defaultValue={3}
              className={classesChamp}
            />
          </Champ>
        </div>

        <Champ label="Précision" aide="Facultatif : ce qui l'intéresse exactement là-dedans.">
          <input name="note" className={classesChamp} />
        </Champ>

        <BoutonSoumettre variante="discret">Ajouter</BoutonSoumettre>
      </form>
    </div>
  );
}
