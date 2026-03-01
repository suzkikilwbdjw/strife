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
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              messageModel.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              '${messageModel.timestamp.hour}:${messageModel.timestamp.minute}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white30 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
