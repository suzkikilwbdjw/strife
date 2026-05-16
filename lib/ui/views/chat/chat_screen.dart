import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/models/message_model.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_event.dart';
import 'package:strife/presentation/blocs/chats/chat_state.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
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
          ListMessages(controller: controller, currentUserId: currentUserId),

          // Поле ввода
          InputField(
            controller: _controller,
            chatId: chatId,
            currentUserId: currentUserId,
          ),
        ],
      ),
    );
  }
}

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required TextEditingController controller,
    required this.chatId,
    required this.currentUserId,
  }) : _controller = controller;

  final TextEditingController _controller;
  final String chatId;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            8, // Поднимается вместе с клавиатурой
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Напишите сообщение...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            // Кнопка отправки
            IconButton(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;

                context.read<ChatBloc>().add(
                  SendMessageRequest(textMessage: text),
                );

                _controller.clear();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListMessages extends StatelessWidget {
  const ListMessages({
    super.key,
    required this.controller,
    required this.currentUserId,
  });

  final ScrollController? controller;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
              // Получаем данные напрямую
              final msgData = message.toFirestore();
              final String? type = msgData['type'];
              final String? roomId = msgData['roomId'];

              if (type == 'call' && roomId != null) {
                // Рисуем плашку звонка для всех
                return InviteInRoomCard(
                  message: message,
                  currentUserId: currentUserId,
                );
              }

              final isMe = message.senderId == currentUserId;

              bool showSenderName = false;
              bool showAvatar = false;

              if (!isMe) {
                if (index == state.messages.length - 1 ||
                    state.messages[index + 1].senderId != message.senderId) {
                  showSenderName = true;
                }
                if (index == 0 ||
                    state.messages[index - 1].senderId != message.senderId) {
                  showAvatar = true;
                }
              }
              final userData = state.usersCache[message.senderId];

              final name =
                  userData?['displayName'] ??
                  (userData?['loading'] == true ? 'Загрузка...' : 'Unknown');

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
    );
  }
}

class InviteInRoomCard extends StatelessWidget {
  const InviteInRoomCard({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  final MessageModel message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            message.senderId == currentUserId
                ? 'Вы создали звонок'
                : 'Вас приглашают в звонок',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final dataMessage = message.toFirestore();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              // Проверка существует ли комната
              final exists = await context
                  .read<VCSRepository>()
                  .checkRoomExists(dataMessage['roomId']);
              if (!context.mounted) return;

              Navigator.of(context).pop(); // закрыли loader

              if (exists) {
                final User user = FirebaseAuth.instance.currentUser!;

                final vcsBloc = context.read<VCSBloc>();

                vcsBloc.add(
                  ConnectRequested(
                    roomId: dataMessage['roomId'],
                    identity: user.uid,
                    name: user.displayName!,
                    photoUrl: user.photoURL,
                  ),
                );

                Navigator.pop(context); // Закрываем саму шторку

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: vcsBloc,
                      child: const RoomView(),
                    ),
                  ),
                );
              } else {
                // Ошибка в случае неправельного id комнаты
                if (!context.mounted) return;

                Navigator.of(context).pop(); // закрываем лоадер

                // Показываем ошибку пользователю
                AppNotifications.showError(
                  context,
                  'Введен неверный id комнаты',
                );

                return;
              }
            },
            child: const Text('Присоединиться'),
          ),
        ],
      ),
    );
  }
}
