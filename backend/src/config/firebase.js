// P02 will load the service account and call admin.initializeApp().
// Stub kept so index.js requires resolve cleanly.

const admin = require('firebase-admin');

let initialized = false;

function init() {
  if (initialized) return admin;
  // const serviceAccount = require(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_KEY));
  // admin.initializeApp({
  //   credential: admin.credential.cert(serviceAccount),
  //   projectId: process.env.FIREBASE_PROJECT_ID,
  // });
  initialized = true;
  return admin;
}

module.exports = { admin, init };
