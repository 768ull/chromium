# Puro Browser — pipeline Android

## Variantes

| Variante | Finalidade | Application ID | Keystore |
|---|---|---|---|
| v1 | Estável | `com.purobrowser.v1` | `puro_v1` |
| v2 | Beta | `com.purobrowser.v2` | `puro_v2` |
| v3 | Dev | `com.purobrowser.v3` | `puro_v3` |
| v4 | Nightly | `com.purobrowser.v4` | `puro_v4` |

O patch `0001-puro-package-id.patch` define o ID diretamente no template GN, sem sufixo automático de canal. Cada variante usa uma chave própria para permitir instalação paralela.

## ABIs

| `target_cpu` | ABI | APK |
|---|---|---|
| arm64 | arm64-v8a | APK ARM64 |
| arm | armeabi-v7a | APK ARM32 |
| x86 | x86 | APK x86 |
| x64 | x86_64 | APK x86_64 |

Cada ABI é uma compilação separada. Não é um único APK universal multi-ABI. Nesta revisão upstream, o alvo Android do Chromium exige Android 10 ou posterior; ARM32 não significa suporte a versões antigas anteriores ao minSdk do projeto.

## De-googling configurado

- `is_chrome_branded=false`, `use_official_google_api_keys=false`, chaves oficiais vazias.
- Desativados Hangouts extension, remoting, mDNS, service discovery, media router e Reporting API.
- `safe_browsing_mode=1` seleciona Safe Browsing com banco local. O modo Android padrão `2` é a variante que usa consulta remota/GMS Core.
- `disable_fieldtrial_testing_config=true` desativa o arquivo de testes de field trials, mas não remove todo o sistema Variations/Finch.
- O patch `0002` remove declarações de manifesto relacionadas a C2DM/FCM, permissão de acesso à conta Google, receiver que exige broadcast GMS e provider Cast.

### Flags solicitadas que não existem

Nesta revisão, `enable_gservices` e `enable_google_now` não são argumentos GN declarados. Não devem ser incluídos: GN rejeita argumentos desconhecidos ou sem efeito. `enable_hangout_services_extension`, `use_official_google_api_keys`, `disable_fieldtrial_testing_config` e `blink_symbol_level` são suportados.

## Pendências que impedem declarar o navegador totalmente de-googled

Os patches atuais ainda não removem integralmente:
- código, telas e pontos de entrada de Sync/login;
- UMA/UKM, provedores de métricas e todo Variations/Finch;
- Crashpad do APK (o template upstream ainda empacota o handler);
- todas as referências de Translate e geolocalização;
- SDKs Google, endpoints, strings e chamadas em bibliotecas nativas;
- página inicial e mecanismo de busca padrão neutros.

A auditoria atual verifica package ID, assinatura, alinhamento, ABI e uma lista explícita de referências no manifesto. Ela não comprova ausência de tráfego Google nem remoção total de telemetria. Não publicar como “totalmente de-googled” até concluir auditoria estática/dinâmica e testes.

## Assinatura

Cada variante usa uma keystore independente. O workflow ativa os esquemas Android V1, V2, V3 e V4; V4 gera arquivo `.idsig`. O número da variante (v1–v4) identifica o pacote; os esquemas de assinatura Android são uma coisa distinta.

Gere as keystores numa máquina confiável:
```bash
bash puro/gen_keystores.sh /caminho/seguro/keys
```
Cadastre oito secrets em Settings → Secrets and variables → Actions:
- `PURO_KEYSTORE_V1` … `PURO_KEYSTORE_V4`: Base64 de cada JKS.
- `PURO_KEYSTORE_V1_PASSWORD` … `PURO_KEYSTORE_V4_PASSWORD`: senha correspondente.

Nunca envie keystores ou senhas ao repositório. Faça backup seguro; perder uma chave impede atualizações in-place daquela variante.

## Runner e execução

Runner self-hosted Linux x64: mínimo 8 CPUs, 16 GB RAM e 200 GB livres; recomendado 32+ CPUs, 64 GB RAM e 400 GB NVMe. O runner hospedado padrão do GitHub não possui espaço suficiente.

1. Cadastre runner com labels `self-hosted`, `linux`, `x64` e `puro-builder`.
2. Configure os oito secrets.
3. Actions → Puro Browser - Android builds → Run workflow.
4. Selecione variante e ABI, ou `build_all_abis=true`.

O workflow aplica patches estritamente e falha se a revisão não corresponder. Informe SHA/branch compatível em `chromium_ref`.

