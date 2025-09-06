const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * 1) Notify all members when a match becomes approved
 */
exports.sendMatchStatusNotification = functions.firestore
  .document("matches/{matchId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return null;

    // Accept either 'approved' (your schema) or 'confirmed' (legacy string)
    const becameApproved =
      before.status !== after.status &&
      (after.status === "approved" || after.status === "confirmed");

    if (!becameApproved) return null;

    const members = Array.isArray(after.members) ? after.members : [];
    if (!members.length) return null;

    // Collect tokens for every member
    const userSnaps = await Promise.all(
      members.map((uid) => db.collection("users").doc(uid).get())
    );
    const tokens = userSnaps.map((s) => s.get("fcmToken")).filter(Boolean);
    if (!tokens.length) return null;

    const payload = {
      notification: {
        title: "Match Confirmed 🎉",
        body: `Your match "${after.matchTitle}" is confirmed. Get ready!`,
      },
      data: {
        type: "matchApproved",
        matchId: context.params.matchId,
        deepLink: `playpal://match/${context.params.matchId}`,
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    };

    const res = await admin.messaging().sendToDevice(tokens, payload);

    // Optional: clean invalid tokens
    const cleanup = [];
    res.results.forEach((r, i) => {
      const e = r.error;
      if (
        e &&
        (e.code === "messaging/invalid-registration-token" ||
          e.code === "messaging/registration-token-not-registered")
      ) {
        cleanup.push(
          db
            .collection("users")
            .doc(members[i])
            .update({ fcmToken: admin.firestore.FieldValue.delete() })
        );
      }
    });
    await Promise.all(cleanup);
    return null;
  });

/**
 * 2) Notify the specific player when admin verifies/rejects their payment
 *    watches: matches/{matchId}/payments/{userId}
 *    Expect the admin to set: { status: "verified" | "rejected", adminComment?: string }
 */
exports.sendPaymentDecisionNotification = functions.firestore
  .document("matches/{matchId}/payments/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return null;

    // Prefer a 'status' field. If you only have a boolean 'verified', map it.
    const beforeStatus =
      typeof before.status === "string"
        ? before.status
        : before.verified
        ? "verified"
        : "pending";

    const afterStatus =
      typeof after.status === "string"
        ? after.status
        : after.verified === true
        ? "verified"
        : "pending";

    if (beforeStatus === afterStatus) return null;
    if (!["verified", "rejected"].includes(afterStatus)) return null;

    const { userId, matchId } = context.params;

    // Fetch that player's FCM token
    const userDoc = await db.collection("users").doc(userId).get();
    const token = userDoc.get("fcmToken");
    if (!token) return null;

    const title =
      afterStatus === "verified" ? "Payment Verified ✅" : "Payment Rejected ❌";
    const body =
      afterStatus === "verified"
        ? "Your payment was verified. See details."
        : `Your payment was rejected${
            after.adminComment ? `: ${after.adminComment}` : ""
          }`;

    // Push notification
    await admin.messaging().sendToDevice(token, {
      notification: { title, body },
      data: {
        type: "paymentDecision",
        status: afterStatus,
        matchId,
        deepLink: `playpal://match/${matchId}?tab=payments`,
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });

    // Optional: also write an in-app notification (for a bell/badge in UI)
    await db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        type: "paymentDecision",
        matchId,
        status: afterStatus,
        title,
        body,
        deepLink: `playpal://match/${matchId}?tab=payments`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

    return null;
  });
