import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/notification_repository.dart';
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

class CallView extends StatelessWidget {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textEditingController = TextEditingController();

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
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Уведомления',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsView(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Основной контент
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Кнопка создания комнаты
                CreateRoomButton(user: FirebaseAuth.instance.currentUser!),

                const SizedBox(width: 8),

                // Кнопка присоединения к звонку
                JoinRoomButton(
                  user: FirebaseAuth.instance.currentUser!,
                  textEditingController: textEditingController,
                ),

                const SizedBox(width: 8),
              ],
            ),

            const Divider(
              height: 24, // Пространство над и под линией
              thickness: 1, // Толщина самой линии
              color: Colors.grey, // Цвет
            ),

            const Text(
              'Недавние',
              style: TextStyle(color: Colors.purple, fontSize: 18),
            ),

            const Divider(
              height: 24, // Пространство над и под линией
              thickness: 1, // Толщина самой линии
              color: Colors.grey, // Цвет
            ),

            Expanded(
              child: ListView.separated(
                itemCount: 20,

                // Разделительная полоса
                separatorBuilder: (context, index) =>
                    Divider(height: 24, thickness: 1, color: Colors.grey),

                // Само создание списка элементов
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Элемент $index'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

                        Navigator.of(context).pop(); // закрыли loader

                        if (exists) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) =>
                                    VCSBloc(context.read<VCSRepository>())..add(
                                      ConnectRequested(
                                        roomName: roomId,
                                        identity: user.uid,
                                        name: user.displayName ?? 'bobik',
                                        photoUrl: user.photoURL,
                                      ),
                                    ),
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
          builder: (context) => NewCallSheet(user: user),
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

          // Фирменная залитая кнопка действия
          ElevatedButton(
            onPressed: () async {
              final senderId = widget.user.uid;
              final senderName = widget.user.displayName!;
              final senderPhotoUrl = widget.user.photoURL!;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final roomId = await context.read<VCSRepository>().createRoom();

              if (!context.mounted) return;
              Navigator.of(context).pop(); // Закрываем крутилку лоадера

              if (roomId.isNotEmpty) {
                final vcsBloc = context.read<VCSBloc>();

                vcsBloc.add(
                  ConnectRequested(
                    roomName: roomId,
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
