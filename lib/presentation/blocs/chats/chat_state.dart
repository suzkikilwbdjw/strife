part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  /// Кэш пользователей
  final Map<String, Map<String, dynamic>> usersCache;
  final Map<String, dynamic> chatData;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.usersCache = const {},
    this.chatData = const {},
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    Map<String, Map<String, dynamic>>? usersCache,
    Map<String, dynamic>? chatData,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      usersCache: usersCache ?? this.usersCache,
      chatData: chatData ?? this.chatData,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, usersCache, chatData];
}
