# Puro: patches de codigo-fonte

Este diretorio recebe patches (.patch) aplicados automaticamente pela Action antes da compilacao, em ordem alfabetica. As flags GN ja removem, em tempo de compilacao, as chaves de API do Google, o Safe Browsing em nuvem, os field trials de teste, o Contextual Search, o reporte (Reporting API), o mDNS e os servicos remotos de reuniao.

Para remocoes que exigem edicao de codigo-fonte (interface e nucleo de Sync e login, metricas UMA, upload de minidumps do Crashpad, integracao de Translate), recomenda-se partir dos patch sets publicos e comprovados do Cromite e do ungoogled-chromium, adaptando-os a base deste repositorio:

- Cromite (sucessor do Bromite): patches Android e conjunto de flags vigente.
- ungoogled-chromium-android: pacote renomeado, Safe Browsing compilado fora e permissoes de conta removidas.

Regras de manutencao:

1. Um patch por tema de remocao, nomeado numericamente (001-disable-sync.patch, 002-disable-uma.patch).
2. Todo patch deve aplicar com git apply sobre a base indicada em chromium_ref.
3. A cada rampa de versao do Chromium, rebasear a serie e validar com gn gen e compilacao completa.
