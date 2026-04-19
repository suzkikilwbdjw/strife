import 'package:strife/data/models/message_model.dart';

abstract class ChatEvent {}

class InitChat extends ChatEvent {
  final String chatId;

  InitChat(this.chatId);
}

class MessagesUpdated extends ChatEvent {
  final List<MessageModel> messages;

  MessagesUpdated(this.messages);
}

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

class LoadUser extends ChatEvent {
  final String userId;

  LoadUser(this.userId);
}
