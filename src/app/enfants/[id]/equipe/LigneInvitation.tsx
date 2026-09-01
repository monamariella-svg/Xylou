"use client";

import { useActionState, useState } from "react";
import { annulerInvitation, corrigerAdresse, type EtatInvitation } from "./actions";
import { BoutonSoumettre, MessageErreur } from "@/components/ui";

const ETAT_INITIAL: EtatInvitation = {};

const LIBELLE_ROLE: Record<string, string> = {
  parent: "Titulaire de l’autorité parentale",
  referent: "Référent",
  enseignant: "Enseignant",
  accompagnant: "AESH ou accompagnant",
};

export function LigneInvitation({
  enfantId,
  invitation,
}: {
  enfantId: string;
  invitation: { id: string; email: string; role: string };
}) {
  const [ouvert, setOuvert] = useState(false);
  const [etat, action] = useActionState(corrigerAdresse, ETAT_INITIAL);

  return (
    <li className="rounded-lg border border-bordure bg-surface p-4 text-sm">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span>
          <span className="font-medium">{invitation.email}</span>
          <span className="ml-2 text-xs text-texte-doux">
            {LIBELLE_ROLE[invitation.role] ?? invitation.role}
          </span>
        </span>

        <span className="flex gap-2">
          <button
            type="button"
            onClick={() => setOuvert((o) => !o)}
            className="rounded-md border border-bordure px-3 py-1 text-xs hover:border-accent hover:text-accent"
          >
            {ouvert ? "Fermer" : "Corriger l’adresse"}
          </button>

          <form action={annulerInvitation}>
            <input type="hidden" name="id" value={invitation.id} />
            <input type="hidden" name="enfantId" value={enfantId} />
            <button
              type="submit"
              className="rounded-md border border-bordure px-3 py-1 text-xs hover:border-alerte hover:text-alerte"
            >
              Annuler
            </button>
          </form>
        </span>
      </div>

      {ouvert ? (
        <form action={action} className="mt-3 space-y-2">
          <input type="hidden" name="id" value={invitation.id} />
          <input type="hidden" name="enfantId" value={enfantId} />

          {/* Dit avant le clic, pas après : la correction n'est pas une retouche
              de l'adresse, c'est une nouvelle invitation. Quelqu'un qui a déjà
              transmis le premier lien doit savoir qu'il vient de l'éteindre. */}
          <p className="text-xs text-texte-doux">
            Le rôle et les matières sont conservés. L’ancien lien cesse de fonctionner :
            s’il a déjà été transmis, il faudra envoyer le nouveau.
          </p>

          <div className="flex flex-wrap gap-2">
            <input
              name="email"
              type="email"
              required
              defaultValue={invitation.email}
              className="flex-1 rounded-md border border-bordure bg-fond px-2 py-1 text-sm"
            />
            <BoutonSoumettre>Réémettre</BoutonSoumettre>
          </div>

          <MessageErreur>{etat.erreur}</MessageErreur>

          {etat.lien ? (
            <div className="rounded-md border border-accent bg-accent-doux p-3">
              <p className="text-sm font-medium text-accent">{etat.succes}</p>
              <p className="mt-1 text-xs text-texte-doux">
                Transmettez ce lien à la personne. Il vaut 30 jours, et ne fonctionnera
                que depuis un compte créé avec cette adresse.
              </p>
              <code className="mt-2 block break-all rounded bg-surface px-2 py-1 text-xs">
                {etat.lien}
              </code>
            </div>
          ) : null}
        </form>
      ) : null}
    </li>
  );
}
