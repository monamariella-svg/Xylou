import Link from "next/link";
import { notFound } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";
import { LIBELLE_ROLE, nomAffiche, type RoleIntervenant } from "@/lib/domaine";
import { ouvrirPreBilan } from "./actions";

type Observation = {
  id: string;
  statut: string;
  rempli_par: string | null;
  role_au_moment: RoleIntervenant | null;
  rempli_le: string;
};

export default async function PagePreBilan({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { supabase, utilisateur } = await exigerUtilisateur();

  const [{ data: ligneEnfant }, { data: lignes }, { data: questionnaire }] =
    await Promise.all([
      supabase.from("enfants").select("id, prenom, nom").eq("id", id).maybeSingle(),
      // Aucun filtre sur l'utilisateur : la politique de 0069 ne laisse remonter
      // que les dossiers où il est intervenant.
      supabase
        .from("observations_capacites")
        .select("id, statut, rempli_par, role_au_moment, rempli_le")
        .eq("enfant_id", id)
        .order("rempli_le", { ascending: false }),
      supabase
        .from("questionnaires_capacites")
        .select("version")
        .eq("courant", true)
        .maybeSingle(),
    ]);

  const enfant = ligneEnfant as { id: string; prenom: string; nom: string } | null;
  if (!enfant) notFound();

  const observations = (lignes ?? []) as Observation[];
  const brouillon = observations.find(
    (o) => o.rempli_par === utilisateur.id && o.statut === "brouillon",
  );

  return (
    <div className="space-y-8">
      <div>
        <Link href={`/enfants/${id}`} className="text-sm text-texte-doux hover:underline">
          ← {nomAffiche(enfant.prenom, enfant.nom)}
        </Link>
        <h1 className="mt-2 text-2xl font-semibold">Pré-bilan</h1>
      </div>

      <section className="rounded-lg border border-bordure bg-surface p-5">
        <h2 className="font-medium">À quoi il sert</h2>
        <p className="mt-2 text-sm text-texte-doux">
          Ce questionnaire ne mesure rien de scolaire : il dit{" "}
          <strong className="font-medium text-texte">
            comment poser les questions à cet enfant
          </strong>
          . Le bilan de niveau viendra ensuite, et il sera construit à partir de
          vos réponses — format des questions, longueur, moment de s&apos;arrêter.
        </p>
        <p className="mt-2 text-sm text-texte-doux">
          Rien de ce que vous répondez ici n&apos;entre dans le résultat du bilan.
          Répondez d&apos;après ce que vous avez vu, et laissez « pas encore
          observé » partout où vous n&apos;avez pas vu : c&apos;est une réponse
          utile, pas un blanc à combler.
        </p>
      </section>

      {questionnaire ? (
        <form action={ouvrirPreBilan}>
          <input type="hidden" name="enfantId" value={id} />
          {brouillon ? (
            <Link
              href={`/enfants/${id}/pre-bilan/${brouillon.id}`}
              className="inline-block rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:opacity-90"
            >
              Reprendre mon pré-bilan
            </Link>
          ) : (
            <button
              type="submit"
              className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:opacity-90"
            >
              Remplir un pré-bilan
            </button>
          )}
        </form>
      ) : (
        <p className="rounded-md border border-alerte bg-alerte-douce px-4 py-3 text-sm text-alerte">
          Aucun questionnaire n&apos;est publié. Les migrations 0069 et 0070 ne
          sont probablement pas appliquées.
        </p>
      )}

      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Ce qui a déjà été rempli</h2>

        {observations.length === 0 ? (
          <p className="text-sm text-texte-doux">
            Rien pour l&apos;instant. Plusieurs personnes peuvent répondre — un
            parent et un enseignant ne voient pas le même enfant, et les deux
            regards comptent.
          </p>
        ) : (
          <ul className="space-y-2">
            {observations.map((o) => (
              <li key={o.id}>
                <Link
                  href={`/enfants/${id}/pre-bilan/${o.id}`}
                  className="flex flex-wrap items-baseline justify-between gap-3 rounded-lg border border-bordure bg-surface p-3 hover:border-accent"
                >
                  <span className="text-sm">
                    {o.role_au_moment
                      ? LIBELLE_ROLE[o.role_au_moment] ?? o.role_au_moment
                      : "Rôle non précisé"}
                    {o.rempli_par === utilisateur.id ? " — vous" : ""}
                    {o.statut === "brouillon" ? (
                      <span className="ml-2 text-xs text-texte-doux">en cours</span>
                    ) : null}
                  </span>
                  <span className="text-xs text-texte-doux">
                    {new Date(o.rempli_le).toLocaleDateString("fr-FR", {
                      day: "numeric",
                      month: "long",
                      year: "numeric",
                    })}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
