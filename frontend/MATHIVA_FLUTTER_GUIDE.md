# MATHIVA Flutter Architecture Guide

This is the single source of truth for how the Flutter frontend is structured.
If you're adding a new screen or feature, this is the pattern to follow.
For how things should *look* (colors, typography, buttons, cards, spacing),
see `MATHIVA_DESIGN_SYSTEM.md`.

## Why this doc exists

A past branch merge stitched together two different architectures that were
built in parallel. One is live and working; the other is mostly orphaned.
This doc names the one that's live, and documents the pattern new work should
follow so we don't end up with a third parallel structure.

## Canonical folder map (the live stack)

| Folder | Purpose |
|---|---|
| `lib/screens/` | Full-page widgets, routed via `app.dart`'s `GoRouter`. |
| `lib/services/` | Static facade classes (e.g. `ChatService`, `SolverService`) that existing screens call directly. Internally backed by `lib/repositories/`. |
| `lib/repositories/` | The actual API contract: an abstract `XRepository` interface, an `api/ApiXRepository` (real backend) and a `mock/MockXRepository` (offline/demo data). |
| `lib/providers/` | Riverpod `Provider<XRepository>` definitions, for screens written as `ConsumerWidget`/`ConsumerStatefulWidget` to read with `ref.read(...)`. |
| `lib/widgets/` | Shared widgets specific to the flat stack (nav bar, app bar, buttons). |
| `lib/presentation/widgets/` | A second shared-widget location (`AnimatedBackground`, `FadeSlideIn`, `TapScale`, `SectionHeader`, etc.) — left over from the merge, but actively used by nearly every screen. Don't move or delete these; keep using them as-is. |
| `lib/models/mathiva_models.dart` | Domain models used by the flat stack (`PracticeProblem`, `MathSubject`, etc.). |
| `lib/data/local_mathiva_data.dart` | Static sample/mock data (e.g. `LocalMathivaData.quadraticProblem`), reused by mock repositories and screen fallbacks. |
| `lib/theme/`, `lib/utils/route_names.dart` | App theme and route-name constants used by `app.dart`. |
| `lib/core/constants/api_constants.dart` | `kBaseUrl` (backend host) and `kUseMockBackend` (dev/demo flag — see below). |

## Deprecated — not deleted yet, do not build on these

These folders belong to the orphaned clean-architecture stack from the merge.
They are not wired into the live app's navigation and several of their
repositories call backend endpoints that don't exist (`/quiz/start`,
`/tutor/ask`). Don't add to them; treat them as scheduled for removal in a
future cleanup pass:

- `lib/presentation/screens/`, `lib/presentation/notifiers/`, `lib/presentation/state/`
- `lib/core/router/`, `lib/core/theme/`, `lib/core/models/`
- `lib/data/repositories/`, `lib/data/models/`, `lib/data/providers/`

Known loose end: `app.dart` still registers five routes into this dead stack
(`/quiz`, `/review`, `/mastery`, `/rewards`, `/tutor`) for screens that nothing
in the live UI navigates to. Leave them alone until the cleanup pass — don't
extend them, and don't be surprised if they 404 against the backend.

**Exception:** `lib/presentation/widgets/` is shared infrastructure, not part
of the deprecated set — see the folder map above.

## State management rule

- **Local/UI-only state** (an animation controller, a drag gesture, which
  step of a multi-step screen is showing) stays exactly as it is today:
  `StatefulWidget` + `setState`. Don't introduce Riverpod for this.
- **Any state backed by a network call** goes through the repository
  pattern below, and the screen reads it via Riverpod (`ConsumerWidget` or
  `ConsumerStatefulWidget` + `ref.read`/`ref.watch`).

## Repository pattern — the convention for every feature, new or old

For a feature called `Foo`:

1. `lib/repositories/foo_repository.dart` — `abstract class FooRepository { Future<...> doThing(); }`
2. `lib/repositories/api/api_foo_repository.dart` — `ApiFooRepository implements FooRepository`, hits the real backend via `Dio` with `baseUrl: kBaseUrl`.
3. `lib/repositories/mock/mock_foo_repository.dart` — `MockFooRepository implements FooRepository`, returns canned data after a short simulated delay.
4. `lib/providers/repository_providers.dart` — add `final fooRepositoryProvider = Provider<FooRepository>((ref) => ApiFooRepository());`.
5. The screen is a `ConsumerWidget`/`ConsumerStatefulWidget` and calls `ref.read(fooRepositoryProvider).doThing()`.

`tutor_repository.dart` and `solver_repository.dart` are the worked examples —
copy their shape for the next feature (e.g. quiz scoring, auth, progress).

### The one exception: `ChatService` / `SolverService`

These predate this convention and already have screens calling them as
static classes (`ChatService.ask(...)`, `SolverService.solveImage(...)`).
Rather than rewrite those screens, they were retrofitted to be thin facades
that delegate to a swappable `repository` field, defaulting to the `Api*`
implementation:

```dart
class ChatService {
  static TutorRepository repository = ApiTutorRepository();
  static Future<String> ask(String question) => repository.ask(question);
}
```

**New features should skip this facade step** and have the screen consume
the provider directly — the facade only exists so two already-shipped
screens didn't need to change.

### Dev/demo mock switch

`kUseMockBackend` in `lib/core/constants/api_constants.dart`, read in
`main.dart` before `runApp`, swaps `ChatService`/`SolverService` over to
their mock repositories. Flip it to `true` to develop/demo the UI without a
running backend (no Ollama, no FastAPI server needed); leave it `false` for
real use.

## API contract notes

- Backend base URL: `kBaseUrl` in `core/constants/api_constants.dart`.
- All backend routes are under `/api/*` (`/api/ask`, `/api/solve`,
  `/api/solve-image`) **except** `/health` and `/quiz`, which are mounted
  directly on the FastAPI app without the prefix.

## Style conventions already established — keep following them

- Each screen file declares its own small set of design-token `Color`
  constants at the top (`_ink`, `_muted`, `_border`, `_surface`, `_pageBg`),
  rather than a global theme object. Match this when adding a screen.
- Motion/layout is composed from shared wrappers in
  `lib/presentation/widgets/`: `AnimatedBackground` (page backdrop),
  `FadeSlideIn` (entrance animation), `TapScale` (pressable scale feedback).
  Use these instead of writing new animation wrappers.
