import 'package:strife/data/models/message_model.dart';

abstract class ChatEvent {}

// Событие инита чата
class InitChat extends ChatEvent {
  final String chatId;

  InitChat(this.chatId);
}

// Событие для обновление сообщений
class MessagesUpdated extends ChatEvent {
  final List<MessageModel> messages;

  MessagesUpdated(this.messages);
}

// Событие для отправки сообщений без уведомления
class SendMessage extends ChatEvent {
  final String chatId;
  final String senderId;
  final String text;

  SendMessage({
    required this.chatId,
    required this.senderId,
    required this.text,
  });
}

// Событие для отправки сообщений c уведомлениями
class SendMessageRequest extends ChatEvent {
  final String textMessage;

  SendMessageRequest({required this.textMessage});
}

// Загрузка пользователя
class LoadUser extends ChatEvent {
  final String userId;

  LoadUser(this.userId);
}
