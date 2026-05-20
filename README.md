# WTF Flutter Test — Guru / Trainer Monorepo

Two Flutter apps (**guru_app**, **trainer_app**) talking to a single **Node.js backend**.
Backend is the *only* place Firebase Admin, 100ms, and Stream Chat server secrets live.
Flutter clients never import `firebase_auth` or `cloud_firestore` directly.

## Architecture (one rule)

```
Flutter  →  HTTP  →  Node.js Backend  →  Firebase Admin SDK  →  Firestore
                                     →  100ms REST
                                     →  Stream Chat server
```

See `ARCHITECTURE.md` for the full diagram and BLoC layer map.

## Repo layout

```
backend/      Node.js — Firebase Admin, 100ms, Stream Chat (server)
shared/       Dart package — models, abstract services, utils, widgets
guru_app/     Flutter app (end users)
trainer_app/  Flutter app (trainers)
```

## First-time setup

### 1. Firebase project
1. [Firebase Console](https://console.firebase.google.com/) → **Add project** → name `wtf-fitness`.
2. **Build → Firestore Database** → *Create database* → **Native mode**, region `us-central1`.
3. **Build → Authentication** → *Get started* → enable **Email/Password**.
4. **⚙ Project settings → Service accounts** → *Generate new private key* → save the JSON as `backend/serviceAccountKey.json` (gitignored).

### 2. Backend
```bash
cd backend
cp .env.example .env          # fill in real values
npm install
node seed.js                  # ONCE only — creates Aarav (trainer) + DK (member); save the printed UIDs
npm run dev                   # http://localhost:3000
curl http://localhost:3000/health
# → {"status":"ok","ts":"..."}
```

### 3. Deploy Firestore rules (deny-all, all access via Admin SDK)
```bash
npm i -g firebase-tools       # one-time
firebase login
firebase use --add            # pick the wtf-fitness project
firebase deploy --only firestore:rules
```

### 4. Seed credentials (after step 2)
| User  | Role    | Email           | Password   |
|-------|---------|-----------------|------------|
| Aarav | trainer | aarav@wtf.fit   | `Wtf@1234` |
| DK    | member  | dk@wtf.fit      | `Wtf@1234` |

DK's `assignedTrainerId` is set to Aarav's UID. UIDs are also written locally to `backend/.seed-uids.local` (gitignored).

> **Note:** `seed.js` is non-idempotent — re-running fails with `auth/email-already-exists`. If you need to re-seed, delete the users in Firebase Console → Authentication first.

## Run (after first-time setup)

### Backend
```bash
cd backend
npm run dev                   # http://localhost:3000
```

### Guru app
```bash
cd guru_app
cp ../.env.example .env       # set BACKEND_BASE_URL=http://10.0.2.2:3000 for Android emu
flutter pub get
flutter run
```

### Trainer app
```bash
cd trainer_app
cp ../.env.example .env
flutter pub get
flutter run
```

## Env setup

- `backend/.env` — Firebase project id, service-account path, 100ms keys, Stream keys, Firebase Web API key.
- Root `.env.example` — copied into each Flutter app; holds `BACKEND_BASE_URL` and `STREAM_CHAT_API_KEY` (publishable only).

## Demo

_Demo link: TBD (added in P17)._ 

## Living docs

| File | Purpose |
|------|---------|
| `ARCHITECTURE.md` | Flow diagram + BLoC layer map |
| `DECISIONS.md` | ADRs |
| `AI_LEDGER.md` | Every AI-assisted change |
| `CHECKLIST.md` | P01–P17 progress |
| `COMMIT_PATTERN.md` | Commit-message rule |
