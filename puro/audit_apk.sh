#!/usr/bin/env bash
set -euo pipefail
APK="${1:?APK obrigatorio}"; BT="${2:?build-tools obrigatorio}"; VARIANT="${3:?variante obrigatoria}"; ABI="${4:?ABI obrigatoria}"
test -s "$APK"
"$BT/apksigner" verify --verbose "$APK"
"$BT/zipalign" -c -v 4 "$APK"
EXPECTED="com.purobrowser.$VARIANT"
BADGING="$("$BT/aapt2" dump badging "$APK")"
printf '%s\n' "$BADGING" | grep -Fq "package: name='$EXPECTED'" || { echo "Application ID incorreto; esperado $EXPECTED" >&2; exit 1; }
unzip -Z1 "$APK" | grep -Fq "lib/$ABI/" || { echo "ABI $ABI nao encontrada no APK" >&2; exit 1; }
MANIFEST="$("$BT/aapt2" dump xmltree --file AndroidManifest.xml "$APK")"
FORBIDDEN='com\.google\.android\.gms\.|com\.google\.android\.c2dm|com\.google\.apps\.now\.CURRENT_ACCOUNT_ACCESS|com\.google\.firebase\.MESSAGING_EVENT|com\.google\.firebase\.provider\.FirebaseInitProvider|com\.google\.android\.play\.core'
if printf '%s\n' "$MANIFEST" | grep -Eiq "$FORBIDDEN"; then echo "Manifesto contem referencias Google/GMS proibidas" >&2; printf '%s\n' "$MANIFEST" | grep -Ein "$FORBIDDEN" >&2 || true; exit 1; fi
echo "AUDITORIA APK APROVADA: $EXPECTED / $ABI"
echo "Esta auditoria nao prova ausencia de endpoints Google ou simbolos em bibliotecas nativas."
