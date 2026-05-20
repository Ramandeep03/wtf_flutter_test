const express = require('express');
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken);

// GET /users   (list all — Trainer needs member list)
router.get('/', async (_req, res) => {
  try {
    const snap = await db.collection('users').get();
    res.json(snap.docs.map((d) => ({ uid: d.id, ...d.data() })));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /users/:uid
router.get('/:uid', async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.params.uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });
    res.json({ uid: doc.id, ...doc.data() });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
