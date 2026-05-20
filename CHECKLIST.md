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

## P07–P17 — TBD (filled in as briefs arrive)
