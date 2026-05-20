// P02/P03 will verify Firebase ID tokens with admin.auth().verifyIdToken().
// Stub returns 501 so accidental hits are obvious during P01.

module.exports = function authMiddleware(req, res, next) {
  if (!req.headers.authorization) {
    return res.status(401).json({ error: 'missing_authorization' });
  }
  return res.status(501).json({ error: 'auth_not_implemented_until_P02' });
};
