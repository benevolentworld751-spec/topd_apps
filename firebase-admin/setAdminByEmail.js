
// setAdminByEmail.js
const admin = require('firebase-admin');
const path = require('path');

// Correct path to your service account JSON
const serviceAccount = require(path.join(__dirname, 'serviceAccount/serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Replace with the email of the user you want to make admin
const EMAIL = "admin@topdworld.com";

admin.auth().getUserByEmail(EMAIL)
  .then((userRecord) => {
    return admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
  })
  .then(() => {
    console.log(`✅ Admin claim added successfully for email: ${EMAIL}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Error setting admin claim by email:", error);
    process.exit(1);
  });
