import Link from "next/link";
import { exigerUtilisateur } from "@/lib/session";
import { FormulaireHabilitation } from "./FormulaireHabilitation";
import { PiecesJustificatives, type Piece } from "./PiecesJustificatives";

const LIBELLE_STATUT: Record<string, string> = {
  en_attente: "En cours d’instruction",
  acceptee: "Accordée",
  refusee: "Non retenue",
  retiree: "Retirée",
};

export default async function PageHabilitation() {
  const { supabase, utilisateur } = await exigerUtilisateur();

  const [{ data: profil }, { data: demandes }] = await Promise.all([
    supabase.from("profils").select("role_plateforme").eq("id", utilisateur.id).maybeSingle(),
    supabase
      .from("demandes_habilitation")
      .select("id, fonction, organisation, statut, motif, cree_le, traitee_le")
      .order("cree_le", { ascending: false }),
  ]);

  const dejaReferent =
    profil?.role_plateforme === "referent" || profil?.role_plateforme === "admin";
  const demandeEnCours = (demandes ?? []).find((d) => d.statut === "en_attente");

  // Les pièces se versent après la demande, et pas avant : la politique de 0054
  // vérifie que le chemin du fichier correspond à une demande existante dont
  // l'appelant est l'auteur. Sans demande, il n'y a pas de dossier où déposer.
  const { data: pieces } = demandeEnCours
    ? await supabase
        .from("habilitation_pieces")
        .select("id, type_piece, libelle, delivree_le, valable_jusqu_au")
        .eq("demande_id", demandeEnCours.id)
        .order("deposee_le")
    : { data: [] };

  return (
    <main className="mx-auto max-w-2xl space-y-8 px-4 py-8">
      <header className="space-y-1">
        <Link href="/tableau-de-bord" className="text-sm text-texte-doux hover:underline">
          ← Tableau de bord
        </Link>
        <h1 className="text-2xl font-semibold">Habilitation de référent</h1>
        <p className="max-w-prose text-sm text-texte-doux">
          Le référent ouvre les dossiers, établit qui détient l’autorité parentale, et
          accède aux informations de santé. C’est pourquoi cette qualité s’instruit plutôt
          qu’elle ne se demande.
        </p>
      </header>

      {/* Les familles et les enseignants n'ont rien à demander : ils entrent par
          invitation. Le dire évite qu'ils remplissent un formulaire inutile. */}
      <p className="rounded-md border border-bordure bg-surface px-4 py-3 text-sm text-texte-doux">
        Vous n’avez pas besoin d’habilitation pour être <strong>parent</strong>,{" "}
        <strong>enseignant</strong> ou <strong>accompagnant</strong> : ces rôles
        s’obtiennent par invitation du référent qui suit l’enfant.
      </p>

      {dejaReferent ? (
        <p className="rounded-md border border-accent bg-accent-doux px-4 py-3 text-sm text-accent">
          Votre compte peut déjà ouvrir des dossiers.
        </p>
      ) : demandeEnCours ? (
        <>
          {/* Deux messages, et la différence n'est pas cosmétique. Annoncer
              « en cours d'instruction » avant que les pièces soient versées
              donne à la personne toutes les raisons de fermer la page — c'est
              fait, elle n'a plus rien à faire. Elle a pourtant l'essentiel à
              faire, et l'administration attendra un dossier qui ne viendra
              jamais. */}
          {(pieces ?? []).length === 0 ? (
            <p className="rounded-md border border-alerte bg-alerte-douce px-4 py-3 text-sm text-alerte">
              <strong>Votre demande n’est pas encore complète.</strong> Joignez les
              documents qui attestent de votre fonction — l’administration ne peut pas
              vérifier sans eux, et une demande sans pièce prend beaucoup plus longtemps à
              instruire.
            </p>
          ) : (
            <p className="rounded-md border border-bordure bg-surface px-4 py-3 text-sm">
              Votre demande est en cours d’instruction, avec{" "}
              {(pieces ?? []).length} document{(pieces ?? []).length > 1 ? "s" : ""}. Vous
              serez prévenu de la décision. Vous pouvez encore en ajouter.
            </p>
          )}

          <PiecesJustificatives
            demandeId={demandeEnCours.id}
            pieces={(pieces ?? []) as Piece[]}
          />
        </>
      ) : (
        <section className="space-y-4">
          <h2 className="text-lg font-semibold">Demander l’habilitation</h2>
          <FormulaireHabilitation />
          <p className="text-xs text-texte-doux">
            Vous pourrez joindre vos pièces justificatives juste après l’envoi de cette
            demande.
          </p>
        </section>
      )}

      {(demandes ?? []).length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Vos demandes</h2>
          <ul className="space-y-2">
            {(demandes ?? []).map((d) => (
              <li
                key={d.id}
                className="rounded-lg border border-bordure bg-surface p-4 text-sm"
              >
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <span className="font-medium">{d.fonction}</span>
                  <span className="text-xs text-texte-doux">
                    {LIBELLE_STATUT[d.statut] ?? d.statut}
                  </span>
                </div>
                {d.organisation ? (
                  <p className="mt-1 text-xs text-texte-doux">{d.organisation}</p>
                ) : null}
                {/* Le motif d'un refus est la seule chose qui permet de revenir
                    avec ce qui manquait. Le masquer transformerait un refus
                    instruit en fin de non-recevoir. */}
                {d.motif ? <p className="mt-2 text-xs">{d.motif}</p> : null}
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </main>
  );
}
