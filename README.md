# Flutter Web MVP

## Features
- Upload photo or capture from camera.
- Calls `POST /v1/analyze-image` with timeout + retry.
- Displays detections, hazard summary, disposal instructions, legal references.
- Portuguese-only UI.
- Placeholder for map integration in Phase 2.
- Camera button is enabled only in secure context (`https`) on web. On `http`, users can still upload from gallery.
- `API_BASE_URL` supports:
  - absolute API URL (example: `http://<EC2_IP>:8000`)
  - same-origin mode (`/`) for reverse-proxy/TLS deployments

## Run
1. `flutter pub get`
2. `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000`

## Test
- `flutter test`
