// Backend base URL -- configurable at build/run time WITHOUT editing code:
//   flutter run  --dart-define=API_BASE_URL=http://192.168.8.35:8000   (phone/Wi-Fi)
//   flutter build web --dart-define=API_BASE_URL=https://api.example.com  (production)
// Defaults to localhost for desktop/web dev. On a real device over Wi-Fi pass
// this PC's LAN IP; for the Android emulator pass http://10.0.2.2:8000.
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

// When true, ChatService/SolverService are wired to their mock repositories
// instead of the real backend (see main.dart) — useful for developing or
// demoing the UI when the FastAPI/Ollama backend isn't running locally.
const bool kUseMockBackend = false;

// Google OAuth client IDs. For web and backend verification this should be the
// Web application client ID from Google Cloud Console.
const String kGoogleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: '',
);

// Optional override for native builds. If empty, the app reuses
// kGoogleClientId as the server client ID so the backend can verify the ID
// token audience against the same OAuth client.
const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);
