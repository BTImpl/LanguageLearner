#!/usr/bin/env bash
# Checks or fixes the formatting of the Dart sources.
#
#   tool/format.sh check   exit non-zero if any file is not formatted (default)
#   tool/format.sh fix     format the files in place
#
# The generated localization files are skipped: we do not format them by hand
# and regenerating them would cause false failures. Used by the CI workflow
# and by the pre-commit hook, so both always check the same thing.
set -euo pipefail

cd "$(dirname "$0")/.."

mode="${1:-check}"

files="$(git ls-files -co --exclude-standard '*.dart' | grep -v '^lib/i18n/app_localizations' || true)"

case "$mode" in
  check) printf '%s\n' "$files" | xargs dart format --output=none --set-exit-if-changed ;;
  fix) printf '%s\n' "$files" | xargs dart format ;;
  *)
    echo "usage: tool/format.sh [check|fix]" >&2
    exit 2
    ;;
esac
