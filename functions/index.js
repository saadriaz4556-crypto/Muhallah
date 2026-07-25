const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const cloudinary = require("cloudinary").v2;

admin.initializeApp();
const db = admin.firestore();

// Set up Cloudinary config from environment variables or hardcode for now
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dexamplecloud',
    api_key: process.env.CLOUDINARY_API_KEY || 'YOUR_API_KEY',
    api_secret: process.env.CLOUDINARY_API_SECRET || 'YOUR_API_SECRET'
});

exports.cleanupLocalVibes = onSchedule("every 1 hours", async (event) => {
    const now = admin.firestore.Timestamp.now();
    console.log(`Starting Local Vibes cleanup at ${now.toDate().toISOString()}`);

    try {
        const snapshot = await db.collection("local_vibes_posts")
            .where("expires_at", "<=", now)
            .where("is_deleted", "==", false)
            .get();

        if (snapshot.empty) {
            console.log("No expired posts found.");
            return;
        }

        let deletedCount = 0;
        let batchOperationCount = 0;
        let batch = db.batch();

        for (const doc of snapshot.docs) {
            const data = doc.data();

            // 1. Delete from Cloudinary if media exists
            if (data.cloudinary_public_id) {
                try {
                    await cloudinary.uploader.destroy(data.cloudinary_public_id);
                    console.log(`Deleted media from Cloudinary: ${data.cloudinary_public_id}`);
                } catch (error) {
                    console.error(`Failed to delete Cloudinary media ${data.cloudinary_public_id}:`, error);
                }
            }

            // 2. Mark as deleted in Firestore
            batch.update(doc.ref, { is_deleted: true });
            deletedCount++;
            batchOperationCount++;

            // 3. Remove mirrored announcement documents
            const announcementsSnapshot = await db.collection('announcements')
                .where('sourceCollection', '==', 'local_vibes_posts')
                .where('sourcePostId', '==', doc.id)
                .get();

            for (const announcementDoc of announcementsSnapshot.docs) {
                batch.delete(announcementDoc.ref);
                batchOperationCount++;
            }

            // NOTE: Batch limit is 500. For production, handle chunking if needed.
            if (batchOperationCount >= 450) {
                await batch.commit();
                console.log(`Committed batch of ${batchOperationCount} operations.`);
                batch = db.batch();
                batchOperationCount = 0;
            }
        }

        if (batchOperationCount > 0) {
            await batch.commit();
        }

        console.log(`Cleanup complete. Total posts marked as deleted: ${snapshot.size}`);

    } catch (error) {
        console.error("Error during Local Vibes cleanup:", error);
    }
});
