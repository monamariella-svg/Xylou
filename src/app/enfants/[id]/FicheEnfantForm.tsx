"use client";

import { useActionState } from "react";
import { majFicheEnfant, type EtatFormulaire } from "../actions";
import {
  AIDE_COMMUNICATION,
  LIBELLE_CLASSE,
  LIBELLE_COMMUNICATION,
  NIVEAUX_CLASSE,
  PROFILS_COMMUNICATION,
  type NiveauClasse,
  type ProfilCommunication,
} from "@/lib/domaine";
import {
  BoutonSoumettre,
  Champ,
  MessageErreur,
  MessageSucces,
  classesChamp,
} from "@/components/ui";

const ETAT_INITIAL: EtatFormulaire = {};

export default function FicheEnfantForm({
  enfantId,
  prenom,
  nom,
  classe,
  communication,
  dateNaissance,
}: {
  enfantId: string;
  prenom: string;
  nom: string;
  classe: NiveauClasse | null;
  communication: ProfilCommunication;
  dateNaissance: string | null;
}) {
  const [etat, action] = useActionState(majFicheEnfant, ETAT_INITIAL);

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="enfantId" value={enfantId} />
      <MessageErreur>{etat.erreur}</MessageErreur>
      <MessageSucces>{etat.succes}</MessageSucces>

      <div className="grid gap-4 sm:grid-cols-2">
        <Champ label="Prénom">
          <input name="prenom" defaultValue={prenom} required className={classesChamp} />
        </Champ>

        <Champ label="Nom" aide="Facultatif. Pour distinguer deux enfants du même prénom.">
          <input name="nom" defaultValue={nom} className={classesChamp} />
        </Champ>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Champ label="Classe">
          <select name="classe" defaultValue={classe ?? ""} className={classesChamp}>
            <option value="">Non renseignée</option>
            {NIVEAUX_CLASSE.map((niveau) => (
              <option key={niveau} value={niveau}>
                {LIBELLE_CLASSE[niveau]}
              </option>
            ))}
          </select>
        </Champ>

        <Champ label="Date de naissance">
          <input
            name="dateNaissance"
            type="date"
            defaultValue={dateNaissance ?? ""}
            className={classesChamp}
          />
        </Champ>
      </div>

      <Champ label="Communication" aide={AIDE_COMMUNICATION[communication]}>
        <select name="communication" defaultValue={communication} className={classesChamp}>
          {PROFILS_COMMUNICATION.map((profil) => (
            <option key={profil} value={profil}>
              {LIBELLE_COMMUNICATION[profil]}
            </option>
          ))}
        </select>
      </Champ>

      <BoutonSoumettre>Enregistrer</BoutonSoumettre>
    </form>
  );
}
