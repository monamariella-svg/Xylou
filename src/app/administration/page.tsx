import Link from "next/link";
import { notFound } from "next/navigation";
import { exigerUtilisateur } from "@/lib/session";
import {
  accepterHabilitation,
  refuserHabilitation,
  masquerLeDossier,
  purgerLeDossier,
} from "./actions";

type Demande = {
  demande_id: string;
  prenom: string | null;
  nom: string | null;
  email: string | null;
  fonction: string;
  organisation: string;
  numero_professionnel: string;
  motivation: string;
  directeur_nom: string;
  directeur_contact: string;
  pieces: number;
  types_fournis: string;
  pieces_perimees: number;
  depuis_jours: number;
};

type Renouvellement = {
  profil_id: string;
  prenom: string | null;
  nom: string | null;
  organisation: string;
  valable_jusqu_au: string;
  jours_restants: number;
  dossiers_suivis: number;
};

type Suppression = {
  demande_id: string;
  enfant_id: string;
  prenom: string;
  motif: string;
  statut: string;
  accords: number;
  titulaires: number;
  purge_prevue_le: string | null;
  depuis_jours: number;
};

type APurger = {
  enfant_id: string;
  prenom: string;
  purge_due_le: string;
  jours_de_retard: number;
  sur_demande: boolean;
};

type PieceAffichee = {
  id: string;
  demande_id: string;
  type_piece: string;
  libelle: string;
  valable_jusqu_au: string | null;
  url: string | null;
};

const LIBELLE_PIECE: Record<string, string> = {
  piece_identite: "Pièce d’identité",
  carte_professionnelle: "Carte professionnelle",
  attestation_employeur: "Attestation d’employeur",
  attestation_direction: "Attestation de direction",
  diplome: "Diplôme",
  agrement: "Agrément",
  assurance_responsabilite: "Assurance",
  autre: "Autre document",
};

async function chargerLesPieces(
  supabase: Awaited<ReturnType<typeof exigerUtilisateur>>["supabase"],
  demandeIds: string[],
): Promise<PieceAffichee[]> {
  if (demandeIds.length === 0) return [];

  const { data } = await supabase
    .from("habilitation_pieces")
    .select("id, demande_id, type_piece, libelle, chemin, valable_jusqu_au")
    .in("demande_id", demandeIds)
    .order("deposee_le");

  const lignes = (data ?? []) as (PieceAffichee & { chemin: string })[];
  if (lignes.length === 0) return [];

  // En un seul appel plutôt qu'un par fichier : signer dix pièces une par une
  // ferait dix allers-retours pour afficher une page.
  const { data: signees } = await supabase.storage
    .from("habilitations")
    .createSignedUrls(
      lignes.map((l) => l.chemin),
      600,
    );

  return lignes.map((ligne, i) => ({
    ...ligne,
    url: signees?.[i]?.signedUrl ?? null,
  }));
}

