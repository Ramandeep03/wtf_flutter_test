const router = require('express').Router();

// Implemented in a later phase. See CHECKLIST.md.
router.all('/', (_req, res) => res.status(501).json({ error: 'call_requests_not_implemented' }));

module.exports = router;
