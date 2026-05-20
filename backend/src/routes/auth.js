const express = require('express');
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY;

// POST /auth/login
// Body: { email, password }
// Returns: { idToken, refreshToken, user }
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }

  try {
    const firebaseRes = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      }
    );
    const firebaseData = await firebaseRes.json();

    if (!firebaseRes.ok) {
      const msg = firebaseData.error?.message || 'Login failed';
      return res.status(401).json({ error: msg });
    }

    const { idToken, refreshToken, localId: uid } = firebaseData;

    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User profile not found' });
    }

    console.log(`[AUTH] login uid=${uid.slice(0, 3)}***${uid.slice(-3)}`);
    return res.json({ idToken, refreshToken, user: { uid, ...userDoc.data() } });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// GET /auth/me   (protected)
router.get('/me', verifyToken, async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'User not found' });
    return res.json({ uid: req.uid, ...doc.data() });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

module.exports = router;
