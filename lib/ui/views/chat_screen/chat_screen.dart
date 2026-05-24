import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
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
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB91ED0);
    final bool isPrivateChat = widget.chatId.contains('_');

    String? partnerId;
    if (isPrivateChat) {
      final parts = widget.chatId.split('_');
      partnerId = parts.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => widget.currentUserId,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.black.withValues(alpha: 0.04),
            height: 1,
          ),
        ),
        automaticallyImplyLeading: false,

        // Кнопка назад
        leading: BackIconButton(),

        title: !isPrivateChat
            ? const Text(
                'Чат встречи',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final userData = state.usersCache[partnerId!];
                  final String name =
                      userData?['displayName'] ??
                      (userData?['loading'] == true
                          ? 'Загрузка...'
                          : 'Пользователь');
                  final String? photoUrl = userData?['photoUrl'];

                  return Row(
                    children: [
                      // Аватарка в шапке чата и статус
                      AvatartAndStatusTopWidget(
                        brandColor: brandColor,
                        photoUrl: photoUrl,
                        partnerId: partnerId,
                      ),
                      const SizedBox(width: 12),

                      // Имя и подзаголовок статуса
                      NameAndSubtitleStatusWidget(
                        name: name,
                        partnerId: partnerId,
                      ),
                    ],
                  );
                },
              ),
      ),

      body: Column(
        children: [
          // Список сообщений
          ListMessages(
            controller: widget.controller,
            currentUserId: widget.currentUserId,
            isPrivateChat: isPrivateChat,
          ),

          // Поле ввода
          InputField(
            controller: _controller,
            chatId: widget.chatId,
            currentUserId: widget.currentUserId,
            isPrivateChat: isPrivateChat,
          ),
        ],
      ),
    );
  }
}

class NameAndSubtitleStatusWidget extends StatelessWidget {
  const NameAndSubtitleStatusWidget({
    super.key,
    required this.name,
    required this.partnerId,
  });

  final String name;
  final String? partnerId;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Небольшой подзаголовок статуса
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('status/$partnerId').onValue,
            builder: (context, snapshot) {
              bool isOnline = false;
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                isOnline = data['state'] == 'online';
              }
              return Text(
                isOnline ? 'в сети' : 'был(а) недавно',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.black38,
                  fontSize: 11,
                  fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AvatartAndStatusTopWidget extends StatelessWidget {
  const AvatartAndStatusTopWidget({
    super.key,
    required this.brandColor,
    required this.photoUrl,
    required this.partnerId,
  });

  final Color brandColor;
  final String? photoUrl;
  final String? partnerId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: brandColor.withValues(alpha: 0.1),
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Icon(Icons.person, color: brandColor, size: 18)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('status/$partnerId').onValue,
            builder: (context, snapshot) {
              bool isOnline = false;
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                isOnline = data['state'] == 'online';
              }

              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BackIconButton extends StatelessWidget {
  const BackIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.black87,
        size: 20,
      ),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required TextEditingController controller,
    required this.chatId,
    required this.currentUserId,
    required this.isPrivateChat,
  }) : _controller = controller;

