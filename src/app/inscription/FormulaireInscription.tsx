"use client";

import { useActionState, useState } from "react";
import { creerUnCompte, type EtatAuth } from "./actions";
import { BoutonSoumettre, Champ, MessageErreur, classesChamp } from "@/components/ui";

const ETAT_INITIAL: EtatAuth = {};

export function FormulaireInscription({ invitation }: { invitation?: string }) {
  const [etat, action] = useActionState(creerUnCompte, ETAT_INITIAL);
  const [destination, setDestination] = useState("rejoindre");

  const referent = !invitation && destination === "habilitation";

  return (
    <form action={action} className="mt-6 space-y-4">
      <MessageErreur>{etat.erreur}</MessageErreur>

      {/* Le jeton traverse le formulaire pour que l'action puisse renvoyer sur
          l'invitation une fois le compte créé. Sans lui, la personne se
          retrouve sur son tableau de bord vide, sans savoir que le lien qu'elle
          a suivi attendait encore quelque chose d'elle. */}
      {invitation ? <input type="hidden" name="invitation" value={invitation} /> : null}

      <div className="grid grid-cols-2 gap-3">
        <Champ label="Prénom">
          <input name="prenom" required autoComplete="given-name" className={classesChamp} />
        </Champ>
        <Champ label="Nom">
          <input name="nom" autoComplete="family-name" className={classesChamp} />
        </Champ>
      </div>

      <Champ
        label="Email"
        aide={
          invitation
            ? "Exactement l'adresse qui a reçu l'invitation — sinon elle ne pourra pas être acceptée."
            : undefined
        }
      >
        <input name="email" type="email" required autoComplete="email" className={classesChamp} />
      </Champ>

      <Champ label="Mot de passe" aide="8 caractères au minimum.">
        <input
          name="motDePasse"
          type="password"
          required
          minLength={8}
          autoComplete="new-password"
          className={classesChamp}
        />
      </Champ>

      {/* Ce n'est pas un choix de rôle : personne ne se déclare référent, et la
          demande sera instruite par l'administration. Mais la déclaration est
          une seule et même chose — « je m'inscris, je veux être référent pour
          tel établissement, voici de qui je le tiens » — et la découper en
          écrans successifs oblige à retrouver chaque fois où l'on en était. */}
      {invitation ? null : (
        <fieldset className="rounded-md border border-bordure bg-surface p-4">
          <legend className="px-1 text-sm font-medium">Pourquoi ce compte ?</legend>
          <div className="mt-2 space-y-2">
            <label className="flex gap-3 text-sm">
              <input
                type="radio"
                name="destination"
                value="rejoindre"
                checked={destination === "rejoindre"}
                onChange={() => setDestination("rejoindre")}
                className="mt-1"
              />
              <span>
                <span className="block">Je rejoins le dossier d’un enfant</span>
                <span className="block text-xs text-texte-doux">
                  Parent, enseignant, accompagnant. Le référent vous enverra une
                  invitation.
                </span>
              </span>
            </label>

            <label className="flex gap-3 text-sm">
              <input
                type="radio"
                name="destination"
                value="habilitation"
                checked={destination === "habilitation"}
                onChange={() => setDestination("habilitation")}
                className="mt-1"
              />
              <span>
                <span className="block">Je demande à être référent</span>
                <span className="block text-xs text-texte-doux">
                  Pour ouvrir des dossiers et suivre des enfants. Votre demande sera
                  instruite par l’administration.
                </span>
              </span>
            </label>
          </div>
        </fieldset>
      )}

      {referent ? (
        <fieldset className="space-y-4 rounded-md border border-accent bg-surface p-4">
          <legend className="px-1 text-sm font-medium text-accent">Votre demande</legend>

          <Champ label="Votre fonction" aide="Coordinatrice ULIS, éducatrice spécialisée, enseignante référente…">
            <input name="fonction" required minLength={3} className={classesChamp} />
          </Champ>

          <Champ label="Établissement ou structure" aide="Le collège, l'IME, le service où vous exercez.">
            <input name="organisation" required minLength={2} className={classesChamp} />
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
              className={classesChamp}
            />
          </Champ>

          <Champ label="Numéro professionnel" aide="ADELI, RPPS, ou tout identifiant qui permet de vous vérifier. Facultatif.">
            <input name="numero" className={classesChamp} />
          </Champ>

          {/* Le directeur n'est pas une formalité : c'est la personne que
              l'administration appellera. Elle ne vous connaît pas, et n'a que
              cela pour vérifier. */}
          <Champ label="Nom du directeur ou de la directrice">
            <input name="directeurNom" required minLength={2} className={classesChamp} />
          </Champ>

          <Champ label="Comment le joindre" aide="Adresse électronique ou téléphone de l'établissement.">
            <input name="directeurContact" required minLength={5} className={classesChamp} />
          </Champ>

          <Champ label="Quelques mots" aide="Ce que vous accompagnez, et pourquoi vous avez besoin d'ouvrir des dossiers.">
            <textarea name="motivation" rows={3} className={classesChamp} />
          </Champ>

          <p className="text-xs text-texte-doux">
            Vous joindrez vos pièces justificatives à l’écran suivant — attestation de
            direction, carte professionnelle, agrément. La demande n’est complète
            qu’avec elles.
          </p>
        </fieldset>
      ) : null}

      <BoutonSoumettre>
        {referent ? "Créer mon compte et envoyer ma demande" : "Créer mon compte"}
      </BoutonSoumettre>
    </form>
  );
}
