import Link from "next/link";
import { notFound } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";
import type { FormulairePreBilan as Formulaire } from "@/lib/pre-bilan";
import {
  FormulairePreBilan,
  type ReponseSaisie,
} from "../FormulairePreBilan";

export default async function PageRemplirPreBilan({
  params,
}: {
  params: Promise<{ id: string; observationId: string }>;
}) {
  const { id, observationId } = await params;
  const { supabase, utilisateur } = await exigerUtilisateur();

  const [{ data: ligne }, { data: reponses }] = await Promise.all([
    supabase
      .from("observations_capacites")
      .select("id, statut, rempli_par, synthese, questionnaires_capacites(contenu, version)")
      .eq("id", observationId)
      .eq("enfant_id", id)
      .maybeSingle(),
    supabase
      .from("observations_reponses")
      .select("item_code, valeur, note")
      .eq("observation_id", observationId),
  ]);

  // Ligne inexistante et ligne d'un dossier qu'on n'a pas le droit de voir se
  // ressemblent ici, et c'est volontaire : la RLS renvoie zéro ligne dans les
  // deux cas.
  if (!ligne) notFound();

  const observation = ligne as unknown as {
    id: string;
    statut: string;
    rempli_par: string | null;
    synthese: Record<string, string> | null;
    questionnaires_capacites:
      | { contenu: Formulaire; version: string }
      | { contenu: Formulaire; version: string }[];
  };

  // Sans types générés, l'inférence prend un lien de plusieurs vers un pour un
  // tableau ; PostgREST renvoie tantôt l'un, tantôt l'autre. On accepte les deux
  // plutôt que de parier — un cast optimiste passerait le build et casserait à
  // l'affichage.
  const lien = Array.isArray(observation.questionnaires_capacites)
    ? observation.questionnaires_capacites[0]
    : observation.questionnaires_capacites;

  if (!lien?.contenu) notFound();

  const sien = observation.rempli_par === utilisateur.id;

  return (
    <div className="space-y-6">
      <div>
        <Link
          href={`/enfants/${id}/pre-bilan`}
          className="text-sm text-texte-doux hover:underline"
        >
          ← Pré-bilan
        </Link>
        <h1 className="mt-2 text-2xl font-semibold">{lien.contenu.title}</h1>
        <p className="mt-1 text-sm text-texte-doux">
          Version {lien.version}. Vos réponses s&apos;enregistrent quand vous le
          demandez — vous pouvez vous arrêter et reprendre.
        </p>
      </div>

      {/* On corrige ce qu'on a observé, pas ce qu'un autre a observé. Deux
          réponses divergentes sont une information : un enfant qui écrit à la
          maison et pas en classe, ce n'est pas une erreur à trancher. */}
      {sien ? (
        <FormulairePreBilan
          enfantId={id}
          observationId={observation.id}
          formulaire={lien.contenu}
          reponses={(reponses ?? []) as ReponseSaisie[]}
          synthese={observation.synthese ?? {}}
          termine={observation.statut === "complete"}
        />
      ) : (
        <>
          <p className="rounded-md border border-bordure bg-surface px-4 py-3 text-sm text-texte-doux">
            Ce pré-bilan a été rempli par quelqu&apos;un d&apos;autre. Vous
            pouvez le lire, pas le modifier : si votre regard diffère, remplissez
            le vôtre — les deux comptent.
          </p>
          <LectureSeule
            formulaire={lien.contenu}
            reponses={(reponses ?? []) as ReponseSaisie[]}
            synthese={observation.synthese ?? {}}
          />
        </>
      )}
    </div>
  );
}

function LectureSeule({
  formulaire,
  reponses,
  synthese,
}: {
  formulaire: Formulaire;
  reponses: ReponseSaisie[];
  synthese: Record<string, string>;
}) {
  const deja = new Map(reponses.map((r) => [r.item_code, r]));
  const libelle = new Map(formulaire.scale.options.map((o) => [o.value, o.label]));

  return (
    <div className="space-y-6">
      {formulaire.domains.map((domaine) => (
        <section key={domaine.id} className="rounded-lg border border-bordure bg-surface p-5">
          <h2 className="text-lg font-medium">{domaine.title}</h2>
          <dl className="mt-3 space-y-2 text-sm">
            {domaine.items.map((item) => {
              const r = deja.get(item.id);
              const valeur =
                r && r.valeur !== null ? libelle.get(r.valeur) : "Pas encore observé";
              return (
                <div key={item.id} className="flex flex-wrap justify-between gap-3">
                  <dt className="max-w-[42rem]">{item.label}</dt>
                  <dd
                    className={
                      r && r.valeur !== null ? "font-medium" : "text-texte-doux"
                    }
                  >
                    {valeur}
                    {r?.note ? (
                      <span className="block text-xs font-normal text-texte-doux">
                        {r.note}
                      </span>
                    ) : null}
                  </dd>
                </div>
              );
            })}
          </dl>
        </section>
      ))}

      {formulaire.synthesis_fields.some((c) => synthese[c.id]) ? (
        <section className="rounded-lg border border-bordure bg-surface p-5">
          <h2 className="text-lg font-medium">Ce que les cases ne disent pas</h2>
          <dl className="mt-3 space-y-3 text-sm">
            {formulaire.synthesis_fields
              .filter((c) => synthese[c.id])
              .map((c) => (
                <div key={c.id}>
                  <dt className="text-texte-doux">{c.label}</dt>
                  <dd className="mt-1 whitespace-pre-line">{synthese[c.id]}</dd>
                </div>
              ))}
          </dl>
        </section>
      ) : null}
    </div>
  );
}
