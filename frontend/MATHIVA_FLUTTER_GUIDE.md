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
| `lib/repositories/` | The actual API contract: an abstract `XRepository` interface, an `api/ApiXRepository` (real backend). |
| `lib/providers/` | Riverpod `Provider<XRepository>` definitions, for screens written as `ConsumerWidget`/`ConsumerStatefulWidget` to read with `ref.read(...)`. |
| `lib/widgets/` | Shared widgets specific to the flat stack (nav bar, app bar, buttons). |
| `lib/presentation/widgets/` | A second shared-widget location (`AnimatedBackground`, `FadeSlideIn`, `TapScale`, `SectionHeader`, etc.) — left over from the merge, but actively used by nearly every screen. Don't move or delete these; keep using them as-is. |
| `lib/models/mathiva_models.dart` | Domain models used by the flat stack (`PracticeProblem`, `MathSubject`, etc.). |
| `lib/data/local_mathiva_data.dart` | Bundled lesson content and sample practice problems. |
| `lib/theme/`, `lib/utils/route_names.dart` | App theme and route-name constants used by `app.dart`. |
| `lib/core/constants/api_constants.dart` | Backend base URL and Google OAuth client IDs. |

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
- **Shared app state** currently uses small static services plus
  `ValueNotifier`s, not a full Riverpod migration. The important examples are:
  `AuthStorage.isAuthenticated`, `AppPreferences.*`, `ProgressStore.current`,
  and `ScanHistoryService.recent`.
- **Network calls** should still go through a repository interface
  (`AuthRepository`, `TutorRepository`, `SolverRepository`,
  `ProgressRepository`). Existing screens often reach those repositories through
  service facades such as `ProgressService` or `SolverService`; new work can use
  that existing style unless you are deliberately migrating a whole feature to
  Riverpod.

## Startup and persisted device state

`lib/main.dart` is the startup spine:

1. Initialize notifications.
2. Load `AppPreferences` from `shared_preferences`.
3. Load the saved JWT through `AuthStorage`.
4. Load recent solved scans through `ScanHistoryService`.
5. Render `MathivaApp`.
6. If signed in, refresh progress and `/auth/me` in the background.

This is why reopening the Android app should keep the user's name immediately:
the cached name is local, while the backend profile refresh happens after the UI
is already on screen.

Local device storage:

- `AuthStorage` - JWT access token only.
- `AppPreferences` - cached display name, dark mode, haptics, reminder settings,
  palette, and other preferences.
- `ScanHistoryService` - recent solved scans shown on Home.

Backend storage:

- user account data and password hash.
- generated quiz questions and attempts.
- progress aggregates derived from attempts.

## Repository pattern — the convention for every feature, new or old

For a feature called `Foo`:

1. `lib/repositories/foo_repository.dart` — `abstract class FooRepository { Future<...> doThing(); }`
2. `lib/repositories/api/api_foo_repository.dart` — `ApiFooRepository implements FooRepository`, hits the real backend via `Dio` with `baseUrl: kBaseUrl`.
3. `lib/providers/repository_providers.dart` — add `final fooRepositoryProvider = Provider<FooRepository>((ref) => ApiFooRepository());`.
4. The screen is a `ConsumerWidget`/`ConsumerStatefulWidget` and calls `ref.read(fooRepositoryProvider).doThing()`.

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

## API contract notes

- Backend base URL: `kBaseUrl` in `core/constants/api_constants.dart`.
- Auth routes are unprefixed: `/auth/register`, `/auth/login`, `/auth/google`,
  `/auth/me`, `/auth/password/forgot`, `/auth/password/reset`.
- Feature routes are under `/api/*`: `/api/ask`, `/api/ask/stream`,
  `/api/solve`, `/api/solve-image`, `/api/quiz/next`,
  `/api/quiz/next-adaptive`, `/api/quiz/review-next`, `/api/quiz/answer`,
  `/api/quiz/submit`, and `/api/user/progress`.
- `/health` is unprefixed and is used by deployment health checks.

## Scan & Solve flow

`lib/screens/image_solver_screen.dart` is the Photomath-style scan screen:

1. Opens the live camera with the `camera` plugin.
2. Shows a draggable/resizable crop box.
3. Captures the photo and crops the selected area locally.
4. Uploads the cropped image through `SolverService.solveImage`.
5. Records successful solves in `ScanHistoryService`.
6. Navigates to `SolutionScreen`.

The web build also uses the live scanner. To avoid stale Flutter web bundles,
`web/index.html` unregisters old service workers and `web/flutter_bootstrap.js`
loads without registering a new one.

## Style conventions already established — keep following them

- Newer screens should prefer `AppTheme.colorsOf(context)` and semantic colors
  from `lib/theme/` over hard-coded screen-local color constants. Some older
  screens still carry local constants from earlier iterations; do not copy that
  pattern into new work.
- Motion/layout is composed from shared wrappers in
  `lib/presentation/widgets/`: `AnimatedBackground` (page backdrop),
  `FadeSlideIn` (entrance animation), `TapScale` (pressable scale feedback).
  Use these instead of writing new animation wrappers.

### Image preparation workers

`lib/services/image_processing.dart` prepares the preview and cropped upload.
The screen calls these functions with `compute`, moving decoding and JPEG
encoding to a worker isolate on native platforms. Flutter web still runs this
work on its event loop. Preview preparation decodes the source once, preserving
original dimensions and the original photo for cropping. Uploads retain the
existing 1280-pixel maximum dimension and JPEG quality of 82.
