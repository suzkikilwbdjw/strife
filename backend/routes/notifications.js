const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

if (!admin.apps.length) {
  const serviceAccount = require('../serviceAccount.json');
  admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
}

const db = admin.firestore();

// Роут для отметки уведомлений прочитанными
router.post('/mark-notifications-read', async (req, res) => {
  try {
    const {userId} = req.body;

    if (!userId) {
      return res.status(400).json({error: 'Missing userId'});
    }

    const unreadSnapshot = await db.collection('notifications')
                               .where('recipientId', '==', userId)
                               .where('status', '==', 'unread')
                               .get();

    if (unreadSnapshot.empty) {
      return res.status(200).json(
          {success: true, message: 'No unread notifications'});
    }

    const batch = db.batch();
    // Переводим каждое найденное уведомление в статус 'read'
    unreadSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {status: 'read'});
    });

    await batch.commit();

    return res.status(200).json(
        {success: true, message: 'All notifications marked as read'});
  } catch (error) {
    console.error('Mark read error:', error);
    return res.status(500).json({error: 'Internal server error'});
  }
});

// Роут для отправки уведомления на приглашение в звонок
router.post('/send-call-request', async (req, res) => {
  const {
    recipientId,
    senderId,
    senderName,
    senderPhotoUrl,
    roomId,
    participantsInfo
  } = req.body;

  const ids = [senderId, recipientId].sort();
  const chatId = ids.join('_');

  try {
    const userDoc = await db.collection('users').doc(recipientId).get();

    if (!userDoc.exists) {
      return res.status(404).json({error: 'Пользователь не найден'});
    }

    const fcmToken = userDoc.data()?.fcmToken;

    await db.collection('chats').doc(chatId).set(
        {
          chatId: chatId,
          lastMessage: 'Видеовстреча',
          lastMessage: 'Видеовстреча',
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
          lastMessageSenderId: senderId,
          lastMessageReadBy: [senderId],
          participants:
              admin.firestore.FieldValue.arrayUnion(senderId, recipientId),
          type: 'private',
          participantsInfo: participantsInfo,
        },
        {merge: true});

    await db.collection('chats').doc(chatId).collection('messages').add({
      senderId: senderId,
      text: 'Приглашение в звонок',
      roomId: roomId,
      type: 'call',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      readBy: [senderId]
    });


    await db.collection('notifications').add({
      type: 'call_request',
      roomId: roomId,
      senderId: senderId,
      recipientId: recipientId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unread'
    });

    if (fcmToken) {
      const message = {
        notification: {
          title: 'Входящий вызов',
          body: `${senderName} приглашает вас в звонок`,
        },
        android: {
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
            imageUrl: senderPhotoUrl,
          },
        },
        data: {type: 'call_request', chatId: chatId, roomId: roomId},
        token: fcmToken,
      };

      try {
        await admin.messaging().send(message);
        console.log('Пуш звонка успешно отправлен');
      } catch (error) {
        if (error.code === 'messaging/registration-token-not-registered') {
          console.log(`Токен получателя ${recipientId} протух.`);
        } else {
          throw error;
        }
      }
    }

    res.status(200).json({success: true});

  } catch (error) {
    console.error('Ошибка при обработке звонка:', error);
    res.status(500).json({error: error.message});
  }
});

// Роут для отправки уведомления о заявки в друзья
router.post('/send-friend-request', async (req, res) => {
  const {recipientId, senderId, senderName, senderPhotoUrl} = req.body;

  try {
    const userDoc = await db.collection('users').doc(recipientId).get();

    if (!userDoc.exists) {
      return res.status(404).json({error: 'Пользователь не найден'});
    }

    const fcmToken = userDoc.data()?.fcmToken;

    await db.collection('notifications').add({
      type: 'friend_request',
      senderId: senderId,
      recipientId: recipientId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl || '',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unread'
    });

    // Отправка Push-уведомления
    if (fcmToken) {
      const message = {
        notification: {
          title: 'Новый запрос в контакты',
          body: `${senderName} хочет добавить вас в друзья`,
        },
        token: fcmToken,
        data: {type: 'friend_request'}
      };

      try {
        await admin.messaging().send(message);
      } catch (error) {
        if (error.code === 'messaging/registration-token-not-registered') {
          console.log(`Токен получателя ${recipientId} не активен.`);
        } else {
          throw error;
        }
      }
    }

    res.status(200).json({success: true});

  } catch (error) {
    console.error('Ошибка при отправке запроса в друзья:', error);
    res.status(500).json({error: error.message});
  }
});

