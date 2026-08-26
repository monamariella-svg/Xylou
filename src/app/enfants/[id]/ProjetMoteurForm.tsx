"use client";

import { useActionState } from "react";
import { enregistrerProjetMoteur, type EtatFormulaire } from "../actions";
import {
  AIDE_LEXIQUE,
  CLES_LEXIQUE,
  LEXIQUE_PAR_DEFAUT,
  LIBELLE_UNIVERS,
  UNIVERS_MOTEUR,
  type CleLexique,
  type UniversMoteur,
} from "@/lib/domaine";
import {
  BoutonSoumettre,
  Champ,
  MessageErreur,
  MessageSucces,
  classesChamp,
} from "@/components/ui";

const ETAT_INITIAL: EtatFormulaire = {};

export default function ProjetMoteurForm({
  enfantId,
  projetId,
  titre,
  univers,
  description,
  lexique,
}: {
  enfantId: string;
  projetId: string | null;
  titre: string;
  univers: UniversMoteur;
  description: string;
  lexique: Record<CleLexique, string>;
}) {
  const [etat, action] = useActionState(enregistrerProjetMoteur, ETAT_INITIAL);

  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="enfantId" value={enfantId} />
      {projetId ? <input type="hidden" name="projetId" value={projetId} /> : null}

      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      <div className="grid gap-4 sm:grid-cols-2">
        <Champ label="Titre du projet">
          <input
            name="titre"
            required
            defaultValue={titre}
            placeholder="L'expédition minière"
            className={classesChamp}
          />
        </Champ>

        <Champ label="Univers">
          <select name="univers" defaultValue={univers} className={classesChamp}>
            {UNIVERS_MOTEUR.map((valeur) => (
              <option key={valeur} value={valeur}>
                {LIBELLE_UNIVERS[valeur]}
              </option>
            ))}
          </select>
        </Champ>
      </div>

      <Champ
        label="Description"
        aide="De quoi parle cet univers, et ce que votre enfant y fait. Ce texte guide la formulation des missions."
      >
        <textarea
          name="description"
          rows={3}
          defaultValue={description}
          className={classesChamp}
        />
      </Champ>

      <fieldset className="rounded-md border border-bordure bg-surface p-4">
        <legend className="px-1 text-sm font-medium">Les mots de votre enfant</legend>
        <p className="mb-4 text-xs text-texte-doux">
          Ce sont les seuls mots qu&apos;il verra à l&apos;écran. Laissez vide pour
          garder le mot courant.
        </p>

        <div className="grid gap-3 sm:grid-cols-2">
          {CLES_LEXIQUE.map((cle) => (
            <Champ key={cle} label={LEXIQUE_PAR_DEFAUT[cle]} aide={AIDE_LEXIQUE[cle]}>
              <input
                name={`lexique_${cle}`}
                defaultValue={lexique[cle] === LEXIQUE_PAR_DEFAUT[cle] ? "" : lexique[cle]}
                placeholder={LEXIQUE_PAR_DEFAUT[cle]}
                className={classesChamp}
              />
            </Champ>
          ))}
        </div>
      </fieldset>

      {projetId ? null : (
        <p className="text-xs text-texte-doux">
          Un seul projet moteur est actif à la fois. En enregistrer un nouveau met
          le précédent de côté, sans effacer ce que votre enfant y a accompli.
        </p>
      )}

      <BoutonSoumettre>
        {projetId ? "Enregistrer" : "Créer le projet moteur"}
      </BoutonSoumettre>
    </form>
  );
}
