import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_event.dart';
import 'package:strife/presentation/blocs/chats/chat_state.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final ScrollController? controller;

  final TextEditingController _controller = TextEditingController();

  ChatScreen({
    required this.chatId,
    required this.currentUserId,
    this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close), // Иконка крестика
            onPressed: () =>
                Navigator.of(context).pop(), // Закрывает модальное окно
          ),
        ],
        automaticallyImplyLeading: false,
        title: const Text('Чат', style: TextStyle(color: Colors.deepPurple)),
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

                if (state.messages.isEmpty) {
                  return const Center(child: Text('Сообщений пока нет'));
                }

                return ListView.builder(
                  reverse: true,
                  controller: controller,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == currentUserId;

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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Фон формы ввода
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Напишите сообщение...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),

                        // Убираем внутренние границы TextField
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  // Кнопка-круг с самолетиком
                  GestureDetector(
                    onTap: () {
                      final text = _controller.text;
                      if (text.trim().isEmpty) return;

                      context.read<ChatBloc>().add(
                        SendMessage(
                          chatId: chatId,
                          senderId: currentUserId,
                          text: text,
                        ),
                      );
                      _controller.clear();
                    },

                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
