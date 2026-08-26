"use client";

import { useState, useTransition } from "react";
import { createClient } from "@/lib/supabase/client";
import { Champ, MessageErreur, classesChamp } from "@/components/ui";

const TYPES = [
  { valeur: "piece_identite", libelle: "Pièce d’identité" },
  { valeur: "carte_professionnelle", libelle: "Carte professionnelle" },
  { valeur: "attestation_employeur", libelle: "Attestation d’employeur" },
  { valeur: "attestation_direction", libelle: "Attestation du directeur d’établissement" },
  { valeur: "diplome", libelle: "Diplôme" },
  { valeur: "agrement", libelle: "Agrément (MDPH, ARS, association)" },
  { valeur: "assurance_responsabilite", libelle: "Assurance responsabilité civile" },
  { valeur: "autre", libelle: "Autre" },
] as const;

export type Piece = {
  id: string;
  type_piece: string;
  libelle: string;
  delivree_le: string | null;
  valable_jusqu_au: string | null;
};

export function PiecesJustificatives({
  demandeId,
  pieces,
}: {
  demandeId: string;
  pieces: Piece[];
}) {
  const [erreur, setErreur] = useState<string | null>(null);
  const [enCours, demarrer] = useTransition();
  const [liste, setListe] = useState<Piece[]>(pieces);

  async function envoyer(formData: FormData) {
    setErreur(null);

    const fichier = formData.get("fichier") as File | null;
    if (!fichier || fichier.size === 0) {
      setErreur("Choisissez un fichier.");
      return;
    }

    // 10 Mo : au-delà, c'est une photo non compressée plutôt qu'un document, et
    // le refuser ici épargne un aller-retour qui échouerait côté stockage.
    if (fichier.size > 10 * 1024 * 1024) {
      setErreur("Ce fichier dépasse 10 Mo. Réduisez-le, ou photographiez le document plutôt que de le scanner en pleine résolution.");
      return;
    }

    const supabase = createClient();

    // Le fichier part directement du navigateur vers le stockage, sans passer
    // par une action serveur : une pièce d'identité scannée dépasse vite la
    // taille qu'un corps de requête accepte, et la faire transiter n'apporterait
    // rien — la politique de 0054 vérifie déjà que le chemin correspond à une
    // demande dont l'appelant est l'auteur.
    const nom = fichier.name.replace(/[^\w.\-]/g, "_");
    const chemin = `${demandeId}/${Date.now()}_${nom}`;

    const { error: erreurDepot } = await supabase.storage
      .from("habilitations")
      .upload(chemin, fichier, { upsert: false });

    if (erreurDepot) {
      setErreur(`L’envoi a échoué : ${erreurDepot.message}`);
      return;
    }

    const { data, error } = await supabase
      .from("habilitation_pieces")
      .insert({
        demande_id: demandeId,
        type_piece: String(formData.get("typePiece") ?? "autre"),
        libelle: fichier.name,
        chemin,
        delivree_le: String(formData.get("delivreeLe") ?? "") || null,
        valable_jusqu_au: String(formData.get("valableJusquAu") ?? "") || null,
      })
      .select("id, type_piece, libelle, delivree_le, valable_jusqu_au")
      .single();

    if (error || !data) {
      // Le fichier est déjà déposé : le laisser sans ligne le rendrait
      // invisible et impossible à retrouver. On le retire.
      await supabase.storage.from("habilitations").remove([chemin]);
      setErreur(`Le document n’a pas pu être enregistré : ${error?.message ?? ""}`);
      return;
    }

    setListe((actuelle) => [...actuelle, data as Piece]);
  }

  return (
    <section className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Pièces justificatives</h2>
        <p className="mt-1 text-sm text-texte-doux">
          Elles ne sont lues que par l’administration, et jamais par les familles. Vous
          pouvez en envoyer plusieurs, et en retirer tant que la demande n’est pas
          instruite.
        </p>
      </div>

      {liste.length > 0 ? (
        <ul className="space-y-2">
          {liste.map((p) => {
            const perimee =
              p.valable_jusqu_au !== null && new Date(p.valable_jusqu_au) < new Date();
            return (
              <li
                key={p.id}
                className="flex flex-wrap items-baseline justify-between gap-2 rounded-md border border-bordure bg-surface p-3 text-sm"
              >
                <span>
                  <span className="font-medium">
                    {TYPES.find((t) => t.valeur === p.type_piece)?.libelle ?? p.type_piece}
                  </span>
                  <span className="ml-2 text-xs text-texte-doux">{p.libelle}</span>
                </span>
                {p.valable_jusqu_au ? (
                  <span className={perimee ? "text-xs text-alerte" : "text-xs text-texte-doux"}>
                    {perimee ? "périmée le " : "valable jusqu’au "}
                    {new Date(p.valable_jusqu_au).toLocaleDateString("fr-FR")}
                  </span>
                ) : null}
              </li>
            );
          })}
        </ul>
      ) : null}

      <form
        action={(formData) => demarrer(() => void envoyer(formData))}
        className="space-y-4 rounded-lg border border-bordure bg-surface p-4"
      >
        <Champ label="Nature du document">
          <select name="typePiece" defaultValue="attestation_direction" className={classesChamp}>
            {TYPES.map((t) => (
              <option key={t.valeur} value={t.valeur}>
                {t.libelle}
              </option>
            ))}
          </select>
        </Champ>

        <div className="grid gap-4 sm:grid-cols-2">
          <Champ label="Délivré le" aide="Facultatif, mais utile.">
            <input type="date" name="delivreeLe" className={classesChamp} />
          </Champ>
          <Champ
            label="Valable jusqu’au"
            aide="Une attestation datée rassure ; une attestation périmée ne prouve rien."
          >
            <input type="date" name="valableJusquAu" className={classesChamp} />
          </Champ>
        </div>

        <Champ label="Document" aide="PDF ou photo, 10 Mo maximum.">
          <input
            type="file"
            name="fichier"
            required
            accept="application/pdf,image/*"
            className="w-full text-sm"
          />
        </Champ>

        <MessageErreur>{erreur}</MessageErreur>

        <button
          type="submit"
          disabled={enCours}
          className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:opacity-90 disabled:opacity-50"
        >
          {enCours ? "Envoi…" : "Envoyer ce document"}
        </button>
      </form>
    </section>
  );
}
