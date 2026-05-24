const {AccessToken, RoomServiceClient} = require('livekit-server-sdk');
const express = require('express');
require('dotenv').config();

const admin = require('firebase-admin');

if (!admin.apps.length) {
  const serviceAccount = require('../serviceAccount.json');
  admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
}

const router = express.Router();

const db = admin.firestore();

const roomService = new RoomServiceClient(
    process.env.LIVEKIT_URL, process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET);

router.use(express.json());
router.use(express.urlencoded({extended: true}));

router.post('/getToken', async (req, res) => {
  try {
    console.log('--- /getToken called ---');
    const {
      room_name: roomName,
      participant_identity: identity,
      participant_name: name,
      photo_url: photoUrl
    } = req.body;

    if (!roomName || !identity) {
      return res.status(400).json(
          {error: 'Missing room_name or participant_identity'});
    }

    const roomDoc = await db.collection('rooms').doc(roomName).get();

    let hostIds = [];
    if (roomDoc.exists) {
      const roomData = roomDoc.data();
      // Вытаскиваем список хостов из БД
      hostIds =
          roomData.hostIds || (roomData.creatorId ? [roomData.creatorId] : []);
    }

    // Проверяем, записан ли текущий пользователь как хост в базе данных
    const isHost = hostIds.includes(identity);
    console.log(`User ${identity} host status from DB:`, isHost);

    // Синхронизируем метаданные комнаты в LiveKit
    if (isHost && hostIds.length > 0) {
      try {
        await roomService.updateRoomMetadata(
            roomName, JSON.stringify({hostIdentities: hostIds}));
      } catch (e) {
        console.log('updateRoomMetadata error:', e.message);
      }
    }

    // Формируем метаданные участника
    const participantMetadata =
        JSON.stringify({photoUrl: photoUrl ?? null, isHost: isHost});

    // Генерируем JWT токен LiveKit
    const token = new AccessToken(
        process.env.LIVEKIT_API_KEY, process.env.LIVEKIT_API_SECRET,
        {identity, name, metadata: participantMetadata, ttl: '10m'});

    token.addGrant(
        {room: roomName, roomJoin: true, canPublish: true, canSubscribe: true});

    const jwt = await token.toJwt();
    console.log('Token created successfully');

    res.send(
        {serverURL: process.env.LIVEKIT_URL, participantToken: jwt, isHost});

  } catch (error) {
    console.error('TOKEN ERROR:', error);
    res.status(500).send({error: 'token error'});
  }
});

router.post('/kickParticipant', async (req, res) => {
  try {
    const {room, participantIdentity} = req.body;
    await roomService.removeParticipant(room, participantIdentity);
    res.send({success: true});
  } catch (error) {
    console.error('Kick error:', error);
    res.status(500).send({error: 'kick failed'});
  }
});

router.post('/muteParticipant', async (req, res) => {
  try {
    const {room, participantIdentity} = req.body;

    const participants = await roomService.listParticipants(room);
    const participant =
        participants.find(p => p.identity === participantIdentity);

    if (!participant) {
      return res.status(404).send({error: 'participant not found'});
    }

    const metadata =
        participant.metadata ? JSON.parse(participant.metadata) : {};

    metadata.mutedByHost = true;

    for (const track of participant.tracks) {
      if (track.type === 'AUDIO') {
        await roomService.mutePublishedTrack(
            room, participantIdentity, track.sid, true);
      }
    }

    await roomService.updateParticipant(
        room, participantIdentity, JSON.stringify(metadata));

    res.send({success: true});
  } catch (error) {
    console.error('Mute error:', error);
    res.status(500).send({error: 'mute failed'});
  }
});

router.post('/enableMicrophone', async (req, res) => {
  try {
    const {room, participantIdentity} = req.body;

    const participants = await roomService.listParticipants(room);
    const participant =
        participants.find(p => p.identity === participantIdentity);

    if (!participant) {
      return res.status(404).send({error: 'participant not found'});
    }

    const metadata =
        participant.metadata ? JSON.parse(participant.metadata) : {};

    metadata.mutedByHost = false;

    for (const track of participant.tracks) {
      if (track.type === 'AUDIO') {
        await roomService.mutePublishedTrack(
            room, participantIdentity, track.sid, false);
      }
    }

    await roomService.updateParticipant(
        room, participantIdentity, JSON.stringify(metadata));

    res.send({success: true});
  } catch (error) {
    console.error('Enable mic error:', error);
    res.status(500).send({error: 'enable mic failed'});
  }
});

