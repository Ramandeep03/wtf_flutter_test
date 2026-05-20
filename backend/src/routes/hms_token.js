const express = require('express');
const { verifyToken } = require('../middleware/auth');
const { appToken } = require('../services/hms');

const router = express.Router();
router.use(verifyToken);

// GET /hms-token?roomId=&role=
router.get('/', (req, res) => {
  const { roomId, role } = req.query;
  if (!roomId || !role) return res.status(400).json({ error: 'roomId and role required' });
  const token = appToken(req.uid, role, roomId);
  console.log(`[RTC] hms token issued uid=${req.uid} role=${role}`);
  res.json({ token });
});

module.exports = router;
