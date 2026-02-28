import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/chat_view_model.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatScreen({
    required this.chatId,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Инициализируем подписку на сообщения при входе
    Future.microtask(
      () => context.read<ChatViewModel>().initChat(widget.chatId),
    );
  }

  void _onSend() {
    if (_controller.text.isNotEmpty) {
      context.read<ChatViewModel>().sendText(
        widget.chatId,
        widget.currentUserId,
        _controller.text,
      );
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Чат")),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: Consumer<ChatViewModel>(
              builder: (context, vm, child) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final messageModel = vm.messages[index];
                    return MessageBubble(
                      messageModel: messageModel,
                      isMe: messageModel.senderId == widget.currentUserId,
                    );
                  },
                );
              },
            ),
          ),

          // Поле ввода
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Введите сообщение...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
