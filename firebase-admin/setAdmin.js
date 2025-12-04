//
// #3. Run Scripts (from package.json)
//✔ Run set admin by UID
//npm run setAdminByUID
//
//✔ Run set admin by Email
//npm run setAdminByEmail
//
//✔ Run create folder in storage
//npm run createFolder

// setAdmin.js
const admin = require('firebase-admin');
const path = require('path');

// Correct path to your service account JSON
const serviceAccount = require(path.join(__dirname, 'serviceAccount/serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// ❗ USE UID — not email
const UID = "kgbEJifEBgQ5Wg8r9RT4ZvnsvP03";

admin.auth().setCustomUserClaims(UID, { admin: true })
  .then(() => {
    console.log(`✅ Admin claim added successfully for UID: ${UID}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Error setting admin claim:", error);
    process.exit(1);
  });
