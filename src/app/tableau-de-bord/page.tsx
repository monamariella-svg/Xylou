import Link from "next/link";
import { exigerUtilisateur } from "@/lib/session";
import { LIBELLE_CLASSE, LIBELLE_UNIVERS, type NiveauClasse, type UniversMoteur } from "@/lib/domaine";
import { marquerToutCommeLu } from "./actions";

type ProjetMoteur = { titre: string; univers: UniversMoteur; actif: boolean };
type LigneEnfant = {
  id: string;
  prenom: string;
  classe: NiveauClasse | null;
  projets_moteurs: ProjetMoteur[];
};

type Notification = {
  id: string;
  titre: string;
  corps: string;
  lien: string;
  cree_le: string;
};

export default async function PageTableauDeBord() {
  const { supabase, utilisateur } = await exigerUtilisateur();

  // Aucun filtre sur l'utilisateur : la politique enfants_lecture (migration 0009)
  // ne laisse remonter que les fiches où il est intervenant. Ajouter un `.eq()`
  // ici donnerait l'illusion que c'est le code qui protège les données.
  const [{ data }, { data: profil }, { data: nonLues }] = await Promise.all([
    supabase
      .from("enfants")
      .select("id, prenom, classe, projets_moteurs(titre, univers, actif)")
      .is("archive_le", null)
      .order("cree_le", { ascending: true }),
    supabase
      .from("profils")
      .select("role_plateforme")
      .eq("id", utilisateur.id)
      .maybeSingle(),
    supabase
      .from("notifications")
      .select("id, titre, corps, lien, cree_le")
      .is("lue_le", null)
      .order("cree_le", { ascending: false })
      .limit(6),
  ]);

  const enfants = (data ?? []) as LigneEnfant[];
  const notifications = (nonLues ?? []) as Notification[];

  // Depuis 0026, ouvrir un dossier est réservé aux référents habilités et à
  // l'administration. Afficher le bouton à tout le monde produirait un refus
  // incompréhensible au moment de valider le formulaire.
  const peutOuvrirUnDossier =
    profil?.role_plateforme === "referent" || profil?.role_plateforme === "admin";

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Tableau de bord</h1>
        <div className="flex flex-wrap gap-2">
          {profil?.role_plateforme === "admin" ? (
            <Link
              href="/administration"
              className="rounded-md border border-bordure px-3 py-2 text-sm hover:border-accent hover:text-accent"
            >
              Administration
            </Link>
          ) : null}
          {peutOuvrirUnDossier ? (
            <Link
              href="/enfants/nouveau"
              className="rounded-md bg-accent px-3 py-2 text-sm font-medium text-white hover:opacity-90"
            >
              Ouvrir un dossier
            </Link>
          ) : null}
        </div>
      </div>

      {/* Les notifications d'abord : ce sont elles qui appellent une action —
          un objectif à signer, un blocage répété, un message. Les mettre après
          la liste des dossiers reviendrait à demander de les chercher. */}
      {notifications.length > 0 ? (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between gap-3">
            <h2 className="text-lg font-semibold">À votre attention</h2>
            <form action={marquerToutCommeLu}>
              <button type="submit" className="text-xs text-texte-doux hover:underline">
                Tout marquer comme lu
              </button>
            </form>
          </div>

          <ul className="space-y-2">
            {notifications.map((n) => (
              <li key={n.id}>
                <Link
                  href={n.lien || "/tableau-de-bord"}
                  className="block rounded-lg border border-bordure bg-surface p-3 hover:border-accent"
                >
                  <span className="block text-sm font-medium">{n.titre}</span>
                  {n.corps ? (
                    <span className="mt-1 block text-xs text-texte-doux">{n.corps}</span>
                  ) : null}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <section>
        <h2 className="sr-only">Dossiers</h2>

        {enfants.length === 0 ? (
          <div className="rounded-lg border border-dashed border-bordure bg-surface p-6">
            <h3 className="font-medium">Aucun dossier pour l&apos;instant</h3>

            {/* Deux situations très différentes, et un seul texte les servirait
                mal : un référent doit ouvrir un dossier, une famille doit
                attendre une invitation. Dire « créez une fiche » à quelqu'un qui
                n'en a pas le droit produit une impasse. */}
            <p className="mt-2 text-sm text-texte-doux">
              {peutOuvrirUnDossier
                ? "Ouvrez un dossier pour commencer. Vous y déclarerez la composition parentale, puis inviterez la famille et l'équipe."
                : "Vous verrez ici les dossiers auxquels vous êtes rattaché. L'accès se fait par invitation : le référent qui suit l'enfant vous enverra un lien."}
            </p>

            {!peutOuvrirUnDossier ? (
              <p className="mt-2 text-sm text-texte-doux">
                Si vous accompagnez des enfants à titre professionnel et devez pouvoir
                ouvrir des dossiers,{" "}
                <Link href="/habilitation" className="text-accent hover:underline">
                  demandez votre habilitation de référent
                </Link>
                .
              </p>
            ) : null}
          </div>
        ) : (
          <ul className="space-y-3">
            {enfants.map((enfant) => {
              const projet = enfant.projets_moteurs?.find((p) => p.actif);
              return (
                <li key={enfant.id}>
                  <Link
                    href={`/enfants/${enfant.id}`}
                    className="block rounded-lg border border-bordure bg-surface p-4 hover:border-accent"
                  >
                    <div className="flex items-baseline justify-between gap-4">
                      <span className="font-medium">{enfant.prenom}</span>
                      <span className="text-sm text-texte-doux">
                        {enfant.classe ? LIBELLE_CLASSE[enfant.classe] : "Classe non renseignée"}
                      </span>
                    </div>
                    <p className="mt-1 text-sm text-texte-doux">
                      {projet
                        ? `${projet.titre} — ${LIBELLE_UNIVERS[projet.univers]}`
                        : "Pas encore de projet moteur"}
                    </p>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
