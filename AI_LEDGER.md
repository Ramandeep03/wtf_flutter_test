# AI Ledger

Every commit tagged `[AI]` MUST have a corresponding entry below.

**Format**

| # | Tool | Intent | Prompt (≤2 lines) | Used | Commit |
|---|------|--------|-------------------|------|--------|
| n | model/tool | what was asked | short paraphrase | yes/partial/no | `<sha>` |

---

## Entries

### #1 — Scaffold monorepo + docs
- **Tool:** Claude Opus 4.7
- **Intent:** Bootstrap the backend-first monorepo (folders, pubspecs, backend skeleton, 6 living docs) per P01 brief.
- **Prompt (≤2 lines):** "P01 — Scaffold + Docs. Architecture rule: Flutter → HTTP → Node → Firebase Admin → Firestore. Create folders, pubspecs (no firebase_auth/cloud_firestore), backend skeleton, all 6 docs. Use api_state package, git init first."
- **Used:** yes
- **Deviation:** Brief specified `api_status` with enum `loading|completed|error` + `data` + `errorMessage` fields. Real pub.dev package is `api_state` v1.0.0 using **sealed classes** (`ApiInitial`, `ApiLoading`, `ApiSuccess<T>`, `ApiFailure<T>`, `ApiRefresh<T>`). ADR#5 and `shared/lib/utils/base_state.dart` reflect the sealed-class pattern instead of the enum pattern.
- **Commit:** `82424a0` — `chore(scaffold): init monorepo backend-first architecture [AI]`

### #2 — Backend setup (Express + Firebase Admin)
- **Tool:** Claude Opus 4.7
- **Intent:** P02 — bring backend to a runnable state: real `package.json`, Firebase Admin init, Bearer-token middleware, `/health`, deny-all Firestore rules, seed script for Aarav (trainer) + DK (member).
- **Prompt (≤2 lines):** "P02 — Backend Setup. Update package.json/firebase.js/auth.js/index.js verbatim from brief, add seed.js, firestore.rules. Keep P01 route stubs wired (option b)."
- **Used:** yes
- **Deviation:** Brief's `index.js` keeps route mounts commented; per user instruction (option b) we kept the P01 snake_case route file stubs but exposed them under the brief's kebab-case mount paths (`/call-requests`, `/session-logs`, `/hms-token`, `/stream-token`). Added `firebase.json` so `firestore.rules` is deployable.
- **Verified live (2026-05-20):** `npm start` boots, `/health` returns ok, Firebase Admin connects to project `wtf-fitness`, both seed users exist in Auth + Firestore (UIDs saved locally in `backend/.seed-uids.local`, gitignored), Firestore rules deployed (per user confirmation).
- **Note:** Seed script is non-idempotent — re-running fails with `auth/email-already-exists`. Acceptable per brief ("run once"); existing UIDs were retrieved via `auth.getUserByEmail()` rather than re-seeding.
- **Commit:** `602cc84` — `chore(backend): setup Express + Firebase Admin SDK [AI]`

### #3 — README first-time setup steps
- **Tool:** Claude Opus 4.7
- **Intent:** Add Firebase project creation, service-account drop, `npm install`, `node seed.js`, and `firebase deploy --only firestore:rules` instructions to root README so a fresh clone can bring P02 up without re-reading chat.
- **Prompt (≤2 lines):** "add these steps to readme.md" (referring to the user-action steps spelled out at the end of P02).
- **Used:** yes
- **Commit:** `42c475f` — `docs(readme): add first-time setup steps (Firebase, seed, rules) [AI]`

### #4 — Backend auth routes (login + me)
- **Tool:** Claude Opus 4.7
- **Intent:** P03 — implement `POST /auth/login` (Firebase Identity Toolkit REST → returns `{ idToken, refreshToken, user }`) and `GET /auth/me` (verifyToken middleware → returns Firestore user doc).
- **Prompt (≤2 lines):** "P03 — Backend Auth Routes. Replace the auth.js stub with login + me per brief. Use native fetch (Node 20+)."
- **Used:** yes
- **Deviation:** Brief lists `node-fetch` as an option for Node <18. We're on Node 24 with `engines >= 20`, so native global `fetch` is used and `node-fetch` is not added to dependencies.
- **Verified live (2026-05-20):** all 4 acceptance curls pass against the seeded DK account; `[AUTH] login uid=…` logs correctly.
- **Commit:** `3e6b7d4` — `feat(backend): auth login + me routes [AI]`

### #5 — Backend users + call-requests routes
- **Tool:** Claude Opus 4.7
- **Intent:** P04 — implement `GET /users`, `GET /users/:uid`, and `/call-requests` CRUD (create with conflict check, list with optional memberId/trainerId filter, PATCH status with optional declineReason).
- **Prompt (≤2 lines):** "P04 — Backend: Users + Call Requests Routes. Replace users.js and call_requests.js stubs with brief verbatim."
- **Used:** yes
- **Added beyond brief:** `firestore.indexes.json` with two composite indexes (`memberId+requestedAt DESC`, `trainerId+requestedAt DESC`) and wired into `firebase.json`. The list query (`.orderBy('requestedAt','desc').where('memberId|trainerId','==',…)`) is a single inequality + equality combo that Firestore requires composite indexes for. Caught live (FAILED_PRECONDITION); deployed indexes via `firebase deploy --only firestore:indexes`.
- **Verified live (2026-05-20):** all 7 acceptance tests pass against DK/Aarav (GET list, GET single, POST create, duplicate slot 409, filtered list, PATCH approve, PATCH decline+reason). Console logs `[SCHEDULE] created id=…` and `[SCHEDULE] updated id=… status=…`.
- **Test data left in Firestore:** two `call_requests` docs (one approved, one declined) — fine for downstream phases.
- **Commit:** `a5751a2` — `feat(backend): users + call-requests CRUD routes [AI]`

