# Backend

Express + Firebase Admin. Owns all Firestore writes, 100ms token minting, and Stream Chat user tokens.

## Run

```bash
cp .env.example .env
# drop your Firebase service account JSON next to package.json as serviceAccountKey.json
npm install
npm run dev      # http://localhost:3000
```

## Routes (P01 stubs — implemented in later phases)

| Method | Path | Phase |
|--------|------|-------|
| POST   | `/auth/signup`      | P03 |
| POST   | `/auth/login`       | P03 |
| GET    | `/auth/me`          | P03 |
| GET/POST/PATCH | `/users`    | P04 |
| CRUD   | `/call_requests`    | P07 |
| GET/POST | `/session_logs`   | P08 |
| POST   | `/rooms`            | P06 |
| POST   | `/hms_token`        | P06 |
| POST   | `/stream_token`     | P05 |
| GET    | `/health`           | P02 |

Auth middleware (`src/middleware/auth.js`) verifies `Authorization: Bearer <Firebase ID token>` on protected routes.
