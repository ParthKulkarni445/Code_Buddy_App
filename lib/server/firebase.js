// firebase.js
const admin = require("firebase-admin");

console.log('Initializing Firebase Admin...');

try {
  const serviceAccount = JSON.parse(process.env.FIREBASE_KEY);
  console.log('Service account parsed successfully');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('Firebase Admin initialized successfully');

  // Export both the admin and Firestore instance
  const db = admin.firestore();
  console.log('Firestore instance created');

  // Test write to verify access
  db.collection('test').doc('test').set({
    timestamp: new Date(),
    test: true
  }).then(() => {
    console.log('Test write successful');
  }).catch(error => {
    console.error('Test write failed:', error);
  });

  module.exports = { admin, db };
} catch (error) {
  console.error('Error initializing Firebase:', error);
  throw error;
}
