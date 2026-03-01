import 'dart:convert';

import 'package:http/http.dart' as http;

class VCSRepository {
  // Адресс server.mjs
  final _httpUrl = Uri.parse('http://62.109.2.27:3000/getToken');

  // Запрос токена у сервера
  Future<Map<String, dynamic>> fetchToken({
    required String room,
    required String identity,
    required String name,
    String? photoUrl,
  }) async {
    final response = await http.post(
      _httpUrl,
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
}