router.post('/disableCamera', async (req, res) => {
  try {
    const {room, participantIdentity} = req.body;

    const participants = await roomService.listParticipants(room);
    const participant =
        participants.find(p => p.identity === participantIdentity);

    if (!participant) {
      return res.status(404).send({error: 'participant not found'});
    }

    const metadata =
        participant.metadata ? JSON.parse(participant.metadata) : {};
    metadata.cameraMutedByHost = true;

    for (const track of participant.tracks) {
      if (track.type === 'VIDEO') {
        await roomService.mutePublishedTrack(
            room, participantIdentity, track.sid, true);
      }
    }

    await roomService.updateParticipant(
        room, participantIdentity, JSON.stringify(metadata));

    res.send({success: true});
  } catch (error) {
    console.error('Disable camera error:', error);
    res.status(500).send({error: 'disable camera failed'});
  }
});

router.post('/enableCamera', async (req, res) => {
  try {
    const {room, participantIdentity} = req.body;

    const participants = await roomService.listParticipants(room);
    const participant =
        participants.find(p => p.identity === participantIdentity);

    if (!participant) {
      return res.status(404).send({error: 'participant not found'});
    }

    const metadata =
        participant.metadata ? JSON.parse(participant.metadata) : {};
    metadata.cameraMutedByHost = false;

    for (const track of participant.tracks) {
      if (track.type === 'VIDEO') {
        await roomService.mutePublishedTrack(
            room, participantIdentity, track.sid, false);
      }
    }

    await roomService.updateParticipant(
        room, participantIdentity, JSON.stringify(metadata));

    res.send({success: true});
  } catch (error) {
    console.error('Enable camera error:', error);
    res.status(500).send({error: 'enable camera failed'});
  }
});

router.post('/transferHost', async (req, res) => {
  try {
    const {room, currentHostId, newHostId, action = 'transfer'} = req.body;

    if (!room || !newHostId) {
      return res.status(400).json({error: 'Missing parameters'});
    }

    const roomRef = db.collection('rooms').doc(room);
    const roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      return res.status(404).json({error: 'Room not found'});
    }

    const roomData = roomDoc.data();
    let hostIds =
        roomData.hostIds || (roomData.creatorId ? [roomData.creatorId] : []);

    if (action === 'transfer') {
      hostIds = hostIds.filter(id => id !== currentHostId);
      if (!hostIds.includes(newHostId)) {
        hostIds.push(newHostId);
      }
    } else if (action === 'add') {
      if (!hostIds.includes(newHostId)) {
        hostIds.push(newHostId);
      }
    }

    await roomRef.update({
      hostIds: hostIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await roomService.updateRoomMetadata(
        room, JSON.stringify({hostIdentities: hostIds}));

    const participants = await roomService.listParticipants(room);

    for (const participant of participants) {
      let participantMetadata = {};

      if (participant.metadata) {
        try {
          participantMetadata = JSON.parse(participant.metadata);
        } catch (e) {
          participantMetadata = {};
        }
      }

      participantMetadata.isHost = hostIds.includes(participant.identity);

      await roomService.updateParticipant(
          room, participant.identity, JSON.stringify(participantMetadata));
    }

    res.send({success: true, hostIds});
  } catch (error) {
    console.error('TRANSFER HOST ERROR:', error);
    res.status(500).send({error: 'transfer failed'});
  }
});

router.post('/terminateRoom', async (req, res) => {
  try {
    const {roomId} = req.body;

    if (!roomId) {
      return res.status(400).json({error: 'Missing roomId'});
    }
    const batch = db.batch();

    const roomRef = db.collection('rooms').doc(roomId);

    batch.update(roomRef, {
      status: 'completed',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    })

    // Ищем встречу в коллекции meetings, которая привязана к этому roomId
    const meetingsSnapshot =
        await db.collection('meetings').where('roomId', '==', roomId).get();

    // Если встреча найдена, переводим её статус в 'completed'
    meetingsSnapshot.docs.forEach((doc) => {
      console.log(`Updating meeting status to completed for doc: ${doc.id}`);
      batch.update(doc.ref, {
        status: 'completed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    try {
      roomService.deleteRoom(roomId);
      console.log(`Room ${roomId} terminated for everyone.`);
    } catch (lkError) {
      console.log('LiveKit room already closed:', lkError.message);
    }

    return res.status(200).json(
        {success: true, message: 'Room terminated successfully'});
  } catch (error) {
    console.error('Terminate room error', error);
    return res.status(500).json({error: 'Internel server error'});
  }
});

module.exports = router;
