# Checklist

## P01 — Scaffold + Docs
- [x] All folders created
- [x] Both Flutter pubspecs correct (no `firebase_auth` / `cloud_firestore`)
- [x] All 6 docs written (README, AI_LEDGER, ARCHITECTURE, DECISIONS, CHECKLIST, COMMIT_PATTERN)
- [x] AI_LEDGER Entry #1 logged
- [x] `chore(scaffold): init monorepo backend-first architecture [AI]` — `82424a0`

## P02 — Backend Setup
- [ ] `npm run dev` → server on :3000 _(needs `serviceAccountKey.json` — user)_
- [ ] `curl http://localhost:3000/health` → `{"status":"ok"}` _(needs boot)_
- [x] Firebase Admin SDK code wired (`src/config/firebase.js`)
- [x] Auth middleware verifies Bearer ID tokens (`src/middleware/auth.js`)
- [x] CORS + JSON body parsing in `src/index.js`
- [x] `.env` loaded via `dotenv`
- [x] `seed.js` created (Aarav trainer + DK member)
- [ ] `node seed.js` executed in Firebase project _(needs service account — user)_
- [x] `firestore.rules` (deny-all) committed
- [ ] Firestore rules deployed to project _(needs `firebase-tools` + login — user)_
- [x] `npm install` clean, all files pass `node --check`

## P03 — Auth (Backend + Flutter)
- [ ] Backend `/auth/signup` `/auth/login` `/auth/me`
- [ ] Flutter auth feature in both apps (data/domain/presentation)
- [ ] Token stored in Hive

## P04 — Users (profiles)
- [ ] CRUD `/users` (admin-gated where needed)
- [ ] Profile screens in both apps

## P05 — Stream Chat integration
- [ ] `/stream_token` mints user tokens
- [ ] `stream_chat_flutter` wired into both apps

## P06 — 100ms calls
- [ ] `/rooms` create
- [ ] `/hms_token` mint
- [ ] Call feature in both apps

## P07 — Call requests (trainer ↔ guru)
- [ ] `/call_requests` CRUD
- [ ] Requests feature in trainer_app, scheduler in guru_app

## P08 — Session logs
- [ ] `/session_logs` create/list
- [ ] Sessions feature in both apps

## P09 — Local notifications
- [ ] Session reminders scheduled
- [ ] Permission flow

## P10 — Theme + shared widgets
## P11 — Routing (go_router)
## P12 — Hive offline cache
## P13 — Error handling + logger
## P14 — Tests (bloc_test + mocktail)
## P15 — Lints + CI
## P16 — Build & sign
## P17 — Demo link + final docs
