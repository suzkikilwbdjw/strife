import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  Stream<User?> get userStream => FirebaseAuth.instance.userChanges();

  // Обоюдное добавление контакта
  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String contactId,
  }) async {
    try {
      // Сначала достаем актуальные данные обоих юзеров
      final myData = await getUserData(currentUserId);
      final partnerData = await getUserData(contactId);

      final batch = _firestore.batch();

      // Записываем данные партнера в контакты
      batch.set(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('contacts')
            .doc(contactId),
        {
          'email': partnerData['email'],
          'displayName': partnerData['displayName'],
          'photoUrl': partnerData['photoUrl'],
          'addedAt': FieldValue.serverTimestamp(),
          'id': contactId,
        },
        SetOptions(merge: true),
      );

      // Записываем мои данные к нему в контакты
      batch.set(
        _firestore
            .collection('users')
            .doc(contactId)
            .collection('contacts')
            .doc(currentUserId),
        {
          'email': myData['email'],
          'displayName': myData['displayName'],
          'photoUrl': myData['photoUrl'],
          'addedAt': FieldValue.serverTimestamp(),
          'id': currentUserId,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Получение списка ID контактов
  Future<List<String>> getContacts(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .get();

      // Извлекаем ID документов
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return []; // Возвращаем пустой список при ошибке
    }
  }

  // Удаление обоюдное удаление контакта
  Future<void> removeContact(String currentUserId, String contactId) async {
    try {
      final batch = _firestore.batch();

      // Ссылка на контакт у меня
      final myContactRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId);

      // Ссылка на контакт у него
      final hisContactRef = _firestore
          .collection('users')
          .doc(contactId)
          .collection('contacts')
          .doc(currentUserId);

      batch.delete(myContactRef);
      batch.delete(hisContactRef);

      await batch.commit();
    } catch (e) {
      return;
    }
  }

  // Стрим для отслеживаний изменений
  Stream<List<Map<String, dynamic>>> getContactsStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.data()['id'],
              'isFavorite': doc.data()['isFavorite'] ?? false,
              'displayName': doc.data()['displayName'],
              'photoUrl': doc.data()['photoUrl'],
              'email': doc.data()['email'],
            };
          }).toList(),
        );
  }

  // Получение данных конкретного пользователя
  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  // Добавление контакта в избранный
  Future<void> toggleFavorite(
    String currentUserId,
    String contactId,
    bool isFavorite,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .update({'isFavorite': isFavorite});
    } catch (_) {
      rethrow;
    }
  }

  // Стрим для отслеживания Встреч
  Stream<List<Map<String, dynamic>>> getMettingsStream(String userId) {
    return _firestore
        .collection('meetings')
        .where('participantIds', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
