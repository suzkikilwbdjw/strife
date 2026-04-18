import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:strife/data/models/message_model.dart';
import 'package:strife/data/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Состояния
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;
  String? _error;

  // Геттеры для UI
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

      // Проверка, есть ли во входящих сообщениях те, где нет моего id
      bool hasUnread = newMessages.any(
        (msg) =>
            msg.senderId != currentUserId &&
            !(msg.readBy?.contains(currentUserId) ?? false),
      );
      if (hasUnread) _chatRepository.markAsRead(chatId, currentUserId!);
    });

    _chatRepository.markAsRead(chatId, FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> sendText(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = MessageModel(
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );
    _error = null;
    try {
      await _chatRepository.sendMessage(chatId, newMessage);
    } on FirebaseException catch (_) {
      /*switch (e.code) {
        case 'unavailable':
          _error = 'Проблемы с сетью. Проверьте интернет.';
        case 'deadline-exceeded':
          _error = 'Время ожидания операции истекло.';
        default:
          _error = 'Ошибка входа: ${e.message}';
      }
      notifyListeners();*/
    }
  }

  void clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
