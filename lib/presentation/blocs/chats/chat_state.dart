import 'package:strife/data/models/message_model.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  /// Кэш пользователей
  final Map<String, Map<String, dynamic>> usersCache;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.usersCache = const {},
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    Map<String, Map<String, dynamic>>? usersCache,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      usersCache: usersCache ?? this.usersCache,
    );
  }
}
