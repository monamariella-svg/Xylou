"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { MessageErreur, MessageSucces } from "@/components/ui";
import { demanderUnBilan, type EtatGeneration } from "./actions";

/**
 * Le bouton, et surtout ce qu'il dit quand il ne peut rien faire.
 *
 * Un bouton grisé sans explication produit un appel au référent. Chaque raison
 * de blocage arrive donc avec le lien de l'écran qui la règle.
 */

const OU_REGLER: { motif: RegExp; texte: string; lien: (id: string) => string }[] = [
  {
    motif: /pré-bilan/i,
    texte: "Remplir le pré-bilan",
    lien: (id) => `/enfants/${id}/pre-bilan`,
  },
  {
    motif: /autorisation/i,
    texte: "Signer les autorisations",
    lien: (id) => `/enfants/${id}/consentements`,
  },
];

function Bouton({ bloque }: { bloque: boolean }) {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={bloque || pending}
      className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-50"
    >
      {pending ? "Enregistrement…" : "Générer un bilan"}
    </button>
  );
}

export default function BoutonGenerer({
  enfantId,
  raisons,
}: {
  enfantId: string;
  raisons: string[];
}) {
  const [etat, action] = useActionState<EtatGeneration, FormData>(demanderUnBilan, {});
  const bloque = raisons.length > 0;

  return (
    <div className="space-y-3">
      <form action={action}>
        <input type="hidden" name="enfantId" value={enfantId} />
        <Bouton bloque={bloque} />
      </form>

      {bloque && (
        <ul className="space-y-1 text-sm text-texte-doux">
          {raisons.map((raison) => {
            const ou = OU_REGLER.find((o) => o.motif.test(raison));
            return (
              <li key={raison}>
                {raison}{" "}
                {ou && (
                  <a href={ou.lien(enfantId)} className="text-accent underline">
                    {ou.texte}
                  </a>
                )}
              </li>
            );
          })}
        </ul>
      )}

      {etat.erreur && <MessageErreur>{etat.erreur}</MessageErreur>}
      {etat.succes && <MessageSucces>{etat.succes}</MessageSucces>}
    </div>
  );
}
