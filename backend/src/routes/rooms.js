const express = require('express');
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { managementToken } = require('../services/hms');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
router.use(verifyToken);

// POST /rooms
// Body: { callRequestId, name? }
// Creates 100ms room, saves RoomMeta, returns it.
router.post('/', async (req, res) => {
  try {
    const { callRequestId, name } = req.body;
    if (!callRequestId) return res.status(400).json({ error: 'callRequestId required' });

    const mgmt = managementToken();
    const hmsRes = await fetch('https://api.100ms.live/v2/rooms', {
      method: 'POST',
      headers: { Authorization: `Bearer ${mgmt}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: name || `room-${uuidv4()}`,
        template_id: process.env.HMS_TEMPLATE_ID,
      }),
    });
    const hmsData = await hmsRes.json();
    if (!hmsRes.ok) return res.status(500).json({ error: hmsData.message || '100ms error' });

    const meta = {
      id: uuidv4(),
      callRequestId,
      hmsRoomId: hmsData.id,
      hmsRoleMember: 'member',
      hmsRoleTrainer: 'trainer',
    };
    await db.collection('room_meta').doc(meta.id).set(meta);
    console.log(`[RTC] room created hmsRoomId=${hmsData.id}`);
    res.status(201).json(meta);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /rooms?callRequestId=
router.get('/', async (req, res) => {
  try {
    const { callRequestId } = req.query;
    if (!callRequestId) return res.status(400).json({ error: 'callRequestId required' });

    const snap = await db.collection('room_meta')
      .where('callRequestId', '==', callRequestId)
      .limit(1)
      .get();
    if (snap.empty) return res.status(404).json({ error: 'Room not found' });
    res.json(snap.docs[0].data());
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
