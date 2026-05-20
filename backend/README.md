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

## API reference

All routes except `/health` and `POST /auth/login` require
`Authorization: Bearer <Firebase ID token>` (middleware attaches `req.uid`).

```
GET    /health                        → { status, ts }

POST   /auth/login                    { email, password } → { idToken, refreshToken, user }
GET    /auth/me                       → user profile

GET    /users                         → all users
GET    /users/:uid                    → one user

POST   /call-requests                 { memberId, trainerId, note, scheduledFor }
GET    /call-requests?memberId=&trainerId=   → filtered list (orderBy requestedAt DESC)
PATCH  /call-requests/:id             { status, declineReason? }

POST   /session-logs                  { memberId, trainerId, startedAt, endedAt, durationSec }
GET    /session-logs?userId=          → user's logs (member + trainer, deduped, sorted)
PATCH  /session-logs/:id              { rating?, memberNotes?, trainerNotes? }

POST   /rooms                         { callRequestId, name? } → room_meta
GET    /rooms?callRequestId=          → room_meta

GET    /hms-token?roomId=&role=       → { token }   (100ms app token, 1h)
GET    /stream-token                  → { token }   (Stream Chat user token)
```

Server logs (greppable): `[AUTH]`, `[SCHEDULE]`, `[RTC]`, `[CHAT]`.
