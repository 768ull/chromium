# Patches do Puro Browser

Os patches sao aplicados antes de `gn gen`, em ordem alfabetica, e agora sao obrigatorios: qualquer divergencia com a revisao fixada encerra a compilacao.

- `0001-puro-package-id.patch`: adiciona `puro_variant` ao template GN Android e define os IDs `com.purobrowser.v1..v4`.
- `0002-remove-google-cloud-android-manifest.patch`: remove permissoes C2DM/conta Google, receiver de broadcast GMS, servicos GCM/FCM e provider Cast do manifesto.

Esses patches nao removem classes Java/C++, bibliotecas nativas ou endpoints do grafo de build. Consulte `puro/README.md` para os itens que ainda exigem trabalho.
