#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SQL="$ROOT/supabase/schema.sql"
DASHBOARD="https://supabase.com/dashboard/project/oadbjhhfkkhblhzmwoyh"
SITE_URL="https://brenton-beachplain.github.io/Mise/"

open_page(){ if command -v open >/dev/null;then open "$1";elif command -v xdg-open >/dev/null;then xdg-open "$1";fi; }
pause(){ read -r -p "$1 Press Enter to continue… " _; }

printf '\nMise Supabase setup — 3 stages, about 5 minutes\n\n'
printf 'This wizard never asks for a database password or secret/service-role key.\n'
pause "Ready?"

printf '\n[1/3] Create the protected snapshot tables\n'
open_page "$DASHBOARD/sql/new"
printf 'The SQL migration is at:\n  %s\n\nCopy all of it into the SQL Editor and choose Run.\n' "$SQL"
if command -v pbcopy >/dev/null;then pbcopy < "$SQL";printf '(The SQL is already on your clipboard.)\n';fi
pause "Confirm the editor reports Success."

printf '\n[2/3] Allow email sign-in to return to Mise\n'
open_page "$DASHBOARD/auth/url-configuration"
printf 'Set Site URL to:\n  %s\nAdd the same value under Redirect URLs, then save.\n' "$SITE_URL"
pause "Confirm the URL configuration is saved."

printf '\n[3/3] Verify email authentication\n'
open_page "$DASHBOARD/auth/providers"
printf 'Open Email and leave Email provider enabled. Save if you changed it.\n'
pause "Confirm Email authentication is enabled."

printf '\nSetup complete. Deploy the app, then use Settings → Cloud backup to sign in.\n'
printf 'On first sign-in, Mise asks before uploading local data when no cloud copy exists.\n\n'
