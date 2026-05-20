const express = require('express');
const { StreamChat } = require('stream-chat');
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken);

const mask = (s) => (s ? `${s.slice(0, 3)}***${s.slice(-3)}` : '???');

// GET /stream-token
//
// Mints a Stream user token for req.uid AND upserts the requesting user
// + their counterpart (member's assignedTrainerId, or trainer's assigned
// members) into Stream — otherwise client.channel(..., members: [...])
// fails with "users involved in channel create operation don't exist".
router.get('/', async (req, res) => {
  try {
    const client = StreamChat.getInstance(
      process.env.STREAM_API_KEY,
      process.env.STREAM_API_SECRET
    );

    const meDoc = await db.collection('users').doc(req.uid).get();
    if (!meDoc.exists) {
      return res.status(404).json({ error: 'User profile not found' });
    }
    const me = meDoc.data();

    // Collect everyone who needs to exist in Stream for this user's chats.
    const peerIds = new Set();
    if (me.role === 'member' && me.assignedTrainerId) {
      peerIds.add(me.assignedTrainerId);
    } else if (me.role === 'trainer') {
      const memberSnap = await db.collection('users')
        .where('assignedTrainerId', '==', req.uid)
        .get();
      memberSnap.docs.forEach((d) => peerIds.add(d.id));
    }

    const users = [{
      id: req.uid,
      name: me.name || me.email || req.uid,
      role: 'user',
    }];

    if (peerIds.size > 0) {
      const peerDocs = await Promise.all(
        [...peerIds].map((id) => db.collection('users').doc(id).get())
      );
      for (const d of peerDocs) {
        if (!d.exists) continue;
        const u = d.data();
        users.push({
          id: d.id,
          name: u.name || u.email || d.id,
          role: 'user',
        });
      }
    }

    await client.upsertUsers(users);

    const token = client.createToken(req.uid);
    console.log(
      `[CHAT] stream token issued uid=${mask(req.uid)} upserted=${users.length}`
    );
    return res.json({ token });
  } catch (e) {
    console.error('[CHAT] stream-token error:', e.message);
    return res.status(500).json({ error: e.message });
  }
});

module.exports = router;
