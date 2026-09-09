"use client";

import { useActionState } from "react";
import { BoutonSoumettre, MessageErreur, MessageSucces } from "@/components/ui";
import {
  AIDE_NOTIFICATION,
  LIBELLE_NOTIFICATION,
  type TypeNotification,
} from "@/lib/domaine";
import { enregistrerPreferences, type EtatPreferences } from "./actions";

export type Reglage = { type: string; actif: boolean };

// La base peut connaître un type que les libellés ne connaissent pas encore :
// `types_notifies_hors_application()` suit le type Postgres, et une migration
// peut précéder le déploiement de l'interface. Afficher le code brut plutôt que
// de laisser une ligne vide — une case sans intitulé se coche au hasard.
function libelle(type: string): string {
  return LIBELLE_NOTIFICATION[type as TypeNotification] ?? type;
}

function aide(type: string): string {
  return AIDE_NOTIFICATION[type as TypeNotification] ?? "";
}

export function FormulairePreferences({ reglages }: { reglages: Reglage[] }) {
  const [etat, action] = useActionState<EtatPreferences, FormData>(
    enregistrerPreferences,
    {},
  );

  return (
    <form action={action} className="space-y-4">
      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      <fieldset className="space-y-2">
        <legend className="sr-only">Notifications reçues par courriel</legend>

        {reglages.map((r) => (
          <label
            key={r.type}
            className="flex items-start gap-3 rounded-lg border border-bordure bg-surface p-3"
          >
            <input
              type="checkbox"
              name={`courriel:${r.type}`}
              defaultChecked={r.actif}
              className="mt-0.5 h-4 w-4 accent-[var(--accent)]"
            />
            <span>
              <span className="block text-sm font-medium">{libelle(r.type)}</span>
              {aide(r.type) ? (
                <span className="mt-0.5 block text-xs text-texte-doux">{aide(r.type)}</span>
              ) : null}
            </span>
          </label>
        ))}
      </fieldset>

      <BoutonSoumettre>Enregistrer</BoutonSoumettre>
    </form>
  );
}
