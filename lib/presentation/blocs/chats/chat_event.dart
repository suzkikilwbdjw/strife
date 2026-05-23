part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Событие инита чата
class InitChat extends ChatEvent {
  final String chatId;

  const InitChat(this.chatId);

  @override
  List<Object> get props => [chatId];
}

//
class InitChats extends ChatEvent {
  final String userId;

  const InitChats({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateChats extends ChatEvent {
  final List<Map<String, dynamic>> allChats;

  const UpdateChats({required this.allChats});

  @override
  List<Object?> get props => [allChats];
}

class SearchChats extends ChatEvent {
  final String searchQuery;

  const SearchChats({required this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

// Событие для обновление сообщений
class MessagesUpdated extends ChatEvent {
  final List<MessageModel> messages;

  const MessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

// Событие для отправки сообщений без уведомления
class SendMessage extends ChatEvent {
  final String chatId;
  final String senderId;
  final String text;

  const SendMessage({
    required this.chatId,
    required this.senderId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, senderId, text];
}

// Событие для отправки сообщений c уведомлениями
class SendMessageRequested extends ChatEvent {
  final String textMessage;

  const SendMessageRequested({required this.textMessage});

  @override
  List<Object?> get props => [textMessage];
}

// Событие для загрузка пользователя
class LoadUser extends ChatEvent {
  final String userId;

  const LoadUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChatDataUpdated extends ChatEvent {
  final Map<String, dynamic> chatData;

  const ChatDataUpdated({required this.chatData});

  @override
  List<Object?> get props => [chatData];
}
