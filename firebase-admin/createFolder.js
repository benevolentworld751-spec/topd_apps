const { Storage } = require('@google-cloud/storage');
const path = require('path');

// Initialize with service account
const storage = new Storage({
  keyFilename: path.join(__dirname, 'serviceAccount/serviceAccountKey.json'),
});

const bucketName = 'topd-app.firebasestorage.app'; // Correct bucket
const folderName = 'menuImages/';

async function createFolder() {
  try {
    const bucket = storage.bucket(bucketName);
    const file = bucket.file(folderName);

    // Creates zero-byte object to simulate folder
    await file.save('');
    console.log(`✅ Folder '${folderName}' created successfully in bucket '${bucketName}'`);
  } catch (error) {
    console.error('❌ Error creating folders:', error);
  }
}

createFolder();
