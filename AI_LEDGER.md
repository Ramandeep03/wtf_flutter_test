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
