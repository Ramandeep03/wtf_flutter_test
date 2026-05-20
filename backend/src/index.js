require('dotenv').config();
const express = require('express');
const cors    = require('cors');

require('./config/firebase');

const app = express();
app.use(cors());
app.use(express.json());

// Request logger — masks Authorization header so the raw idToken
// never lands in stdout / log files.
app.use((req, _res, next) => {
  const h = req.headers.authorization;
  const auth = h ? `Bearer ****${h.slice(-4)}` : 'none';
  console.log(`[API] ${req.method} ${req.path} auth=${auth}`);
  next();
});

app.get('/health', (_, res) => res.json({ status: 'ok', ts: new Date().toISOString() }));

// Route stubs (real handlers added per part — see CHECKLIST.md)
app.use('/auth',          require('./routes/auth'));
app.use('/users',         require('./routes/users'));
app.use('/call-requests', require('./routes/call_requests'));
app.use('/session-logs',  require('./routes/session_logs'));
app.use('/rooms',         require('./routes/rooms'));
app.use('/hms-token',     require('./routes/hms_token'));
app.use('/stream-token',  require('./routes/stream_token'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on :${PORT}`));