// Роут для отправки уведомления о встрече
router.post('/send-meeting-request', async (req, res) => {
  const {
    senderId,
    participantIds,
    senderName,
    senderPhotoUrl,
    roomId,
    titleMeeting,
    meetingDateTime
  } = req.body;

  try {
    const meetingDate = new Date(meetingDateTime);
    const meetingTimestamp = admin.firestore.Timestamp.fromDate(meetingDate);

    // Сохраняем встречу в БД
    const meetingRef = await db.collection('meetings').add({
      senderId: senderId,
      titleMeeting: titleMeeting,
      meetingDateTime: meetingTimestamp,
      participantIds:
          admin.firestore.FieldValue.arrayUnion(senderId, ...participantIds),
      roomId: roomId,
      reminderSent: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'not_started'
    });

    // Рассылаем уведомления всем участникам
    const promises = participantIds.map(async (recipientId) => {
      const userDoc = await db.collection('users').doc(recipientId).get();
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data()?.fcmToken;
      const userLang = userDoc.data()?.language || 'ru';

      const meetingDate = meetingTimestamp.toDate();
      const formattedDate = formatDateForNotification(meetingDate, userLang);
      const formattedTime = formatTimeForNotification(meetingDate, userLang);

      await db.collection('notifications').add({
        type: 'meeting_request',
        senderId: senderId,
        recipientId: recipientId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        roomId: roomId,
        titleMeeting: titleMeeting,
        meetingDateTime: meetingTimestamp,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: 'unread'
      });

      if (fcmToken) {
        const message = {
          notification: {
            title: `Новая встреча: ${titleMeeting}`,
            body: `${senderName} пригласил вас на ${formattedDate} в ${
                formattedTime}`,
          },
          android: {
            notification: {
              channelId: 'high_importance_channel',
              priority: 'high',
            },
          },
          token: fcmToken,
          data: {
            type: 'meeting_request',
            roomId: roomId,
            meetingId: meetingRef.id
          },
        };

        try {
          await admin.messaging().send(message);
        } catch (error) {
          if (error.code === 'messaging/registration-token-not-registered') {
            console.log(
                `Токен пользователя ${recipientId} неактивен. Удаляем...`);
            await db.collection('users').doc(recipientId).update({
              fcmToken: admin.firestore.FieldValue.delete()
            });
          } else {
            console.error('Ошибка отправки FCM:', error);
          }
        }
      }
    });

    await Promise.all(promises);
    res.status(200).json({success: true, meetingId: meetingRef.id});

  } catch (error) {
    console.error('Error sending meeting request:', error);
    res.status(500).json({error: error.message});
  }
})

