export default function PageConfigurationRequise() {
  return (
    <div className="mx-auto max-w-xl">
      <h1 className="text-2xl font-semibold">Configuration Supabase manquante</h1>
      <p className="mt-3 text-sm text-texte-doux">
        L&apos;application démarre, mais elle n&apos;a pas de base à interroger.
      </p>

      <ol className="mt-6 list-decimal space-y-2 pl-5 text-sm">
        <li>
          Copier <code className="rounded bg-fond px-1">.env.local.example</code> en{" "}
          <code className="rounded bg-fond px-1">.env.local</code>.
        </li>
        <li>
          Y renseigner <code className="rounded bg-fond px-1">NEXT_PUBLIC_SUPABASE_URL</code> et{" "}
          <code className="rounded bg-fond px-1">NEXT_PUBLIC_SUPABASE_ANON_KEY</code>, depuis
          Supabase &rsaquo; Project Settings &rsaquo; API.
        </li>
        <li>
          Appliquer les migrations de{" "}
          <code className="rounded bg-fond px-1">supabase/migrations/</code> dans l&apos;ordre,
          via le SQL Editor.
        </li>
        <li>
          Relancer <code className="rounded bg-fond px-1">npm run dev</code> : Next.js ne relit
          pas ce fichier à chaud.
        </li>
      </ol>
    </div>
  );
}
