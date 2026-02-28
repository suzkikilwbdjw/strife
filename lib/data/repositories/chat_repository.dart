import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получения потока сообщений
  Stream<List<MessageModel>> getMessage(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Отправка сообщений
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final batch = _firestore.batch();

    // Ссылка на новое сообщение
    DocumentReference messageReference = _firestore
        .collection('chats')
        .doc('chatId')
        .collection('messages')
        .doc();

    // Ссылка на чат
    DocumentReference chatReference = _firestore
        .collection('chats')
        .doc('chatId');

    batch.set(messageReference, message.toFirestore());

    batch.update(chatReference, {
      'lastMessage': message.text,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Создание или получение id личного чата, вне комнаты
  Future<String> getOrCreatePrivateChatId(String myId, String partnerId) async {
    List<String> ids = [myId, partnerId]..sort();

    String chatId = ids.join('_');

    DocumentSnapshot chatDocument = await _firestore
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDocument.exists) {
      ChatModel newChat = ChatModel(
        id: chatId,
        type: ChatType.private,
        participants: ids,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(newChat.toFirestore());
    }

    return chatId;
  }

  Future<void> syncRoomChat(
    String liveKitRoomId,
    List<String> participantIds,
  ) async {
    DocumentReference chatReference = _firestore
        .collection('chats')
        .doc(liveKitRoomId);

    await chatReference.set({
      'type': 'room',
      'liveKitRoomId': liveKitRoomId,
      'participants': FieldValue.arrayUnion(participantIds),
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
