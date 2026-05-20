const express = require('express');
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
router.use(verifyToken);

// POST /session-logs
// Body: { memberId, trainerId, startedAt, endedAt, durationSec }
router.post('/', async (req, res) => {
  try {
    const { memberId, trainerId, startedAt, endedAt, durationSec } = req.body;
    if (!memberId || !trainerId || !startedAt || !endedAt || durationSec == null) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const id = uuidv4();
    const log = {
      id, memberId, trainerId, startedAt, endedAt, durationSec,
      rating: null, memberNotes: null, trainerNotes: null,
    };
    await db.collection('session_logs').doc(id).set(log);
    console.log(`[RTC] session log created id=${id}`);
    res.status(201).json(log);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /session-logs?userId=
router.get('/', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ error: 'userId required' });

    const [asMember, asTrainer] = await Promise.all([
      db.collection('session_logs').where('memberId', '==', userId).orderBy('startedAt', 'desc').get(),
      db.collection('session_logs').where('trainerId', '==', userId).orderBy('startedAt', 'desc').get(),
    ]);

    const all = [...asMember.docs, ...asTrainer.docs]
      .map((d) => d.data())
      .sort((a, b) => b.startedAt.localeCompare(a.startedAt));

    // deduplicate by id (in case userId is both member and trainer of the same log — defensive)
    const seen = new Set();
    const unique = all.filter((l) => {
      if (seen.has(l.id)) return false;
      seen.add(l.id);
      return true;
    });
    res.json(unique);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PATCH /session-logs/:id
// Body: { rating?, memberNotes?, trainerNotes? }
router.patch('/:id', async (req, res) => {
  try {
    const ref = db.collection('session_logs').doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });

    const { rating, memberNotes, trainerNotes } = req.body;
    const updates = {};
    if (rating       != null) updates.rating       = rating;
    if (memberNotes  != null) updates.memberNotes  = memberNotes;
    if (trainerNotes != null) updates.trainerNotes = trainerNotes;
    await ref.update(updates);
    res.json({ ...doc.data(), ...updates });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
