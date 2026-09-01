"use client";

import { useState, useTransition } from "react";
import { Champ, classesChamp } from "@/components/ui";
import { chercherParUai } from "@/lib/annuaire-education";

/**
 * Les champs qui décrivent l'établissement, partagés par l'inscription et la
 * page d'habilitation.
 *
 * L'UAI vient en premier parce qu'il remplit les suivants. C'est l'ordre de la
 * commodité, pas celui de l'importance : l'adresse reste l'exigence, l'UAI est
 * le raccourci quand il existe.
 */
export function ChampsEtablissement() {
  const [enCours, demarrer] = useTransition();
  const [uai, setUai] = useState("");
  const [nom, setNom] = useState("");
  const [adresse, setAdresse] = useState("");
  const [message, setMessage] = useState<string | null>(null);

  function rechercher() {
    setMessage(null);
    demarrer(async () => {
      const etablissement = await chercherParUai(uai);

      if (!etablissement) {
        // Ni erreur ni blocage : le raccourci n'a pas fonctionné, la saisie
        // manuelle reste ouverte et c'est tout ce qui compte.
        setMessage(
          "Établissement introuvable dans l’annuaire public. Vérifiez le code, ou renseignez les champs à la main.",
        );
        return;
      }

      if (etablissement.nom) setNom(etablissement.nom);
      if (etablissement.adresse) setAdresse(etablissement.adresse);
      setMessage(
        etablissement.telephone
          ? `Trouvé. Téléphone de l’établissement : ${etablissement.telephone}`
          : "Trouvé.",
      );
    });
  }

  return (
    <>
      <Champ
        label="Code UAI de l’établissement"
        aide="Sept chiffres et une lettre, par exemple 0123456A. Il figure sur les documents officiels de l'établissement. Laissez vide si votre structure n'en a pas — les IME et SESSAD relèvent d'un autre répertoire."
      >
        <div className="flex gap-2">
          <input
            name="uai"
            value={uai}
            onChange={(e) => setUai(e.target.value.toUpperCase())}
            maxLength={8}
            placeholder="0123456A"
            className={classesChamp}
          />
          <button
            type="button"
            onClick={rechercher}
            disabled={enCours || uai.length !== 8}
            className="shrink-0 rounded-md border border-bordure px-3 py-2 text-sm hover:border-accent hover:text-accent disabled:opacity-40"
          >
            {enCours ? "…" : "Rechercher"}
          </button>
        </div>
      </Champ>

      {message ? <p className="-mt-2 text-xs text-texte-doux">{message}</p> : null}

      <Champ label="Établissement ou structure" aide="Le collège, l'IME, le service où vous exercez.">
        <input
          name="organisation"
          required
          minLength={2}
          value={nom}
          onChange={(e) => setNom(e.target.value)}
          className={classesChamp}
        />
      </Champ>

      <Champ
        label="Adresse de l’établissement"
        aide="Son nom seul ne l'identifie pas : il existe une trentaine de « collège Jean Moulin » en France."
      >
        <textarea
          name="etablissementAdresse"
          required
          minLength={5}
          rows={2}
          value={adresse}
          onChange={(e) => setAdresse(e.target.value)}
          className={classesChamp}
        />
      </Champ>
    </>
  );
}
