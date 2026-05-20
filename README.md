# WTF Flutter Test — Guru / Trainer Monorepo

Two Flutter apps (**guru_app**, **trainer_app**) talking to a single **Node.js backend**.
Backend is the *only* place Firebase Admin, 100ms, and Stream Chat server secrets live.
Flutter clients never import `firebase_auth` or `cloud_firestore` directly.

# Links for Live APK
1. [Guru_App](https://drive.google.com/file/d/1GrzUjTv1PufXmGShHcRZVyUeJePZB-hF/view?usp=sharing)
2. [Trainer_app](https://drive.google.com/file/d/1hyCHwS_P6zncntuvgF8oo3uuMhuSd3cM/view?usp=sharing)

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

### From VS Code (recommended)
Open the workspace in VS Code, then use the **Run and Debug** panel (Cmd+Shift+D). Configs:

| Config | What it does |
|---|---|
| **Backend (npm run dev)** | Launches the Node server with nodemon; loads `backend/.env`. |
| **Guru App** | `flutter run` against `guru_app/`, on the device currently selected in VS Code. |
| **Trainer App** | Same, against `trainer_app/`. |
| **Backend + Guru** *(compound)* | Backend + Guru together; Stop button stops both. |
| **Backend + Trainer** *(compound)* | Backend + Trainer together. |

Both Flutter configs pass `--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000` (Android emulator default). For an iOS sim or a physical device, edit `.vscode/launch.json` to use `http://localhost:3000` or your LAN IP.

#### Building release APKs
Cmd+Shift+P → **Tasks: Run Task**:

| Task | Output |
|---|---|
| **Build Guru APK (release)** | `guru_app/build/app/outputs/flutter-apk/app-release.apk` |
| **Build Trainer APK (release)** | `trainer_app/build/app/outputs/flutter-apk/app-release.apk` |
| **Build BOTH APKs (release)** | both, sequentially — also the default `Cmd+Shift+B` build task |
| **Backend: npm install** | runs `npm install` in `backend/` |

> Android-specific: APKs are signed with the debug keystore so `flutter run --release` works without setup. For a real release sign, add a signing config to `guru_app/android/app/build.gradle.kts` (and trainer's).

#### `.vscode/launch.json` (copy-paste — replace `YOUR_STREAM_KEY`)
```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Backend (npm run dev)",
      "type": "node",
      "request": "launch",
      "cwd": "${workspaceFolder}/backend",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "envFile": "${workspaceFolder}/backend/.env",
      "console": "integratedTerminal",
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "name": "Guru App",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/guru_app",
      "program": "lib/main.dart",
      "flutterMode": "debug",
      "toolArgs": [
        "--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=STREAM_CHAT_API_KEY=YOUR_STREAM_KEY"
      ]
    },
    {
      "name": "Trainer App",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/trainer_app",
      "program": "lib/main.dart",
      "flutterMode": "debug",
      "toolArgs": [
        "--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=STREAM_CHAT_API_KEY=YOUR_STREAM_KEY"
      ]
    },
        {
      "name": "Guru App (Release)",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/guru_app",
      "program": "lib/main.dart",
      "flutterMode": "release",
      "toolArgs": [
        "--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=STREAM_CHAT_API_KEY=YOUR_STREAM_KEY"
      ]
    },
    {
      "name": "Trainer App (Release)",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/trainer_app",
      "program": "lib/main.dart",
      "flutterMode": "release",
      "toolArgs": [
        "--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=STREAM_CHAT_API_KEY=YOUR_STREAM_KEY"
      ]
    }
  ],
  "compounds": [
    {
      "name": "Backend + Guru",
      "configurations": ["Backend (npm run dev)", "Guru App"],
      "stopAll": true
    },
    {
      "name": "Backend + Trainer",
      "configurations": ["Backend (npm run dev)", "Trainer App"],
      "stopAll": true
    }
  ]
}
```

#### `.vscode/tasks.json` (copy-paste — replace `YOUR_STREAM_KEY`)
```jsonc
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Guru APK (release)",
      "type": "shell",
      "command": "flutter",
      "args": [
        "build", "apk", "--release",
        "--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=STREAM_CHAT_API_KEY=YOUR_STREAM_KEY"
      ],
      "options": { "cwd": "${workspaceFolder}/guru_app" },
      "problemMatcher": [],
      "presentation": { "panel": "dedicated", "reveal": "always", "clear": true },
      "group": "build"
    },
    {
      "label": "Build Trainer APK (release)",
      "type": "shell",
      "command": "flutter",
      "args": [
        "build", "apk", "--release",
        "--dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=STREAM_CHAT_API_KEY=YOUR_STREAM_KEY"
      ],
      "options": { "cwd": "${workspaceFolder}/trainer_app" },
      "problemMatcher": [],
      "presentation": { "panel": "dedicated", "reveal": "always", "clear": true },
      "group": "build"
    },
    {
      "label": "Build BOTH APKs (release)",
      "dependsOn": ["Build Guru APK (release)", "Build Trainer APK (release)"],
      "dependsOrder": "sequence",
      "problemMatcher": [],
      "group": { "kind": "build", "isDefault": true }
    },
    {
      "label": "Backend: npm install",
      "type": "shell",
      "command": "npm",
      "args": ["install"],
      "options": { "cwd": "${workspaceFolder}/backend" },
      "problemMatcher": []
    }
  ]
}
```

> `YOUR_STREAM_KEY` is your Stream Chat publishable API key from the Stream dashboard (App Access Keys). The Stream **secret** must stay in `backend/.env` only.

### From the terminal

#### Backend
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

[Guru_App](https://youtu.be/MRfmOMh8dJc)
[Trainer_app](https://youtu.be/GiqmQclHv28)

## Living docs

| File | Purpose |
|------|---------|
| `ARCHITECTURE.md` | Flow diagram + BLoC layer map |
| `DECISIONS.md` | ADRs |
| `AI_LEDGER.md` | Every AI-assisted change |
| `CHECKLIST.md` | P01–P17 progress |
| `COMMIT_PATTERN.md` | Commit-message rule |
