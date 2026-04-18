import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/chat_view_model.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final ScrollController? controller;

  const ChatScreen({
    required this.chatId,
    required this.currentUserId,
    this.controller,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Инициализируем подписку на сообщения при входе
    Future.microtask(() {
      if (!mounted) return;
      context.read<ChatViewModel>().initChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    /*if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        context.read<ChatViewModel>().clearError();
      });
    }*/

    return Scaffold(
      appBar: AppBar(
        title: const Text("Чат", style: TextStyle(color: Colors.deepPurple)),
        centerTitle: true,
      ),
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
                  controller: widget.controller,
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final messageModel = vm.messages[index];
                    final isMe = messageModel.senderId == widget.currentUserId;

                    bool showSenderName = false;
                    bool showAvatar = false;

                    if (!isMe) {
                      if (index == vm.messages.length - 1 ||
                          vm.messages[index + 1].senderId !=
                              messageModel.senderId) {
                        showSenderName = true;
                      }
                      if (index == 0 ||
                          vm.messages[index - 1].senderId !=
                              messageModel.senderId) {
                        showAvatar = true;
                      }
                    }
                    final userData = vm.getUserData(messageModel.senderId);
                    final String name =
                        userData?['displayName'] ?? "Загрузка...";
                    final String? photoUrl = userData?['photoUrl'];

                    return MessageBubble(
                      messageModel: messageModel,
                      isMe: isMe,
                      showSenderName:
                          showSenderName, // Показывать ли имя отправителя
                      showAvatar: showAvatar, // Показывать ли аватар
                      senderName: name, // Передаем имя
                      senderPhoto: photoUrl, // Передаем ссылку на фото
                    );
                  },
                );
              },
            ),
          ),

          /*if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),*/

          // Поле ввода
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
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
