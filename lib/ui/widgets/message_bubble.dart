import 'package:flutter/material.dart';
import 'package:strife/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel messageModel;
  final bool isMe;
  final bool showSenderName; // Показать ли никнейм
  final bool showAvatar; // Показать ли аватар
  final String? senderName; // Имя отправителя
  final String? senderPhoto; // Фото отправителя

  const MessageBubble({
    super.key,
    required this.messageModel,
    required this.isMe,
    this.showSenderName = false,
    this.showAvatar = false,
    this.senderName,
    this.senderPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.widthOf(context) * 0.75,
          ),

          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment:
                CrossAxisAlignment.end, // Аватар прижат к низу сообщения
            children: <Widget>[
              // Отображение фото отправителя
              if (!isMe)
                SizedBox(
                  width: 35,
                  child: showAvatar
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: senderPhoto != null
                              ? NetworkImage(senderPhoto!)
                              : null,
                          child: senderPhoto == null
                              ? const Icon(Icons.person)
                              : null,
                        )
                      : SizedBox.shrink(),
                ),

              const SizedBox(width: 8),

              // Облачко
              Flexible(
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.purpleAccent
                          : Colors.grey.shade200, // Цвет сообщения

                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(
                          isMe || !showAvatar ? 12 : 0,
                        ),
                        bottomRight: Radius.circular(
                          !isMe || !showAvatar ? 12 : 0,
                        ),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: <Widget>[
                        // Никнейм отправителя
                        if (showSenderName)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              senderName ?? 'Person',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors
                                    .deepPurple, // Цвет никнейма отправителя
                              ),
                            ),
                          ),

                        // Отображение текста самого сообщения
                        Text(
                          messageModel.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Align(
                          alignment: Alignment
                              .centerRight, // Для того что бы время было всегда справо
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Отображение времени отправки
                              Text(
                                '${messageModel.timestamp.hour}:${messageModel.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10, // размер шрифта текста
                                  color: isMe
                                      ? Colors.grey.shade200
                                      : Colors.black54, // Цвет времени
                                ),
                              ),

                              // Отображение статуса сообщения в случае если оно отправлено мной
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  messageModel.isPending
                                      ? Icons
                                            .access_time_rounded // Часики
                                      : (messageModel.readBy != null &&
                                            messageModel.readBy!.length > 1)
                                      ? Icons
                                            .done_all_rounded // Две галочки в случае прочтения сообщения
                                      : Icons.done, // Одна галочка
                                  size: 16,
                                  color:
                                      (messageModel.readBy != null &&
                                          messageModel.readBy!.length > 1)
                                      ? Colors
                                            .cyanAccent // Подсветка сообщения в случае прочтения
                                      : (isMe
                                            ? Colors.grey.shade200
                                            : Colors.black54), // Цвет галочек
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
