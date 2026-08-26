"use client";

import { useActionState, useState } from "react";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";
import { inviter, type EtatInvitation } from "./actions";

const ROLES = [
  {
    valeur: "parent",
    libelle: "Titulaire de l’autorité parentale",
    aide: "Signe les autorisations et valide les objectifs. Réservé au référent.",
  },
  {
    valeur: "referent",
    libelle: "Référent",
    aide: "Suit le dossier. Un suppléant a les mêmes accès, sans la signature.",
  },
  {
    valeur: "enseignant",
    libelle: "Enseignant",
    aide: "Voit tout le scolaire, écrit dans sa matière seulement.",
  },
  {
    valeur: "accompagnant",
    libelle: "AESH ou accompagnant",
    aide: "Voit le suivi quotidien. Ni le diagnostic, ni les copies.",
  },
] as const;

export function FormulaireInvitation({
  enfantId,
  matieres,
}: {
  enfantId: string;
  matieres: { code: string; libelle: string }[];
}) {
  const [etat, action] = useActionState<EtatInvitation, FormData>(inviter, {});
  const [role, setRole] = useState<string>("enseignant");
  const [toutes, setToutes] = useState(false);

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="enfantId" value={enfantId} />

      <Champ label="Adresse électronique">
        <input
          name="email"
          type="email"
          required
          autoComplete="off"
          className={classesChamp}
          placeholder="prenom.nom@exemple.fr"
        />
      </Champ>

      <fieldset>
        <legend className="mb-2 text-sm font-medium">Rôle</legend>
        <div className="space-y-2">
          {ROLES.map((r) => (
            <label
              key={r.valeur}
              className="flex gap-3 rounded-md border border-bordure bg-surface p-3"
            >
              <input
                type="radio"
                name="role"
                value={r.valeur}
                checked={role === r.valeur}
                onChange={() => setRole(r.valeur)}
                className="mt-1"
              />
              <span>
                <span className="block text-sm font-medium">{r.libelle}</span>
                <span className="block text-xs text-texte-doux">{r.aide}</span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      <Champ
        label="Fonction"
        aide="En clair : « coordinatrice ULIS », « professeure de mathématiques », « AVS ». Facultatif."
      >
        <input name="fonction" className={classesChamp} />
      </Champ>

      {/* Les matières ne concernent que les enseignants. Les afficher pour les
          autres rôles ferait croire qu'elles comptent, alors que la base les
          ignore. */}
      {role === "enseignant" ? (
        <fieldset className="rounded-md border border-bordure bg-surface p-4">
          <legend className="px-1 text-sm font-medium">Matières enseignées</legend>

          <label className="mb-3 flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              name="toutesMatieres"
              value="oui"
              checked={toutes}
              onChange={(e) => setToutes(e.target.checked)}
            />
            Toutes les matières
            <span className="text-xs text-texte-doux">(professeur des écoles)</span>
          </label>

          {!toutes ? (
            <div className="grid gap-2 sm:grid-cols-2">
              {matieres.map((m) => (
                <label key={m.code} className="flex items-center gap-2 text-sm">
                  <input type="checkbox" name="matieres" value={m.code} />
                  {m.libelle}
                </label>
              ))}
            </div>
          ) : null}
        </fieldset>
      ) : null}

      <MessageErreur>{etat.erreur}</MessageErreur>

      {/* Pas d'envoi automatique : aucun service de courriel n'est branché. Le
          lien s'affiche pour être transmis à la main, et le dire évite d'attendre
          un message qui ne partira pas. */}
      {etat.lien ? (
        <div className="rounded-md border border-accent bg-accent-doux p-3 text-sm">
          <p className="font-medium text-accent">{etat.succes}</p>
          <p className="mt-1 text-xs text-texte-doux">
            Aucun courriel n’est envoyé : transmettez ce lien à la personne. Il vaut 30
            jours, et ne fonctionnera que depuis un compte créé avec cette adresse.
          </p>
          <code className="mt-2 block break-all rounded bg-surface px-2 py-1 text-xs">
            {etat.lien}
          </code>
        </div>
      ) : null}

      <BoutonSoumettre>Créer l’invitation</BoutonSoumettre>
    </form>
  );
}
