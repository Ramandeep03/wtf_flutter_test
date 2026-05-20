const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

/// Resolves the Firebase service account from one of:
///   1. FIREBASE_SERVICE_ACCOUNT_B64   — base64-encoded JSON in env var
///                                       (preferred for hosted runtimes
///                                       like Fly.io / Render where you
///                                       can't ship a file in the repo).
///   2. FIREBASE_SERVICE_ACCOUNT_KEY   — filesystem path to a JSON file
///                                       (local dev — defaults to
///                                       `./serviceAccountKey.json`).
function loadServiceAccount() {
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_B64;
  if (b64 && b64.trim().length > 0) {
    return JSON.parse(Buffer.from(b64, 'base64').toString('utf-8'));
  }
  const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY
    || './serviceAccountKey.json';
  const resolved = path.resolve(process.cwd(), keyPath);
  return JSON.parse(fs.readFileSync(resolved, 'utf-8'));
}

const serviceAccount = loadServiceAccount();

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db   = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
