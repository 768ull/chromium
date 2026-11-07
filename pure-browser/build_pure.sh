#!/usr/bin/env bash
# Pure Browser - orquestrador de compilacao (Chromium for Android)
# Uso: ./build_pure.sh <variante> <abi>
#      variante: v1 | v2 | v3 | v4      abi: arm64 | arm | x86 | x64
set -euo pipefail

VARIANT="${1:?Uso: build_pure.sh <v1|v2|v3|v4> <arm64|arm|x86|x64>}"
ABI="${2:?Uso: build_pure.sh <v1|v2|v3|v4> <arm64|arm|x86|x64>}"

case "$VARIANT" in v1|v2|v3|v4) ;; *) echo "Variante invalida: $VARIANT"; exit 1 ;; esac
case "$ABI" in arm64|arm|x86|x64) ;; *) echo "ABI invalida: $ABI"; exit 1 ;; esac

SRC="${SRC:-$HOME/pure-browser/src}"
KEYSTORE_DIR="${KEYSTORE_DIR:-$HOME/keystores}"
DIST="${DIST:-$SRC/dist}"
KEYSTORE_PASSWORD="${KEYSTORE_PASSWORD:?Defina a variavel de ambiente KEYSTORE_PASSWORD}"

declare -A PKG=(
  [v1]=com.purobrowser.v1
  [v2]=com.purobrowser.v2
  [v3]=com.purobrowser.v3
  [v4]=com.purobrowser.v4
)
declare -A KEYNAME=( [v1]=pure_v1 [v2]=pure_v2 [v3]=pure_v3 [v4]=pure_v4 )

[ -d "$SRC" ] || { echo "Checkout nao encontrado em $SRC"; exit 1; }
[ -f "$KEYSTORE_DIR/${KEYNAME[$VARIANT]}.jks" ] || {
  echo "Keystore ausente: $KEYSTORE_DIR/${KEYNAME[$VARIANT]}.jks"
  echo "Execute antes: ./generate_keystores.sh"
  exit 1
}

cd "$SRC"
OUT="$SRC/out/${VARIANT}-${ABI}"
mkdir -p "$OUT" "$DIST"

cat > "$OUT/args.gn" <<EOF
# Pure Browser - variante ${VARIANT} - ABI ${ABI}
target_os = "android"
target_cpu = "${ABI}"
is_debug = false
is_official_build = true
is_component_build = false
symbol_level = 0
blink_symbol_level = 0
disable_fieldtrial_testing_config = true

# Des-Googlizacao em nivel de compilacao
use_official_google_api_keys = false
safe_browsing_mode = 0
enable_reporting = false
enable_hangout_services_extension = false
enable_mdns = false
enable_remoting = false
build_contextual_search = false

# Flags legadas solicitadas no projeto: o laco abaixo remove
# automaticamente qualquer uma que a revisao atual nao reconheca.
enable_gservices = false
enable_google_now = false

chrome_public_manifest_package = "${PKG[$VARIANT]}"
android_channel = "default"

proprietary_codecs = true
ffmpeg_branding = "Chrome"

android_keystore_name = "${KEYNAME[$VARIANT]}"
android_keystore_path = "$KEYSTORE_DIR/${KEYNAME[$VARIANT]}.jks"
android_keystore_password = "$KEYSTORE_PASSWORD"
EOF

# O gn rejeita argumentos desconhecidos; remove a flag e tenta novamente.
ok=0
for attempt in 1 2 3 4 5; do
  if gn gen "$OUT" 2> "$OUT/gn.err"; then
    ok=1
    break
  fi
  if ! grep -q 'Unrecognized argument' "$OUT/gn.err"; then
    cat "$OUT/gn.err" >&2
    exit 1
  fi
  flag="$(grep 'Unrecognized argument' "$OUT/gn.err" | cut -d '"' -f2 | head -n 1)"
  if [ -z "$flag" ]; then
    cat "$OUT/gn.err" >&2
    exit 1
  fi
  grep -v "^${flag} =" "$OUT/args.gn" > "$OUT/args.gn.tmp"
  mv "$OUT/args.gn.tmp" "$OUT/args.gn"
  echo "Aviso: flag legada nao reconhecida pela revisao atual foi removida: ${flag}"
done
[ "$ok" -eq 1 ] || { echo "gn gen falhou"; cat "$OUT/gn.err" >&2; exit 1; }

autoninja -C "$OUT" chrome_public_apk

cp -f "$OUT/apks/ChromePublic.apk" "$DIST/PureBrowser-${VARIANT}-${ABI}.apk"
echo "APK gerado: $DIST/PureBrowser-${VARIANT}-${ABI}.apk"
