"use client";

import { useFormStatus } from "react-dom";

export function Champ({
  label,
  aide,
  children,
}: {
  label: string;
  aide?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-medium">{label}</span>
      {children}
      {aide ? <span className="mt-1 block text-xs text-texte-doux">{aide}</span> : null}
    </label>
  );
}

export const classesChamp =
  "w-full rounded-md border border-bordure bg-surface px-3 py-2 text-sm " +
  "focus:border-accent focus:outline-none";

export function MessageErreur({ children }: { children?: React.ReactNode }) {
  if (!children) return null;
  return (
    <p
      role="alert"
      className="rounded-md border border-alerte bg-alerte-douce px-3 py-2 text-sm text-alerte"
    >
      {children}
    </p>
  );
}

export function MessageSucces({ children }: { children?: React.ReactNode }) {
  if (!children) return null;
  return (
    <p className="rounded-md border border-accent bg-accent-doux px-3 py-2 text-sm text-accent">
      {children}
    </p>
  );
}

// `useFormStatus` doit être appelé dans un composant *enfant* du <form>, pas dans
// le composant qui rend le <form> : sinon il renvoie toujours pending = false.
export function BoutonSoumettre({
  children,
  variante = "principal",
}: {
  children: React.ReactNode;
  variante?: "principal" | "discret";
}) {
  const { pending } = useFormStatus();
  const base = "rounded-md px-4 py-2 text-sm font-medium disabled:opacity-50";
  const style =
    variante === "principal"
      ? "bg-accent text-white hover:opacity-90"
      : "border border-bordure bg-surface hover:bg-fond";

  return (
    <button type="submit" disabled={pending} className={`${base} ${style}`}>
      {pending ? "…" : children}
    </button>
  );
}
