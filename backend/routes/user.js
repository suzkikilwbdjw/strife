require('dotenv').config();

const express = require('express');
const router = express.Router();

const admin = require('firebase-admin');
const db = admin.firestore();

router.post('/update-name', async (req, res) => {
  try {
    const {userId, newName} = req.body;

    if (!userId || !newName) {
      return res.status(400).json({error: 'Missing userId or newName'});
    }

    let batch = db.batch();
    let operationCount = 0;

    const batches = [batch];

    const addUpdateToBatch = (docRef, data) => {
      if (operationCount >= 500) {
        batch = db.batch();
        batches.push(batch);
        operationCount = 0;
      }
      batch.update(docRef, data);
      operationCount++;
    };

    // Обновляем основной документ пользователя в корневой коллекции
    const userRef = db.collection('users').doc(userId);
    addUpdateToBatch(userRef, {displayName: newName});

    // Находим имя во всех подколлекциях "contacts"
    const contactsSnapshot =
        await db.collectionGroup('contacts').where('id', '==', userId).get();

    contactsSnapshot.docs.forEach((doc) => {
      addUpdateToBatch(doc.ref, {displayName: newName});
    });

    // Находим имя во всех коллекциях "notifications"
    const notificationsSnapshot = await db.collectionGroup('notifications')
                                      .where('senderId', '==', userId)
                                      .get();

    notificationsSnapshot.docs.forEach((doc) => {
      addUpdateToBatch(doc.ref, {senderName: newName});
    });

    // Находим имя во всех коллекциях "chats"
    const chatsSnapshot = await db.collection('chats')
                              .where('participants', 'array-contains', userId)
                              .get();

    chatsSnapshot.docs.forEach((doc) => {
      const updateData = {};
      updateData[`participantsInfo.${userId}.displayName`] = newName;

      addUpdateToBatch(doc.ref, updateData);
    });

    // Выполняем все батчи
    await Promise.all(batches.map(b => b.commit()));

    // Обновляем профиль внутри FirebasAuth
    await admin.auth().updateUser(userId, {
      displayName: newName,
    });

    return res.status(200).json(
        {success: true, message: 'Username updated everywhere successfully'});

  } catch (error) {
    console.error('Error updating username across Firestore:', error);
    return res.status(500).json(
        {error: 'Internal server error', details: error.message});
  }
});

module.exports = router;
