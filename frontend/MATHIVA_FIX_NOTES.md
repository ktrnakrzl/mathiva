# Mathiva Flutter Fix Notes

This version was refactored to follow the supplied Mathiva Flutter Frontend Development Guide.

These are historical refactoring notes. The app now uses API repositories; the offline mock mode has been removed.

## What changed
- Replaced the old `lib/` layout with the required guide structure.
- Added Riverpod setup with `ProviderScope`.
- Replaced direct `MaterialApp` route table with `go_router`.
- Added API-contract data models with exact JSON field names.
- Added repository interfaces, mock repositories, and API repositories.
- Kept the app using mock repositories through `repository_providers.dart`.
- Added `AsyncValue` loading/data/error handling in repository-driven screens.
- Added `flutter_math_fork` math rendering helpers.
- Added step-by-step reveal UI for tutor and answer feedback screens.
- Added required dependencies to `pubspec.yaml`.

## Important
Configure the backend with `API_BASE_URL` at build or run time. Login, tutor, solver, and progress use the backend.