  final TextEditingController _controller;
  final String chatId;
  final String currentUserId;
  final bool isPrivateChat;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB91ED0);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
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
              onPressed: isPrivateChat == true
                  ? () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      context.read<ChatBloc>().add(
                        SendMessageRequested(textMessage: text),
                      );

                      _controller.clear();
                    }
                  : () {
                      final text = _controller.text.trim();

                      context.read<ChatBloc>().add(
                        SendMessage(
                          chatId: chatId,
                          senderId: currentUserId,
                          text: text,
                        ),
                      );

                      _controller.clear();
                    },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: brandColor,
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
    required this.isPrivateChat,
  });

  final ScrollController? controller;
  final String currentUserId;
  final bool isPrivateChat;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB91ED0)),
            );
          }

          if (state.messages.isEmpty) {
            return const Center(
              child: Text(
                'Сообщений пока нет\nНапишите что-нибудь...',
                style: TextStyle(color: Colors.black38, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            reverse: true,
            controller: controller,
            itemCount: state.messages.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemBuilder: (context, index) {
              final message = state.messages[index];

              // Получаем данные
              final msgData = message.toFirestore();
              final String? type = msgData['type'];
              final String? roomId = msgData['roomId'];

              // Карточка приглашения в звонок
              if (type == 'call' && roomId != null) {
                // Рисуем плашку звонка для всех
                return InviteInRoomCard(
                  key: ValueKey(message.id),
                  roomId: roomId,
                  senderId: msgData['senderId'],
                  currentUserId: currentUserId,
                );
              }

              final isMe = message.senderId == currentUserId;

              bool showSenderName = false;
              bool showAvatar = false;

              // Если чат приватный — аватарки и имена принудительно гасим
              if (!isPrivateChat && !isMe) {
                // Показываем имя над верхним сообщением в блоке автора
                if (index == state.messages.length - 1 ||
                    state.messages[index + 1].senderId != message.senderId) {
                  showSenderName = true;
                }

                // Показываем аватарку у нижнего сообщения в блоке автора
                if (index == 0 ||
                    state.messages[index - 1].senderId != message.senderId) {
                  showAvatar = true;
                }
              }

              // Достаем имя и фото автора
              final userData = state.usersCache[message.senderId];
              final String name =
                  userData?['displayName'] ??
                  (userData?['loading'] == true
                      ? 'Загрузка...'
                      : 'Пользователь');
              final String? photo = userData?['photoUrl'];

              return MessageBubble(
                messageModel: message,
                isMe: isMe,
                showSenderName: showSenderName,
                showAvatar: showAvatar,
                senderName: name,
                senderPhoto: photo,
                isPrivateChat: isPrivateChat,
              );
            },
          );
        },
      ),
    );
  }
}

class InviteInRoomCard extends StatelessWidget {
  final String senderId;
  final String roomId;
  final String currentUserId;

  const InviteInRoomCard({
    super.key,
    required this.currentUserId,
    required this.senderId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB91ED0);

    if (roomId.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isMe = senderId == currentUserId;

    return StreamBuilder<bool>(
      stream: context.read<VCSRepository>().watchRoomStatus(roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: brandColor,
                ),
              ),
            ),
          );
        }

        final bool isCompleted = snapshot.data ?? false;
        final bool isActive = !isCompleted;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? brandColor.withValues(alpha: 0.06)
                : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? brandColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Иконка трубки
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? brandColor.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive
                      ? Icons.video_call_rounded
                      : Icons.videocam_off_outlined,
                  color: isActive ? brandColor : Colors.black38,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Текст заголовка
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMe
                          ? (isActive
                                ? 'Вы создали звонок'
                                : 'Вы создавали звонок')
                          : (isActive
                                ? 'Приглашение в звонок'
                                : 'Пропущенный звонок'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isActive ? Colors.black87 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? 'Звонок сейчас активен' : 'Звонок завершен',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? brandColor : Colors.black38,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              isActive
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Показываем крутилку лоадера
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(color: brandColor),
                          ),
                        );

                        // Проверяем существование комнаты
                        final bool exists = await context
                            .read<VCSRepository>()
                            .checkRoomExists(roomId);

                        if (!context.mounted) return;
                        Navigator.popUntil(context, (route) => !route.isFirst);

                        if (exists) {
                          final User user = FirebaseAuth.instance.currentUser!;
                          final vcsBloc = context.read<VCSBloc>();

                          vcsBloc.add(
                            ConnectRequested(
                              roomId: roomId,
                              identity: user.uid,
                              name: user.displayName!,
                              photoUrl: user.photoURL,
                            ),
                          );

                          // Открываем экран комнаты звонка
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: vcsBloc,
                                child: const RoomView(),
                              ),
                            ),
                          );
                        } else {
                          Navigator.pop(context);

                          AppNotifications.showError(
                            context,
                            'Эта комната больше не доступна на сервере',
                          );
                        }
                      },
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Завершен',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
