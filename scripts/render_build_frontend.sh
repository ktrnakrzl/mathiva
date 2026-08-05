#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  git clone --depth 1 --branch "${FLUTTER_VERSION:-stable}" \
    https://github.com/flutter/flutter.git /tmp/flutter
  export PATH="/tmp/flutter/bin:$PATH"
fi

flutter config --enable-web
flutter --version

cd frontend
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:?API_BASE_URL is required}" \
  --dart-define=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"
