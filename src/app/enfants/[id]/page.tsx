import Link from "next/link";
import { notFound } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";
import {
  lireLexique,
  nomAffiche,
  type NiveauClasse,
  type ProfilCommunication,
  type UniversMoteur,
} from "@/lib/domaine";
import { etatDesConsentements, dossierUtilisable } from "@/lib/consentements";
import FicheEnfantForm from "./FicheEnfantForm";
import SanteForm from "./SanteForm";
import CentresInteretSection, { type CentreInteret } from "./CentresInteretSection";
import ProjetMoteurForm from "./ProjetMoteurForm";

type Enfant = {
  id: string;
  prenom: string;
  nom: string;
  classe: NiveauClasse | null;
  communication: ProfilCommunication;
  date_naissance: string | null;
};

// Next.js 16 génère un helper `PageProps<"/enfants/[id]">`, mais il n'existe
// qu'après un premier build. On type explicitement pour qu'un `tsc --noEmit`
// passe sur un dépôt fraîchement cloné. `params` est une promesse : l'accès
// synchrone a été retiré en 16.
export default async function PageEnfant({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { supabase, utilisateur } = await exigerUtilisateur();

  const { data: ligneEnfant } = await supabase
    .from("enfants")
    .select("id, prenom, nom, classe, communication, date_naissance")
    .eq("id", id)
    .maybeSingle();

  const enfant = ligneEnfant as Enfant | null;

  // Une fiche inexistante et une fiche qu'on n'a pas le droit de voir se
  // ressemblent ici, et c'est volontaire : RLS renvoie zéro ligne dans les deux
  // cas, et l'interface ne doit pas révéler laquelle des deux situations c'est.
  if (!enfant) notFound();

  const [{ data: sante }, { data: centres }, { data: projet }, { data: role }] =
    await Promise.all([
      supabase
        .from("enfants_sante")
        .select("besoins_particuliers, amenagements, suivis_exterieurs")
        .eq("enfant_id", id)
        .maybeSingle(),
      supabase
        .from("centres_interet")
        .select("id, libelle, intensite, note")
        .eq("enfant_id", id)
        .order("intensite", { ascending: false }),
      supabase
        .from("projets_moteurs")
        .select("id, titre, univers, description, lexique")
        .eq("enfant_id", id)
        .eq("actif", true)
        .maybeSingle(),
      supabase
        .from("intervenants_enfant")
        .select("role")
        .eq("enfant_id", id)
        .eq("profil_id", utilisateur.id)
        .is("retire_le", null)
        .maybeSingle(),
    ]);

  // On décide d'après le rôle, pas d'après la présence de la ligne : une fiche
  // sans donnée de santé enregistrée renverrait `sante === null` tout comme une
  // fiche que la RLS refuse, et on masquerait la section à un parent qui a
  // simplement laissé le champ vide.
  const accesSante = role?.role === "parent" || role?.role === "referent";

  // Vide pour un enseignant ou un accompagnant : la fonction ne répond qu'au
  // cercle qui signe. `dossierUtilisable([])` vaut alors vrai, et aucun
  // avertissement ne s'affiche — c'est le bon comportement, ce n'est pas à eux
  // de régler cette question.
  const etatsConsentement = accesSante ? await etatDesConsentements(id) : [];
  const utilisable = dossierUtilisable(etatsConsentement);

  return (
    <div className="space-y-8">
      <div>
        <Link href="/tableau-de-bord" className="text-sm text-texte-doux hover:underline">
          ← Tableau de bord
        </Link>
        <h1 className="mt-2 text-2xl font-semibold">
          {nomAffiche(enfant.prenom, enfant.nom)}
        </h1>

        <nav className="mt-3 flex flex-wrap gap-3 text-sm">
          <Link
            href={`/enfants/${id}/equipe`}
            className="rounded-md border border-bordure px-3 py-1 hover:border-accent hover:text-accent"
          >
            Équipe
          </Link>
          <Link
            href={`/enfants/${id}/consentements`}
            className="rounded-md border border-bordure px-3 py-1 hover:border-accent hover:text-accent"
          >
            Autorisations
          </Link>
        </nav>
      </div>

      {/* L'avertissement porte sur ce qui bloque, pas sur ce qui manque en
          général : tant que les autorisations nécessaires ne sont pas signées
          par tous les titulaires, l'équipe ne voit rien et l'IA ne produit
          rien. Sans cette phrase ici, la question se posera ailleurs, sous la
          forme « pourquoi le professeur ne voit pas la fiche ». */}
      {!utilisable ? (
        <p className="rounded-md border border-alerte bg-alerte-douce px-4 py-3 text-sm text-alerte">
          Ce dossier n’est pas encore actif : il attend les autorisations de tous les
          titulaires de l’autorité parentale.{" "}
          <Link href={`/enfants/${id}/consentements`} className="underline">
            Voir où ça en est
          </Link>
          .
        </p>
      ) : null}

      <Section
        titre="Fiche"
        aide="Les informations qui situent l'enfant. Elles sont visibles par toute l'équipe rattachée au dossier."
      >
        <FicheEnfantForm
          enfantId={enfant.id}
          prenom={enfant.prenom}
          nom={enfant.nom}
          classe={enfant.classe}
          communication={enfant.communication}
          dateNaissance={enfant.date_naissance}
        />
      </Section>

      {accesSante ? (
        <Section
          titre="Besoins et aménagements"
          aide="Visible par les titulaires de l'autorité parentale et par le référent, jamais par les enseignants ni par les accompagnants. La saisie demande l'autorisation correspondante, signée par tous les titulaires."
        >
          <SanteForm
            enfantId={enfant.id}
            besoins={sante?.besoins_particuliers ?? ""}
            amenagements={sante?.amenagements ?? ""}
            suivis={sante?.suivis_exterieurs ?? ""}
          />
        </Section>
      ) : null}

      <Section
        titre="Centres d'intérêt"
        aide="Ce sur quoi on accrochera les apprentissages. C'est la matière première du projet moteur."
      >
        <CentresInteretSection
          enfantId={enfant.id}
          centres={(centres ?? []) as CentreInteret[]}
        />
      </Section>

      <Section
        titre="Projet moteur"
        aide="Le fil rouge. Tout ce que votre enfant verra à l'écran sera écrit dans cet univers et avec ces mots-là."
      >
        <ProjetMoteurForm
          enfantId={enfant.id}
          projetId={projet?.id ?? null}
          titre={projet?.titre ?? ""}
          univers={(projet?.univers as UniversMoteur | undefined) ?? "autre"}
          description={projet?.description ?? ""}
          lexique={lireLexique(projet?.lexique)}
        />
      </Section>
    </div>
  );
}

function Section({
  titre,
  aide,
  children,
}: {
  titre: string;
  aide: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-lg border border-bordure bg-surface p-5">
      <h2 className="text-lg font-medium">{titre}</h2>
      <p className="mt-1 mb-4 text-sm text-texte-doux">{aide}</p>
      {children}
    </section>
  );
}
