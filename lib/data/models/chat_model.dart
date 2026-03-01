import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { private, room }

class ChatModel {
  final String id;
  final ChatType type;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastUpdate;
  final String? liveKitRoomId;

  ChatModel({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastUpdate,
    this.liveKitRoomId,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    Map data = documentSnapshot.data() as Map;

    return ChatModel(
      id: data['id'],
      type: data['type'] == 'room' ? ChatType.room : ChatType.private,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      liveKitRoomId: data['liveKitRoomId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type == ChatType.room ? 'room' : 'private',
      'participants': participants,
      'lastMessage': lastMessage,
      'lastUpdate': FieldValue.serverTimestamp(),
      'liveKitRoomId': liveKitRoomId,
    };
  }
}
