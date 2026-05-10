import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/chat/chat_screen.dart';
import 'package:strife/ui/widgets/contact_widget.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    // Преобразуем Firestore Timestamp в DateTime
    DateTime date = (timestamp as Timestamp).toDate();
    DateTime now = DateTime.now();

    // Если сегодня — показываем только время, если нет — дату
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Загловок страницы
      appBar: AppBar(
        toolbarHeight: 130,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Чаты',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.right,
                ),

                Container(
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFBDBDBD).withValues(alpha: 0.4),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    child: Icon(Icons.add, color: Colors.white, size: 24.0),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => NewChatSheet(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFD9D9D9).withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                hintText: 'Поиск чата...',
                hintStyle: TextStyle(color: Color(0xFFD3C9C9)),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<ChatRepository>().getAllMyChats(
          FirebaseAuth.instance.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(child: Text('У вас пока нет активных чатов'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(4),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const Divider(thickness: 0.5),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final myId = FirebaseAuth.instance.currentUser!.uid;
              final participants = List<String>.from(
                chat['participants'] ?? [],
              );

              // Находим ID собеседника
              String partnerId;

              if (participants.length > 1) {
                partnerId = participants.firstWhere(
                  (id) => id != myId,
                  orElse: () => myId, // Если вдруг не нашли, берем себя
                );
              } else {
                partnerId = myId;
              }

              // Используем FutureBuilder, чтобы подтянуть данные собеседника
              return FutureBuilder<Map<String, dynamic>>(
                future: context.read<UserRepository>().getUserData(partnerId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data ?? {};
                  final name = userData['displayName'] ?? 'Загрузка...';
                  final photo = userData['photoUrl'];

                  return ListTile(
                    onTap: () {
                      // Переход в чат
                      _navigateToChat(context, chat['id'], myId);
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: photo != null
                              ? NetworkImage(photo)
                              : null,
                          backgroundColor: Colors.purple.shade100,
                          child: photo == null
                              ? Text(name[0].toUpperCase())
                              : null,
                        ),
                        Positioned(
                          bottom: 1.0,
                          right: 1.0,
                          child: StreamBuilder<DatabaseEvent>(
                            stream: FirebaseDatabase.instance
                                .ref('status/$partnerId')
                                .onValue,
                            builder: (context, snapshot) {
                              bool isOnline = false;
                              if (snapshot.hasData &&
                                  snapshot.data!.snapshot.value != null) {
                                final data = Map<String, dynamic>.from(
                                  snapshot.data!.snapshot.value as Map,
                                );
                                isOnline = data['state'] == 'online';
                              }

                              return Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chat['lastMessage'] ?? 'Нет сообщений',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chat['lastUpdate'] != null
                              ? formatTimestamp(chat['lastUpdate'])
                              : '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NewChatSheet extends StatelessWidget {
  const NewChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.55,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final contacts = context.watch<ContactsBloc>().state.filteredContacts;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок и кнопка закрытия
                _buildHeader(context),

                // Поиск
                _buildSearchField(context),

                // Список контактов
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ContactWidget(userData: contact);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Для заголовка
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 24),
        const Text(
          'Начать переписку',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  // Для поиска
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      onChanged: (value) {
        context.read<ContactsBloc>().add(
          SearchContactsRequested(searchQuery: value),
        );
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD9D9D9).withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        hintText: 'Поиск контактов...',
        hintStyle: TextStyle(color: Color(0xFFD3C9C9)),
      ),
    );
  }
}

/*class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.purple.shade900,
            backgroundImage: contact['photoUrl'] != null
                ? NetworkImage(contact['photoUrl'])
                : null,
            child: contact['photoUrl'] == null
                ? Text(
                    contact['displayName'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          // Индикатор статуса (онлайн/оффлайн)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: contact['isOnline'] == true ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        contact['displayName'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        contact['email'] ?? '',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: IconButton(
        onPressed: () async {
          final myId = FirebaseAuth.instance.currentUser!.uid;

          // 1. Получаем ID чата
          final chatId = await context
              .read<ChatRepository>()
              .getOrCreatePrivateChatId(myId, contact['id']);

          if (!context.mounted) return;

          // 2. Закрываем шторку
          Navigator.pop(context);

          // 3. Открываем экран чата
          _navigateToChat(context, chatId, myId);
        },
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8E9FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.purple,
            size: 20,
          ),
        ),
      ),
    );
  }
}*/

void _navigateToChat(BuildContext context, String chatId, String myId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => ChatBloc(
          chatRepository: context.read<ChatRepository>(),
          userRepository: context.read<UserRepository>(),
        )..add(InitChat(chatId)),
        child: ChatScreen(chatId: chatId, currentUserId: myId),
      ),
    ),
  );
}
