import 'package:flutter/material.dart';
import 'package:strife/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel messageModel;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.messageModel,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.widthOf(context) * 0.27,
            maxWidth: MediaQuery.widthOf(context) * 0.5,
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  messageModel.text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),

                const SizedBox(height: 4),

                Text(
                  '${messageModel.timestamp.hour}:${messageModel.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white30 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
