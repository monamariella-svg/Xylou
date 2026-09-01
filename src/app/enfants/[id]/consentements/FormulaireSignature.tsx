"use client";

import { useActionState } from "react";
import { BoutonSoumettre, MessageErreur, MessageSucces, classesChamp } from "@/components/ui";
import type { TexteASigner } from "@/lib/consentements";
import { signerLesConsentements, type EtatSignature } from "./actions";

export function FormulaireSignature({
  enfantId,
  textes,
}: {
  enfantId: string;
  textes: TexteASigner[];
}) {
  const [etat, action] = useActionState<EtatSignature, FormData>(signerLesConsentements, {});

  return (
    <form action={action} className="space-y-6">
      <input type="hidden" name="enfantId" value={enfantId} />

      {textes.map((texte) => (
        <section
          key={texte.texte_id}
          className="rounded-lg border border-bordure bg-surface p-4"
        >
          <div className="mb-2 flex flex-wrap items-baseline gap-2">
            <h2 className="text-base font-semibold">{texte.titre}</h2>
            {/* Plus de mention « facultatif » : depuis 0066, les quatre textes
                conditionnent le fonctionnement de l'outil. Laisser l'étiquette
                pour le cas contraire, c'est afficher une possibilité que la
                base refuse ensuite. */}
            <span className="text-xs text-texte-doux">
              {texte.obligatoire ? "Nécessaire au fonctionnement" : "Sans effet sur l’accès"}
            </span>
          </div>

          {/* Le texte tel qu'il est enregistré, sans reformulation : c'est lui
              qui sera rattaché à la signature, et l'afficher autrement qu'il
              n'est stocké ferait signer autre chose que ce qui est conservé. */}
          <p className="whitespace-pre-line text-sm leading-relaxed text-texte-doux">
            {texte.contenu}
          </p>

          <fieldset className="mt-4 flex flex-wrap gap-4">
            <legend className="sr-only">{texte.titre}</legend>

            <label className="flex items-center gap-2 text-sm">
              <input
                type="radio"
                name={`choix_${texte.type}`}
                value="accepte"
                required
                defaultChecked={texte.obligatoire}
              />
              J’accepte
            </label>

            {/* Pas d'option de refus sur un consentement nécessaire : la base la
                rejetterait, et proposer un choix impossible n'est pas un choix. */}
            {texte.obligatoire ? (
              <span className="text-xs text-texte-doux">
                Sans cette autorisation, le dossier ne peut pas être utilisé.
              </span>
            ) : (
              <label className="flex items-center gap-2 text-sm">
                <input type="radio" name={`choix_${texte.type}`} value="refuse" required />
                Je refuse
              </label>
            )}
          </fieldset>
        </section>
      ))}

      <div className="rounded-lg border border-bordure bg-surface p-4">
        <label className="block">
          <span className="mb-1 block text-sm font-medium">Votre nom, pour signer</span>
          <input
            name="signature"
            required
            minLength={2}
            autoComplete="name"
            className={classesChamp}
            placeholder="Prénom et nom"
          />
          <span className="mt-1 block text-xs text-texte-doux">
            Votre nom, la date et l’adresse de connexion sont conservés avec le texte que
            vous venez de lire. Vous pourrez retirer votre accord à tout moment.
          </span>
        </label>
      </div>

      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      <BoutonSoumettre>Signer</BoutonSoumettre>
    </form>
  );
}
