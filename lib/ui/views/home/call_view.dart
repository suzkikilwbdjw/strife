import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/notifications/notifications_view.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
import 'package:strife/ui/widgets/contact_widget.dart';

class CallView extends StatefulWidget {
  const CallView({super.key});

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  late final TextEditingController _textEditingController;
  late final User _user;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _user = FirebaseAuth.instance.currentUser!;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Заголовок в верху страницы
      appBar: AppBar(
        toolbarHeight: 110,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
        ),

        // Основной заголовок и подзаголовок
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Strife',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 32,
              ),
            ),
            Text(
              'Видеоконференции',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),

        // Правая часть с кнопками действий
        actions: [
          // Иконка уведомлений
          StreamBuilder<int>(
            stream: context
                .read<NotificationRepository>()
                .getUnreadCountNotificationStream(_user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              final hasUnread = unreadCount > 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsView(),
                        ),
                      );
                    },
                  ),

                  if (hasUnread)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedScale(
                        scale: hasUnread ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFB91ED0),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Основной контент
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16),

          // Блок верхних кнопок действий
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Кнопка создания комнаты
                Expanded(
                  child: CreateRoomButton(
                    user: FirebaseAuth.instance.currentUser!,
                  ),
                ),
                const SizedBox(width: 12),
                // Кнопка присоединения к звонку
                Expanded(
                  child: JoinRoomButton(
                    user: FirebaseAuth.instance.currentUser!,
                    textEditingController: _textEditingController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Надписи недавние звонки
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Недавние звонки',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'История ваших недавних аудио и видеоконференций',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Список истории звонков
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CallHistory(user: _user),
            ),
          ),
        ],
      ),
    );
  }
}

class CallHistory extends StatelessWidget {
  const CallHistory({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<UserRepository>().getCallsStream(user.uid),
      builder: (context, snapshot) {
        // Обработка ошибки
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        // Затем состояние ожидания
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Проверяем наличие данных
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('У вас пока нет истории звонков'));
        }

        final calls = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: calls.length,
          itemBuilder: (context, index) {
            final call = calls[index];

            return CallCardWidget(
              callData: call,
              onJoinPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final vcsBloc = context.read<VCSBloc>();

                vcsBloc.add(
                  ConnectRequested(
                    roomId: call['id'],
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
              },
            );
          },
        );
      },
    );
  }
}

class CallCardWidget extends StatelessWidget {
  final Map<String, dynamic> callData;
  final VoidCallback onJoinPressed;

