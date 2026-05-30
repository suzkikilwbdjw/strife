import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class VCSRepository {
  // Адресс server.mjs
  final _httpUrl = 'https://seva.danilkin2244.fvds.ru';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Запрос токена у сервера
  Future<Map<String, dynamic>> fetchToken({
    required String roomId,
    required String identity,
    required String name,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_httpUrl/livekit/getToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room_name': roomId,
        'participant_identity': identity + Random().nextDouble().toString(),
        'participant_name': name,
        'photo_url': photoUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка получения токена: ${response.statusCode}');
    }
  }

  // Отключить доступ к микрофону участнику
  Future<void> muteParticipant({
    required String roomId,
    required String participantIdentity,
  }) async {
    await http.post(
      Uri.parse('$_httpUrl/livekit/muteParticipant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room': roomId,
        'participantIdentity': participantIdentity,
      }),
    );
  }

  // Включить доступ к микрофону участнику
  Future<void> unmuteParticipant({
    required String roomId,
    required String participantIdentity,
  }) async {
    await http.post(
      Uri.parse('$_httpUrl/livekit/enableMicrophone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room': roomId,
        'participantIdentity': participantIdentity,
      }),
    );
  }

  // Отключить доступ к камере участнику
  Future<void> disableCamera({
    required String roomId,
    required String participantIdentity,
  }) async {
    await http.post(
      Uri.parse('$_httpUrl/livekit/disableCamera'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room': roomId,
        'participantIdentity': participantIdentity,
      }),
    );
  }

  // Разрешить доступ к камере участнику
  Future<void> enableCamera({
    required String roomId,
    required String participantIdentity,
  }) async {
    await http.post(
      Uri.parse('$_httpUrl/livekit/enableCamera'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room': roomId,
        'participantIdentity': participantIdentity,
      }),
    );
  }

  // Выгнать участника
  Future<void> kickParticipant({
    required String roomId,
    required String participantIdentity,
  }) async {
    await http.post(
      Uri.parse('$_httpUrl/livekit/kickParticipant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room': roomId,
        'participantIdentity': participantIdentity,
      }),
    );
  }

  // Передать права хоста
  Future<void> transferHost({
    required String roomId,
    required String newHostId,
  }) async {
    await http.post(
      Uri.parse('$_httpUrl/livekit/transferHost'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room': roomId,
        'currentHostId': FirebaseAuth.instance.currentUser!.uid,
        'newHostId': newHostId,
        'action': 'add',
      }),
    );
  }

  // Создать запись комнаты в БД
  Future<String> createRoom({
    required String roomName,
    required String creatorId,
    String status = 'active',
    String type = 'call',
  }) async {
    try {
      final roomRef = _firestore.collection('rooms').doc();

      await roomRef.set({
        'roomName': roomName,
        'creatorId': creatorId,
        'participantIds': [creatorId],
        'hostIds': [creatorId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': status,
        'type': type,
      });

      return roomRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Добавить участника в БД
  Future<String> addParticipant({
    required String roomId,
    required String participantId,
  }) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);

      await roomRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
        'participantIds': FieldValue.arrayUnion([participantId]),
      });

      return roomRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Проверить существует ли комната
  Future<bool> checkRoomExists(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Запрос на заверешение комнаты для всех
  Future<void> terminateRoom(String roomId) async {
    final res = await http.post(
      Uri.parse('$_httpUrl/livekit/terminateRoom'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomId': roomId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Ошибка завершения комнаты: ${res.statusCode}');
    }
  }

  Stream<bool> watchRoomStatus(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return true;
      }
      final data = snapshot.data();
      return data?['status'] == 'completed';
    });
  }

  // Проверка на существовавние комнаты
  Future<bool> isRoomCompleted(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['status'] == 'completed';
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }
}
