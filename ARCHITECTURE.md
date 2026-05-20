# Architecture

## Hard rule

**Flutter never imports `firebase_auth` or `cloud_firestore`.**
All Firebase access is server-side, through the Node backend, via Firebase Admin SDK.

## Flow

```
┌─────────────┐   HTTPS + ID token    ┌──────────────────────┐
│  guru_app   │ ────────────────────▶ │                      │
│ (Flutter)   │ ◀──────────────────── │                      │
└─────────────┘     JSON responses    │                      │
                                      │   Node.js Backend    │   Firebase Admin SDK    ┌──────────────┐
┌─────────────┐                       │   (Express)          │ ──────────────────────▶ │  Firestore   │
│ trainer_app │ ────────────────────▶ │                      │                         └──────────────┘
│ (Flutter)   │ ◀──────────────────── │                      │
└─────────────┘                       │                      │   REST                  ┌──────────────┐
                                      │                      │ ──────────────────────▶ │   100ms      │
                                      │                      │                         └──────────────┘
                                      │                      │   server SDK            ┌──────────────┐
                                      │                      │ ──────────────────────▶ │ Stream Chat  │
                                      └──────────────────────┘                         └──────────────┘
```

- Flutter authenticates via backend `/auth/*` endpoints; backend mints/verifies Firebase ID tokens.
- Flutter holds the ID token, sends it as `Authorization: Bearer <token>` on every request.
- Backend `middleware/auth.js` verifies it with Firebase Admin and attaches `req.user`.
- 100ms auth tokens and Stream Chat user tokens are minted server-side and handed back to Flutter.

## Flutter layering (per feature)

```
features/<name>/
├── data/            HTTP clients, DTOs, repository impls
├── domain/          entities (re-exported from shared/), repo interfaces, use-cases
└── presentation/
    ├── bloc/        BLoC/Cubit + states (extending shared base state)
    └── (pages, widgets)
```

- `shared/` holds cross-app primitives: pure-Dart models, abstract service interfaces, theme/logger/constants, reusable widgets.
- Each feature's BLoC state uses **`api_state`** sealed classes (`ApiInitial` / `ApiLoading` / `ApiSuccess<T>` / `ApiFailure<T>` / `ApiRefresh<T>`) — see ADR#5.

## Core wiring (per app)

```
lib/core/
├── di.dart              service locator (get_it or manual)
├── router.dart          go_router config
├── hive_init.dart       Hive boxes for offline cache / settings
└── bloc_observer.dart   global BLoC logging
```

## Local notifications

`flutter_local_notifications` schedules in-app reminders driven by Firestore data the backend exposes. No FCM in P01.
