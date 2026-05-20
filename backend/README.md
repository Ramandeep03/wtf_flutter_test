# WTF Backend

## Run

```bash
cp .env.example .env          # fill in values
# drop your Firebase service account JSON next to package.json as serviceAccountKey.json
npm install
node seed.js                  # once only — creates Aarav (trainer) + DK (member)
npm run dev                   # development (nodemon)
npm start                     # production
```

## Firestore rules

Deny-all rules (all access via Admin SDK) live in `../firestore.rules`.
Deploy with:

```bash
firebase login
firebase use --add            # pick the wtf-fitness project
firebase deploy --only firestore:rules
```

## Endpoints

| Method | Path | Phase |
|--------|------|-------|
| GET    | `/health`         | P02 (live) |
| ANY    | `/auth/*`         | P03 (501 stub) |
| ANY    | `/users/*`        | P04 (501 stub) |
| ANY    | `/call-requests/*`| P07 (501 stub) |
| ANY    | `/session-logs/*` | P08 (501 stub) |
| ANY    | `/rooms/*`        | P06 (501 stub) |
| ANY    | `/hms-token/*`    | P06 (501 stub) |
| ANY    | `/stream-token/*` | P05 (501 stub) |

Auth middleware (`src/middleware/auth.js`) verifies `Authorization: Bearer <Firebase ID token>` and attaches `req.uid` on protected routes (wired in P03+).
