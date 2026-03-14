import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addContact(String currentUserId, String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .set({'addedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Ошибка: $e');
    }
  }
}
