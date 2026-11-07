#!/usr/bin/env bash
# Compila uma variante Puro para uma ABI Android.
# Uso: build_puro.sh <v1|v2|v3|v4> <arm64|arm|x86|x64> <chromium-src> <dist>
set -euo pipefail
VARIANT="${1:?variante obrigatoria (v1|v2|v3|v4)}"
CPU="${2:?target_cpu obrigatorio (arm64|arm|x86|x64)}"
SRC="${3:?diretorio da arvore Chromium obrigatorio}"
DIST="${4:?diretorio de saida obrigatorio}"
case "$VARIANT" in v1) CHANNEL=stable;; v2) CHANNEL=beta;; v3) CHANNEL=dev;; v4) CHANNEL=canary;; *) echo "Variante invalida" >&2; exit 2;; esac
case "$CPU" in arm64) ABI=arm64-v8a;; arm) ABI=armeabi-v7a;; x86) ABI=x86;; x64) ABI=x86_64;; *) echo "CPU invalida" >&2; exit 2;; esac
command -v gn >/dev/null && command -v autoninja >/dev/null || { echo "depot_tools ausente do PATH" >&2; exit 1; }
test -f "$SRC/chrome/android/BUILD.gn"
OUT="$SRC/out/puro-$VARIANT-$CPU"
mkdir -p "$OUT" "$DIST"
cat > "$OUT/args.gn" <<EOF
target_os = "android"
target_cpu = "$CPU"
is_debug = false
is_official_build = true
is_component_build = false
is_java_debug = false
puro_variant = "$VARIANT"
android_channel = "$CHANNEL"
symbol_level = 0
blink_symbol_level = 0
v8_symbol_level = 0
chrome_pgo_phase = 0
dcheck_always_on = false
debuggable_apks = false
exclude_unwind_tables = true
treat_warnings_as_errors = false
is_chrome_branded = false
use_official_google_api_keys = false
google_api_key = ""
google_default_client_id = ""
google_default_client_secret = ""
enable_hangout_services_extension = false
enable_mdns = false
enable_service_discovery = false
disable_fieldtrial_testing_config = true
safe_browsing_mode = 1
EOF
cd "$SRC"
gn gen "$OUT"
autoninja -C "$OUT" chrome_public_apk
APK="$OUT/apks/ChromePublic.apk"
test -s "$APK" || { echo "APK nao foi produzido: $APK" >&2; exit 1; }
cp "$APK" "$DIST/Puro-$VARIANT-$ABI-unsigned.apk"
if [ -n "${GITHUB_ENV:-}" ]; then printf 'PURO_ABI=%s\nPURO_VARIANT=%s\n' "$ABI" "$VARIANT" >> "$GITHUB_ENV"; fi
echo "APK nao assinado: $DIST/Puro-$VARIANT-$ABI-unsigned.apk"
