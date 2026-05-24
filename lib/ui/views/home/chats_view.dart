import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/chat_screen/chat_screen.dart';
import 'package:strife/ui/widgets/contact_widget.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (context) => ChatBloc(
        chatRepository: context.read<ChatRepository>(),
        userRepository: context.read<UserRepository>(),
        notificationRepository: context.read<NotificationRepository>(),
      )..add(InitChats(userId: userId)),
      child: Scaffold(
        // Загловок страницы
        appBar: AppBar(
          toolbarHeight: 140,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: Theme.of(
                context,
              ).extension<GradientTheme>()!.mainGradient,
            ),
          ),

          title: ChatAppBar(),
        ),

        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final chats = state.filteredChats;

            if (chats.isEmpty) {
              if (state.searchQuery.isNotEmpty) {
                return const Center(
                  child: Text(
                    'Чаты не найдены',
                    style: TextStyle(color: Colors.black45, fontSize: 15),
                  ),
                );
              }
              return const Center(
                child: Text(
                  'У вас пока нет активных чатов',
                  style: TextStyle(color: Colors.black45, fontSize: 15),
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                //Данные чата
                final chat = chats[index];

                // Мой id
                final myId = FirebaseAuth.instance.currentUser!.uid;

                // Учасtника чата, list содеrжит только id
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

                // Достаем данные из мапы participantsInfo
                final Map<String, dynamic> participantsInfo =
                    chat['participantsInfo'] ?? {};
                final Map<String, dynamic> partnerData =
                    participantsInfo[partnerId] ?? {};

                final String name = partnerData['displayName'];
                final String? photo = partnerData['photoUrl'];

                return UserInChatCard(
                  photo: photo,
                  name: name,
                  partnerId: partnerId,
                  chat: chat,
                  myId: myId,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class UserInChatCard extends StatelessWidget {
  const UserInChatCard({
    super.key,
    required this.photo,
    required this.name,
    required this.partnerId,
    required this.chat,
    required this.myId,
  });

  final dynamic photo;
  final dynamic name;
  final String partnerId;
  final Map<String, dynamic> chat;
  final String myId;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB91ED0);

    // Достаем данные последнего сообщения
    final String lastMessage = chat['lastMessage'] ?? 'Нет сообщений';
    final String? lastMessageSenderId =
        chat['lastMessageSenderId']; // ID отправителя последнего сообщения
    final List<dynamic> lastMessageReadBy =
        chat['lastMessageReadBy'] ?? []; // Кто прочитал последнее сообщение

    final bool isMyMessage = lastMessageSenderId == myId;
    // Если сообщение чужое и моего ID нет в списке прочитавших — оно непрочитанное
    final bool isUnreadForMe =
        !isMyMessage &&
        lastMessageSenderId != null &&
        !lastMessageReadBy.contains(myId);
    // Если сообщение моё и ID собеседника есть в списке — оно прочитано собеседником
    final bool isReadByPartner =
        isMyMessage && lastMessageReadBy.contains(partnerId);

    final chatRepo = context.read<ChatRepository>();
    final userRepo = context.read<UserRepository>();
    final notifRepo = context.read<NotificationRepository>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openElevation: 0,
        closedElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        closedColor: isUnreadForMe
            ? brandColor.withValues(alpha: 0.06)
            : const Color(0xFFF5F5F7),
        openColor: Theme.of(context).scaffoldBackgroundColor,

        openBuilder: (context, _) => BlocProvider(
          create: (_) => ChatBloc(
            chatRepository: chatRepo,
            userRepository: userRepo,
            notificationRepository: notifRepo,
          )..add(InitChat(chat['id'])),
          child: ChatScreen(chatId: chat['id'], currentUserId: myId),
        ),

        closedBuilder: (context, openContainerAction) => InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: brandColor.withValues(alpha: 0.1),
          highlightColor: brandColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: brandColor.withValues(alpha: 0.15),
                      backgroundImage:
                          photo != null && photo.toString().isNotEmpty
                          ? NetworkImage(photo)
                          : null,
                      child: photo == null || photo.toString().isEmpty
                          ? Text(
                              name != null && name.toString().isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: brandColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 0.0,
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
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Имя и последние сообщение
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name ?? 'Пользователь',
                        style: TextStyle(
                          fontWeight: isUnreadForMe
                              ? FontWeight.bold
                              : FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          color: isUnreadForMe
                              ? Colors.black87
                              : Colors.black54,
                          fontSize: 13,
                          fontWeight: isUnreadForMe
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Время галочка/индикатор
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Время последнего обновления чата
                    Text(
                      chat['lastUpdate'] != null
                          ? _formatTimestamp(chat['lastUpdate'])
                          : '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Если сообщение отправил я
                    if (isMyMessage &&
                        chat['lastMessage'] != null &&
                        chat['lastMessage'].toString().isNotEmpty)
                      Icon(
                        isReadByPartner
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 16,
                        color: isReadByPartner ? brandColor : Colors.black38,
                      ),

                    // Если сообщение пришло мне и оно не прочитано
                    if (isUnreadForMe)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: brandColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
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
                fontSize: 26,
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28.0,
              ),
              onPressed: () {
                final chatBloc = context.read<ChatBloc>();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => SingleChildScrollView(
                    child: BlocProvider.value(
                      value: chatBloc,
                      child: const NewChatSheet(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Поле поиска чатов
        TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (searchQuery) {
            context.read<ChatBloc>().add(SearchChats(searchQuery: searchQuery));
          },
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
    _contactsBloc.add(const SearchContactsRequested(searchQuery: ''));
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
          ContactListWidget(contacts: contacts),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class ContactListWidget extends StatelessWidget {
  const ContactListWidget({super.key, required this.contacts});

  final List<Map<String, dynamic>> contacts;

  @override
  Widget build(BuildContext context) {
    // Извлекаем репозитории на самом верхнем уровне виджета, где контекст 100% валидный
    final chatRepo = context.read<ChatRepository>();
    final userRepo = context.read<UserRepository>();
    final notifRepo = context.read<NotificationRepository>();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
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

                final containerKey = GlobalKey<OpenContainerState>();

                String? generatedChatId;
                final currentUser = FirebaseAuth.instance.currentUser;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: OpenContainer(
                    key: containerKey,
                    tappable: false,
                    transitionType: ContainerTransitionType.fadeThrough,
                    transitionDuration: const Duration(milliseconds: 500),
                    openElevation: 0,
                    closedElevation: 0,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    openShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    closedColor: const Color(
                      0xFFB91ED0,
                    ).withValues(alpha: 0.04),
                    openColor: Theme.of(context).scaffoldBackgroundColor,

                    openBuilder: (context, _) => BlocProvider(
                      create: (_) => ChatBloc(
                        chatRepository: chatRepo,
                        userRepository: userRepo,
                        notificationRepository: notifRepo,
                      )..add(InitChat(generatedChatId!)),
                      child: ChatScreen(
                        chatId: generatedChatId!,
                        currentUserId: currentUser!.uid,
                      ),
                    ),

                    closedBuilder: (context, openContainer) => Ink(
                      decoration: BoxDecoration(
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
                          if (currentUser == null) return;

                          final myId = currentUser.uid;
                          final partnerId = contact['id'];

                          final Map<String, Map<String, String>>
                          participantsInfo = {
                            myId: {
                              'displayName': currentUser.displayName ?? 'Я',
                              'photoUrl': currentUser.photoURL ?? '',
                            },
                            partnerId: {
                              'displayName': contact['displayName'] ?? '',
                              'photoUrl': contact['photoUrl'] ?? '',
                            },
                          };

                          final chatId = await chatRepo
                              .getOrCreatePrivateChatId(
                                myId,
                                partnerId,
                                participantsInfo,
                              );

                          generatedChatId = chatId;

                          if (!context.mounted) return;

                          Navigator.pop(context);

                          containerKey.currentState?.openContainer();
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
                  ),
                );
              },
            ),
    );
  }
}
