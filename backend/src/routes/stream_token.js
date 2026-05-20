const express = require('express');
const { StreamChat } = require('stream-chat');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken);

// GET /stream-token
router.get('/', (req, res) => {
  const client = StreamChat.getInstance(
    process.env.STREAM_API_KEY,
    process.env.STREAM_API_SECRET
  );
  const token = client.createToken(req.uid);
  console.log(`[CHAT] stream token issued uid=${req.uid.slice(0, 3)}***${req.uid.slice(-3)}`);
  res.json({ token });
});

module.exports = router;