export default async function PageAdministration() {
  const { supabase, utilisateur } = await exigerUtilisateur();

  const { data: profil } = await supabase
    .from("profils")
    .select("role_plateforme")
    .eq("id", utilisateur.id)
    .maybeSingle();

  // Une page d'administration qui répondrait « accès refusé » confirmerait son
  // existence. Elle n'existe pas pour qui n'est pas administrateur.
  if (profil?.role_plateforme !== "admin") notFound();

  const [habilitations, renouvellements, suppressions, aPurger, echecs] =
    await Promise.all([
      supabase.rpc("habilitations_a_instruire"),
      supabase.rpc("habilitations_a_renouveler", { p_preavis_jours: 60 }),
      supabase.rpc("suppressions_en_cours"),
      supabase.rpc("dossiers_a_purger"),
      supabase.rpc("envois_en_echec", { p_depuis_jours: 7 }),
    ]);

  const demandes = (habilitations.data ?? []) as Demande[];

  // Les pièces elles-mêmes, avec un lien d'ouverture. Sans elles, l'écran dirait
  // « trois documents versés » sans permettre de les lire — ce qui reviendrait à
  // demander de valider sur la foi d'un compteur.
  //
  // Les liens sont signés et valent dix minutes : le bucket est privé, et une
  // URL permanente vers une pièce d'identité traînerait ensuite dans un
  // historique de navigation.
  const pieces = await chargerLesPieces(
    supabase,
    demandes.map((d) => d.demande_id),
  );
  const aRenouveler = (renouvellements.data ?? []) as Renouvellement[];
  const enSuppression = (suppressions.data ?? []) as Suppression[];
  const purgeables = (aPurger.data ?? []) as APurger[];

  return (
    <main className="mx-auto max-w-4xl space-y-10 px-4 py-8">
      <header className="space-y-1">
        <Link href="/tableau-de-bord" className="text-sm text-texte-doux hover:underline">
          ← Tableau de bord
        </Link>
        <h1 className="text-2xl font-semibold">Administration</h1>
        <p className="max-w-prose text-sm text-texte-doux">
          Les habilitations, les suppressions et ce qui n’a pas fonctionné. Cette page ne
          donne accès à aucun contenu de dossier — administrer n’est pas accompagner.
        </p>
      </header>

      {/* ------------------------------------------------ habilitations */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">
          Demandes d’habilitation
          {demandes.length > 0 ? (
            <span className="ml-2 rounded-full bg-accent px-2 py-0.5 text-xs text-white">
              {demandes.length}
            </span>
          ) : null}
        </h2>

        {demandes.length === 0 ? (
          <p className="text-sm text-texte-doux">Aucune demande en attente.</p>
        ) : (
          <ul className="space-y-3">
            {demandes.map((d) => (
              <li key={d.demande_id} className="rounded-lg border border-bordure bg-surface p-4">
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <span className="font-medium">
                    {[d.prenom, d.nom].filter(Boolean).join(" ") || d.email}
                  </span>
                  <span className="text-xs text-texte-doux">
                    depuis {d.depuis_jours} jour{d.depuis_jours > 1 ? "s" : ""}
                  </span>
                </div>

                <dl className="mt-2 space-y-1 text-sm">
                  <div className="flex gap-2">
                    <dt className="text-texte-doux">Fonction</dt>
                    <dd>{d.fonction}</dd>
                  </div>
                  {d.organisation ? (
                    <div className="flex gap-2">
                      <dt className="text-texte-doux">Structure</dt>
                      <dd>{d.organisation}</dd>
                    </div>
                  ) : null}
                  {d.numero_professionnel ? (
                    <div className="flex gap-2">
                      <dt className="text-texte-doux">Numéro</dt>
                      <dd>{d.numero_professionnel}</dd>
                    </div>
                  ) : null}
                  <div className="flex gap-2">
                    <dt className="text-texte-doux">Adresse</dt>
                    <dd>{d.email}</dd>
                  </div>
                </dl>

                {/* Mis en évidence, et non noyé dans la liste : c'est le seul
                    élément de la demande qui se vérifie par un appel. Le reste
                    est déclaratif. */}
                {d.directeur_nom ? (
                  <p className="mt-3 rounded-md border border-bordure bg-fond px-3 py-2 text-sm">
                    <span className="text-texte-doux">Atteste : </span>
                    <span className="font-medium">{d.directeur_nom}</span>
                    {d.directeur_contact ? (
                      <span className="ml-2 text-texte-doux">— {d.directeur_contact}</span>
                    ) : null}
                  </p>
                ) : null}

                {d.motivation ? (
                  <p className="mt-2 whitespace-pre-line text-sm">{d.motivation}</p>
                ) : null}

                {/* Les pièces, ouvrables. Un compteur seul demanderait de
                    valider sans avoir rien lu. */}
                {d.pieces === 0 ? (
                  <p className="mt-3 rounded-md border border-alerte bg-alerte-douce px-3 py-2 text-xs text-alerte">
                    Aucune pièce justificative versée. Vous pouvez accorder
                    l’habilitation malgré tout, mais il faudra dire sur quoi vous vous
                    fondez.
                  </p>
                ) : (
                  <ul className="mt-3 space-y-1">
                    {pieces
                      .filter((p) => p.demande_id === d.demande_id)
                      .map((p) => {
                        const perimee =
                          p.valable_jusqu_au !== null &&
                          new Date(p.valable_jusqu_au) < new Date();
                        return (
                          <li key={p.id} className="flex flex-wrap items-baseline gap-2 text-sm">
                            {p.url ? (
                              <a
                                href={p.url}
                                target="_blank"
                                rel="noreferrer"
                                className="text-accent underline"
                              >
                                {LIBELLE_PIECE[p.type_piece] ?? p.type_piece}
                              </a>
                            ) : (
                              <span>{LIBELLE_PIECE[p.type_piece] ?? p.type_piece}</span>
                            )}
                            <span className="text-xs text-texte-doux">{p.libelle}</span>
                            {perimee ? (
                              <span className="text-xs text-alerte">
                                périmée le{" "}
                                {new Date(p.valable_jusqu_au!).toLocaleDateString("fr-FR")}
                              </span>
                            ) : null}
                          </li>
                        );
                      })}
                  </ul>
                )}

                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                  <form action={accepterHabilitation} className="space-y-2 rounded-md border border-bordure p-3">
                    <input type="hidden" name="demandeId" value={d.demande_id} />
                    <label className="block text-xs font-medium">
                      Habilitation valable jusqu’au
                      <input
                        type="date"
                        name="valableJusquAu"
                        className="mt-1 w-full rounded-md border border-bordure bg-fond px-2 py-1 text-sm"
                      />
                    </label>
                    <label className="block text-xs font-medium">
                      Sur quoi vous vous fondez
                      <input
                        name="motif"
                        placeholder={d.pieces === 0 ? "Obligatoire sans pièce" : "Facultatif"}
                        className="mt-1 w-full rounded-md border border-bordure bg-fond px-2 py-1 text-sm"
                      />
                    </label>
                    <button
                      type="submit"
                      className="w-full rounded-md bg-accent px-3 py-1.5 text-sm text-white hover:opacity-90"
                    >
                      Accorder
                    </button>
                  </form>

                  <form action={refuserHabilitation} className="space-y-2 rounded-md border border-bordure p-3">
                    <input type="hidden" name="demandeId" value={d.demande_id} />
                    <label className="block text-xs font-medium">
                      Motif du refus
                      <input
                        name="motif"
                        minLength={10}
                        placeholder="Ce qui manquait, pour qu’elle puisse revenir avec"
                        className="mt-1 w-full rounded-md border border-bordure bg-fond px-2 py-1 text-sm"
                      />
                    </label>
                    <button
                      type="submit"
                      className="w-full rounded-md border border-bordure px-3 py-1.5 text-sm hover:border-alerte hover:text-alerte"
                    >
                      Ne pas retenir
                    </button>
                  </form>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* ------------------------------------------------ renouvellements */}
      {aRenouveler.length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Habilitations à renouveler</h2>
          <ul className="space-y-2">
            {aRenouveler.map((r) => (
              <li
                key={r.profil_id}
                className="rounded-lg border border-bordure bg-surface p-4 text-sm"
              >
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <span className="font-medium">
                    {[r.prenom, r.nom].filter(Boolean).join(" ")}
                  </span>
                  <span className="text-xs text-alerte">
                    {r.jours_restants < 0
                      ? `expirée depuis ${-r.jours_restants} jours`
                      : `dans ${r.jours_restants} jours`}
                  </span>
                </div>
                {/* Le nombre de dossiers suivis dit ce qu'un non-renouvellement
                    coûterait. Sans lui, la décision se prend à l'aveugle. */}
                <p className="mt-1 text-xs text-texte-doux">
                  {r.organisation ? `${r.organisation} · ` : ""}
                  {r.dossiers_suivis} dossier{r.dossiers_suivis > 1 ? "s" : ""} suivi
                  {r.dossiers_suivis > 1 ? "s" : ""}
                </p>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {/* ------------------------------------------------ suppressions */}
      {enSuppression.length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Suppressions en cours</h2>
          <ul className="space-y-2">
            {enSuppression.map((s) => (
              <li
                key={s.demande_id}
                className="rounded-lg border border-bordure bg-surface p-4 text-sm"
              >
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <span className="font-medium">{s.prenom}</span>
                  <span className="text-xs text-texte-doux">
                    {s.accords} accord{s.accords > 1 ? "s" : ""} sur {s.titulaires}
                  </span>
                </div>
                <p className="mt-1 text-xs text-texte-doux">{s.motif}</p>

                {s.statut === "accordee" ? (
                  <form action={masquerLeDossier} className="mt-3">
                    <input type="hidden" name="demandeId" value={s.demande_id} />
                    <button
                      type="submit"
                      className="rounded-md border border-bordure px-3 py-1 text-xs hover:border-alerte hover:text-alerte"
                    >
                      Masquer le dossier
                    </button>
                  </form>
                ) : s.statut === "masquee" ? (
                  <p className="mt-2 text-xs text-texte-doux">
                    Masqué. Effacement définitif prévu le{" "}
                    {s.purge_prevue_le
                      ? new Date(s.purge_prevue_le).toLocaleDateString("fr-FR")
                      : "—"}
                    . Le retour en arrière reste possible jusque-là.
                  </p>
                ) : (
                  <p className="mt-2 text-xs text-texte-doux">
                    En attente de l’accord de tous les titulaires.
                  </p>
                )}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {/* ------------------------------------------------ purges */}
      {purgeables.length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Effacements arrivés à terme</h2>
          <p className="text-sm text-texte-doux">
            La purge n’est pas automatique : elle effacerait des dossiers un dimanche
            matin sans que personne l’ait décidé ce jour-là.
          </p>
          <ul className="space-y-2">
            {purgeables.map((p) => (
              <li
                key={p.enfant_id}
                className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-alerte bg-surface p-4 text-sm"
              >
                <span>
                  <span className="font-medium">{p.prenom}</span>
                  <span className="ml-2 text-xs text-texte-doux">
                    dû depuis {p.jours_de_retard} jour{p.jours_de_retard > 1 ? "s" : ""}
                    {p.sur_demande ? " · suppression demandée" : " · archivage à terme"}
                  </span>
                </span>
                <form action={purgerLeDossier}>
                  <input type="hidden" name="enfantId" value={p.enfant_id} />
                  <button
                    type="submit"
                    className="rounded-md border border-alerte px-3 py-1 text-xs text-alerte hover:bg-alerte-douce"
                  >
                    Effacer définitivement
                  </button>
                </form>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {/* ------------------------------------------------ envois */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Envois en échec</h2>
        {/* Sans cet écran, une clé d'API expirée passe inaperçue jusqu'à ce
            qu'une famille signale n'avoir rien reçu depuis trois semaines. */}
        {(echecs.data ?? []).length === 0 ? (
          <p className="text-sm text-texte-doux">
            Rien à signaler sur les sept derniers jours.
          </p>
        ) : (
          <ul className="space-y-2">
            {(echecs.data as { canal: string; statut: string; nombre: number; derniere_erreur: string }[]).map(
              (e, i) => (
                <li
                  key={i}
                  className="rounded-lg border border-alerte bg-surface p-4 text-sm"
                >
                  <span className="font-medium">
                    {e.nombre} envoi{e.nombre > 1 ? "s" : ""} par {e.canal} — {e.statut}
                  </span>
                  {e.derniere_erreur ? (
                    <p className="mt-1 break-all text-xs text-texte-doux">
                      {e.derniere_erreur}
                    </p>
                  ) : null}
                </li>
              ),
            )}
          </ul>
        )}
      </section>
    </main>
  );
}