### #6 — Backend session-logs + rooms + 100ms/Stream tokens
- **Tool:** Claude Opus 4.7
- **Intent:** P05 — implement `/session-logs` CRUD (POST/GET-by-userId with member|trainer union and dedupe/PATCH), `/rooms` (POST → 100ms REST + save room_meta; GET by callRequestId), `/hms-token` (local JWT signed with HMS_APP_SECRET), `/stream-token` (Stream Chat user token). Add `services/hms.js`, deploy session_logs composite indexes, append full API reference to backend README.
- **Prompt (≤2 lines):** "P05 — Backend: Session Logs + Room Meta + 100ms + Stream Chat Routes. Replace 4 route stubs + hms.js verbatim from brief."
- **Used:** yes
- **Added beyond brief:** two more composite indexes (`session_logs.memberId+startedAt DESC`, `trainerId+startedAt DESC`) appended to `firestore.indexes.json` and deployed; new "API reference" section in `backend/README.md` replacing the old phase-status table.
- **Verified live (2026-05-20):** session-logs POST/GET (member side + trainer side, after index build)/PATCH all green. /hms-token returns a JWT decoding to {user_id, role, room_id, type:app, version:2, access_key, iat, nbf, exp, jti}. /stream-token returns a JWT with user_id claim.
- **NOT live-verified:** `POST /rooms` — placeholder `HMS_APP_ACCESS_KEY/SECRET/TEMPLATE_ID` in .env make 100ms reject the management token with 500 "Token validation error". Code matches brief; re-test once real 100ms creds are dropped. Same caveat applies to the *usability* of /hms-token and /stream-token tokens by real services (they sign locally regardless of cred validity).
- **Commit:** `0759163` — `feat(backend): session-logs + rooms + tokens routes [AI]`

