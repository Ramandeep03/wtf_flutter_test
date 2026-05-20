# Checklist

## P01 — Scaffold + Docs
- [x] All folders created
- [x] Both Flutter pubspecs correct (no `firebase_auth` / `cloud_firestore`)
- [x] All 6 docs written (README, AI_LEDGER, ARCHITECTURE, DECISIONS, CHECKLIST, COMMIT_PATTERN)
- [x] AI_LEDGER Entry #1 logged
- [x] `chore(scaffold): init monorepo backend-first architecture [AI]` — `82424a0`

## P02 — Backend Setup
- [x] `npm run dev` → server on :3000
- [x] `curl http://localhost:3000/health` → `{"status":"ok","ts":"..."}` ✅ verified 2026-05-20
- [x] Firebase Admin SDK connected (project `wtf-fitness`)
- [x] Auth middleware verifies Bearer ID tokens (`src/middleware/auth.js`)
- [x] CORS + JSON body parsing in `src/index.js`
- [x] `.env` loaded via `dotenv`
- [x] `seed.js` created (Aarav trainer + DK member)
- [x] Users present in Firebase Auth + Firestore (UIDs in `backend/.seed-uids.local`, gitignored)
- [x] `firestore.rules` (deny-all) committed
- [x] Firestore rules deployed to project
- [x] `chore(backend): setup Express + Firebase Admin SDK [AI]` — `602cc84`

## P03 — Auth (Backend + Flutter)
### Backend (this phase)
- [x] `POST /auth/login` valid creds → `{ idToken, refreshToken, user }` ✅ verified
- [x] `POST /auth/login` wrong password → 401 `INVALID_LOGIN_CREDENTIALS` ✅ verified
- [x] `GET /auth/me` with valid token → user profile ✅ verified
- [x] `GET /auth/me` without token → 401 `Missing token` ✅ verified
- [x] Console logs `[AUTH] login uid=…` ✅ verified
### Flutter (later phase)
- [ ] Flutter auth feature in both apps (data/domain/presentation)
- [ ] Token stored in Hive

## P04 — Backend: Users + Call Requests
- [x] `GET /users` → list, 200 ✅
- [x] `GET /users/:uid` → single, 200 ✅
- [x] `POST /call-requests` → 201, status=pending ✅
- [x] Duplicate approved slot → 409 `Slot already booked` ✅
- [x] `GET /call-requests?memberId=` → filtered list, 200 (composite index deployed) ✅
- [x] `PATCH /call-requests/:id` status=approved → updated ✅
- [x] `PATCH /call-requests/:id` status=declined + reason → updated ✅
- [x] Console logs `[SCHEDULE] created/updated` ✅
- [x] `feat(backend): users + call-requests CRUD routes [AI]`

## P05 — Backend: Session Logs + Room Meta + 100ms + Stream Chat Routes
- [x] `POST /session-logs` → 201, doc in Firestore ✅
- [x] `GET /session-logs?userId=` returns logs for member side ✅
- [x] `GET /session-logs?userId=` returns logs for trainer side ✅
- [x] `PATCH /session-logs/:id` updates rating + memberNotes + trainerNotes ✅
- [x] `GET /hms-token?roomId=&role=` returns structurally valid JWT (all claims: user_id, role, room_id, type=app, version=2, iat/nbf/exp/jti) ✅
- [x] `GET /stream-token` returns Stream Chat JWT (user_id claim) ✅
- [x] `POST /rooms` code wired; ❌ live call to api.100ms.live fails with placeholder HMS_* creds (expected). Re-test after dropping real 100ms keys.
- [x] Composite indexes for session_logs (memberId+startedAt, trainerId+startedAt) deployed
- [x] backend/README.md updated with full API reference
- [x] `feat(backend): session-logs + rooms + tokens routes [AI]`

