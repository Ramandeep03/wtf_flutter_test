require('dotenv').config();
const { auth, db } = require('./src/config/firebase');

async function seed() {
  // Create Aarav (trainer)
  const aarav = await auth.createUser({
    email: 'aarav@wtf.fit',
    password: 'Wtf@1234',
    displayName: 'Aarav',
  });
  await db.collection('users').doc(aarav.uid).set({
    uid: aarav.uid,
    name: 'Aarav',
    email: 'aarav@wtf.fit',
    role: 'trainer',
    createdAt: new Date().toISOString(),
  });

  // Create DK (member, assigned to Aarav)
  const dk = await auth.createUser({
    email: 'dk@wtf.fit',
    password: 'Wtf@1234',
    displayName: 'DK',
  });
  await db.collection('users').doc(dk.uid).set({
    uid: dk.uid,
    name: 'DK',
    email: 'dk@wtf.fit',
    role: 'member',
    assignedTrainerId: aarav.uid,
    createdAt: new Date().toISOString(),
  });

  console.log('Seeded:', { aarav: aarav.uid, dk: dk.uid });
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
