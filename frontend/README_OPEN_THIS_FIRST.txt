MATHIVIA - FIXED FRONTEND ZIP

What was fixed in this ZIP:
1. Added cupertino_icons to pubspec.yaml.
2. Removed local.properties so every computer can generate its own Android SDK paths.
3. Disabled Android release minify/R8 for easier APK builds while testing.
4. Replaced deprecated Color.withOpacity(...) usages with Color.withValues(alpha: ...).
5. Removed the unused app_theme import in mathiva_bottom_nav.dart.
6. Turned off const-only style lint suggestions so flutter analyze focuses on real errors.

How to open:
1. Extract this ZIP.
2. Open the extracted mathivia folder in VS Code or Android Studio.
3. Open Terminal in the same folder where pubspec.yaml is located.
4. Run:
   flutter clean
   flutter pub get
   flutter analyze

How to run on tablet:
1. Enable Developer Options and USB debugging on the tablet.
2. Plug the tablet into your laptop with USB.
3. On the tablet, tap Allow USB debugging if it appears.
4. Run:
   flutter devices
5. Copy the device ID and run:
   flutter run -d DEVICE_ID

How to build APK:
   flutter clean
   flutter pub get
   flutter build apk --release

APK location after build:
   build/app/outputs/flutter-apk/app-release.apk

Important:
This ZIP is the frontend-only Flutter project. If your GitHub main branch has OCR/backend/ML Kit code that is not in this ZIP, upload that exact GitHub ZIP too because it may need separate fixing.
