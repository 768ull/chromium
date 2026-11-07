#!/usr/bin/env bash
# Gera os quatro keystores das variantes do Pure Browser.
# Execute UMA UNICA VEZ na maquina de compilacao e guarde backup seguro:
# sem o keystore original nao ha como atualizar o aplicativo instalado.
set -euo pipefail

KEYSTORE_DIR="${KEYSTORE_DIR:-$HOME/keystores}"
mkdir -p "$KEYSTORE_DIR"
cd "$KEYSTORE_DIR"

read -r -s -p "Senha dos keystores: " PASS; echo
[ -n "$PASS" ] || { echo "Senha vazia nao permitida."; exit 1; }

for v in v1 v2 v3 v4; do
  keytool -genkeypair -v \
    -keystore "pure_${v}.jks" \
    -storepass "$PASS" \
    -alias "pure_${v}" \
    -keyalg RSA -keysize 4096 \
    -validity 10000 \
    -storetype JKS \
    -dname "CN=Pure Browser ${v}, O=Pure Browser Project, C=BR"
done

chmod 600 pure_*.jks
echo "Keystores gerados em $KEYSTORE_DIR"
echo "Defina o secret PURE_KEYSTORE_PASSWORD no repositorio com a mesma senha."