## P06 — Flutter: ApiClient + Hive + Constants + AppLogger
- [x] `ApiClient.instance.get('/health')` returns `{"status":"ok"}` ✅ live test
- [x] `ApiClient.saveToken(token)` stores in Hive; `storedToken` reads it ✅ unit test
- [x] AppLogger, Failures, Extensions, SnackbarHelper, AppTheme compile ✅
- [x] Both `main.dart` call `HiveInit.initialize()` + set `Bloc.observer = AppBlocObserver()` ✅
- [x] `flutter analyze` shared → No issues found ✅
- [x] `flutter analyze` guru_app + trainer_app → No issues found ✅
- [x] `flutter test` shared → 7/7 passing (Hive round-trip, Failures equality, IntExt/DateTimeExt, AppLogger ring buffer)
- [x] **Beyond brief:** dark theme support (`AppTheme.light(seed)` + `AppTheme.dark(seed)`, neutrals split, brand+status constant). Both apps use `themeMode: ThemeMode.system`.
- [x] `feat(flutter): ApiClient + Hive + AppLogger + theme [AI]`

## P07 — Flutter: AuthCubit + Login Screens + Routing
- [x] AuthRepository (interface + impl) calling `/auth/login` + `/auth/me` ✅
- [x] AuthCubit (Cubit<ApiStatus<UserEntity>>) with checkSession / login / logout ✅
- [x] go_router with redirect on splash/login/home + refresh from cubit stream ✅
- [x] SplashPage + LoginForm (shared) + LoginPage per app (prefill dk / aarav) ✅
- [x] Guru HomePage (3 cards: Chat / Schedule / Sessions) ✅
- [x] Trainer HomePage (4 tiles: Members / Chats / Requests / Sessions) ✅
- [x] RoleAppBar with role badge + name + logout ✅
- [x] Page stubs for every route in both apps' router ✅
- [x] flutter_bloc + go_router added to shared/pubspec.yaml ✅
- [x] flutter analyze shared/guru/trainer → No issues ✅
- [x] flutter test → 12/12 (api_client + auth_cubit unit suites) ✅
- [x] Live integration smoke (vs real backend): login OK / wrong pw / cold-restart auto-sign-in / logout → 4/4 ✅
- [x] `feat(auth): AuthCubit + login screens + router [AI]`
- [ ] **Runtime UI verification on an emulator** — not done; needs an Android/iOS sim session.

## P08 — Flutter: Stream Chat Initialisation
- [x] `StreamChatService` singleton wrapping `StreamChatClient` ✅
- [x] `StreamChatCubit` = `Cubit<ApiStatus<Unit>>` (connect / disconnect)
- [x] Both apps: `MultiBlocProvider(authCubit + streamChatCubit)` + `BlocListener<AuthCubit>` that calls `streamChatCubit.connect(user)` on `ApiSuccess<UserEntity>`, `disconnect()` otherwise
- [x] Both apps: `MaterialApp.router(builder: StreamChat(client:..., child: child))`
- [x] `ChatListPage` (both apps) listens for `StreamChatCubit` `ApiSuccess` and calls `channel.watch()` for the DK↔Aarav 1:1 channel
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared → 12/12 still pass
- [ ] **Runtime not verified end-to-end**: real Stream connection requires real `STREAM_API_KEY` + `STREAM_API_SECRET` (backend `.env` currently has placeholders). Code returns a token, but Stream rejects it → `[CHAT] Stream connect error: …`. Re-test after dropping real creds.
- [x] `feat(chat): Stream Chat init + StreamChatCubit [AI]`

## P09 — Flutter: Chat List Screen
- [x] `SkeletonList` + `ErrorRetryWidget` in shared
- [x] `ChatListView` (shared) — `StreamChannelListController` filter `members in [uid]`, `channelStateSort` by `last_message_at` DESC
- [x] FAB + empty-state button push `/chat/conv`
- [x] `_ChannelTile` shows peer name (auto-picks non-self member), last-message text + relative timestamp, unread badge
- [x] `_EmptyChat` shows exact copy "No messages yet. Start the conversation."
- [x] `ApiLoading` / `ApiInitial` → `SkeletonList(itemCount: 3)`
- [x] `ApiFailure(:final error)` → `ErrorRetryWidget(message: error.message, onRetry: connect)`
- [x] Per-app `ChatListPage` retains the channel-watch listener from P08
- [x] Avatar background uses role-aware primary (guru blue / trainer red) — brief hardcoded guruPrimary
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared → 12/12 still pass
- [ ] **Runtime not verified**: real channel list + unread badge need real Stream creds. Same blocker as P08.
- [x] `feat(chat-list): StreamChannelListView + unread badge [AI]`

