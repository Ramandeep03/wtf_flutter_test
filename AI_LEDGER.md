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
- **Commit:** `feat(backend): session-logs + rooms + tokens routes [AI]`
