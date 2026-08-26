// Les textes de consentement ne vivent plus ici.
//
// Ils étaient en dur dans ce fichier, avec un identifiant de version en
// constante. La migration 0037 les a déplacés dans `textes_consentement` : une
// table versionnée, figée après publication, à laquelle chaque signature se
// rattache par clé étrangère.
//
// Ce n'est pas un déménagement de confort. Un texte en constante se modifie par
// un commit, et rien ne relie alors une signature d'hier à ce qui était affiché
// hier — la preuve du consentement repose sur l'historique Git, ce qui ne vaut
// rien devant qui conteste. En base, un texte publié ne se réécrit pas : on en
// publie une nouvelle version, et les signatures anciennes continuent de
// pointer sur ce que les gens avaient réellement sous les yeux.
//
// Ce fichier ne contient donc plus que les types et les accès.

import { createClient } from "@/lib/supabase/server";

export type TypeConsentement =
  | "traitement_donnees_sante"
  | "partage_equipe_pedagogique"
  | "generation_ia"
  | "conservation_historique";

/** Un texte en vigueur que la personne connectée n'a pas encore signé. */
export type TexteASigner = {
  texte_id: string;
  type: TypeConsentement;
  version: string;
  titre: string;
  contenu: string;
  obligatoire: boolean;
};

/** Où en est un consentement pour l'enfant, tous titulaires confondus. */
export type EtatConsentement = {
  type: TypeConsentement;
  titre: string;
  obligatoire: boolean;
  titulaires_attendus: number;
  titulaires_rattaches: number;
  signatures: number;
  actif: boolean;
  /** Prénoms des titulaires qui n'ont pas encore signé, séparés par des virgules. */
  manquants: string;
};

export async function textesASigner(enfantId: string): Promise<TexteASigner[]> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("consentements_a_signer", { p_enfant: enfantId });
  return (data ?? []) as TexteASigner[];
}

export async function etatDesConsentements(enfantId: string): Promise<EtatConsentement[]> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("etat_des_consentements", { p_enfant: enfantId });
  return (data ?? []) as EtatConsentement[];
}

/**
 * Un dossier est utilisable quand tous les consentements obligatoires sont
 * actifs — c'est-à-dire signés par *tous* les titulaires de l'autorité
 * parentale, pas seulement par celui qui regarde l'écran.
 *
 * Sert à afficher un avertissement avant que l'équipe se demande pourquoi elle
 * ne voit rien : depuis 0051, un dossier sans consentement est inerte pour les
 * enseignants et pour l'IA.
 */
export function dossierUtilisable(etats: EtatConsentement[]): boolean {
  return etats.filter((e) => e.obligatoire).every((e) => e.actif);
}