## P10 — Flutter: Chat Conversation Screen
- [x] `ConversationView` (shared) opens DK↔Aarav channel, calls `watch()`
- [x] `StreamMessageListView` with custom `messageBuilder` that swaps system messages for `_SystemBubble`
- [x] `_ConvAppBar` shows peer name + Online + camera-icon stub (wired in P13)
- [x] `_QuickReplies` row with 3 ActionChips that `sendMessage` on tap
- [x] `_SystemBubble` is centred grey pill (light + dark themed)
- [x] `StreamMessageInput` underneath quick replies
- [x] `sendSystemMessage({memberUid, trainerUid, text})` helper exported for approve/decline use cases
- [x] Per-app `ConversationPage` wraps `ConversationView` in `StreamChatTheme` so own-message bubbles match the role's primary (guru blue / trainer red); other-message bubbles match the surface color of the active light/dark theme
- [x] `flutter analyze` shared + both apps → No issues
- [x] `flutter test` shared still 12/12
- [ ] **Runtime not verified**: real Stream creds still needed (same blocker as P08/P09).
- [x] `feat(chat-conv): StreamMessageListView + quick replies + system bubble [AI]`

## P11 — Flutter: Scheduler + Request Flow
- [x] `ApiClient.getList()` (paid down P06 list-endpoint debt)
- [x] `CallRequestEntity` + `canJoinCall(r)` (shared)
- [x] `CallRequestRepository` (create/getForMember/getForTrainer/updateStatus) + `RoomRepository.create` (shared)
- [x] `generateSlots(date)` 30-min slots between `slotStartHour`/`slotEndHour` (shared)
- [x] Guru `SchedulerCubit` — form state (date/slot/note/submitStatus) with past-slot / 140-char / no-slot guards
- [x] Guru `MyRequestsCubit` = `Cubit<ApiStatus<List<CallRequestEntity>>>`
- [x] Guru `SchedulerPage` — day chips (Today/Tomorrow/+2), 30-min slot wrap (past = greyed, no-tap), 140-char note, submit button → snackbar + `ctx.go('/requests')`
- [x] Guru `MyRequestsPage` — list with status badge (Pending⏳ / Approved✓ / Declined+reason) + Join Call button when `canJoinCall`
- [x] Guru router: added `/requests` route
- [x] Trainer `RequestsBloc` — events Loaded/Approved/Declined, state holds list + `processingIds` set + last error
- [x] Approve flow wires: `POST /rooms` → `PATCH /call-requests/:id status=approved` → `sendSystemMessage("Call approved for …")` → reload
- [x] Decline flow wires: `PATCH … status=declined declineReason=…` → `sendSystemMessage("Call request declined. Reason: …")` → reload
- [x] Trainer `RequestsPage` — Pending / All tabs, per-row spinner via `processingIds`, decline reason bottom sheet
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared 12/12 ; guru 3/3 SchedulerCubit blocTests
- [ ] **Runtime gaps** (in ledger #12):
  - Approve `POST /rooms` returns 500 against placeholder 100ms creds — approve flow surfaces error snackbar.
  - `sendSystemMessage` no-ops/errors against placeholder Stream creds; wrapped in try/catch so the underlying PATCH still succeeds.
  - Local notification to DK on approve = P14 work.
- [x] `feat(scheduler): SchedulerCubit + RequestsBloc + backend calls [AI]`

## P12 — Flutter: Pre-Join Screen + Permissions
- [x] `PreJoinCubit` fetches `GET /rooms?callRequestId=…` and emits `ApiSuccess<String>(hmsRoomId)`
- [x] "Ready to join? Check mic and camera." rendered on `ApiSuccess`
- [x] Mic / Camera toggles flip icon + active border (light + dark theme aware)
- [x] Join button disabled while room is loading and while `CallBloc` is in `ApiLoading`
- [x] `CallBloc` stub emits `ApiSuccess` so router can advance; full 100ms wiring is P13
- [x] `requestCallAndNavigate(ctx, …)` shared helper requests mic+cam, navigates `/pre-join?callRequestId=…&role=…`
- [x] Guru `MyRequestsPage` Join Call → permission-gated nav
- [x] Trainer `RequestsPage` All-tab approved row → Join Call (permission-gated, role='trainer')
- [x] Both apps' router `/pre-join` reads `callRequestId` query param (renamed from `roomId`)
- [x] Cancel pops back via `context.pop()`
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared 12/12 ; guru 3/3
- [x] Both apps materialized via `flutter create --platforms=android,ios --org=dev.ramandeep .` — `9c888c4`
- [x] AndroidManifest: 6 `<uses-permission>` entries (INTERNET / CAMERA / RECORD_AUDIO / MODIFY_AUDIO_SETTINGS / FOREGROUND_SERVICE / BLUETOOTH_CONNECT)
- [x] Android `minSdk = 21` / `targetSdk = 34` (in `app/build.gradle.kts`)
- [x] iOS Info.plist usage descriptions (NSCamera / NSMicrophone / NSBluetoothAlways / NSBluetoothPeripheral)
- [x] iOS Podfile: `platform :ios, '13.0'` + `permission_handler` preprocessor macros
- [ ] **Runtime gap** — `GET /rooms` returns 404 unless a `room_meta` doc has been created via trainer-approve (which itself needs real 100ms creds). End-to-end pre-join can't be validated until those creds drop.
- [x] `feat(call): PreJoinCubit + pre-join screen + permissions [AI]`

## P13 — Flutter: CallBloc + In-Call Screen
- [x] `CallBloc` implements `HMSUpdateListener` — all 14 interface methods stubbed; `onJoin` / `onPeerUpdate` / `onHMSError` / `onReconnecting` / `onReconnected` / `onTrackUpdate` / `onPeerListUpdate` / `onRemovedFromRoom` are wired
- [x] State: `CallState(phase, peers, isMuted, isVideoOff, joinedAt, errorMessage)` with `CallPhase = idle | joining | inCall | ended | failed`
- [x] Events: `CallJoinRequested` (fetches `/hms-token?roomId=…&role=…` → `HMSSDK.join`) · `CallEndRequested` · `CallMuteToggled` · `CallVideoToggled` · `CallCameraFlipped` · internal `CallHms*` events fired from listener callbacks
- [x] `CallView` (shared): full-screen remote `HMSTextureView`, PiP local view, peer-name + live MM:SS timer, reconnecting overlay on `CallPhase.joining` after `joinedAt` is set, 4 controls (mute/video/flip/end)
- [x] PreJoinView + CallView swap inside one route (preserves `CallBloc` across the join → in-call transition; `pushReplacement` would have destroyed it)
- [x] On `CallPhase.ended` / `CallPhase.failed` with `joinedAt` set → `pushReplacement('/post-call', extra: SessionLogDraft(...))`
- [x] `SessionLogDraft` model added (used by post-call in P14)
- [x] hmssdk_flutter + collection added to shared/pubspec
- [x] `flutter analyze` shared + both apps → No issues
- [x] `flutter test` shared 18/18 (12 prior + 6 new CallBloc blocTests: token-failure / connected / reconnecting / reconnected / terminal-failure / non-terminal-failure no-op) ; guru 3/3
- [ ] **Runtime not verified** — requires real 100ms creds + a real `room_meta` doc created via approve flow. Same blocker chain as P11/P12. Code structurally complete.
- [ ] Camera icon in chat AppBar (brief: "wire now") — left as no-op for now; looking up the active approved request from inside a stateless AppBar action wants an async repo lookup, will fold into P14.
- [x] `feat(call): CallBloc + 100ms in-call screen [AI]`

## P14 — Flutter: Session Logs + Post-Call
- [x] `SessionLogEntity` + `SessionLogRepository` (create / getForUser / update) in shared, uses `getList()`
- [x] `PostCallCubit` — auto-creates session log on init, then `setRating/setMemberNote/setTrainerNote/save()`; phase enum (`creating | ready | saving | saved | failed`)
- [x] `SessionLogsCubit` — `ApiStatus<List<…>>` + `LogFilter` (`all | last7Days | thisMonth`) + `displayed` getter sorted newest-first
- [x] `PostCallView` (shared) — member sheet (5-star rating + note + "Submit Rating"), trainer sheet (notes + "Mark as Complete"). Snackbar "Session saved to your logs." then `go('/sessions')` on `phase=saved`.
- [x] `SessionsView` (shared) — filter chips, skeleton/error/empty/data, list tiles, draggable detail modal with "Rate Now" (member, when no rating) and "Save Notes" (both roles)
- [x] Per-app `PostCallPage` reads `SessionLogDraft` from `state.extra`; redirects if missing memberId/trainerId
- [x] Per-app `SessionsPage` provides `SessionLogsCubit` and shows `SessionsView`
- [x] `SessionLogDraft.memberId` / `.trainerId` now threaded properly: `requestCallAndNavigate(memberId, trainerId)` → `/pre-join?…&memberId=&trainerId=` → `PreJoinPage(memberId, trainerId)` → `PreJoinView` constructs the draft with the correct ids
- [x] Both Join Call call sites (guru `MyRequestsPage`, trainer `RequestsPage` All-tab) now pass `request.memberId` + `request.trainerId`
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared 24/24 (18 prior + 3 PostCallCubit + 3 SessionLogsCubit) ; guru 3/3
- [ ] **Runtime not verified end-to-end** — session-log creation hits the live backend (works against P05's `/session-logs` route), but the upstream flow that produces a `SessionLogDraft` requires the call flow to actually complete, which is still gated on real 100ms creds.
- [x] `feat(sessions): PostCallCubit + SessionLogsCubit + backend calls [AI]`

## P15 — Flutter: Local Notifications
- [x] `NotificationService` (shared): `initialize()` / `show()` / `schedule()` / `cancel()`, timezone via `flutter_timezone`
- [x] `NotifId` constants (`callApproved` / `callDeclined` / `callReminder` / `newMessage`)
- [x] `await NotificationService.instance.initialize();` in both `main()` — logs `[NOTIF] initialized`
- [x] AndroidManifest: `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` / `RECEIVE_BOOT_COMPLETED` / `POST_NOTIFICATIONS`; `ScheduledNotificationReceiver` + boot receiver inside `<application>`
- [x] `MyRequestsCubit` (guru) is now **diff-aware**: tracks previous list, fires `callApproved` + scheduled `callReminder` (10-min) on pending→approved, and `callDeclined` (with reason) on pending→declined
- [x] `StreamChatService.connect` subscribes to `EventType.messageNew` → fires `newMessage` notification when own-user mismatched AND app not in foreground
- [x] Subscription canceled on `disconnect`
- [x] flutter_local_notifications / timezone / flutter_timezone added to `shared/pubspec.yaml`
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared 24/24 ; guru 3/3
- [ ] **Runtime not verified** — needs a device / emulator with `flutter run`.
- [ ] **iOS prompt at startup** — using lazy `DarwinInitializationSettings()`; pass `requestAlertPermission: true` etc. if you want the prompt at boot.
- [ ] Notification tap deep-linking — currently just logs the payload; P17 work.
- [x] `feat(notif): local notifications for calls + Stream Chat messages [AI]`

## P16 — Debug Logging + Sensitive Data Masking
- [x] `LogMask` (shared/utils/log_mask.dart) — `token` / `uid` / `secret` / `email` / `url`
- [x] `AppLogger` switched to `logger ^2.4.0` with PrettyPrinter + emojis + colors; new methods `i / w / e / t` (`log` kept as `@Deprecated` alias to keep the old test green)
- [x] `LogTag` extended with `nav` and `api`
- [x] `ApiClient` logs every request via `LogMask.url(method, path)`; `_handle` logs failures as `HTTP <code> <masked> — <msg>`
- [x] `ApiClient.saveToken` / `clearToken` log via `LogMask.token`; `_headers` getter logs nothing
- [x] `AuthRepository.login` masks `uid` + `email`
- [x] `StreamChatService.connect` masks `uid`
- [x] `CallBloc._onJoin` masks hms-token + caller uid
- [x] Backend `index.js` request middleware masks `Authorization` header (`Bearer ****xxxx`)
- [x] Backend `auth.js` / `hms_token.js` / `stream_token.js` mask `uid` to `xxx***xxx`
- [x] All 31 `AppLogger.log(...)` call sites migrated to `.i/.w/.e/.t` (test file kept on `log()` to exercise the deprecated alias)
- [x] Codebase grep for `token=$/idToken=$/password=$/uid=${...}` in log strings → zero hits
- [x] `flutter analyze` shared + guru + trainer → No issues
- [x] `flutter test` shared 29/29 (24 prior + 5 LogMask)
- [x] `feat(logging): AppLogger + LogMask sensitive data masking [AI]`

## P17 — TBD (filled in as briefs arrive)
