require('dotenv').config();

const express = require('express');
const cors = require('cors');

require('./config/firebase');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const callRequestRoutes = require('./routes/call_requests');
const sessionLogRoutes = require('./routes/session_logs');
const roomRoutes = require('./routes/rooms');
const hmsTokenRoutes = require('./routes/hms_token');
const streamTokenRoutes = require('./routes/stream_token');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/call_requests', callRequestRoutes);
app.use('/session_logs', sessionLogRoutes);
app.use('/rooms', roomRoutes);
app.use('/hms_token', hmsTokenRoutes);
app.use('/stream_token', streamTokenRoutes);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`backend listening on :${port}`));
