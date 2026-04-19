import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_event.dart';
import 'package:strife/presentation/blocs/chats/chat_state.dart';
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
      context.read<ChatBloc>().add(InitChat(widget.chatId));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Метод отвечающий за отправку сообщения
  void _onSend() {
    final text = _controller.text;

    if (text.trim().isEmpty) return;

    context.read<ChatBloc>().add(
      SendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        text: text,
      ),
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Чат", style: TextStyle(color: Colors.deepPurple)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  reverse: true,
                  controller: widget.controller,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    bool showSenderName = false;
                    bool showAvatar = false;

                    if (!isMe) {
                      if (index == state.messages.length - 1 ||
                          state.messages[index + 1].senderId !=
                              message.senderId) {
                        showSenderName = true;
                      }
                      if (index == 0 ||
                          state.messages[index - 1].senderId !=
                              message.senderId) {
                        showAvatar = true;
                      }
                    }
                    final userData = state.usersCache[message.senderId];

                    final name =
                        userData?['displayName'] ??
                        (userData?['loading'] == true
                            ? 'Загрузка...'
                            : 'Unknown');

                    final photo = userData?['photoUrl'];

                    return MessageBubble(
                      messageModel: message,
                      isMe: isMe,
                      showSenderName: showSenderName,
                      showAvatar: showAvatar,
                      senderName: name,
                      senderPhoto: photo,
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
