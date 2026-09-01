"use client";

import { useActionState } from "react";
import { creerUnEnfant, type EtatFormulaire } from "../actions";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";
import { LIBELLE_CLASSE, NIVEAUX_CLASSE } from "@/lib/domaine";
const ETAT_INITIAL: EtatFormulaire = {};

export default function PageNouvelEnfant() {
  const [etat, action] = useActionState(creerUnEnfant, ETAT_INITIAL);

  return (
    <div className="mx-auto max-w-xl">
      <h1 className="text-2xl font-semibold">Ouvrir un dossier</h1>
      <p className="mt-2 text-sm text-texte-doux">
        Uniquement ce que vous savez sans la famille : de quel enfant il s&apos;agit,
        dans quelle classe, et combien de personnes détiennent l&apos;autorité
        parentale. Vous inviterez les titulaires à l&apos;étape suivante, et la fiche
        se remplira avec eux — date de naissance, mode de communication, centres
        d&apos;intérêt, aménagements. Rien de tout cela ne se devine.
      </p>

      <form action={action} className="mt-6 space-y-5">
        <MessageErreur>{etat.erreur}</MessageErreur>

        {/* Le nom est facultatif mais proposé d'emblée : un référent suit
            plusieurs dizaines de dossiers, et deux « Lucas » dans la même liste
            ne se distinguent pas. Voir la migration 0065. */}
        <div className="grid gap-4 sm:grid-cols-2">
          <Champ label="Prénom">
            <input name="prenom" required className={classesChamp} />
          </Champ>

          <Champ label="Nom" aide="Facultatif. Pour distinguer deux enfants du même prénom.">
            <input name="nom" className={classesChamp} />
          </Champ>
        </div>

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

        <BoutonSoumettre>Ouvrir le dossier et inviter la famille</BoutonSoumettre>
      </form>
    </div>
  );
}
