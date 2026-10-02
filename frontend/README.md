# Mathiva Flutter Frontend

This is the live Flutter app for Mathiva. It is no longer just a UI prototype:
it logs in against the FastAPI backend, stores the user's session locally,
calls the tutor/solver/progress APIs, and can build for Android APK or web.

## What The App Does

- **Auth:** register, log in, Google sign-in, forgot/reset password, and profile lookup.
- **Home:** greets the signed-in learner, shows progress stats, recent scans, and entry points.
- **Scan & Solve:** opens a live camera scanner with a crop box, uploads the cropped image, and shows a step-by-step solution.
- **Tutor Chat:** sends math questions to the backend tutor cascade.
- **Lessons & Practice:** uses local curriculum content and backend-backed adaptive quiz/progress endpoints.
- **Settings:** stores name, dark mode, reminders, haptics, and other preferences on-device.

## Where Data Lives

Stored on the user's device with `shared_preferences`:

- JWT login token (`AuthStorage`)
- cached display name and app preferences (`AppPreferences`)
- recent solved scan history (`ScanHistoryService`)

Stored in the backend database:

- account email/name/password hash
- generated quiz questions and quiz attempts
- progress data such as points, streak, accuracy, and mastery

On app startup, `main.dart` loads local preferences first so the UI is not blank,
then refreshes profile/progress in the background if the user is signed in.

## Backend URL

The backend is selected at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
flutter build apk --release --dart-define=API_BASE_URL=https://mathiva.onrender.com
flutter build web --release --dart-define=API_BASE_URL=https://mathiva.onrender.com
```

For Android emulator local backend testing, use `http://10.0.2.2:8000`.
For a physical phone on Wi-Fi, use the computer's LAN IP.

## Build APK

Release builds require a real signing key. Copy
`android/key.properties.example` to `android/key.properties` and fill in your
local keystore values, or provide these CI environment variables:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

```bash
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://mathiva.onrender.com
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Release builds use R8 minification and resource shrinking. If signing is not
configured, Gradle stops before producing a release artifact.

## Build Web

```bash
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://mathiva.onrender.com
```

The web shell unregisters old Flutter service workers in `web/index.html`, and
`web/flutter_bootstrap.js` loads the app without registering a new service
worker. This avoids stale Flutter web cache serving an old UI after deployment.

## Important Files

- `lib/main.dart` - startup order: notifications, preferences, auth token, scan history, background profile/progress warmup.
- `lib/app.dart` - routes and auth redirect logic.
- `lib/core/constants/api_constants.dart` - `API_BASE_URL`, Google client IDs.
- `lib/services/auth_storage.dart` - persisted JWT token.
- `lib/services/app_preferences.dart` - persisted local preferences and cached name.
- `lib/screens/image_solver_screen.dart` - live camera scanner, crop UI, preview, solve upload.
- `lib/repositories/api/` - real Dio clients for auth, tutor, solver, and progress.

## Why It Can Feel Slow

The hosted backend may cold start on Render. The first request after inactivity
can take tens of seconds while the service wakes. The app now keeps local session
and preferences so reopening does not look like it forgot the user, but backend
profile/progress/tutor/solver calls still depend on the server being awake.