  const CallCardWidget({
    super.key,
    required this.callData,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String roomName = callData['roomName'] ?? 'Без названия';
    final List<dynamic> participants = callData['participantIds'] ?? [];
    final String status = callData['status'] ?? 'active';
    final bool isActive = status == 'active';

    const brandColor = Color(0xFFB91ED0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? brandColor.withValues(alpha: 0.06)
              : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? brandColor.withValues(alpha: 0.15)
                : Colors.black12,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Иконка звонка в цвет статуса
              Container(
                padding: const EdgeInsets.all(12),
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
                  color: isActive ? brandColor : Colors.black45,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Информация о звонке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Название комнаты
                    Text(
                      roomName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isActive ? Colors.black : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Количество участников и дата
                    Row(
                      children: [
                        // Иконка людей
                        Icon(
                          Icons.people_alt_outlined,
                          size: 14,
                          color: isActive
                              ? brandColor.withValues(alpha: 0.7)
                              : Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        // Цифра участников
                        Text(
                          '${participants.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? brandColor : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Разделитель-точка
                        const Icon(
                          Icons.circle,
                          size: 4,
                          color: Colors.black26,
                        ),
                        const SizedBox(width: 12),
                        // Дата создания
                        Expanded(
                          child: Text(
                            _formatCallDate(callData['createdAt']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Динамическая кнопка
              isActive
                  ? ElevatedButton(
                      onPressed: onJoinPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            brandColor, // Фиолетовая кнопка "Войти"
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
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
        ),
      ),
    );
  }

  // Форматирование даты из Firestore Timestamp
  String _formatCallDate(dynamic createdAt) {
    if (createdAt == null) return 'Только что';
    if (createdAt is! Timestamp) return 'Неизвестно';

    final DateTime dateTime = createdAt.toDate();
    final DateTime now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Сегодня в ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return 'Вчера в ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd MMM, HH:mm', 'ru').format(dateTime);
    }
  }
}

class JoinRoomButton extends StatelessWidget {
  const JoinRoomButton({
    super.key,
    required this.user,
    required this.textEditingController,
  });

  final TextEditingController textEditingController;
  final User user;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.65,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  children: <Widget>[
                    // Заголовок
                    const Padding(
                      padding: EdgeInsets.only(bottom: 9.0),
                      child: Text(
                        'Присоединиться к звонку',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Поле с вводом id комнаты
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                          hintText: 'Введите id встречи...',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(
                            Icons.connect_without_contact_rounded,
                            color: Colors.grey,
                          ), // Иконка поиска
                          filled: true,

                          fillColor: Color(0xFFD9D9D9),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // Кнопка присоединиться
                    FilledButton(
                      onPressed: () async {
                        final roomId = textEditingController.text.trim();
                        if (roomId.isEmpty) return;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final exists = await context
                            .read<VCSRepository>()
                            .checkRoomExists(roomId);

                        if (!context.mounted) return;

                        if (exists) {
                          final vcsBloc = context.read<VCSBloc>();

                          vcsBloc.add(
                            ConnectRequested(
                              roomId: roomId,
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

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.purpleAccent, // Цвет фона кнопки
                        fixedSize: Size(
                          MediaQuery.widthOf(context) * 0.8,
                          60,
                        ), // Размер кнопки
                        textStyle: TextStyle(fontSize: 18),
                      ),

                      child: Text('Присоединиться'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },

      // Оформление кнопки
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),

      // Оформление кнопки
      child: Ink(
        height: 150,
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9D9D9).withValues(alpha: 0.7),
              ),
              child: const Icon(Icons.add, size: 50),
            ),

            const SizedBox(height: 8),

            const Text(
              'Присоединиться',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateRoomButton extends StatelessWidget {
  const CreateRoomButton({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        // Загружаем список контактов
        context.read<ContactsBloc>().add(
          LoadContactsRequested(currentUserId: user.uid),
        );

        context.read<ContactsBloc>().add(
          SearchContactsRequested(searchQuery: ''),
        );

        // Открывает диалоговое окно с созданием звонка
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) =>
              SingleChildScrollView(child: NewCallSheet(user: user)),
        );
      },

      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(8),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),

      child: Ink(
        width: 170,
        height: 170,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: Theme.of(context).extension<GradientTheme>()!.mainGradient,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: <Widget>[
            Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9D9D9).withValues(alpha: 0.4),
              ),
              child: const Icon(Icons.videocam_outlined, size: 50),
            ),

            const SizedBox(height: 8),

            const Text(
              'Новый звонок',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewCallSheet extends StatefulWidget {
  final User user;

  const NewCallSheet({super.key, required this.user});

  @override
  State<NewCallSheet> createState() => _NewCallSheetState();
}

class _NewCallSheetState extends State<NewCallSheet> {
  final Set<String> _selectedUserIds = {};
  final _searchController = TextEditingController();
  final _roomNameController = TextEditingController();

  late ContactsBloc _contactsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contactsBloc = context.read<ContactsBloc>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomNameController.dispose();
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

          // Левосторонний заголовок
          const Text(
            'Начать звонок',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          const Text(
            'Выберите контакты из списка ниже, чтобы пригласить их в новую комнату звонка.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // Поле названия звонка
          TextField(
            controller: _roomNameController,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            decoration: const InputDecoration(
              labelText: 'Название звонка',
              hintText: 'Обсуждение проекта...',
              prefixIcon: Icon(Icons.label_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

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
              maxHeight: MediaQuery.sizeOf(context).height * 0.35,
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
                      final isSelected = _selectedUserIds.contains(
                        contact['id'],
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Ink(
                          decoration: BoxDecoration(
                            // Если контакт выбран, плашка становится чуть насыщеннее
                            color: isSelected
                                ? const Color(
                                    0xFFB91ED0,
                                  ).withValues(alpha: 0.08)
                                : const Color(
                                    0xFFB91ED0,
                                  ).withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(
                                      0xFFB91ED0,
                                    ).withValues(alpha: 0.2)
                                  : const Color(
                                      0xFFB91ED0,
                                    ).withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedUserIds.remove(contact['id']);
                                } else {
                                  _selectedUserIds.add(contact['id']);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              child: ContactWidget(
                                userData: contact,
                                // Кнопка выбора
                                trailing: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFB91ED0)
                                        : const Color(
                                            0xFFB91ED0,
                                          ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_rounded
                                        : Icons.add_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFB91ED0),
                                    size: 20,
                                  ),
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

          // Кнопка создать звонок
          ElevatedButton(
            onPressed: () async {
              final rawRoomName = _roomNameController.text.trim();
              final displayRoomName = rawRoomName.isNotEmpty
                  ? rawRoomName
                  : 'Групповой звонок';

              final senderId = widget.user.uid;
              final senderName = widget.user.displayName!;
              final senderPhotoUrl = widget.user.photoURL!;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final roomId = await context.read<VCSRepository>().createRoom(
                roomName: displayRoomName,
                creatorId: senderId,
              );

              if (!context.mounted) return;
              Navigator.of(context).pop(); // Закрываем крутилку лоадера

              if (roomId.isNotEmpty) {
                final vcsBloc = context.read<VCSBloc>();

                vcsBloc.add(
                  ConnectRequested(
                    roomId: roomId,
                    identity: widget.user.uid,
                    name: widget.user.displayName!,
                    photoUrl: widget.user.photoURL,
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

                final notificationRepository = context
                    .read<NotificationRepository>();

                for (var id in _selectedUserIds) {
                  notificationRepository.sendCallRequest(
                    recipientId: id,
                    roomId: roomId,
                    senderId: senderId,
                    senderPhotoUrl: senderPhotoUrl,
                    senderName: senderName,
                  );
                }
              } else {
                AppNotifications.showError(
                  context,
                  'Не удалось создать комнату',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Начать звонок',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