### #7 — Flutter: ApiClient + Hive + theme + AppLogger
- **Tool:** Claude Opus 4.7
- **Intent:** P06 — bring up the Flutter foundation in `shared/`: `ApiClient` (singleton, http + Hive-backed Bearer token), `AppConstants`, `AppTheme`/`AppColors`/`AppTypography`/`AppSpacing`, `AppLogger` (20-entry ring), `Failure` hierarchy, DateTime/int extensions, `SnackbarHelper`. Per-app `core/hive_init.dart` + `core/bloc_observer.dart`. Both `main.dart` wired to `HiveInit.initialize()` + `Bloc.observer`.
- **Prompt (≤2 lines):** "P06 — Flutter: ApiClient + Hive + Constants + AppLogger. Replace shared utils, add core/, update mains. Mid-task addendum: add dark theme support."
- **Used:** yes
- **Beyond brief — dark theme:** user asked mid-phase. `AppTheme.light(seed)` + `AppTheme.dark(seed)` both factory `ThemeData`. Neutrals split into light/dark constants; brand + status colors kept constant across themes. Both apps wire `theme:`, `darkTheme:`, and `themeMode: ThemeMode.system`.
- **Beyond brief — barrel hygiene:** `api_state` exports its own `Failure`, which collides with the brief's `models/failures.dart`. Re-exported `package:api_state/api_state.dart` with `hide Failure` so the shared API has one canonical `Failure`.
- **Beyond brief — `ApiClient` list-endpoint limitation:** brief's signatures return `Map<String,dynamic>`. Our `/users` and `/call-requests?…` return JSON arrays — those calls will throw at `jsonDecode(...) as Map`. Not a P06 problem since the only verified call is `/health`; we'll add a list-aware method (e.g. `getList`) when P07/P08 needs it.
- **Verified live (2026-05-20):** `flutter analyze` clean across shared/guru_app/trainer_app; `flutter test` 7/7 passing (Hive token round-trip, Failure equality, extensions, ring buffer); separate live smoke test (`test/_health_smoke.dart`, prefixed `_` so it's opt-in) calls `ApiClient.instance.get('/health')` against the running backend and returns `{status: ok, ts: …}`.
- **Commit:** `e76a132` — `feat(flutter): ApiClient + Hive + AppLogger + theme [AI]`

### #8 — Flutter auth: UserEntity, AuthRepository, AuthCubit, login screens, router
- **Tool:** Claude Opus 4.7
- **Intent:** P07 — wire end-to-end auth: shared `UserEntity` + `AuthRepository(Impl)` calling `/auth/login` & `/auth/me`, shared `AuthCubit`, shared `LoginForm`/`SplashPage`/`RoleAppBar`. Per-app DI, go_router with splash→login→home redirect, per-app `LoginPage` (prefill dk for guru, aarav for trainer), per-app `HomePage` (3 cards / 4 tiles), feature-page stubs for every route, updated `bloc_observer`, updated `main.dart` wiring `BlocProvider.value(authCubit) + MaterialApp.router`. AuthCubit unit tests via `bloc_test` + `mocktail`, plus a live-backend integration smoke covering login OK, wrong-pw, cold-restart auto-sign-in, and logout.
- **Prompt (≤2 lines):** "P07 — Flutter: AuthCubit + Login Screens + Routing. Wire brief's AuthRepo/Cubit/router/screens; both apps."
- **Used:** yes
- **Deviations (significant — see ADR#5):**
  1. `AuthState` is not the brief's custom class with `ApiStatus` *enum*. It is `typedef AuthState = ApiStatus<UserEntity>;` (sealed class from `api_state` v1.0.0). UI uses `state is ApiLoading`, `state is ApiSuccess`, etc.
  2. Our domain failures (`AuthFailure`, `NetworkFailure`, `ValidationFailure`, `ServerFailure`) now extend `api_state.Failure` (which carries `message`, `code?`, `stackTrace?`). The local abstract `Failure` was deleted. Barrel re-exports `api_state` *without* `hide Failure` now — one canonical `Failure` for both ApiFailure carriers and domain types.
  3. Router redirect uses `state is ApiSuccess<UserEntity>` instead of a bool getter, and routes through `/splash` while `state is ApiLoading || ApiInitial`.
  4. Logout emits `ApiInitial` (not `ApiFailure`) since there's no error to surface; router still redirects to `/login` because `!isAuth`.
  5. `AuthCubit` + `AuthRepository` live in `shared/lib/` (not per-feature), so both apps depend on the same instance. Added `flutter_bloc`, `bloc`, `go_router`, `bloc_test`, `mocktail` to `shared/pubspec.yaml`.
  6. `LoginForm` is the shared widget; per-app `LoginPage` is a 3-line wrapper that supplies role-specific prefill + headline. Brief's "same widget, different pre-fill" turned into "extracted widget + 1-line wrappers".
- **Verified live (2026-05-20):**
  - `flutter analyze` clean across shared + guru_app + trainer_app.
  - `flutter test` shared → **12/12** (7 from P06 utilities + 5 new AuthCubit bloc tests covering checkSession-ok, checkSession-no-token, login-success, login-failure, logout).
  - Live `_auth_live_smoke.dart` against running backend → **4/4** (login DK ok + token persisted, login wrong-pw → ApiFailure(INVALID_LOGIN_CREDENTIALS), Aarav login + new cubit instance + `checkSession()` via stored Hive token → ApiSuccess[Aarav] (auto-sign-in proven), logout → ApiInitial + token cleared).
- **Not verified by me:** rendering on a real emulator. The visual checks ("home shows DK", "snackbar appears on wrong pw", "RoleAppBar badge") will pass given the cubit/UI plumbing tested, but I didn't boot a simulator. User can `flutter run` in either app to confirm.
- **Commit:** `d16ea51` — `feat(auth): AuthCubit + login screens + router [AI]`

### #9 — Flutter Stream Chat init
- **Tool:** Claude Opus 4.7
- **Intent:** P08 — wrap Stream Chat lifecycle: `StreamChatService` singleton, `StreamChatCubit` (connect/disconnect), `BlocListener<AuthCubit>` in `main.dart` that drives connect on `ApiSuccess<UserEntity>` and disconnect otherwise, `StreamChat` widget wrapping the router, `ChatListPage` listening for connect → `channel.watch()` for the deterministic 1:1 DK↔Aarav channel.
- **Prompt (≤2 lines):** "P08 — Flutter: Stream Chat Initialisation. Wire service + cubit + StreamChat wrapper + ChatListPage channel watch."
- **Used:** yes
- **Deviations from brief:**
  1. `StreamChatState` is `typedef ApiStatus<Unit>` (fpdart's `Unit`) — same ADR#5 reason as P07.
  2. `BlocListener<AuthCubit>` uses sealed-class pattern matching (`case ApiSuccess(:final data)`) instead of `state.isAuth` / `state.user!`.
  3. `getOrCreateChannel` builds the channel id from **sorted** UIDs so member-side and trainer-side both resolve the same id regardless of who navigates first; the brief's `chat-$memberUid-$trainerUid` would have created two ids for the same pair.
  4. `StreamChatCubit` takes an optional `StreamChatService` parameter for testability.
- **Verified:** `flutter analyze` clean on shared/guru/trainer; `flutter test` shared 12/12.
- **NOT verified live:** real Stream connection needs real `STREAM_API_KEY`/`SECRET` in `backend/.env` (currently placeholders). Backend's `/stream-token` signs a JWT with the placeholder secret, Stream's servers reject it on `connectUser`, cubit transitions to `ApiFailure(ServerFailure(…))`. Code path is correct; re-test after credentials are dropped.
- **Commit:** `d7fd6a3` — `feat(chat): Stream Chat init + StreamChatCubit [AI]`

### #10 — Flutter chat list screen
- **Tool:** Claude Opus 4.7
- **Intent:** P09 — chat list with skeleton loading, error retry, empty state, channel tiles with peer name + last message + relative timestamp + unread badge. Shared `ChatListView`; per-app `ChatListPage` retains P08's connect→`channel.watch()` listener.
- **Prompt (≤2 lines):** "P09 — Flutter: Chat List Screen. Wire StreamChannelListController/View + SkeletonList + ErrorRetryWidget + _ChannelTile + _EmptyChat."
- **Used:** yes
- **Deviations from brief:**
  1. Controller param renamed `sort:` → `channelStateSort:` and typed `SortOption<ChannelState>('last_message_at')` per actual `stream_chat_flutter_core` v8.3 API.
  2. State checks use sealed-class pattern (`chatState is ApiLoading || chatState is ApiInitial`, `case ApiFailure(:final error)`). Brief used non-existent `ApiStatus.loading` enum values.
  3. `_ChannelTile` avatar uses role-aware primary color (guru blue / trainer red) instead of brief's hardcoded `AppColors.guruPrimary` — the brief said "both apps — same widget" so role-awareness is needed.
  4. Channel id from sorted UIDs (continuation of P08 deviation).
  5. `stream_chat_flutter` import in `chat_list.dart` uses `hide StreamChatState` to dodge a collision with our cubit's typedef.
  6. `SkeletonList` skeleton blocks pick the right border color for light/dark theme.
- **Verified:** `flutter analyze` clean on shared + both apps; `flutter test` shared 12/12.
- **NOT verified live:** still blocked on real Stream credentials (same as P08).
- **Commit:** `49ab50e` — `feat(chat-list): StreamChannelListView + unread badge [AI]`

### #11 — Flutter chat conversation screen
- **Tool:** Claude Opus 4.7
- **Intent:** P10 — `ConversationView` shared widget with `StreamMessageListView` (custom builder swapping system messages for a centred grey pill), `_QuickReplies`, `_ConvAppBar` with peer name and camera-icon stub, `StreamMessageInput`. Per-app `ConversationPage` wraps it in `StreamChatTheme` so own bubbles match the role's brand color. `sendSystemMessage({memberUid, trainerUid, text})` helper for approve/decline use cases.
- **Prompt (≤2 lines):** "P10 — Flutter: Chat Conversation Screen. Build ConversationPage, _ConvAppBar, _QuickReplies, _SystemBubble + sendSystemMessage helper. Theme own-bubbles per role."
- **Used:** yes
- **Deviations:**
  1. Conversation lives in shared (`widgets/conversation.dart`); per-app page is a 6-line `StreamChatTheme` wrapper supplying the brand color. Brief's bubble theming was inline; pulling it out keeps the heavy widget app-agnostic.
  2. `messageBuilder` signature in v8.3 takes `StreamMessageWidget defaultMessageWidget` (not generic `Widget`).
  3. `_SystemBubble` colors flip for light/dark theme (brief hardcoded light surface).
  4. `sendSystemMessage` takes explicit `memberUid`/`trainerUid` params since the helper has no `BuildContext` to read auth from. Use cases that call it know the UIDs from the call request anyway.
- **Verified:** `flutter analyze` clean shared + both apps; `flutter test` shared 12/12.
- **NOT verified live:** real-time delivery / typing / read receipts blocked on real Stream creds (same as P08/P09).
- **Commit:** `d3112ef` — `feat(chat-conv): StreamMessageListView + quick replies + system bubble [AI]`

### #12 — Flutter scheduler + request flow
- **Tool:** Claude Opus 4.7
- **Intent:** P11 — full request lifecycle. Shared `CallRequestEntity` + `canJoinCall`, `CallRequestRepository` (4 methods) + minimal `RoomRepository`, `generateSlots`. Guru `SchedulerCubit` form state, `MyRequestsCubit`, `SchedulerPage` (day chips, slot wrap with past greyed, 140-char note, snackbar + go('/requests') on submit), `MyRequestsPage`. Trainer `RequestsBloc` (Loaded / Approved / Declined) wiring POST /rooms → PATCH status → sendSystemMessage → reload, `RequestsPage` with Pending/All tabs, per-row spinner, decline-reason bottom sheet. 3 SchedulerCubit blocTests.
- **Prompt (≤2 lines):** "P11 — Scheduler + Request Flow. Shared entity/repo/slots; Guru SchedulerCubit+MyRequestsCubit+pages with /requests route; Trainer RequestsBloc+page; sendSystemMessage on approve/decline."
- **Used:** yes
- **Tech-debt paid off:** P06's known gap — `ApiClient.get` only returned Map. Added `ApiClient.getList()` returning `Future<List<dynamic>>`. Repository uses it for `/call-requests?…` and treats non-array responses as ApiException.
- **Deviations from brief:**
  1. `SchedulerState` is form-shaped not pure ApiStatus — it holds date/slot/note + a nested `submitStatus: ApiStatus<Unit>` per ADR#5. Brief's `ApiStatus` enum doesn't exist.
  2. `MyRequestsCubit` is `Cubit<ApiStatus<List<CallRequestEntity>>>` directly; brief proposed a custom `AsyncState<T>` helper — superseded by `api_state`'s sealed classes.
  3. `RequestsState` carries `list: ApiStatus<List<...>>` + `processingIds: Set<String>` + `lastError: String?`. Pattern matching for list rendering; snackbar fired on `lastError` change.
  4. `RoomRepository` split out from `CallRequestRepository` so the approve flow makes the dependency explicit and is easy to mock.
  5. Brief's `RequestApproved` flow ordering followed: rooms first, then PATCH, then system message; failure at rooms aborts and surfaces the error (rather than masking it and proceeding).
  6. `sendSystemMessage` wrapped in try/catch in both approve and decline branches so a failing Stream Chat doesn't roll back a successful PATCH. Logged as `[CHAT] system msg failed (…)`.
- **Verified:** `flutter analyze` clean shared + guru + trainer. `flutter test` shared 12/12. guru_app 3/3 SchedulerCubit blocTests covering past-slot reject, >140-char reject, success path with slot/note cleared.
- **Runtime gaps documented:**
  - `POST /rooms` returns 500 against placeholder HMS_* creds; trainer approve will currently snackbar "Could not create call room: …". Will green once real 100ms creds land.
  - `sendSystemMessage` will throw against placeholder STREAM_* creds; caught, logged, PATCH still succeeds.
  - Local notification to DK after trainer approves is P14 scope.
- **Commit:** `232981d` — `feat(scheduler): SchedulerCubit + RequestsBloc + backend calls [AI]`

### #13 — Flutter pre-join + permissions
- **Tool:** Claude Opus 4.7
- **Intent:** P12 — `PreJoinCubit` fetches `/rooms?callRequestId=…`; `PreJoinView` (shared) shows camera placeholder + mic/cam toggles + role label + Join button; per-app `PreJoinPage` provides MultiBlocProvider. Stub `CallBloc` so PreJoinView's Join-Call wiring compiles before P13. Shared `requestCallAndNavigate(ctx, …)` helper requests mic+camera permissions then `ctx.push('/pre-join?…')`. Wired into both apps' request lists.
- **Prompt (≤2 lines):** "P12 — Pre-Join Screen + Permissions. PreJoinCubit + PreJoinPage + permission gate. AndroidManifest entries (deferred — apps have no android/ folder)."
- **Used:** yes
- **Deviations from brief:**
  1. `PreJoinState`: `ApiStatus<String>` carries the fetched `hmsRoomId` directly. Brief's flat `status + hmsRoomId + errorMessage` collapses into the sealed type per ADR#5.
  2. `CallBloc` is a real stub in shared — `CallJoinRequested` emits `ApiLoading` → `ApiSuccess(unit)` so the router redirect to `/call` works pre-P13. Will be replaced with 100ms SDK plumbing.
  3. PreJoinView and the permission helper live in shared; per-app `PreJoinPage` is a 12-line wrapper. Brief had a single per-app PreJoinPage.
  4. Router param renamed from `roomId` to `callRequestId` to match what the page actually needs (the request id, not the 100ms room id — the room id is fetched server-side from the request).
  5. Permission helper is a top-level function (`requestCallAndNavigate`) rather than a method on a request list; same effect with less boilerplate at call sites.
  6. `_DeviceToggle` colors flip for light/dark theme.
- **NOT done:**
  - **AndroidManifest + build.gradle**: Both Flutter apps are still Dart-only (no `android/` or `ios/` folders). Brief asks for permission entries + `minSdk 21` / `targetSdk 34`. To do this I'd need to run `flutter create --platforms=android,ios .` in each app, which generates ~50 platform files (kotlin MainActivity, gradle wrappers, ios Runner, default package id `com.example.guru_app`). Asked the user; awaiting their choice on package id before materializing.
- **Verified:** `flutter analyze` clean shared + guru + trainer. `flutter test` shared 12/12 + guru 3/3 still passing.
- **Runtime gap:** `GET /rooms` is currently a 404 unless a trainer has approved a request and successfully created a 100ms room — which itself needs real HMS_* creds.
- **Commit:** `75f768b` — `feat(call): PreJoinCubit + pre-join screen + permissions [AI]`

### #14 — Materialize android + ios platform projects
- **Tool:** Claude Opus 4.7
- **Intent:** Run `flutter create --platforms=android,ios --org=dev.ramandeep .` in both apps so the Dart-only scaffolds from P01 finally have native projects. Pure scaffold commit; no Dart changes.
- **Prompt (≤2 lines):** User: "1 do dev.ramandeep for both and 2 use both android and ios I will test on both and 3 yes seperate them but first push the current code".
- **Used:** yes
- **Output:** ~63 native files per app — Kotlin `MainActivity` at `dev/ramandeep/<app>/`, gradle Kotlin DSL, gradle wrapper, iOS Runner xcodeproj/workspace, `Info.plist`, `LaunchScreen.storyboard`, `Main.storyboard`, full app-icon + launch-image asset catalog, `Podfile`, `.gitignore`, `.metadata`, `README.md`. Default app icons are stock Flutter blue/white "F".
- **Deleted:** boilerplate `test/widget_test.dart` files that referenced the counter-app `MyApp` class which doesn't exist in our `main.dart`.
- **Verified:** `flutter analyze` clean on both apps post-scaffold.
- **Commit:** `9c888c4` — `chore(scaffold): materialize android + ios platforms [AI]`

### #15 — Patch native projects for call permissions
- **Tool:** Claude Opus 4.7
- **Intent:** P12 brief follow-up: add the 6 Android `<uses-permission>` entries (INTERNET / CAMERA / RECORD_AUDIO / MODIFY_AUDIO_SETTINGS / FOREGROUND_SERVICE / BLUETOOTH_CONNECT), pin Android `minSdk = 21` / `targetSdk = 34`, and add the iOS counterparts: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`. Set Podfile `platform :ios, '13.0'` and `GCC_PREPROCESSOR_DEFINITIONS` (`PERMISSION_CAMERA=1`, `PERMISSION_MICROPHONE=1`, `PERMISSION_BLUETOOTH=1`) so `permission_handler` only compiles the macros we actually use.
- **Used:** yes
- **Beyond brief:**
  - iOS plist + Podfile changes (brief only listed Android); without them the `permission_handler` runtime calls would silently no-op on iOS.
  - Android gradle file is Kotlin DSL (`build.gradle.kts`) since the scaffold from #14 used the modern template; brief showed legacy Groovy.
- **Verified:** `flutter analyze` clean on both apps. Not yet `flutter build` against either platform (no SDK / pod install run from here).
- **Commit:** `3b24f39` — `chore(platform): call permissions + minSdk/targetSdk in android + ios [AI]`

### #16 — Flutter CallBloc + in-call screen (100ms)
- **Tool:** Claude Opus 4.7
- **Intent:** P13 — replace P12's `CallBloc` stub with a full implementation that fetches `/hms-token`, joins 100ms via `HMSSDK`, listens to `HMSUpdateListener` callbacks, exposes mute / video / flip / end events, and surfaces reconnection. Add `CallView` (shared): remote `HMSTextureView`, local PiP, name + MM:SS timer, reconnecting overlay, 4-button control bar. Add `SessionLogDraft` model for the navigate-to-/post-call payload.
- **Prompt (≤2 lines):** "P13 — CallBloc + In-Call Screen. Real 100ms hmssdk_flutter wiring, full state machine + tests."
- **Used:** yes
- **Deviations from brief:**
  1. **`CallState` is a class, not `status: ApiStatus` enum.** Used a `CallPhase` enum (`idle | joining | inCall | ended | failed`) because `api_state` has no such enum (ADR#5). Brief's "ApiStatus.loading = connecting or reconnecting" maps to `joining` with `joinedAt != null`; "ApiStatus.error" splits into `ended` (user-initiated) vs `failed` (terminal HMS).
  2. **`HMSVideoView` → `HMSTextureView(track: peer.videoTrack!)`** — v1.11.1 API takes a track, not a peer. Local PiP uses `local!.videoTrack` with `setMirror: true`.
  3. **`onError` → `onHMSError`** — actual interface method name in v1.11.1.
  4. **All 14 `HMSUpdateListener` methods implemented** (brief listed only 9). `onPeerListUpdate`, `onRoleChangeRequest`, `onChangeTrackStateRequest`, `onAudioDeviceChanged` no-op; `onRemovedFromRoom` emits a terminal `CallHmsFailed("Removed from room", isTerminal: true)`.
  5. **Internal `_HMS_*` events made public (`CallHms*`)** so blocTests can poke them directly without instantiating fake HMSRoom/HMSPeer values (which have many required ctor params).
  6. **PreJoin → InCall is *not* `pushReplacement`.** Single `/pre-join` route hosts the `CallBloc`; `PreJoinView` swaps to `CallView` when `phase == inCall` (or joining-while-reconnecting). `pushReplacement` would have destroyed the bloc mid-SDK-handshake. `/call` route now just redirects to `/home`.
  7. **`CallBloc` takes optional `api` + `sdkFactory` ctor params** so tests can mock the token call and avoid real SDK instantiation.
  8. **Camera-icon-in-AppBar deferred** to P14 — looking up "the active approved request" from inside a stateless AppBar action wants an async repo lookup that doesn't fit the current `_ConvAppBar` shape.
- **Verified:** `flutter analyze` clean shared + both apps. `flutter test` shared 18/18 (12 prior + 6 new — token-failure / connected / reconnecting / reconnected / terminal-failure / non-terminal-no-op). `flutter test` guru 3/3.
- **NOT verified:** runtime 100ms join. Requires real HMS_* creds and an approved request that successfully created a `room_meta` doc — gated by P11's approve-flow runtime gap.
- **Commit:** `98ae76e` — `feat(call): CallBloc + 100ms in-call screen [AI]`

### #17 — Flutter session logs + post-call sheets
- **Tool:** Claude Opus 4.7
- **Intent:** P14 — full session-log lifecycle. Shared `SessionLogEntity` + `SessionLogRepository`. `PostCallCubit` (auto-create on init, then collect rating/notes, save). `SessionLogsCubit` (`ApiStatus<List>` + `LogFilter`). `PostCallView` (member vs trainer sheet, `_StarRating`). `SessionsView` (filter chips + list + draggable detail modal with rate-now / edit-notes). Wire SessionLogDraft.memberId/trainerId through the call flow properly.
- **Prompt (≤2 lines):** "P14 — Session Logs + Post-Call. Build cubits + shared views + tests, and finally propagate memberId/trainerId through the call URL."
- **Used:** yes
- **Bug fix on top of P13:** `SessionLogDraft.memberId` / `.trainerId` in P13 were derived from `user.assignedTrainerId` — fine for member, broken for trainer (trainers don't have an `assignedTrainerId`). Now both ids come from the originating `CallRequestEntity` and are threaded `requestCallAndNavigate(memberId, trainerId)` → `/pre-join?…&memberId=&trainerId=` → `PreJoinPage(memberId, trainerId)` → `PreJoinView` constructs the draft with the correct ids.
- **Deviations from brief:**
  1. `PostCallState` uses a `PostCallPhase` enum (`creating | ready | saving | saved | failed`) instead of the brief's flat `ApiStatus`. Same ADR#5 reason as everywhere else.
  2. `SessionLogsState` carries `listStatus: ApiStatus<List<…>>` + `filter`; `displayed` getter computes the filtered+sorted view.
  3. Snackbar on save fires via `listenWhen: (p,c) => p.phase != c.phase`; brief's listener would have re-shown the toast on note edits.
  4. Detail modal — "Rate Now" only shown to members without an existing rating; "Save Notes" shown for trainer always, for member only when expanded.
- **Verified:** `flutter analyze` clean shared + guru + trainer. `flutter test` shared 24/24 (18 prior + 3 PostCallCubit create / save / fail + 3 SessionLogsCubit load-sorted / filter-last7 / filter-thisMonth). guru 3/3.
- **Runtime gap:** session-log POST/PATCH work against the live backend (P05 endpoints are deployed), but producing a `SessionLogDraft` requires a real call to complete — gated on real 100ms creds.
- **Commit:** `f71f600` — `feat(sessions): PostCallCubit + SessionLogsCubit + backend calls [AI]`

### #18 — Flutter local notifications
- **Tool:** Claude Opus 4.7
- **Intent:** P15 — `NotificationService` (shared) with initialize/show/schedule/cancel + timezone setup, `NotifId` constants. Wire firing sites: diff-aware `MyRequestsCubit` (guru) for approve/decline + 10-min reminder, `StreamChatService.connect` for incoming chat messages while backgrounded. Android manifest entries (perm + receivers). Init in both `main()`.
- **Prompt (≤2 lines):** "P15 — Flutter: Local Notifications. NotificationService + diff-aware approve/decline + Stream messageNew while backgrounded."
- **Used:** yes
- **Deviations from brief:**
  1. **`NotificationService` is an instance singleton** (`NotificationService.instance.show(...)`), not a static-only class — keeps the API consistent with `StreamChatService.instance` from P08 and lets tests inject if needed.
  2. **iOS init uses bare `DarwinInitializationSettings()`** — the platform will lazily prompt for permission on first `show()/schedule()`. Brief did the same; calling out so it's clear we're not requesting at boot.
  3. **`MyRequestsCubit` made diff-aware** with a private `_previous` list. Brief sketched it inline; pulling it into the cubit means there's one canonical place that fires notifications when statuses transition, regardless of how `load()` was triggered.
  4. **Foreground check** in `StreamChatService._startMessageNotifications` uses `SchedulerBinding.instance.lifecycleState` (the brief's `WidgetsBinding.lifecycleState` doesn't exist as a property — `WidgetsBinding` does not expose lifecycle directly; it goes through SchedulerBinding).
  5. **Subscription canceled on disconnect** so logout doesn't leak the event listener.
  6. **Added `POST_NOTIFICATIONS` permission** (Android 13+) which the brief omitted.
- **NOT done:**
  - Notification-tap deep-linking — `onDidReceiveNotificationResponse` logs the payload (`call_join:<id>`) but doesn't navigate. Deferred to P17 (router state + GoRouter parsing).
- **Verified:** `flutter analyze` clean shared + both apps. `flutter test` shared 24/24 (no notification tests added — would require platform channel mocking that's not worth it for a thin wrapper).
- **NOT verified live:** needs a real device; flutter_local_notifications is platform-channel heavy.
- **Commit:** `c4ed433` — `feat(notif): local notifications for calls + Stream Chat messages [AI]`

### #19 — AppLogger + LogMask sensitive-data masking
- **Tool:** Claude Opus 4.7
- **Intent:** P16 — pretty `AppLogger` via the `logger` package (`.i / .w / .e / .t`), `LogMask` helpers (`token` / `uid` / `secret` / `email` / `url`), and apply masking at every call site that touches sensitive values. Backend request-logger middleware masking the `Authorization` header. Audit the codebase for raw tokens / passwords in log strings.
- **Prompt (≤2 lines):** "P16 — Debug Logging + Sensitive Data Masking. AppLogger uses logger pkg, mask uid/token/email everywhere, never log Authorization header."
- **Used:** yes
- **Deviations from brief:**
  1. **`AppLogger.log()` kept as `@Deprecated` alias** for `.i()` so the pre-existing 20-entry ring-buffer test (`api_client_test.dart`) doesn't break, and to avoid touching 31 call sites in a single commit.
  2. **All 31 call sites migrated** anyway by bulk-sed: routine logs → `.i`, warnings → `.w`, errors → `.e`, low-level traces (BlocObserver, API request paths) → `.t`. Tags `auth` callers that were really lifecycle/nav went to the new `LogTag.nav`.
  3. **Backend uid masking** in `auth.js` / `hms_token.js` / `stream_token.js` — brief covered only the request middleware; I extended to every route that interpolated `uid` in `console.log`.
  4. **`ApiClient._headers` audited** — brief said "no logging here", code already had none; added a comment to make the no-log policy load-bearing.
- **Codebase grep:** zero matches for `token=$`, `idToken=$`, `password=$`, `uid=${user.uid}` (without mask) in log strings across `shared/lib`, `guru_app/lib`, `trainer_app/lib`, `backend/src`.
- **Verified:** `flutter analyze` clean shared + guru + trainer. `flutter test` shared 29/29 (24 prior + 5 new `LogMask` unit tests covering token / uid / email / secret / url helpers).
- **Commit:** `ea2eb0d` — `feat(logging): AppLogger + LogMask sensitive data masking [AI]`

### #20 — VS Code launch + APK build configs
- **Tool:** Claude Opus 4.7
- **Intent:** Add `.vscode/launch.json` (Backend + Guru + Trainer + Backend+Guru / Backend+Trainer compounds) and `.vscode/tasks.json` (per-app APK release builds + a "Build BOTH APKs" sequence as the default build task + an "npm install" helper). Update README.md with a VS Code section.
- **Prompt (≤2 lines):** "Create vs code code runner json for server and app and one to build both applications apk. and keep in mind for android as well. add that in readme.md file and do not push it. addd this in ledger."
- **Used:** yes
- **Notes:**
  1. Flutter configs run on whichever device is currently selected in VS Code (no `deviceId` pin) — user explicitly asked not to make them simulator-special.
  2. `--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000` baked in for Android emulator default; iOS sim / physical device users edit the value in `launch.json` (e.g. host LAN IP `http://192.168.1.10:3000`).
  3. `--dart-define=STREAM_CHAT_API_KEY=9bezp69e22kw` baked in — Stream's API key is publishable per their docs (the secret stays in `backend/.env`).
  4. Backend launch config reads `backend/.env` via `envFile` so the same Firebase / HMS / Stream secrets the manual run uses also drive the F5 path.
  5. APK builds use `--release` and pass the same dart-defines so the built artifact talks to the correct backend.
- **Push policy:** committed locally only — not pushed per the user's instruction.
- **Commit:** `216902a` — `docs(vscode): VS Code launch + APK build configs (README copy-paste) [AI]`

### #21 — Android build chain unblock (Kotlin daemon, desugaring, version bumps)
- **Tool:** Claude Opus 4.7
- **Intent:** User reported `flutter run` on device A015 failing with `e: The daemon has terminated unexpectedly on startup attempt #1` followed by `Application finished`. Cascade of build fixes to get a debug APK actually building on both apps with JDK 21 / AGP 8.11 / Kotlin 2.2.20 / Flutter 3.41.
- **Used:** yes
- **Fixes applied (in the order I hit them):**
  1. **Kotlin daemon OOM on startup.** Both apps' `android/gradle.properties`: dropped Gradle JVM `-Xmx` from 8G → 4G (was crowding the host) and added `kotlin.daemon.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=256m` so the Kotlin daemon doesn't inherit a tiny default. Commented `kotlin.compiler.execution.strategy=in-process` as a fallback if it flakes again.
  2. **`flutter_local_notifications` requires core library desugaring.** Both `app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` in `compileOptions`, added a `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:…") }` block.
  3. **`flutter_timezone` 2.1.0 uses the removed v1-embedding `Registrar`.** Bumped to `^4.0.0` (latest 5.0.2 also fine) in all three pubspecs.
  4. **`flutter_local_notifications` 17.x pins `timezone ^0.9.0`, which blocked the bump.** Bumped `flutter_local_notifications` to `^20.1.0` everywhere.
  5. **`flutter_local_notifications` v20 changed everything to named args.** Rewrote `NotificationService` to use `_plugin.show(id:…, title:…, …)`, `zonedSchedule(scheduledDate:…, …)`, `cancel(id:…)`, dropped the removed `UILocalNotificationDateInterpretation`, switched `initialize()` to the `settings:` named param.
  6. **`desugar_jdk_libs` 2.0.4 below the required 2.1.4.** Bumped both build.gradle.kts.
  7. **`image_gallery_saver_plus` 3.x (transitive of stream_chat_flutter) also uses removed `Registrar`.** Added `dependency_overrides: image_gallery_saver_plus: ^4.0.1` in both app pubspecs.
- **Build result:** `flutter build apk --debug ...` succeeds on both apps — `guru_app/build/app/outputs/flutter-apk/app-debug.apk` and `trainer_app/.../app-debug.apk`.
- **Verified:** `flutter analyze` clean shared + guru + trainer; `flutter test` shared 29/29 still passing.
- **Heads-up:** Flutter's "Upgrading build.gradle.kts" auto-migration that ran on the user's `flutter run` had reverted `minSdk = 21` back to `flutter.minSdkVersion` in trainer's `build.gradle.kts`. Left it that way — current Flutter SDK's default minSdkVersion is now ≥ 21 anyway. Guru's stayed pinned to 21.
- **Push policy:** local commit only.
- **Commit:** `2af53ac` — `fix(android): unblock build chain — kotlin daemon, desugaring, dep bumps [AI]`

### #22 — Stream Chat user upsert (channel members must exist)
- **Tool:** Claude Opus 4.7
- **Intent:** User reported `StreamChatNetworkError(code: 4): GetOrCreateChannel failed with error: "The following users are involved in channel create operation, but don't exist: [<Aarav's UID>]"`. Stream requires both peers of a 1:1 channel to exist as Stream users before `client.channel(..., extraData: { members: [...] })` succeeds. We never created the peer-side user.
- **Used:** yes
- **Fix:** rewrote `backend/src/routes/stream_token.js` to look up the requesting user's Firestore doc, derive the peer set (member → `assignedTrainerId`; trainer → all members whose `assignedTrainerId` is this trainer), and `client.upsertUsers([self, ...peers])` before issuing the token. Guarantees that as soon as either side has logged in, both ends of the channel exist server-side.
- **Verified live (2026-05-20):** DK login → `GET /stream-token` returned token + server logged `[CHAT] stream token issued uid=K8n***jD2 upserted=2` (DK + Aarav). Channel creation no longer 400s on the client.
- **Drive-by cleanup:** A find-replace had corrupted `.env.example`, `README.md` (5 places), `.vscode/launch.json` (comment), and AI_LEDGER #20 — `http://192.168.1.10:3000` got split across a newline + spaces. All restored to clean URLs.
- **Commit:** `fix(chat): upsert Stream users so channel members exist [AI]`
