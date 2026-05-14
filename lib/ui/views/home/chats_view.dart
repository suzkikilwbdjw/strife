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
        // Увеличиваем высоту, чтобы полям ввода не было тесно внутри градиента
        toolbarHeight: 140,
        backgroundColor: Colors.transparent,
        elevation: 0, // Убираем тень под AppBar
        // Применяем ваш фирменный фиолетовый градиент Strife
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
        ),

        title: ChatAppBar(),
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

          return ListView.builder(
            padding: const EdgeInsets.all(4),
            itemCount: chats.length,
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

class ChatAppBar extends StatelessWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                fontSize: 26, // Слегка увеличили для солидности
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28.0,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => const NewChatSheet(),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Поле поиска чатов
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Поиск чатов',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'Введите имя или название...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),

            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final _searchController = TextEditingController();

  late ContactsBloc _contactsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contactsBloc = context.read<ContactsBloc>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // При закрытии шторки сбрасываем строку поиска, чтобы вернуть полный список контактов
    _contactsBloc.add(SearchContactsRequested(searchQuery: ''));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsBloc>().state.filteredContacts;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Полоска-индикатор сверху шторки
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Заголовок
          const Text(
            'Начать переписку',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          const Text(
            'Выберите друга из списка контактов, чтобы открыть приватный чат.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // Поле поиска
          TextField(
            controller: _searchController,
            onChanged: (value) {
              context.read<ContactsBloc>().add(
                SearchContactsRequested(searchQuery: value),
              );
            },
            decoration: const InputDecoration(
              labelText: 'Поиск контактов',
              hintText: 'Введите имя...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Список контактов
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(context).height *
                  0.4, // Список занимает максимум 40% экрана
            ),
            child: contacts.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Контакты не найдены',
                        style: TextStyle(color: Colors.black45, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB91ED0,
                            ).withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFFB91ED0,
                              ).withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            splashColor: const Color(
                              0xFFB91ED0,
                            ).withValues(alpha: 0.1),
                            highlightColor: const Color(
                              0xFFB91ED0,
                            ).withValues(alpha: 0.04),
                            onTap: () async {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser == null) return;

                              final myId = currentUser.uid;
                              final chatId = await context
                                  .read<ChatRepository>()
                                  .getOrCreatePrivateChatId(
                                    myId,
                                    contact['id'],
                                  );

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _navigateToChat(context, chatId, myId);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              child: ContactWidget(
                                userData: contact,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

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
