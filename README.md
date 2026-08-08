# ReciclaMack Olho Vivo — Frontend

Interface web do projeto de extensão universitária **Olho Vivo — Identificação de Resíduos Eletroeletrônicos por Visão Computacional**, desenvolvido no âmbito da Universidade Presbiteriana Mackenzie, Faculdade de Computação e Informática (FCI).

O frontend permite que a comunidade envie ou capture uma foto de um resíduo eletroeletrônico, consulte a API de análise por visão computacional e visualize orientações de descarte ambientalmente correto.

## Contexto acadêmico

- Instituição: Universidade Presbiteriana Mackenzie
- Unidade: Faculdade de Computação e Informática (FCI)
- Área temática: Meio Ambiente, Tecnologia e Produção, Educação Ambiental
- Linha de extensão: Gestão de Resíduos Sólidos e Educação para a Sustentabilidade
- Coordenação/orientação: Profa. Sandra Bozolan

## Equipe discente

- Ricardo Zulian de Souza Amaral
- Marcos Volponi Cervan
- Flavio Estevam Nogueira Andrade

## Funcionalidades

- Upload de foto ou captura pela câmera do navegador.
- Integração com `POST /v1/analyze-image`.
- Exibição de detecções, resumo de risco, orientações de descarte e referências legais.
- Interface em português.
- Suporte a `API_BASE_URL` absoluto ou modo same-origin (`/`) para deploy com proxy HTTPS.
- Botão de câmera habilitado apenas em contexto seguro (`https`); em `http`, o usuário ainda pode enviar foto da galeria.

## Executar localmente

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Testes

```powershell
flutter test
```

## Papel no sistema

Este repositório é autônomo e contém apenas a aplicação Flutter Web. A API, o modelo de inferência e o pipeline de treinamento ficam em repositórios separados.

## Ambientes de implantação

A bancada Docker compila o frontend em modo same-origin, com `API_BASE_URL=/`. Ela fica disponível em `http://192.168.1.51:8088`; no Jetson, a mesma compilação fica em `http://<ip-reservado>/`. O proxy encaminha `/v1` para a API, portanto a interface não precisa conhecer a porta `8000`.

Em HTTP na LAN, o navegador permite envio de arquivo, mas bloqueia a câmera de clientes remotos. O modo totem funciona porque o Chromium e a câmera estão no próprio Jetson e a interface é aberta por `http://localhost`. Uma futura câmera em navegador remoto ainda exigirá HTTPS. Consulte `../../deploy/README.md`.


## Versão 0.2.0: imagem anotada e modo totem

A interface mantém os bytes da foto analisada e desenha todas as caixas retornadas pela API sobre a imagem, com rótulo em português e confiança. A API deve fornecer `image_width` e `image_height` no mesmo sistema de coordenadas das caixas.

Existem dois modos de compilação:

```powershell
flutter build web --release --dart-define=API_BASE_URL=/ --dart-define=APP_MODE=web
flutter build web --release --dart-define=API_BASE_URL=/ --dart-define=APP_MODE=totem --dart-define=TOTEM_RESET_SECONDS=45
```

No modo `totem`, o Chromium executado no próprio Jetson abre `http://localhost/`, mostra a câmera USB local, captura uma foto por solicitação e envia apenas essa foto à API local. Não há streaming de vídeo pela rede nem inferência contínua. Navegadores remotos em HTTP continuam limitados ao envio de arquivos.
