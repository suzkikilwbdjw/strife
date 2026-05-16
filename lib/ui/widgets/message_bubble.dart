import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strife/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel messageModel;
  final bool isMe;
  final bool showSenderName; // Показать ли никнейм
  final bool showAvatar; // Показать ли аватар
  final String senderName; // Имя отправителя
  final String? senderPhoto; // Фото отправителя
  final bool isPrivateChat; // Является ли чат приватным

  const MessageBubble({
    super.key,
    required this.messageModel,
    required this.isMe,
    required this.showSenderName,
    required this.showAvatar,
    required this.senderName,
    this.senderPhoto,
    required this.isPrivateChat,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB91ED0);

    // Достаем системные поля для статуса галочек
    final msgData = messageModel.toFirestore();
    final List<dynamic> readBy = msgData['readBy'] ?? [];

    // В приватном чате ищем ID собеседника в массиве readBy, чтобы понять, прочитал ли он,
    // если в readBy больше 1 человека — значит, сообщение прочитано получателем
    final bool isReadByPartner = readBy.length > 1;

    return Padding(
      padding: EdgeInsets.only(top: showSenderName ? 10.0 : 2.0, bottom: 2.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //  Аватарка слева (Только в групповом чате встречи для чужих сообщений)
          if (!isMe && !isPrivateChat)
            AvatarWidget(
              showAvatar: showAvatar,
              brandColor: brandColor,
              senderPhoto: senderPhoto,
              senderName: senderName,
            ),

          // Блок сообщения
          MessageBlock(
            isMe: isMe,
            showSenderName: showSenderName,
            senderName: senderName,
            brandColor: brandColor,
            showAvatar: showAvatar,
            messageModel: messageModel,
            isReadByPartner: isReadByPartner,
          ),

          if (isMe && !isPrivateChat) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class MessageBlock extends StatelessWidget {
  const MessageBlock({
    super.key,
    required this.isMe,
    required this.showSenderName,
    required this.senderName,
    required this.brandColor,
    required this.showAvatar,
    required this.messageModel,
    required this.isReadByPartner,
  });

  final bool isMe;
  final bool showSenderName;
  final String senderName;
  final Color brandColor;
  final bool showAvatar;
  final MessageModel messageModel;
  final bool isReadByPartner;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Имя отправителя (Только в групповом чате встречи)
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(
                left: 4.0,
                bottom: 4.0,
                right: 4.0,
              ),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brandColor,
                ),
              ),
            ),

          // Сам пузырь с текстом
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFB91ED0) : const Color(0xFFF2F2F7),

              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : (showAvatar ? 4 : 16)),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Текст сообщения
                Flexible(
                  child: Text(
                    messageModel.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Время и cтатус
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(messageModel.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white54 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Галочки статуса
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isReadByPartner
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: isReadByPartner ? Colors.white : Colors.white54,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Быстрый метод форматирования времени сообщений
  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('HH:mm').format(dateTime);
  }
}

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.showAvatar,
    required this.brandColor,
    required this.senderPhoto,
    required this.senderName,
  });

  final bool showAvatar;
  final Color brandColor;
  final String? senderPhoto;
  final String senderName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      margin: const EdgeInsets.only(right: 8),
      child: showAvatar
          ? CircleAvatar(
              radius: 16,
              backgroundColor: brandColor.withValues(alpha: 0.15),
              backgroundImage: senderPhoto != null && senderPhoto!.isNotEmpty
                  ? NetworkImage(senderPhoto!)
                  : null,
              child: senderPhoto == null || senderPhoto!.isEmpty
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: brandColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            )
          : const SizedBox.shrink(),
    );
  }
}
