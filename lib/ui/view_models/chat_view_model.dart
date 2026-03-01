import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:strife/data/models/message_model.dart';
import 'package:strife/data/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  // Состояния
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;

  // Геттеры для UI
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // Инициализация чата
  void initChat(String chatId) {
    _isLoading = true;
    notifyListeners();

    _streamSubscription?.cancel();

    _streamSubscription = _chatRepository.getMessage(chatId).listen((
      newMessages,
    ) {
      _messages = newMessages;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> sendText(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = MessageModel(
      id: '',
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      await _chatRepository.sendMessage(chatId, newMessage);
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
