const express = require('express');
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
router.use(verifyToken);

// POST /call-requests
// Body: { memberId, trainerId, note, scheduledFor }
router.post('/', async (req, res) => {
  try {
    const { memberId, trainerId, note, scheduledFor } = req.body;
    if (!memberId || !trainerId || !scheduledFor) {
      return res.status(400).json({ error: 'memberId, trainerId, scheduledFor required' });
    }

    // Conflict check — is this slot already approved?
    const conflict = await db.collection('call_requests')
      .where('trainerId', '==', trainerId)
      .where('status', '==', 'approved')
      .where('scheduledFor', '==', scheduledFor)
      .get();
    if (!conflict.empty) {
      return res.status(409).json({ error: 'Slot already booked' });
    }

    const id = uuidv4();
    const request = {
      id,
      memberId,
      trainerId,
      note: note || '',
      scheduledFor,
      requestedAt: new Date().toISOString(),
      status: 'pending',
      declineReason: null,
    };
    await db.collection('call_requests').doc(id).set(request);
    console.log(`[SCHEDULE] created id=${id}`);
    res.status(201).json(request);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /call-requests?memberId=&trainerId=
router.get('/', async (req, res) => {
  try {
    const { memberId, trainerId } = req.query;
    let query = db.collection('call_requests').orderBy('requestedAt', 'desc');
    if (memberId) query = query.where('memberId', '==', memberId);
    if (trainerId) query = query.where('trainerId', '==', trainerId);
    const snap = await query.get();
    res.json(snap.docs.map((d) => d.data()));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PATCH /call-requests/:id
// Body: { status, declineReason? }
router.patch('/:id', async (req, res) => {
  try {
    const { status, declineReason } = req.body;
    const allowed = ['pending', 'approved', 'declined', 'cancelled'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const ref = db.collection('call_requests').doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });

    const updates = { status };
    if (declineReason) updates.declineReason = declineReason;
    await ref.update(updates);

    console.log(`[SCHEDULE] updated id=${req.params.id} status=${status}`);
    res.json({ ...doc.data(), ...updates });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
