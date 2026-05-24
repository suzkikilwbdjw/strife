part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final List<Map<String, dynamic>> allChats;
  final List<Map<String, dynamic>> filteredChats;

  final List<MessageModel> messages;

  final bool isLoading;
  final String? error;
  final String searchQuery;

  /// Кэш пользователей
  final Map<String, Map<String, dynamic>> usersCache;

  final Map<String, dynamic> chatData;

  const ChatState({
    this.allChats = const [],
    this.filteredChats = const [],
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.usersCache = const {},
    this.chatData = const {},
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? allChats,
    List<Map<String, dynamic>>? filteredChats,
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Map<String, Map<String, dynamic>>? usersCache,
    Map<String, dynamic>? chatData,
  }) {
    return ChatState(
      allChats: allChats ?? this.allChats,
      filteredChats: filteredChats ?? this.filteredChats,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      usersCache: usersCache ?? this.usersCache,
      chatData: chatData ?? this.chatData,
    );
  }

  @override
  List<Object?> get props => [
    allChats,
    filteredChats,
    messages,
    isLoading,
    error,
    usersCache,
    chatData,
  ];
}
