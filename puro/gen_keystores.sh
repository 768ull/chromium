#!/usr/bin/env bash
# gen_keystores.sh: gera as quatro keystores das variantes Puro (RSA 4096).
# ATENCAO: executar apenas em maquina local confiavel; nunca em ambientes de CI.
# Uso: gen_keystores.sh <dir_destino>
set -euo pipefail
KEYS="${1:?diretorio de destino obrigatorio}"
mkdir -p "$KEYS"
for v in v1 v2 v3 v4; do
  PASS="$(openssl rand -base64 24)"
  keytool -genkeypair -v \
    -keystore "$KEYS/puro-$v.jks" \
    -alias "puro_$v" \
    -keyalg RSA -keysize 4096 -validity 10000 \
    -storepass "$PASS" -keypass "$PASS" \
    -dname "CN=Puro Browser $v, OU=Engineering, O=Puro, C=BR"
  echo "puro-$v.jks => senha: $PASS" | tee -a "$KEYS/senhas.txt"
done
chmod 600 "$KEYS"/*.jks "$KEYS"/senhas.txt
echo ""
echo "Cadastre no GitHub (Settings > Secrets and variables > Actions) os seguintes segredos:"
for v in v1 v2 v3 v4; do
  echo "  PURO_KEYSTORE_${v^^} = <conteudo de: base64 -w0 $KEYS/puro-$v.jks>"
  echo "  PURO_KEYSTORE_${v^^}_PASSWORD = <senha correspondente em $KEYS/senhas.txt>"
done
