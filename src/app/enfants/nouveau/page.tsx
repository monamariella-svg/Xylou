"use client";

import { useActionState } from "react";
import { creerUnEnfant, type EtatFormulaire } from "../actions";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";
import {
  AIDE_COMMUNICATION,
  LIBELLE_CLASSE,
  LIBELLE_COMMUNICATION,
  NIVEAUX_CLASSE,
  PROFILS_COMMUNICATION,
} from "@/lib/domaine";
const ETAT_INITIAL: EtatFormulaire = {};

export default function PageNouvelEnfant() {
  const [etat, action] = useActionState(creerUnEnfant, ETAT_INITIAL);

  return (
    <div className="mx-auto max-w-xl">
      <h1 className="text-2xl font-semibold">Ouvrir un dossier</h1>
      <p className="mt-2 text-sm text-texte-doux">
        Le strict nécessaire pour commencer. Vous inviterez ensuite la famille, qui
        signera les autorisations — rien ne fonctionne avant. Les centres
        d&apos;intérêt, le projet moteur et les aménagements viennent après.
      </p>

      <form action={action} className="mt-6 space-y-5">
        <MessageErreur>{etat.erreur}</MessageErreur>

        <Champ label="Prénom">
          <input name="prenom" required className={classesChamp} />
        </Champ>

        <div className="grid gap-4 sm:grid-cols-2">
          <Champ label="Classe">
            <select name="classe" defaultValue="" className={classesChamp}>
              <option value="">Non renseignée</option>
              {NIVEAUX_CLASSE.map((niveau) => (
                <option key={niveau} value={niveau}>
                  {LIBELLE_CLASSE[niveau]}
                </option>
              ))}
            </select>
          </Champ>

          <Champ label="Date de naissance" aide="Facultatif.">
            <input name="dateNaissance" type="date" className={classesChamp} />
          </Champ>
        </div>

        <fieldset>
          <legend className="mb-2 text-sm font-medium">Communication</legend>
          <div className="space-y-2">
            {PROFILS_COMMUNICATION.map((profil, index) => (
              <label
                key={profil}
                className="flex gap-3 rounded-md border border-bordure bg-surface p-3"
              >
                <input
                  type="radio"
                  name="communication"
                  value={profil}
                  defaultChecked={index === 0}
                  className="mt-1"
                />
                <span>
                  <span className="block text-sm font-medium">
                    {LIBELLE_COMMUNICATION[profil]}
                  </span>
                  <span className="block text-xs text-texte-doux">
                    {AIDE_COMMUNICATION[profil]}
                  </span>
                </span>
              </label>
            ))}
          </div>
        </fieldset>

        {/* La composition parentale, établie par le référent. Elle détermine
            combien de signatures il faudra pour valider un objectif, autoriser
            un traitement, ou supprimer le dossier. Deux par défaut : à un,
            l'oubli laisserait un parent décider seul en garde alternée sans que
            personne ne le remarque ; à deux, l'oubli bloque et se corrige. */}
        <fieldset className="rounded-md border border-bordure bg-surface p-4">
          <legend className="px-1 text-sm font-medium">Autorité parentale</legend>
          <p className="mb-3 text-xs text-texte-doux">
            Combien de personnes détiennent l&apos;autorité parentale ? Chacune devra
            signer les autorisations et valider les objectifs. Vous pourrez corriger
            ensuite.
          </p>
          <div className="space-y-2">
            <label className="flex items-center gap-3 text-sm">
              <input type="radio" name="titulaires" value="2" defaultChecked />
              Deux titulaires
            </label>
            <label className="flex items-center gap-3 text-sm">
              <input type="radio" name="titulaires" value="1" />
              Un seul titulaire
            </label>
          </div>
        </fieldset>

        <BoutonSoumettre>Ouvrir le dossier</BoutonSoumettre>
      </form>
    </div>
  );
}
