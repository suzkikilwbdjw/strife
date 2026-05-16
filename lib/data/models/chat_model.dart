import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { private, room }

class ChatModel {
  final String? id;
  final ChatType type;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastUpdate;
  final Map<String, Map<String, String>>? participantsInfo;

  ChatModel({
    this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastUpdate,
    this.participantsInfo,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    final Map<String, dynamic> data =
        documentSnapshot.data() as Map<String, dynamic>;

    return ChatModel(
      id: documentSnapshot.id,
      type: data['type'] == 'room' ? ChatType.room : ChatType.private,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      participantsInfo: data['participantsInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type == ChatType.room ? 'room' : 'private',
      'participants': participants,
      'lastMessage': lastMessage,
      'lastUpdate': FieldValue.serverTimestamp(),
      'participantsInfo': participantsInfo,
    };
  }
}
