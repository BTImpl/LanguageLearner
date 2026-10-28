#!/usr/bin/env bash
# Builds an unsigned release IPA for sideloading with AltStore (card LL-46).
#
#   tool/build_ipa.sh                       build with the default backend
#   API_BASE_URL=https://... tool/build_ipa.sh   build against another backend
#
# The result is build/ipa/LanguageLearner.ipa. It is not signed: AltStore signs
# it with the Apple ID of the person who installs it (see README, "Installing
# on an iPhone without the App Store").
set -euo pipefail

cd "$(dirname "$0")/.."

defines=()
if [[ -n "${API_BASE_URL:-}" ]]; then
  defines+=("--dart-define=API_BASE_URL=${API_BASE_URL}")
  echo "Backend: ${API_BASE_URL}"
else
  echo "Backend: the default of AppConfig (the Cloud Run service)"
fi

flutter build ios --release --no-codesign ${defines[@]+"${defines[@]}"}

app="build/ios/iphoneos/Runner.app"
if [[ ! -d "$app" ]]; then
  echo "error: $app was not built" >&2
  exit 1
fi

out="build/ipa"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

rm -rf "$out"
mkdir -p "$out" "$work/Payload"
cp -R "$app" "$work/Payload/"
(cd "$work" && zip -qry "$OLDPWD/$out/LanguageLearner.ipa" Payload)

echo "Done: $out/LanguageLearner.ipa ($(du -h "$out/LanguageLearner.ipa" | cut -f1))"
