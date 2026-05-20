const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

function signHms(payload, exp) {
  return jwt.sign(
    {
      ...payload,
      access_key: process.env.HMS_APP_ACCESS_KEY,
      iat: Math.floor(Date.now() / 1000),
      nbf: Math.floor(Date.now() / 1000),
    },
    process.env.HMS_APP_SECRET,
    { algorithm: 'HS256', expiresIn: exp, jwtid: uuidv4() }
  );
}

function managementToken() {
  return signHms({ type: 'management', version: 2 }, '24h');
}

function appToken(userId, role, roomId) {
  return signHms({ user_id: userId, role, room_id: roomId, type: 'app', version: 2 }, '1h');
}

module.exports = { managementToken, appToken };
