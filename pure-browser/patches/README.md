# Camada de patches de des-Googlizacao

As flags de compilacao (GN) removem grande parte das integracoes com o
Google, mas nao tudo. Esta camada conclui o trabalho em tres frentes.

## 1. Base recomendada: ungoogled-chromium-android

Porte os patches do projeto:

    https://github.com/ungoogled-software/ungoogled-chromium-android

O conjunto cobre login e sincronizacao de contas, telemetria (UMA),
reporte de falhas (Crashpad), integracao de traducao, Safe Browsing
residual, motores de busca e elementos de interface do Google no Android.

Aplicacao:

    git apply --3way < patch

## 2. Patches especificos do Pure Browser

- Nome do aplicativo: recurso de string IDS_APP_NAME em chrome/android.
- Buscador padrao neutro: components/search_engines/prepopulated_engines.json
  (definir DuckDuckGo, Startpage ou Qwant como padrao; remover o Google da
  lista inicial).
- Pagina inicial e nova aba padrao: preferencias em chrome/android.
- Manifesto: remocao de servicos, metadados e intents residuais ligados ao
  Google Play Services em chrome/android/java/AndroidManifest.xml.

## 3. Substituicao de dominios e poda de binarios

Siga a documentacao de domain substitution e binary pruning do projeto
ungoogled-chromium para remover chamadas residuais a dominios do Google.

## Manutencao

A cada sincronizacao com o upstream, reaplique a serie de patches a partir
deste diretorio (pure-browser/patches/), versionando os arquivos para
manter a compilacao reproduzivel.
