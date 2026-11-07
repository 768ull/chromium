# Puro Browser: pipeline de compilacao (GitHub Actions)

Este diretorio implementa, sobre o espelho oficial do Chromium hospedado neste repositorio, o pipeline de compilacao do navegador Puro para Android: quatro variantes independentes (v1 Estavel, v2 Beta, v3 Dev, v4 Nightly), quatro ABIs (arm64-v8a, armeabi-v7a, x86, x86_64), assinatura individual por variante e verificacao de conformidade sem dependencias de servicos Google.

## Estrutura

| Arquivo | Funcao |
| --- | --- |
| .github/workflows/puro-browser.yml | Action de compilacao, assinatura, verificacao e publicacao |
| puro/build_puro.sh | Gera args.gn de cada celula da matriz e compila chrome_public_apk |
| puro/gen_keystores.sh | Gera as quatro keystores (uma por variante) |
| puro/args_template.gn | Modelo para compilacao manual local |
| puro/patches/ | Diretorio para patches de codigo-fonte (opcional) |

## Requisitos de infraestrutura

A compilacao do Chromium nao cabe nos runners gratuitos do GitHub (ubuntu-latest possui cerca de 20 GB de disco livre; a arvore do Chromium exige mais de 200 GB). Registre um runner self-hosted com o label puro-builder:

| Recurso | Minimo | Recomendado |
| --- | --- | --- |
| CPUs | 8 | 16 a 32 |
| RAM | 16 GB | 32 a 64 GB |
| Disco livre | 200 GB | 400 GB NVMe |
| SO | Ubuntu 22.04 ou 24.04 | Ubuntu 24.04 |
| Outros | sudo sem senha, git, acesso a internet | Ubuntu 24.04 |

Cadastro: Settings > Actions > Runners > New self-hosted runner, atribuindo o label puro-builder. Contas organizacionais em planos pagos podem, alternativamente, usar larger runners com disco de 640 GB ou mais (32 vCPU ou superior), ajustando o parametro runner_label.

## Configuracao unica

1. Gerar as keystores em maquina local confiavel:

   ```bash
   bash puro/gen_keystores.sh /caminho/seguro/keys
   ```

2. Cadastrar oito segredos em Settings > Secrets and variables > Actions:

   | Segredo | Conteudo |
   | --- | --- |
   | PURO_KEYSTORE_V1 | saida de base64 -w0 puro-v1.jks |
   | PURO_KEYSTORE_V1_PASSWORD | senha da keystore v1 |
   | PURO_KEYSTORE_V2 ate PURO_KEYSTORE_V4 | idem, por variante |

3. (Opcional) Vendorizar patches de codigo-fonte em puro/patches/*.patch, conforme as notas em puro/patches/README.md.

## Como disparar

Apos mesclar este branch no branch padrao, use a aba Actions > Puro Browser - Compilacao e Assinatura de APK > Run workflow. Sem mesclar, e possivel disparar diretamente sobre este branch:

```bash
gh workflow run puro-browser.yml --ref puro-browser -f variant=v1 -f target_cpu=arm64
gh workflow run puro-browser.yml --ref puro-browser -f variant=v4 -f build_all_abis=true -f publish_release=true
```

## Parametros do workflow

| Parametro | Valores | Efeito |
| --- | --- | --- |
| variant | v1, v2, v3, v4 | Define application ID (com.purobrowser.vN), canal e keystore |
| target_cpu | arm64, arm, x86, x64 | ABI do APK gerado |
| build_all_abis | booleano | Compila as quatro ABIs em matriz paralela |
| chromium_ref | SHA de commit | Fixa a base do espelho (vazio = HEAD do branch principal) |
| runner_label | label do runner | Padrao: puro-builder |
| publish_release | booleano | Publica os APKs como Release do repositorio |

## Sobre as assinaturas

As variantes V1 a V4 correspondem a pacotes distintos (com.purobrowser.v1 a v4), cada qual com keystore propria, o que permite a instalacao paralela no mesmo aparelho. Independente da variante, todo APK e assinado com os esquemas V1 (JAR), V2 e V3, verificados pelo passo apksigner verify. O esquema V4 de assinatura destina-se apenas a instalacoes incrementais via adb e nao substitui os anteriores; por isso permanece desativado.

## Limitacoes conhecidas

1. Runners padrao do GitHub nao compilam o Chromium; o workflow aborta com erro explicito se houver menos de 200 GB livres.
2. O espelho nao possui tags; informe um SHA de commit ou deixe chromium_ref vazio para usar o HEAD do branch principal.
3. O cache de acoes do GitHub e limitado a 10 GB por repositorio; a arvore (mais de 100 GB) nao pode ser cacheada, de modo que cada execucao realiza a sincronizacao completa.
4. As flags GN implementam a remocao em tempo de compilacao (chaves de API, Safe Browsing, field trials, Contextual Search, reporte e servicos remotos). Remocoes de codigo-fonte adicionais (Sync, UMA, upload de minidumps, Translate) exigem patches em puro/patches, aplicados automaticamente quando presentes.
5. A primeira compilacao de cada ABI demanda tipicamente de 4 a 12 horas, conforme o hardware; execucoes subsequentes na mesma maquina podem reutilizar o diretorio out se preservado.
