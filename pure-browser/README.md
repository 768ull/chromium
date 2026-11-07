# Pure Browser

Navegador web para Android construido sobre a base aberta do Chromium (este
repositorio), sem servicos, telemetria, chaves de API ou dependencias do
Google, com quatro variantes de pacote e suporte a multiplas arquiteturas.

## Estrutura deste kit

| Arquivo | Finalidade |
| --- | --- |
| build_pure.sh | Orquestrador: gera o args.gn, compila chrome_public_apk e coleta o APK |
| generate_keystores.sh | Gera os quatro keystores de assinatura (executar uma unica vez) |
| args/v1.gn ... args/v4.gn | Modelos de configuracao de compilacao por variante |
| patches/README.md | Camada de patches de des-Googlizacao |
| .github/workflows/build-pure.yml | Workflow de compilacao via GitHub Actions |

## Requisitos da maquina de compilacao

A compilacao do Chromium para Android NAO cabe nos runners hospedados
gratuitos do GitHub (4 nucleos, disco insuficiente, limite de 6 horas por
job). E obrigatorio um runner auto-hospedado com:

- Linux 64 bits (Ubuntu 20.04+ ou Debian 11+)
- 16 nucleos ou mais (recomendado)
- Minimo de 16 GB de RAM (recomendado 32 GB)
- Minimo de 150 GB livres em disco (recomendado 250 GB)
- Git e Python 3 instalados

## Passo 1 - Registrar o runner auto-hospedado

Na maquina Linux de compilacao:

    mkdir ~/runner && cd ~/runner
    # Baixe a versao atual do runner em:
    #   https://github.com/actions/runner/releases
    # Gere o token em: Settings > Actions > Runners > New self-hosted runner
    ./config.sh --url https://github.com/768ull/chromium --token <TOKEN> --labels chromium-builder
    ./run.sh

Modo servico (opcional):

    sudo ./svc.sh install && sudo ./svc.sh start

## Passo 2 - Keystores e secret

Na maquina de compilacao:

    ./generate_keystores.sh

Em seguida, em Settings > Secrets and variables > Actions, crie o secret
PURE_KEYSTORE_PASSWORD com a senha definida no passo acima.

## Passo 3 - Disparar a compilacao

O push deste kit ja dispara automaticamente uma compilacao da variante v1
para a ABI arm64. Compilacoes adicionais: aba Actions > Build Pure Browser
APK > Run workflow, escolhendo variante (v1, v2, v3, v4) e ABI (arm64, arm,
x86, x64).

Enquanto nenhum runner com o rotulo chromium-builder estiver registrado, o
job permanece no estado Queued (aguardando runner). Esse e o comportamento
esperado.

## Dependencias do sistema (uma unica vez)

O script de dependencias exige root. Se o runner nao tiver sudo sem senha,
execute uma vez manualmente na maquina:

    sudo ~/pure-browser/src/build/install-build-deps.sh --android

## Variantes

| Variante | ID de pacote | Finalidade |
| --- | --- | --- |
| V1 | com.purobrowser.v1 | Estavel de producao |
| V2 | com.purobrowser.v2 | Beta de testes publicos |
| V3 | com.purobrowser.v3 | Desenvolvimento (Dev) |
| V4 | com.purobrowser.v4 | Noturna (Nightly), atualizacoes continuas |

Como os quatro identificadores sao distintos, as quatro variantes coexistem
no mesmo aparelho.

## Arquiteturas

| target_cpu | ABI do APK | Publico |
| --- | --- | --- |
| arm64 | arm64-v8a | Aparelhos ARM modernos de 64 bits |
| arm | armeabi-v7a | Aparelhos ARM de 32 bits antigos |
| x86 | x86 | Emuladores e tablets Intel antigos |
| x64 | x86_64 | Emuladores modernos e tablets Intel |

Nao existe alvo GN que empacote todas as ABIs em um unico APK: cada
combinacao variante x ABI e uma compilacao independente. Para um arquivo
universal, compile chrome_public_bundle e utilize bundletool
(build-apks --mode=universal).

## Des-Googlizacao

Camada 1, flags GN (ja incluidas em build_pure.sh e args/*.gn):
use_official_google_api_keys=false, safe_browsing_mode=0,
enable_reporting=false, disable_fieldtrial_testing_config=true,
enable_hangout_services_extension=false, entre outras.

Camada 2, patches de codigo: veja patches/README.md.

## Avisos legais

- O Chromium e licenciado sob BSD de tres clausulas: preserve os arquivos
  LICENSE e os avisos de direitos autorais na distribuicao.
- Nao utilize o nome ou o logotipo Chromium no produto final. Inclua o aviso
  de que o Pure Browser nao e endossado pelo Google nem pelo projeto
  Chromium.
- proprietary_codecs=true e ffmpeg_branding="Chrome" habilitam H.264/AAC;
  avalie o licenciamento de patentes antes da distribuicao comercial.
