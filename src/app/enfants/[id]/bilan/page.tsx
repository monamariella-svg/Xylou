import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { LIBELLE_CLASSE, type NiveauClasse } from "@/lib/domaine";
import BoutonGenerer from "./BoutonGenerer";
import { annulerLaDemande } from "./actions";

/**
 * L'écran du bilan : ce qu'on peut demander, ce qui est en cours, ce qui existe.
 *
 * Le coût est annoncé avant le clic. C'est le sens même d'un bouton manuel :
 * si l'on ne dit pas ce que ça coûte, « ne pas générer pour rien » est un vœu.
 */

const LIBELLE_STATUT: Record<string, string> = {
  en_attente: "En attente",
  en_cours: "En cours",
  terminee: "Terminée",
  echec: "Échec",
  annulee: "Annulée",
};

function euros(centimes: number): string {
  return `${(centimes / 100).toFixed(2).replace(".", ",")} €`;
}

export default async function PageBilan({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) redirect("/connexion");

  const { data: enfant } = await supabase
    .from("enfants")
    .select("prenom, classe")
    .eq("id", id)
    .maybeSingle();

  if (!enfant) redirect("/tableau-de-bord");

  const [{ data: raisons }, { data: demandes }, { data: bilans }] = await Promise.all([
    supabase.rpc("raisons_de_ne_pas_generer", { p_enfant: id }),
    supabase
      .from("generations_bilan")
      .select("id, statut, cree_le, terminee_le, derniere_erreur, cout_centimes, bilan_id")
      .eq("enfant_id", id)
      .order("cree_le", { ascending: false })
      .limit(5),
    supabase
      .from("bilans_positionnement")
      .select("id, statut, demarre_le, matieres")
      .eq("enfant_id", id)
      .order("demarre_le", { ascending: false })
      .limit(5),
  ]);

  // L'ordre de grandeur, tiré des générations déjà payées plutôt que d'une
  // estimation théorique. Sans historique, on ne prétend pas savoir.
  const passees = (demandes ?? []).filter((d) => d.statut === "terminee" && d.cout_centimes > 0);
  const moyenne =
    passees.length > 0
      ? passees.reduce((somme, d) => somme + Number(d.cout_centimes), 0) / passees.length
      : null;

  const enCours = (demandes ?? []).find(
    (d) => d.statut === "en_attente" || d.statut === "en_cours",
  );

  return (
    <div className="space-y-8">
      <div>
        <Link href={`/enfants/${id}`} className="text-sm text-texte-doux hover:underline">
          ← {enfant.prenom}
        </Link>
        <h1 className="mt-2 text-2xl font-semibold">Bilan de positionnement</h1>
        <p className="mt-1 text-sm text-texte-doux">
          Le bilan situe {enfant.prenom} sur les attendus officiels
          {enfant.classe ? ` de ${LIBELLE_CLASSE[enfant.classe as NiveauClasse]}` : ""}. Il
          commence en dessous et monte : les premières questions sont faites pour être
          réussies.
        </p>
      </div>

      <section className="rounded-lg border border-bordure bg-surface p-5">
        <h2 className="text-lg font-medium">Générer un bilan</h2>
        <p className="mt-1 mb-4 text-sm text-texte-doux">
          Rien ne se génère tout seul. La génération produit un brouillon, que vous relisez
          avant qu&apos;il soit proposé à {enfant.prenom}.
          {moyenne !== null && ` Les générations précédentes ont coûté ${euros(moyenne)} en moyenne.`}
        </p>

        <BoutonGenerer enfantId={id} raisons={(raisons as string[]) ?? []} />

        {enCours && enCours.statut === "en_attente" && (
          <form action={annulerLaDemande} className="mt-4">
            <input type="hidden" name="enfantId" value={id} />
            <input type="hidden" name="demandeId" value={enCours.id} />
            <button type="submit" className="text-sm text-texte-doux underline">
              Annuler la demande
            </button>
          </form>
        )}
      </section>

      {(demandes ?? []).length > 0 && (
        <section className="rounded-lg border border-bordure bg-surface p-5">
          <h2 className="text-lg font-medium">Demandes récentes</h2>
          <ul className="mt-4 space-y-3 text-sm">
            {(demandes ?? []).map((d) => (
              <li key={d.id} className="border-b border-bordure pb-3 last:border-0 last:pb-0">
                <div className="flex flex-wrap items-baseline gap-x-3">
                  <span className="font-medium">{LIBELLE_STATUT[d.statut] ?? d.statut}</span>
                  <span className="text-texte-doux">
                    {new Date(d.cree_le).toLocaleString("fr-FR")}
                  </span>
                  {d.cout_centimes > 0 && (
                    <span className="text-texte-doux">{euros(Number(d.cout_centimes))}</span>
                  )}
                </div>
                {/* Une erreur de génération se lit, elle ne se devine pas : sans
                    elle, un référent réessaierait la même chose indéfiniment. */}
                {d.derniere_erreur && (
                  <p className="mt-1 text-texte-doux">{d.derniere_erreur}</p>
                )}
              </li>
            ))}
          </ul>
        </section>
      )}

      {(bilans ?? []).length > 0 && (
        <section className="rounded-lg border border-bordure bg-surface p-5">
          <h2 className="text-lg font-medium">Bilans</h2>
          <ul className="mt-4 space-y-2 text-sm">
            {(bilans ?? []).map((b) => (
              <li key={b.id} className="flex flex-wrap items-baseline gap-x-3">
                <span className="font-medium">{b.statut}</span>
                <span className="text-texte-doux">
                  {new Date(b.demarre_le).toLocaleDateString("fr-FR")}
                </span>
                <span className="text-texte-doux">{(b.matieres ?? []).join(", ")}</span>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
