#!/usr/bin/env bash
#
# Applique toutes les migrations sur un PostgreSQL jetable, puis, sur demande,
# écrit le schéma obtenu dans supabase/schema.sql.
#
#   ./supabase/verification/executer.sh            vérifie seulement
#   ./supabase/verification/executer.sh --schema   vérifie et régénère le schéma
#
set -euo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${PGTEST_PORT:-55432}"
DONNEES="$(mktemp -d)/data"
BIN="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | tail -1 || true)"
[ -n "$BIN" ] && export PATH="$BIN:$PATH"

command -v initdb >/dev/null || { echo "PostgreSQL introuvable (initdb)."; exit 2; }

# initdb refuse de tourner en root : on passe par un compte dédié le cas échéant.
if [ "$(id -u)" = 0 ]; then
  id pgtest >/dev/null 2>&1 || useradd -m pgtest
  COMME="su pgtest -c"
  mkdir -p "$DONNEES" && chown -R pgtest "$(dirname "$DONNEES")" && chmod 700 "$DONNEES"
else
  COMME="bash -c"
  mkdir -p "$DONNEES"
fi

nettoyer() {
  $COMME "pg_ctl -D '$DONNEES' -m immediate stop" >/dev/null 2>&1 || true
  rm -rf "$(dirname "$DONNEES")"
}
trap nettoyer EXIT

$COMME "PATH='$PATH' initdb -D '$DONNEES' -U pgtest --auth=trust" >/dev/null
$COMME "PATH='$PATH' pg_ctl -D '$DONNEES' -o '-k /tmp -p $PORT -c listen_addresses=' -w start" >/dev/null

psql_() { $COMME "psql -h /tmp -p $PORT -U pgtest -d ${1} -q -v ON_ERROR_STOP=1 ${2:-}"; }

psql_ postgres "-c 'create database xylou;'"
psql_ xylou < "$RACINE/supabase/verification/bouchons-supabase.sql"

for f in "$RACINE"/supabase/migrations/*.sql; do
  if ! psql_ xylou < "$f" 2>/tmp/xylou-migration.err; then
    echo "✗ $(basename "$f")"
    head -20 /tmp/xylou-migration.err
    exit 1
  fi
done

echo "✓ $(ls "$RACINE"/supabase/migrations/*.sql | wc -l) migrations appliquées"

if [ "${1:-}" = "--schema" ]; then
  {
    sed 's/^/-- /' "$RACINE/supabase/verification/entete-schema.txt"
    # `\restrict` porte un jeton tiré au hasard à chaque exécution. Le garder
    # ferait apparaître une différence à chaque régénération, et une vraie
    # modification du schéma s'y perdrait. Ce garde-fou protège une
    # restauration ; ce fichier est une référence, on ne restaure pas depuis lui.
    $COMME "PATH='$PATH' pg_dump -h /tmp -p $PORT -U pgtest -d xylou \
      --schema-only --schema=public --no-owner --no-privileges" \
      | grep -v '^.\(un\)\?restrict '
  } > "$RACINE/supabase/schema.sql"
  echo "✓ supabase/schema.sql régénéré"
fi
