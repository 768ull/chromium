#!/usr/bin/env bash
# build_puro.sh: compila uma celula da matriz Puro (variante x ABI).
# Uso: build_puro.sh <v1|v2|v3|v4> <arm64|arm|x86|x64> <dir_arvore_chromium> <dir_dist>
set -euo pipefail

VARIANT="${1:?variante (v1|v2|v3|v4) obrigatoria}"
CPU="${2:?target_cpu (arm64|arm|x86|x64) obrigatorio}"
SRC="${3:?diretorio da arvore do Chromium obrigatorio}"
DIST="${4:?diretorio de saida obrigatorio}"

case "$VARIANT" in
  v1) CHANNEL="stable" ;;
  v2) CHANNEL="beta" ;;
  v3) CHANNEL="dev" ;;
  v4) CHANNEL="canary" ;;
  *) echo "Variante invalida: $VARIANT"; exit 1 ;;
esac

case "$CPU" in
  arm64) ABI="arm64-v8a" ;;
  arm)   ABI="armeabi-v7a" ;;
  x86)   ABI="x86" ;;
  x64)   ABI="x86_64" ;;
  *) echo "target_cpu invalido: $CPU"; exit 1 ;;
esac

command -v gn >/dev/null 2>&1 || { echo "gn nao encontrado no PATH (instale o depot_tools)"; exit 1; }

cd "$SRC"
OUT="out/puro-$VARIANT-$CPU"
mkdir -p "$OUT" "$DIST"

cat > "$OUT/args.gn" <<'EOF'
# ==== Plataforma ====
target_os = "android"
target_cpu = "__CPU__"
is_debug = false
is_official_build = true
is_component_build = false
android_channel = "__CHANNEL__"

# ==== Simbolos e desempenho ====
symbol_level = 0
blink_symbol_level = 0
v8_symbol_level = 0
chrome_pgo_phase = 0
dcheck_always_on = false
debuggable_apks = false
exclude_unwind_tables = true
treat_warnings_as_errors = false
icu_use_data_file = true

# ==== De-googling: chaves, telemetria e servicos web ====
use_official_google_api_keys = false
google_api_key = ""
google_default_client_id = ""
google_default_client_secret = ""
safe_browsing_mode = 0
disable_fieldtrial_testing_config = true
enable_reporting = false
enable_remoting = false
enable_mdns = false
enable_service_discovery = false
build_contextual_search = false
enable_hangout_services_extension = false

# ==== Identidade da variante (permite instalacao paralela) ====
chrome_public_manifest_package = "com.purobrowser.__VARIANT__"

# ==== Midia (interoperabilidade com o ecossistema Android) ====
ffmpeg_branding = "Chrome"
proprietary_codecs = true
enable_av1_decoder = true
enable_dav1d_decoder = true
media_use_openh264 = false
EOF

sed -i "s/__CPU__/$CPU/g; s/__CHANNEL__/$CHANNEL/g; s/__VARIANT__/$VARIANT/g" "$OUT/args.gn"

gn gen "$OUT"
autoninja -C "$OUT" chrome_public_apk

cp "$OUT/apks/ChromePublic.apk" "$DIST/Puro-$VARIANT-$ABI-unsigned.apk"

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "ABI_NAME=$ABI" >> "$GITHUB_ENV"
  echo "VARIANT=$VARIANT" >> "$GITHUB_ENV"
fi

echo "Concluido: $DIST/Puro-$VARIANT-$ABI-unsigned.apk"
