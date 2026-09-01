import Link from "next/link";
import { notFound } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";
import { nomAffiche } from "@/lib/domaine";
import { FormulaireInvitation } from "./FormulaireInvitation";
import { retirerDuDossier } from "./actions";
import { LigneInvitation } from "./LigneInvitation";

const LIBELLE_ROLE: Record<string, string> = {
  parent: "Titulaire de l’autorité parentale",
  referent: "Référent",
  enseignant: "Enseignant",
  accompagnant: "AESH ou accompagnant",
};

type Profil = { prenom: string | null; nom: string | null; email: string | null };

// Sans types générés, l'inférence ne sait pas que `profils` est un lien de
// plusieurs vers un : elle le prend pour un tableau. PostgREST, lui, renvoie
// tantôt l'objet, tantôt le tableau selon ce qu'il détecte de la clé étrangère.
// On accepte les deux plutôt que de parier sur l'un — un cast optimiste
// passerait le build et casserait à l'affichage.
function premierProfil(valeur: unknown): Profil | null {
  if (!valeur) return null;
  if (Array.isArray(valeur)) return (valeur[0] as Profil) ?? null;
  return valeur as Profil;
}

function nommer(profil: Profil | null): string {
  if (!profil) return "Compte inconnu";
  const nom = [profil.prenom, profil.nom].filter(Boolean).join(" ").trim();
  return nom || profil.email || "Compte sans nom";
}

export default async function PageEquipe({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { supabase } = await exigerUtilisateur();

  const { data: enfant } = await supabase
    .from("enfants")
    .select("id, prenom, nom, titulaires_autorite_parentale")
    .eq("id", id)
    .maybeSingle();

  if (!enfant) notFound();

  const [{ data: peutComposer }, { data: intervenants }, { data: invitations }, { data: matieres }] =
    await Promise.all([
      supabase.rpc("peut_composer_l_equipe", { p_enfant: id }),
      supabase
        .from("intervenants_enfant")
        .select("id, profil_id, role, fonction, principal, toutes_matieres, profils(prenom, nom, email)")
        .eq("enfant_id", id)
        .is("retire_le", null)
        .order("role"),
      supabase
        .from("invitations")
        .select("id, email, role, fonction, expire_le, acceptee_le, annulee_le")
        .eq("enfant_id", id)
        .is("acceptee_le", null)
        .is("annulee_le", null)
        .order("cree_le", { ascending: false }),
      supabase.from("matieres").select("code, libelle").order("ordre"),
    ]);

  const parents = (intervenants ?? []).filter((i) => i.role === "parent");
  const manqueTitulaire =
    parents.length < (enfant.titulaires_autorite_parentale ?? 2);

  return (
    <main className="mx-auto max-w-3xl space-y-8 px-4 py-8">
      <header className="space-y-1">
        <Link href={`/enfants/${id}`} className="text-sm text-texte-doux hover:underline">
          ← Dossier de {nomAffiche(enfant.prenom, enfant.nom)}
        </Link>
        <h1 className="text-2xl font-semibold">Équipe</h1>
        <p className="max-w-prose text-sm text-texte-doux">
          Qui accompagne {enfant.prenom}, et à quel titre. Chacun entre par une
          invitation qu’il accepte lui-même — personne n’est rattaché à son insu.
        </p>
      </header>

      {/* Le blocage le plus fréquent, annoncé avant qu'il se manifeste : sans
          tous les titulaires rattachés, rien ne se valide et rien ne s'active. */}
      {manqueTitulaire ? (
        <p className="rounded-md border border-alerte bg-alerte-douce px-4 py-3 text-sm text-alerte">
          {enfant.titulaires_autorite_parentale} titulaires de l’autorité parentale sont
          déclarés, {parents.length} a rejoint le dossier. Tant qu’il en manque un, aucun
          objectif ne se valide et aucune autorisation ne devient effective.
        </p>
      ) : null}

      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Rattachés au dossier</h2>

        <ul className="space-y-2">
          {(intervenants ?? []).map((i) => {
            const profil = premierProfil(i.profils);
            return (
              <li
                key={i.id}
                className="rounded-lg border border-bordure bg-surface p-4 text-sm"
              >
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <span className="font-medium">{nommer(profil)}</span>
                  <span className="text-xs text-texte-doux">
                    {LIBELLE_ROLE[i.role] ?? i.role}
                    {i.role === "referent" && i.principal ? " · principal" : ""}
                    {i.role === "referent" && !i.principal ? " · suppléant" : ""}
                    {i.role === "enseignant" && i.toutes_matieres ? " · toutes matières" : ""}
                  </span>
                </div>

                {i.fonction ? (
                  <p className="mt-1 text-xs text-texte-doux">{i.fonction}</p>
                ) : null}

                {/* Un titulaire de l'autorité parentale ne se retire pas d'ici :
                    la fonction de 0033 le refuse, et le proposer laisserait
                    croire l'inverse. Depuis 0062, le retrait revient au
                    référent — proposer le bouton à un parent produirait un
                    refus au clic. */}
                {i.role !== "parent" && peutComposer ? (
                  <form action={retirerDuDossier} className="mt-3 flex flex-wrap gap-2">
                    <input type="hidden" name="enfantId" value={id} />
                    <input type="hidden" name="profilId" value={i.profil_id} />
                    <input
                      name="motif"
                      placeholder="Motif du retrait"
                      className="flex-1 rounded-md border border-bordure bg-fond px-2 py-1 text-xs"
                    />
                    <button
                      type="submit"
                      className="rounded-md border border-bordure px-3 py-1 text-xs hover:border-alerte hover:text-alerte"
                    >
                      Retirer
                    </button>
                  </form>
                ) : null}
              </li>
            );
          })}
        </ul>
      </section>

      {(invitations ?? []).length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Invitations en attente</h2>
          <ul className="space-y-2">
            {(invitations ?? []).map((inv) => (
              <LigneInvitation key={inv.id} enfantId={id} invitation={inv} />
            ))}
          </ul>
        </section>
      ) : null}

      {/* Composer l'équipe revient au référent : il connaît l'établissement et
          peut vérifier qu'une adresse est bien celle du professeur qu'elle
          prétend être. Un parent connaît le nom de l'enseignant, pas les moyens
          de s'en assurer.
          Proposer le formulaire à tout le monde produirait un refus à l'envoi —
          une promesse qu'on ne tient pas. */}
      {peutComposer ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Inviter quelqu’un</h2>
          <FormulaireInvitation enfantId={id} matieres={matieres ?? []} />
        </section>
      ) : (
        <section className="space-y-2">
          <h2 className="text-lg font-semibold">Inviter quelqu’un</h2>
          <p className="rounded-md border border-bordure bg-surface px-4 py-3 text-sm text-texte-doux">
            L’équipe est composée par le référent du dossier : c’est lui qui répond des
            personnes rattachées, comme l’administration répond de lui. Si quelqu’un doit
            rejoindre le dossier, dites-le-lui — il l’invitera.
          </p>
        </section>
      )}
    </main>
  );
}
