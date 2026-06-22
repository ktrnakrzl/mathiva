# Mathiva Flutter Fix Notes

This version was refactored to follow the supplied Mathiva Flutter Frontend Development Guide.

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
The backend is not connected yet. The app is still using mocks. When Kat confirms the backend is ready, swap the repository providers from `Mock...Repository()` to `Api...Repository(ref.read(dioProvider))` and update `kBaseUrl` in `lib/core/constants/api_constants.dart`.
