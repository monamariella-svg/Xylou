import Link from "next/link";
import { exigerUtilisateur } from "@/lib/session";
import { FormulairePreferences, type Reglage } from "./FormulairePreferences";

type LignePreference = { type: string; canal: string; actif: boolean };

export default async function PagePreferencesNotification() {
  const { supabase } = await exigerUtilisateur();

  const [{ data: types }, { data: existantes }] = await Promise.all([
    // La liste vient de la base (0067) et non d'une constante recopiée ici :
    // proposer de couper un courriel qui ne part jamais, ou omettre un type qui
    // part, sont les deux pannes qu'un écran de préférences ne peut pas avoir.
    supabase.rpc("types_notifies_hors_application"),
    // Aucun filtre sur le profil : la politique `preferences_gestion` de 0059
    // ne laisse voir que les siennes.
    supabase
      .from("preferences_notification")
      .select("type, canal, actif")
      .eq("canal", "courriel"),
  ]);

  const refus = new Map(
    ((existantes ?? []) as LignePreference[]).map((p) => [p.type, p.actif]),
  );

  // L'absence de préférence vaut accord, exactement comme dans le trigger de
  // 0059. Cocher par défaut est ce qui rend l'écran fidèle : décocher ce que la
  // base enverra quand même serait un mensonge d'interface.
  const reglages: Reglage[] = ((types ?? []) as string[]).map((type) => ({
    type,
    actif: refus.get(type) ?? true,
  }));

  return (
    <div className="space-y-6">
      <div>
        <Link
          href="/notifications"
          className="text-sm text-texte-doux hover:text-accent hover:underline"
        >
          ← Notifications
        </Link>
        <h1 className="mt-2 text-2xl font-semibold">Ce que je reçois par courriel</h1>
      </div>

      <p className="text-sm text-texte-doux">
        Tout reste consultable dans l&apos;application, quoi que vous décochiez
        ici : ces choix ne portent que sur les courriels. Les notifications qui
        n&apos;appellent aucune action — un badge obtenu, une récompense qui
        approche — ne sont jamais envoyées par courriel et ne figurent donc pas
        dans cette liste.
      </p>

      {reglages.length === 0 ? (
        <p className="rounded-lg border border-dashed border-bordure bg-surface p-6 text-sm text-texte-doux">
          La liste n&apos;a pas pu être lue. Si cet écran reste vide, la migration
          0067 n&apos;est probablement pas appliquée.
        </p>
      ) : (
        <FormulairePreferences reglages={reglages} />
      )}
    </div>
  );
}
