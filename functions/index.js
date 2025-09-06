const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.verifyTestUser = functions.https.onRequest(async (req, res) => {
  const uid = req.query.uid;

  if (!uid) {
    return res.status(400).send("Missing UID");
  }

  try {
    const userRecord = await admin.auth().updateUser(uid, {
      emailVerified: true,
    });
    return res.send(`✅ Verified: ${userRecord.email}`);
  } catch (err) {
    return res.status(500).send(`❌ Error: ${err.message}`);
  }
});

