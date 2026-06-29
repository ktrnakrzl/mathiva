// Testing on a real device over Wi-Fi: 127.0.0.1 means "the phone itself",
// so it must point at this PC's LAN IP instead. Revert to 127.0.0.1 for
// desktop/web testing, or 10.0.2.2 for the Android emulator.
const String kBaseUrl = 'http://192.168.8.33:8000';

// When true, ChatService/SolverService are wired to their mock repositories
// instead of the real backend (see main.dart) — useful for developing or
// demoing the UI when the FastAPI/Ollama backend isn't running locally.
const bool kUseMockBackend = false;
