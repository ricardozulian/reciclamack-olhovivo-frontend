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
