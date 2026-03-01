import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.readBy,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<String>? readBy;

  // Превращаем Snapshot из Firestore в объект
  factory MessageModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    Map data = documentSnapshot.data() as Map;

    return MessageModel(
      id: documentSnapshot.id,
      senderId: data['senderId'] ?? ' ',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  // Для отправки в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': id,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': readBy ?? [senderId],
    };
  }
}
