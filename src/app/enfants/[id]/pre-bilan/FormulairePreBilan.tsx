"use client";

import { useActionState } from "react";
import { BoutonSoumettre, MessageErreur, MessageSucces } from "@/components/ui";
import {
  domaineSansScore,
  nomChampItem,
  nomChampNote,
  nomChampSynthese,
  AIDE_DIRECTION,
  MENTION_SANS_SCORE,
  type FormulairePreBilan as Formulaire,
  type ItemPreBilan,
} from "@/lib/pre-bilan";
import { enregistrerPreBilan, type EtatPreBilan } from "./actions";

export type ReponseSaisie = { item_code: string; valeur: number | null; note: string };

export function FormulairePreBilan({
  enfantId,
  observationId,
  formulaire,
  reponses,
  synthese,
  termine,
}: {
  enfantId: string;
  observationId: string;
  formulaire: Formulaire;
  reponses: ReponseSaisie[];
  synthese: Record<string, string>;
  termine: boolean;
}) {
  const [etat, action] = useActionState<EtatPreBilan, FormData>(enregistrerPreBilan, {});

  const deja = new Map(reponses.map((r) => [r.item_code, r]));
  const options = formulaire.scale.options;

  return (
    <form action={action} className="space-y-8">
      <input type="hidden" name="observationId" value={observationId} />
      <input type="hidden" name="enfantId" value={enfantId} />

      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      {formulaire.domains.map((domaine) => {
        const sansScore = domaineSansScore(domaine);

        return (
          <section
            key={domaine.id}
            className="rounded-lg border border-bordure bg-surface p-5"
          >
            <h2 className="text-lg font-medium">{domaine.title}</h2>
            {sansScore ? (
              <p className="mt-1 text-sm text-texte-doux">{MENTION_SANS_SCORE}</p>
            ) : null}

            <ul className="mt-4 space-y-5">
              {domaine.items.map((item) => (
                <Item
                  key={item.id}
                  item={item}
                  options={options}
                  saisie={deja.get(item.id)}
                />
              ))}
            </ul>
          </section>
        );
      })}

      {/* Le texte libre après les cases, et non avant : on écrit mieux sur un
          enfant après avoir passé en revue ce qu'il fait, et la question qui
          compte le plus — une évaluation ratée alors qu'il maîtrisait — demande
          d'avoir la tête dans le sujet. */}
      <section className="rounded-lg border border-bordure bg-surface p-5">
        <h2 className="text-lg font-medium">Ce que les cases ne disent pas</h2>
        <p className="mt-1 text-sm text-texte-doux">
          Facultatif, mais c&apos;est souvent ici que se trouve ce qui change
          vraiment la façon de poser les questions.
        </p>

        <div className="mt-4 space-y-5">
          {formulaire.synthesis_fields.map((champ) => (
            <label key={champ.id} className="block">
              <span className="mb-1 block text-sm font-medium">{champ.label}</span>
              <textarea
                name={nomChampSynthese(champ.id)}
                defaultValue={synthese[champ.id] ?? ""}
                rows={3}
                className="w-full rounded-md border border-bordure bg-surface px-3 py-2 text-sm focus:border-accent focus:outline-none"
              />
            </label>
          ))}
        </div>
      </section>

      {/* Deux boutons, deux gestes différents. 72 questions ne se remplissent
          pas d'une traite, et obliger à aller au bout produirait des réponses
          au hasard vers la fin — exactement les données sur lesquelles le bilan
          serait ensuite calibré. */}
      <div className="flex flex-wrap items-center gap-3">
        <BoutonSoumettre variante="discret">Enregistrer et reprendre plus tard</BoutonSoumettre>
        <button
          type="submit"
          name="terminer"
          value="1"
          className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:opacity-90"
        >
          {termine ? "Enregistrer les modifications" : "Terminer le pré-bilan"}
        </button>
      </div>
    </form>
  );
}

function Item({
  item,
  options,
  saisie,
}: {
  item: ItemPreBilan;
  options: { value: number; label: string }[];
  saisie?: ReponseSaisie;
}) {
  const aide = AIDE_DIRECTION[item.direction];
  const valeur = saisie?.valeur;

  return (
    <li>
      <fieldset>
        <legend className="text-sm">
          {item.label}
          {aide ? (
            <span className="ml-2 text-xs text-texte-doux">{aide}</span>
          ) : null}
        </legend>

        <div className="mt-2 flex flex-wrap gap-x-5 gap-y-2">
          {options.map((o) => (
            <label key={o.value} className="flex items-center gap-1.5 text-sm">
              <input
                type="radio"
                name={nomChampItem(item.id)}
                value={String(o.value)}
                defaultChecked={valeur === o.value}
                className="h-4 w-4 accent-[var(--accent)]"
              />
              {o.label}
            </label>
          ))}

          {/* Coché par défaut, et c'est voulu : tant que personne n'a répondu,
              la vérité est qu'on ne l'a pas observé. Laisser les quatre cases
              vides pousserait à en cocher une pour « finir la ligne ». */}
          <label className="flex items-center gap-1.5 text-sm text-texte-doux">
            <input
              type="radio"
              name={nomChampItem(item.id)}
              value=""
              defaultChecked={valeur === undefined || valeur === null}
              className="h-4 w-4 accent-[var(--accent)]"
            />
            Pas encore observé
          </label>
        </div>

        {item.note_field ? (
          <input
            type="text"
            name={nomChampNote(item.id)}
            defaultValue={saisie?.note ?? ""}
            placeholder="Précisez, si vous le souhaitez"
            className="mt-2 w-full rounded-md border border-bordure bg-surface px-3 py-1.5 text-sm focus:border-accent focus:outline-none"
          />
        ) : null}
      </fieldset>
    </li>
  );
}
