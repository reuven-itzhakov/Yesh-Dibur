const admin = require('firebase-admin');

// אטימת אבטחה והכנה ל-Docker/Cloud: משיכת המפתח הסודי ממשתני סביבה ולא מקובץ פיזי
let serviceAccount;
if (process.env.FIREBASE_CREDENTIALS) {
  serviceAccount = JSON.parse(process.env.FIREBASE_CREDENTIALS);
} else {
  // Fallback לסביבת הפיתוח המקומית בלבד
  serviceAccount = require('../../serviceAccountKey.json');
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const messaging = admin.messaging();

module.exports = { auth, messaging };