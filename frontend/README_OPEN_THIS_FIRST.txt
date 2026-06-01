MATHIVA FRONTEND STRUCTURE V2

This version follows your new requested structure:
lib/screens
lib/widgets
lib/models
lib/services
lib/data
lib/theme
lib/utils

Included screens:
- Login
- Register
- Home
- STEM Subjects
- Topics
- Lesson
- Practice
- Result
- Progress

Important:
- Frontend only
- Uses Navigator routes
- No backend
- No OCR
- No AI/RAG yet
- Lessons are local placeholder content based on STEM math topics while the AI dataset/training is not finished

How to run:
1. Open this mathivia folder in VS Code or Android Studio.
2. Start your emulator.
3. Run these commands:
   flutter clean
   flutter pub get
   flutter run -d emulator-5554

If emulator-5554 is not your device ID:
   flutter devices
   flutter run -d YOUR_DEVICE_ID
