# ReciclaMack Olho Vivo Frontend

This repository contains the Flutter Web interface for the ReciclaMack university extension project.

The user interface text remains in Portuguese.

## Academic context

- Institution: Universidade Presbiteriana Mackenzie
- School: Faculdade de Computação e Informática (FCI)
- Coordinator: Professor Sandra Bozolan

## Student team

- Ricardo Zulian de Souza Amaral
- Marcos Volponi Cervan
- Flavio Estevam Nogueira Andrade

## Features

- Image upload and browser camera capture.
- Integration with `POST /v1/analyze-image`.
- Detection boxes, confidence values, risk guidance, and disposal guidance.
- Portuguese user interface.
- Absolute or same-origin `API_BASE_URL` support.
- Camera control only in a secure context or on `http://localhost`.

## Run locally

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Run tests

```powershell
flutter test
```

## Deployment environments

The Docker test host builds the frontend with `API_BASE_URL=/`.

The LAN interface is `http://192.168.1.51:8088`.

The Jetson interface is `http://<JETSON_IP>/`.

Nginx sends `/v1` to the API, so the frontend does not need direct API port information.

Remote HTTP browsers can upload files but cannot use the camera.

The totem uses `http://localhost` in Chromium on the Jetson. This local origin can use the attached camera.

A future remote camera interface needs HTTPS.

Read `../../deploy/README.md` for deployment details.

## Version 0.2.0

The interface keeps the analyzed image bytes and draws every returned box on the image.

The API supplies `image_width` and `image_height` in the same coordinate system as the boxes.

Build the two modes with these commands:

```powershell
flutter build web --release --dart-define=API_BASE_URL=/ --dart-define=APP_MODE=web
flutter build web --release --dart-define=API_BASE_URL=/ --dart-define=APP_MODE=totem --dart-define=TOTEM_RESET_SECONDS=45 --dart-define=TOTEM_SCAN_INTERVAL_MS=1000 --dart-define=TOTEM_CONFIRM_FRAMES=2
```

The `totem` mode captures probe images at a fixed interval. It requires two matching dominant-class results before confirmation.

The API does not retain probe images. It retains only the confirmed image and its prediction sidecar.

The system does not stream video over the network.
