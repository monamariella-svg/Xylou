import Link from "next/link";
import { exigerUtilisateur } from "@/lib/session";
import { marquerCommeLue, marquerToutCommeLu } from "./actions";

type Notification = {
  id: string;
  titre: string;
  corps: string;
  lue_le: string | null;
  cree_le: string;
};

// Assez pour retrouver ce qu'on cherche « la semaine dernière », assez peu pour
// que la page reste une page. Au-delà, ce n'est plus une liste de notifications
// mais un journal, et le bon endroit pour ça est le dossier de l'enfant.
const MAX = 60;

function dateCourte(iso: string): string {
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

function Ligne({ n }: { n: Notification }) {
  const lue = Boolean(n.lue_le);

  return (
    <li className="flex items-start gap-2">
      <Link
        // Le clic marque la notification lue avant de rediriger (voir
        // [id]/route.ts). `prefetch` désactivé pour cette raison précise :
        // précharger la cible reviendrait à marquer lu tout ce que la souris
        // survole.
        prefetch={false}
        href={`/notifications/${n.id}`}
        className={`min-w-0 flex-1 rounded-lg border p-3 hover:border-accent ${
          lue ? "border-bordure bg-fond" : "border-bordure bg-surface"
        }`}
      >
        <span className="flex items-baseline justify-between gap-3">
          <span className={`text-sm ${lue ? "" : "font-medium"}`}>
            {/* La pastille double la couleur de fond, qui ne suffit pas seule :
                un écart de fond aussi faible que celui de la palette n'est pas
                perçu par tout le monde. */}
            {lue ? null : (
              <span aria-hidden="true" className="mr-2 inline-block h-2 w-2 rounded-full bg-accent align-middle" />
            )}
            {n.titre}
            {lue ? null : <span className="sr-only"> (non lue)</span>}
          </span>
          <span className="shrink-0 text-xs text-texte-doux">{dateCourte(n.cree_le)}</span>
        </span>
        {n.corps ? (
          <span className="mt-1 block text-xs text-texte-doux">{n.corps}</span>
        ) : null}
      </Link>

      {/* Hors du lien, et non dedans : un <form> à l'intérieur d'un <a> est du
          HTML invalide, et le navigateur défait l'imbrication à sa façon.
          Ce bouton sert le cas courant d'une notification qu'on a comprise
          depuis son titre et qui n'appelle rien — sans lui, la seule manière de
          la faire disparaître est de tout marquer lu, y compris ce qu'on n'a
          pas regardé. */}
      {lue ? null : (
        <form action={marquerCommeLue} className="pt-3">
          <input type="hidden" name="id" value={n.id} />
          <button
            type="submit"
            className="text-xs whitespace-nowrap text-texte-doux hover:text-accent hover:underline"
          >
            Marquer lu
          </button>
        </form>
      )}
    </li>
  );
}

export default async function PageNotifications() {
  const { supabase } = await exigerUtilisateur();

  // Aucun filtre sur le destinataire : la politique `notifications_lecture` de
  // 0014 ne laisse remonter que les siennes.
  const { data } = await supabase
    .from("notifications")
    .select("id, titre, corps, lue_le, cree_le")
    .order("cree_le", { ascending: false })
    .limit(MAX);

  const notifications = (data ?? []) as Notification[];
  const nonLues = notifications.filter((n) => !n.lue_le);
  const lues = notifications.filter((n) => n.lue_le);

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Notifications</h1>
        <Link
          href="/notifications/preferences"
          className="text-sm text-texte-doux hover:text-accent hover:underline"
        >
          Choisir ce que je reçois par courriel
        </Link>
      </div>

      {notifications.length === 0 ? (
        <div className="rounded-lg border border-dashed border-bordure bg-surface p-6">
          <h2 className="font-medium">Rien pour l&apos;instant</h2>
          <p className="mt-2 text-sm text-texte-doux">
            Vous serez prévenu ici — et par courriel — d&apos;un message, d&apos;un
            objectif qui attend votre validation ou d&apos;une difficulté qui se
            répète.
          </p>
        </div>
      ) : null}

      {nonLues.length > 0 ? (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between gap-3">
            <h2 className="text-lg font-semibold">
              À votre attention
              <span className="ml-2 text-sm font-normal text-texte-doux">
                {nonLues.length}
              </span>
            </h2>
            <form action={marquerToutCommeLu}>
              <button type="submit" className="text-xs text-texte-doux hover:underline">
                Tout marquer comme lu
              </button>
            </form>
          </div>

          <ul className="space-y-2">
            {nonLues.map((n) => (
              <Ligne key={n.id} n={n} />
            ))}
          </ul>
        </section>
      ) : null}

      {/* Ce qui a été lu reste consultable. « Je l'ai vu passer sans avoir le
          temps » est la situation la plus fréquente, et une notification qui
          disparaît à la lecture oblige à retrouver l'information ailleurs. */}
      {lues.length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-texte-doux">Déjà lues</h2>
          <ul className="space-y-2">
            {lues.map((n) => (
              <Ligne key={n.id} n={n} />
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
