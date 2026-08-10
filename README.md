# ITSM Framework — Flutter Client

A context-aware, offline-first IT Service Management app for Ghanaian
organisations, built **write-once-run-everywhere**: the same codebase ships
to Android, iOS, Windows, macOS, Linux, and the web from a single `lib/`
tree, with responsive layouts that adapt from a phone in the field to a
technician's desktop.

It talks to the [ITSM backend](../backend) over a REST API and keeps working
when the network doesn't — ticket creation, status updates, and comments
queue locally and sync automatically once connectivity returns.

--- 

## Table of contents

- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Configuring the backend URL](#configuring-the-backend-url)
- [Running on each platform](#running-on-each-platform)
- [Responsiveness — write once, run everywhere](#responsiveness--write-once-run-everywhere)
- [Offline-first sync](#offline-first-sync)
- [Building for release](#building-for-release)
- [Known gaps / next steps](#known-gaps--next-steps)
- [Troubleshooting](#troubleshooting)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          UI (features/)                     │
│   screens per role: end user, technician, manager, admin    │
└───────────────────────────┬───────────────────────────────--┘
                             │ watches / reads
┌───────────────────────────▼───────────────────────────────--┐
│                    Providers (Riverpod)                     │
│  auth · tickets · assets · knowledge base · notifications ·  │
│  technicians · connectivity                                  │
└───────────────────────────┬───────────────────────────────--┘
                             │ calls
┌───────────────────────────▼───────────────────────────────--┐
│                   Services (services/)                       │
│   one per backend module — pure API + offline-fallback logic │
└──────────┬──────────────────────────────────┬───────────────┘
           │                                  │
┌──────────▼──────────┐            ┌──────────▼──────────────┐
│   core/network/      │            │   core/storage/          │
│  Dio client, auth     │            │  Hive cache, offline     │
│  refresh, error       │            │  write queue, secure     │
│  mapping              │            │  token storage           │
└──────────┬───────────-┘            └──────────┬──────────────┘
           │                                    │
           ▼                                    ▼
   Backend REST API                     Local device storage
  (Express + PostgreSQL)              (survives app restarts)
```

Screens never talk to Dio directly — they read/write through providers,
which delegate to services. This keeps the offline/caching logic in one
place per domain instead of scattered through the UI.

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| State management | Riverpod (`flutter_riverpod`) | Already used throughout; testable, no BuildContext needed for logic |
| Navigation | `go_router` | Declarative, works identically on mobile/desktop/web, deep-link friendly |
| HTTP | `dio` | Interceptors for auth + token refresh, typed error handling, works on every platform including web |
| Offline cache & queue | `hive` / `hive_flutter` | Pure-Dart, no native dependencies — same code path on every platform, including web (IndexedDB) |
| Secure token storage | `flutter_secure_storage` | Keychain / Keystore / libsecret / Credential Manager per platform |
| Connectivity | `connectivity_plus` | Real link-state detection (not link ⇒ backend reachable — see caveat below) |
| Charts | `fl_chart` | Manager/analytics dashboards |

## Project structure

```
lib/
  config/            Environment + API base URL resolution
  core/
    network/          Dio client, endpoint constants, typed exceptions
    storage/           Secure token storage, Hive cache, offline sync queue
    utils/              Responsive helpers, formatters
    extensions/
    constants/
  services/            One file per backend module (auth, tickets, assets, ...)
  models/              Domain models with fromJson/toJson matching backend shapes
  providers/           Riverpod state — the only thing screens talk to
  features/            Screens, grouped by role/domain
  routes/              go_router configuration + auth-based redirects
  shared/widgets/      Reusable widgets (adaptive shell, cards, badges, ...)
  theme/               Design tokens, colors, typography
```

## Prerequisites

- **Flutter SDK** ≥ 3.22 (Dart ≥ 3.4) — install via
  [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install)
- The [backend](../backend) running somewhere reachable (locally via Docker
  Compose, or deployed) — see its own README for setup
- Platform-specific toolchains for whichever targets you build:
  - **Android**: Android Studio + SDK/NDK, or just `flutter doctor` guiding you through it
  - **iOS/macOS**: Xcode (macOS host required)
  - **Windows desktop**: Visual Studio with the "Desktop development with C++" workload
  - **Linux desktop**: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`
  - **Web**: nothing extra — Chrome/Edge for local dev

Run `flutter doctor` after installing and resolve anything it flags before
continuing.

## Setup

This zip contains the `lib/`, `pubspec.yaml`, and `analysis_options.yaml` —
it does **not** contain the platform runner folders (`android/`, `ios/`,
`windows/`, `macos/`, `linux/`, `web/`), since those are generated by the
Flutter tool and weren't part of the original upload. Generate them once:

```bash
cd itsm_framework          # this project's root (where pubspec.yaml lives)
flutter create . --platforms=android,ios,windows,macos,linux,web --org com.yourcompany
flutter pub get
```

`flutter create .` is safe to run on an existing `lib/` — it only adds the
missing platform scaffolding and won't touch your Dart code. If you only
plan to ship to some platforms, list only those in `--platforms`.

If you use Hive's optional code-generation adapters later (not required for
the current setup, which stores plain JSON strings), run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Configuring the backend URL

The app resolves its API base URL at build/run time via `--dart-define` —
nothing is hardcoded, so the same build artifact isn't tied to one
environment. See `lib/config/env.dart` for the full resolution logic.

**Local development, emulator/simulator:**

```bash
# Android emulator (needs the special 10.0.2.2 alias — handled automatically)
flutter run

# iOS simulator / macOS / Windows / Linux desktop / web — localhost works directly
flutter run
```

**Local development, physical device on the same Wi-Fi:**
`localhost` means *the device itself*, not your dev machine, so you must
pass your machine's LAN IP explicitly:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000/api/v1
```

**Staging / production builds** — always pass this explicitly (the app
throws a clear error at startup if you don't, rather than silently pointing
at localhost):

```bash
flutter build apk --release \
  --dart-define=ENV=prod \
  --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1
```

## Running on each platform

```bash
flutter devices           # see what's available
flutter run -d chrome     # web
flutter run -d windows    # Windows desktop
flutter run -d linux      # Linux desktop
flutter run -d macos      # macOS desktop
flutter run -d <android-device-or-emulator-id>
flutter run -d <ios-simulator-or-device-id>   # macOS host only
```

## Responsiveness — write once, run everywhere

`lib/core/utils/responsive.dart` defines three breakpoints (mobile <600,
tablet <900, desktop ≥900 logical pixels) used throughout the UI via
`Responsive.value(context, mobile: ..., tablet: ..., desktop: ...)` and
`Responsive.pagePadding(context)`. The navigation shell
(`shared/widgets/adaptive_shell.dart`) itself switches between a bottom nav
bar (phone), a rail (tablet), and a full sidebar (desktop) automatically —
there's no separate "mobile app" and "desktop app" to maintain.

When adding new screens, prefer `Responsive.value(...)` over hardcoded
`MediaQuery` breakpoint checks, and test at a few widths
(`flutter run -d chrome` + resizing the browser window is the fastest way to
eyeball all three tiers without switching devices).

## Offline-first sync

- **Reads** (`GET /tickets`, `/assets`, `/knowledge-base`, ...) cache their
  last successful response in Hive (`core/storage/local_cache_service.dart`),
  so a cold start with no signal still shows the last-known data instead of
  a blank screen.
- **Writes** (creating a ticket, adding a comment, changing status) are
  applied to local state immediately for a responsive feel. If the request
  fails because the device is offline, it's persisted in
  `core/storage/sync_queue_service.dart` instead of being lost.
- When `connectivity_plus` reports the device back online, `autoSyncProvider`
  (wired up in `adaptive_shell.dart`) automatically replays everything in the
  queue against the backend. The `POST /tickets` payload includes a
  client-generated `offlineId` so a retried create can't accidentally create
  a duplicate ticket server-side.
- The **Sync Queue** screen (`features/sync/`) shows what's pending/syncing/
  failed and lets you retry manually.

**Caveat:** `connectivity_plus` reports link status (Wi-Fi/cellular
present), not "can actually reach the backend." A request can still fail
with a network error on a connected-but-captive-portal or backend-down
network — `ApiClient`'s error mapping treats that the same as being
offline and queues the write either way, so this doesn't break the offline
story, but don't rely on the connectivity indicator alone to mean "the
server is reachable."

## Building for release

```bash
# Android (App Bundle for Play Store; APK for direct install)
flutter build appbundle --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1
flutter build apk --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1

# iOS (requires Xcode + a valid signing setup)
flutter build ipa --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1

# Windows
flutter build windows --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1

# macOS
flutter build macos --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1

# Linux
flutter build linux --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1

# Web
flutter build web --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com/api/v1
```

Each platform's build output goes under `build/<platform>/` — see Flutter's
own [deployment docs](https://docs.flutter.dev/deployment) for
store-submission specifics (signing, provisioning profiles, Play Console /
App Store Connect / Microsoft Store listings, etc.), which are outside what
this codebase itself controls.

## Known gaps / next steps

Being upfront about what's genuinely wired versus not yet, so nothing here
is a surprise in production:

- **Technician performance fields** (`resolvedToday`, `resolvedThisWeek`,
  customer satisfaction, online/presence) aren't fully available from the
  backend today. `TechniciansService` merges `GET /users/technicians` with
  `GET /analytics/technician-performance` to get real resolution-rate and
  SLA data, but a few fields still default to 0 — see the comment on
  `Technician.fromJson` for exactly what a backend addition would need to
  provide.
- **Per-ticket device telemetry** (`features/telemetry/`,
  `_TelemetryPreviewCard` on the ticket detail screen) still renders mock
  data. The backend's telemetry endpoints are keyed by *device*, not by
  *ticket* — there's no "diagnostics for this specific ticket" endpoint, so
  this needs either a `ticket.deviceId → GET /telemetry/devices/:deviceId`
  lookup or a backend change linking telemetry to tickets.
- **Registration's department field** is collected as free text but the
  backend's `POST /auth/register` expects a `departmentId` (a real
  department record) — new accounts currently register with no department
  set. A `GET /departments` endpoint + picker would close this.
- **Push notifications** (Firebase, already wired server-side) aren't
  registered from the client yet — the FCM token endpoint
  (`PATCH /users/me/fcm-token`) exists on the backend but nothing calls it.
- File attachments: the ticket model can parse attachment metadata from the
  API, but the upload flow (picking a file and `POST`ing it to
  `/tickets/:id/attachments`) isn't wired into the submit/detail screens yet.

None of these block using the app for its core flow (sign in, browse/create/
manage tickets, browse assets and the knowledge base, get notified) — they're
scoped out clearly so the next round of work has a concrete list rather than
a vague "make it more complete."

## Troubleshooting

- **"No API_BASE_URL provided for a prod/staging build"** — you built with
  `--dart-define=ENV=prod` (or `staging`) without also passing
  `--dart-define=API_BASE_URL=...`. This is deliberate: better a loud
  startup error than a release build silently pointed at `localhost`.
- **Android emulator can't reach the backend** — confirm the backend is
  actually listening on `0.0.0.0`, not just `127.0.0.1`, and that you didn't
  override `API_BASE_URL` to `localhost` (use the default, which resolves to
  `10.0.2.2` automatically on Android).
- **Physical device can't reach a locally-running backend** — pass your
  machine's LAN IP explicitly (see [Configuring the backend
  URL](#configuring-the-backend-url)) and make sure your machine's firewall
  allows inbound connections on the backend's port.
- **401 loops / gets logged out unexpectedly** — check the backend's
  `JWT_ACCESS_EXPIRES_IN` / `JWT_REFRESH_EXPIRES_IN` are sane, and that the
  device's clock is correct (JWT expiry checks are time-based).
