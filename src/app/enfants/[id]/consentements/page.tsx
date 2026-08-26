import Link from "next/link";
import { notFound } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";
import {
  textesASigner,
  etatDesConsentements,
  dossierUtilisable,
} from "@/lib/consentements";
import { FormulaireSignature } from "./FormulaireSignature";

export default async function PageConsentements({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { supabase } = await exigerUtilisateur();

  const { data: enfant } = await supabase
    .from("enfants")
    .select("id, prenom")
    .eq("id", id)
    .maybeSingle();

  // Pas de fiche visible : soit elle n'existe pas, soit les politiques RLS la
  // masquent. On ne distingue pas les deux — le faire dirait à un inconnu qu'un
  // dossier existe à cet identifiant.
  if (!enfant) notFound();

  const [aSigner, etats] = await Promise.all([
    textesASigner(id),
    etatDesConsentements(id),
  ]);

  const utilisable = dossierUtilisable(etats);

  return (
    <main className="mx-auto max-w-3xl space-y-8 px-4 py-8">
      <header className="space-y-1">
        <Link href={`/enfants/${id}`} className="text-sm text-texte-doux hover:underline">
          ← Dossier de {enfant.prenom}
        </Link>
        <h1 className="text-2xl font-semibold">Autorisations</h1>
        <p className="max-w-prose text-sm text-texte-doux">
          Ces textes disent ce que Xylou fait des informations de {enfant.prenom}, et ce
          qu’il n’en fait pas. Chaque titulaire de l’autorité parentale signe pour
          lui-même.
        </p>
      </header>

      {/* L'avertissement d'abord : une équipe qui ne voit rien cherchera un bug
          avant de penser à cette page, et le référent qui l'ouvre doit
          comprendre en une phrase pourquoi son dossier est muet. */}
      {!utilisable ? (
        <p className="rounded-md border border-alerte bg-alerte-douce px-4 py-3 text-sm text-alerte">
          Tant que les autorisations nécessaires ne sont pas signées par tous les
          titulaires, les enseignants et les accompagnants ne voient rien du dossier, et
          aucun contenu n’est généré.
        </p>
      ) : null}

      {aSigner.length > 0 ? (
        <FormulaireSignature enfantId={id} textes={aSigner} />
      ) : (
        <p className="rounded-md border border-accent bg-accent-doux px-4 py-3 text-sm text-accent">
          Vous avez signé tous les textes en vigueur.
        </p>
      )}

      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Où en est le dossier</h2>

        <ul className="space-y-2">
          {etats.map((etat) => (
            <li
              key={etat.type}
              className="rounded-lg border border-bordure bg-surface p-4 text-sm"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <span className="font-medium">{etat.titre}</span>
                <span className={etat.actif ? "text-accent" : "text-texte-doux"}>
                  {etat.actif ? "Accordée" : "En attente"}
                </span>
              </div>

              <p className="mt-1 text-xs text-texte-doux">
                {etat.signatures} signature{etat.signatures > 1 ? "s" : ""} sur{" "}
                {etat.titulaires_attendus} titulaire
                {etat.titulaires_attendus > 1 ? "s" : ""}
                {etat.obligatoire ? " · nécessaire" : " · facultative"}
              </p>

              {/* Nommer qui manque évite la question « pourquoi ça ne marche
                  pas », qui se pose sinon à chaque fois. */}
              {etat.manquants ? (
                <p className="mt-1 text-xs text-texte-doux">
                  En attente de {etat.manquants}.
                </p>
              ) : null}

              {etat.titulaires_rattaches < etat.titulaires_attendus ? (
                <p className="mt-1 text-xs text-alerte">
                  {etat.titulaires_attendus} titulaires sont déclarés, mais{" "}
                  {etat.titulaires_rattaches} seulement ont rejoint le dossier. Invitez le
                  titulaire manquant, ou demandez au référent de corriger la composition.
                </p>
              ) : null}
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