// Роут для обновления данных встречи
router.put('/update-meeting/:id', async (req, res) => {
  const {id} = req.params;
  const {
    titleMeeting,
    meetingDateTime,
    participantIds,
    senderName,
    senderId,
    senderPhotoUrl,
    roomId
  } = req.body;

  try {
    const meetingDate = new Date(meetingDateTime);
    const meetingTimestamp = admin.firestore.Timestamp.fromDate(meetingDate);

    await db.collection('meetings').doc(id).update({
      titleMeeting: titleMeeting,
      meetingDateTime: meetingTimestamp,
      participantIds: participantIds,
      reminderSent: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const promises = participantIds.map(async (recipientId) => {
      const userDoc = await db.collection('users').doc(recipientId).get();
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data()?.fcmToken;
      const userLang = userDoc.data()?.language || 'ru';

      const meetingDate = meetingTimestamp.toDate();
      const formattedDate = formatDateForNotification(meetingDate, userLang);
      const formattedTime = formatTimeForNotification(meetingDate, userLang);

      await db.collection('notifications').add({
        type: 'update_meeting_request',
        senderId: senderId,
        recipientId: recipientId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        roomId: roomId || '',
        titleMeeting: titleMeeting,
        meetingDateTime: meetingTimestamp,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: 'unread'
      });

      if (fcmToken) {
        const message = {
          notification: {
            title: `Встреча изменена: ${titleMeeting}`,
            body: `${senderName} изменил параметры встречи на ${
                formattedDate} в ${formattedTime}`,
          },
          android: {
            notification: {
              channelId: 'high_importance_channel',
              priority: 'high',
            },
          },
          token: fcmToken,
          data: {
            type: 'update_meeting_request',
            roomId: roomId || '',
            meetingId: id
          },
        };

        try {
          await admin.messaging().send(message);
        } catch (error) {
          if (error.code === 'messaging/registration-token-not-registered') {
            console.log(
                `Токен пользователя ${recipientId} неактивен. Удаляем...`);
            await db.collection('users').doc(recipientId).update({
              fcmToken: admin.firestore.FieldValue.delete()
            });
          } else {
            console.error('Ошибка отправки FCM:', error);
          }
        }
      }
    });

    await Promise.all(promises);
    res.status(200).json({success: true});

  } catch (error) {
    console.error('Error updating meeting:', error);
    res.status(500).json({error: error.message});
  }
});

router.post('/check-meeting-reminders', async (req, res) => {
  try {
    const now = admin.firestore.Timestamp.now();
    const tenMinutesFromNow =
        new admin.firestore.Timestamp(now.seconds + 10 * 60, now.nanoseconds);

    // Ищем встречи, которые начнутся через 10 минут
    const meetingsSnapshot =
        await db.collection('meetings')
            .where('meetingDateTime', '>=', now)
            .where('meetingDateTime', '<=', tenMinutesFromNow)
            .where('reminderSent', '==', false)
            .get();

    if (meetingsSnapshot.empty) {
      return res.status(200).json(
          {success: true, message: 'No meetings to remind'});
    }

    const results = [];

    for (const doc of meetingsSnapshot.docs) {
      const meeting = doc.data();
      const meetingId = doc.id;

      // Отправляем уведомления всем участникам
      const promises = meeting.participantIds.map(async (participantId) => {
        const userDoc = await db.collection('users').doc(participantId).get();
        if (!userDoc.exists) return;

        const fcmToken = userDoc.data()?.fcmToken;
        const userLang = userDoc.data()?.language || 'ru';

        const meetingDate = meeting.meetingDateTime.toDate();
        const formattedDate = formatDateForNotification(meetingDate, userLang);
        const formattedTime = formatTimeForNotification(meetingDate, userLang);

        await db.collection('notifications').add({
          type: 'meeting_reminder_request',
          meetingId: meetingId,
          recipientId: participantId,
          senderId: meeting.senderId,
          titleMeeting: meeting.titleMeeting,
          meetingDateTime: meeting.meetingDateTime,
          roomId: meeting.roomId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: 'unread'
        });

        // Обновляем данные встречи
        await db.collection('meetings').doc(meetingId).update({
          status: 'started'
        });

        if (fcmToken) {
          const message = {
            notification: {
              title: '⏰ Встреча скоро начнется!',
              body: `"${meeting.titleMeeting}" начнется сегодня в ${
                  formattedTime}`,
            },
            android: {
              notification: {
                channelId: 'high_importance_channel',
                priority: 'high',
              },
            },
            token: fcmToken,
            data: {
              type: 'meeting_reminder_request',
              meetingId: meetingId,
              roomId: meeting.roomId,
            },
          };

          try {
            await admin.messaging().send(message);
            return {participantId, status: 'sent'};
          } catch (error) {
            if (error.code === 'messaging/registration-token-not-registered') {
              console.log(`Токен пользователя ${participantId} неактивен.`);
              await db.collection('users').doc(participantId).update({
                fcmToken: admin.firestore.FieldValue.delete()
              });
              return {participantId, status: 'token_invalid'};
            } else {
              console.error('Ошибка отправки FCM:', error);
              return {participantId, status: 'error', error: error.message};
            }
          }
        }
        return {participantId, status: 'no_token'};
      });

      await Promise.all(promises);

      // Отмечаем, что напоминание отправлено
      await db.collection('meetings').doc(meetingId).update({
        reminderSent: true,
        reminderSentAt: admin.firestore.FieldValue.serverTimestamp()
      });

      results.push({
        meetingId: meetingId,
        title: meeting.titleMeeting,
        participantsCount: meeting.participantIds.length
      });
    }

    res.status(200).json({
      success: true,
      reminderCount: meetingsSnapshot.size,
      results: results
    });

  } catch (error) {
    console.error('Error checking meeting reminders:', error);
    res.status(500).json({error: error.message});
  }
});

// Роут для отправки уведомления о личном сообщении
router.post('/send-message-request', async (req, res) => {
  const {
    recipientId,
    senderId,
    senderName,
    senderPhotoUrl,
    textMessage,
  } = req.body;

  const ids = [senderId, recipientId].sort();
  const chatId = ids.join('_');

  try {
    const userDoc = await db.collection('users').doc(recipientId).get();

    if (!userDoc.exists) {
      return res.status(404).json({error: 'Пользователь не найден'});
    }

    const fcmToken = userDoc.data()?.fcmToken;

    await db.collection('chats').doc(chatId).collection('messages').add({
      senderId: senderId,
      text: textMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      readBy: [senderId]
    });

    await db.collection('chats').doc(chatId).update({
      lastMessage: textMessage,
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      lastMessageSenderId: senderId,
      lastMessageReadBy: [senderId],
    });

    await db.collection('notifications').add({
      type: 'message_request',
      senderId: senderId,
      recipientId: recipientId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unread'
    });

    if (fcmToken) {
      const message = {
        notification: {
          title: senderName,
          body: textMessage,
        },
        android: {
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
            imageUrl: senderPhotoUrl,
          },
        },
        data: {type: 'message_request', chatId: chatId},
        token: fcmToken,
      };

      try {
        await admin.messaging().send(message);
        console.log('Пуш сообщения успешно отправлен');
      } catch (error) {
        if (error.code === 'messaging/registration-token-not-registered') {
          console.log(`Токен получателя ${recipientId} протух.`);
        } else {
          throw error;
        }
      }
    }

    res.status(200).json({success: true});

  } catch (error) {
    console.error('Ошибка при обработке сообщения:', error);
    res.status(500).json({error: error.message});
  }
});


function formatDateForNotification(date, lang = 'ru') {
  const options = {day: 'numeric', month: 'long'};
  if (lang === 'ru') {
    return date.toLocaleDateString('ru-RU', options);
  } else {
    return date.toLocaleDateString('en-US', options);
  }
}

function formatTimeForNotification(date, lang = 'ru') {
  const options = {hour: '2-digit', minute: '2-digit'};
  if (lang === 'ru') {
    return date.toLocaleTimeString('ru-RU', options);
  } else {
    return date.toLocaleTimeString('en-US', options);
  }
}



router.put('/cancle-meeting-request/:id', async (req, res) => {
  const {meetingId} = req.params;

  const {
    senderId,
    participantIds,
    senderName,
    senderPhotoUrl,
    roomId,
    meetingDateTime,
    titleMeeting,
  } = req.body;

  try {
    const meetingDate = new Date(meetingDateTime);

    const batch = db.batch();

    // Получаем ссылку на встречи
    const meetingRef = db.collection('meetings').doc(meetingId);

    // Получаем ссылку на комнаты
    const roomRef = db.collection('rooms').doc(roomId);

    batch.update(meetingRef, {
      status: 'cancelled',
    })

    batch
        .update(roomRef, {
          status: 'cancelled',
        })

            await batch.commit();

    // Рассылаем уведомления всем участникам об отмене встречи
    const promises = participantIds.map(async (recipientId) => {
      const userDoc = await db.collection('users').doc(recipientId).get();
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data()?.fcmToken;
      const userLang = userDoc.data()?.language || 'ru';

      const formattedDate = formatDateForNotification(meetingDate, userLang);
      const formattedTime = formatTimeForNotification(meetingDate, userLang);

      await db.collection('notifications').add({
        type: 'cancle_meeting_request',
        senderId: senderId,
        recipientId: recipientId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        roomId: roomId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: 'unread'
      });

      if (fcmToken) {
        const message = {
          notification: {
            title: `Встреча ${titleMeeting} отменена`,
            body: `${senderName} отменил встречу на ${formattedDate} ${
                formattedTime}`,
          },
          android: {
            notification: {
              channelId: 'high_importance_channel',
              priority: 'high',
            },
          },
          token: fcmToken,
          data: {
            type: 'cancle_meeting_request',
          },
        };

        try {
          await admin.messaging().send(message);
        } catch (error) {
          if (error.code === 'messaging/registration-token-not-registered') {
            console.log(
                `Токен пользователя ${recipientId} неактивен. Удаляем...`);
            await db.collection('users').doc(recipientId).update({
              fcmToken: admin.firestore.FieldValue.delete()
            });
          } else {
            console.error('Ошибка отправки FCM:', error);
          }
        }
      }
    });

    await Promise.all(promises);
    res.status(200).json({success: true, meetingId: meetingRef.id});

  } catch (error) {
    console.error('Error sending meeting request:', error);
    res.status(500).json({error: error.message});
  }
});

module.exports = router;
