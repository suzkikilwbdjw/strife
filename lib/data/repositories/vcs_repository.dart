import 'dart:convert';

import 'package:http/http.dart' as http;

class VCSRepository {
  // Адресс server.mjs
  final _httpUrl = 'http://62.109.2.27:3000';

  // Запрос токена у сервера
  Future<Map<String, dynamic>> fetchToken({
    required String room,
    required String identity,
    required String name,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_httpUrl/getToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room_name': room,
        'participant_identity': identity,
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
      Uri.parse('$_httpUrl/muteParticipant'),
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
      Uri.parse('$_httpUrl/enableMicrophone'),
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
      Uri.parse('$_httpUrl/disableCamera'),
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
      Uri.parse('$_httpUrl/enableCamera'),
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
      Uri.parse('$_httpUrl/kickParticipant'),
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
      Uri.parse('$_httpUrl/transferHost'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'room': roomId, 'newHostId': newHostId}),
    );
  }
}
