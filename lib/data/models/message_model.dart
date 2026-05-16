import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  MessageModel({
    this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.readBy,
    this.type,
    this.isPending = false,
    this.roomId,
  });

  final String? id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<String>? readBy;
  final bool isPending;
  final String? type;
  final String? roomId;

  // Превращаем Snapshot из Firestore в объект
  factory MessageModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    final Map<String, dynamic> data =
        documentSnapshot.data() as Map<String, dynamic>;

    final Timestamp? firestoreTimestamp = data['timestamp'] as Timestamp?;

    return MessageModel(
      id: documentSnapshot.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: firestoreTimestamp?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? []),
      isPending: documentSnapshot.metadata.hasPendingWrites,
      type: data['type'],
      roomId: data['roomId'],
    );
  }

  // Для отправки в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': readBy ?? [senderId],
      'type': type ?? 'text',
      'roomId': roomId,
    };
  }
}
