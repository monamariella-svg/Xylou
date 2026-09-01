"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { retirerDuDossier } from "./actions";

export type Intervenant = {
  id: string;
  profil_id: string;
  role: string;
  fonction: string | null;
  principal: boolean | null;
  toutes_matieres: boolean | null;
  cree_le: string | null;
  prenom: string | null;
  nom: string | null;
  email: string | null;
};

const LIBELLE_ROLE: Record<string, string> = {
  parent: "Titulaire de l’autorité parentale",
  referent: "Référent",
  enseignant: "Enseignant",
  accompagnant: "AESH ou accompagnant",
};

function qualite(i: Intervenant): string {
  const base = LIBELLE_ROLE[i.role] ?? i.role;
  if (i.role === "referent") return `${base}${i.principal ? " · principal" : " · suppléant"}`;
  if (i.role === "enseignant" && i.toutes_matieres) return `${base} · toutes matières`;
  return base;
}

export function LigneIntervenant({
  enfantId,
  intervenant,
  peutComposer,
  estSoiMeme,
}: {
  enfantId: string;
  intervenant: Intervenant;
  peutComposer: boolean;
  estSoiMeme: boolean;
}) {
  const router = useRouter();
  const [ouvert, setOuvert] = useState(false);
  const [email, setEmail] = useState(intervenant.email ?? "");
  const [message, setMessage] = useState<{ erreur?: string; succes?: string }>({});
  const [enCours, demarrer] = useTransition();

  const nomComplet =
    [intervenant.prenom, intervenant.nom].filter(Boolean).join(" ").trim() ||
    intervenant.email ||
    "Compte sans nom";

  // Le référent corrige l'adresse des autres, jamais la sienne : la sienne se
  // change depuis ses réglages, où il prouve qu'il en est le titulaire.
  const corrigible = peutComposer && !estSoiMeme;

  function corriger() {
    setMessage({});
    demarrer(async () => {
      const reponse = await fetch("/api/intervenants/adresse", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ enfantId, profilId: intervenant.profil_id, email }),
      });
      const donnees = await reponse.json().catch(() => ({}));
      if (!reponse.ok) {
        setMessage({ erreur: donnees.erreur ?? "La correction a échoué." });
        return;
      }
      setMessage({ succes: donnees.succes });
      setOuvert(false);
      router.refresh();
    });
  }

  return (
    <li className="rounded-lg border border-bordure bg-surface p-4 text-sm">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <span className="font-medium">{nomComplet}</span>
        <span className="text-xs text-texte-doux">{qualite(intervenant)}</span>
      </div>

      {/* Ce qui est rattaché, montré plutôt que deviné. Le nom seul ne dit pas
          quelle adresse a été invitée, et c'est précisément la question qu'on
          se pose quand quelqu'un ne reçoit rien. */}
      <dl className="mt-2 space-y-0.5 text-xs text-texte-doux">
        {intervenant.email ? (
          <div className="flex gap-2">
            <dt className="sr-only">Adresse</dt>
            <dd className="break-all">{intervenant.email}</dd>
          </div>
        ) : null}
        {intervenant.fonction ? (
          <div>
            <dt className="sr-only">Fonction</dt>
            <dd>{intervenant.fonction}</dd>
          </div>
        ) : null}
        {intervenant.cree_le ? (
          <div>
            <dt className="sr-only">Rattaché le</dt>
            <dd>
              Rattaché le{" "}
              {new Date(intervenant.cree_le).toLocaleDateString("fr-FR", {
                day: "numeric",
                month: "long",
                year: "numeric",
              })}
            </dd>
          </div>
        ) : null}
      </dl>

      {message.succes ? (
        <p className="mt-2 rounded-md border border-accent bg-accent-doux px-3 py-2 text-xs text-accent">
          {message.succes} Prévenez la personne : c’est désormais avec cette adresse
          qu’elle se connecte.
        </p>
      ) : null}

      <div className="mt-3 flex flex-wrap gap-2">
        {corrigible ? (
          <button
            type="button"
            onClick={() => setOuvert((o) => !o)}
            className="rounded-md border border-bordure px-3 py-1 text-xs hover:border-accent hover:text-accent"
          >
            {ouvert ? "Fermer" : "Corriger l’adresse"}
          </button>
        ) : null}

        {/* Un titulaire de l'autorité parentale ne se retire pas d'ici : la
            fonction de 0033 le refuse, et le proposer laisserait croire
            l'inverse. */}
        {intervenant.role !== "parent" && peutComposer ? (
          <form action={retirerDuDossier} className="flex flex-1 flex-wrap gap-2">
            <input type="hidden" name="enfantId" value={enfantId} />
            <input type="hidden" name="profilId" value={intervenant.profil_id} />
            <input
              name="motif"
              placeholder="Motif du retrait"
              className="min-w-32 flex-1 rounded-md border border-bordure bg-fond px-2 py-1 text-xs"
            />
            <button
              type="submit"
              className="rounded-md border border-bordure px-3 py-1 text-xs hover:border-alerte hover:text-alerte"
            >
              Retirer
            </button>
          </form>
        ) : null}
      </div>

      {ouvert ? (
        <div className="mt-3 space-y-2 rounded-md border border-bordure bg-fond p-3">
          {/* L'avertissement avant l'action, pas après : changer l'adresse d'un
              compte change ce qui l'ouvre. Personne ne doit découvrir ça en
              cliquant. */}
          <p className="text-xs text-texte-doux">
            Cette adresse est celle avec laquelle la personne se connecte. La corriger
            change son identifiant : l’ancienne cesse aussitôt de fonctionner, et il
            vous revient de la prévenir. L’opération est consignée dans le journal du
            dossier.
          </p>

          <div className="flex flex-wrap gap-2">
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="flex-1 rounded-md border border-bordure bg-surface px-2 py-1 text-sm"
            />
            <button
              type="button"
              onClick={corriger}
              disabled={enCours || !email.trim() || email.trim() === intervenant.email}
              className="rounded-md bg-accent px-3 py-1 text-xs font-medium text-white disabled:opacity-50"
            >
              {enCours ? "En cours…" : "Corriger"}
            </button>
          </div>

          {message.erreur ? (
            <p className="rounded-md border border-alerte bg-alerte-douce px-3 py-2 text-xs text-alerte">
              {message.erreur}
            </p>
          ) : null}
        </div>
      ) : null}
    </li>
  );
}
