import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class CallView extends StatelessWidget {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textEditingController = TextEditingController();

    return Scaffold(
      // Заголовок в верху страницы
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Strife',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 36,
              ),
            ),

            const Text(
              'Видеоконференции',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
        actions: [
          // Кнопка уведомлений
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => NotificationsView()),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ), // Белое кольцо
                ),
                child: const Icon(
                  Icons.notifications_none_rounded, // Иконка колокольчика
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
        ),
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
  const NewCallSheet({super.key, required this.user});

  final User user;

  @override
  State<NewCallSheet> createState() => _NewCallSheetState();
}

class _NewCallSheetState extends State<NewCallSheet> {
  final Set<String> _selectedUserIds = {};
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65, // Откроется на 60% высоты
      maxChildSize: 0.65,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        // Получаем актуальный список контактов
        final contacts = context.watch<ContactsBloc>().state.filteredContacts;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          child: Column(
            children: <Widget>[
              // Заголовок
              const Padding(
                padding: EdgeInsets.only(bottom: 9.0),
                child: Text(
                  "Начать звонок",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // Поиск контактов
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: TextField(
                  onChanged: (value) {
                    // При изменеии текста отправляем событие на поиcк
                    context.read<ContactsBloc>().add(
                      SearchContactsRequested(searchQuery: value),
                    );
                  },

                  decoration: InputDecoration(
                    hintText: 'Поиск контакта...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(
                      Icons.search,
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

              // Список контактов
              Expanded(
                child: contacts.isNotEmpty
                    ? ListView.separated(
                        itemCount: contacts.length,
                        controller: scrollController,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];

                          // Сам участник
                          return ContactWidget(
                            userData: contact,
                            trailing: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0xFFF8E9FF),
                                shape: BoxShape.circle,
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                child: _selectedUserIds.contains(contact['id'])
                                    ? const Icon(Icons.check)
                                    : const Icon(Icons.add),
                                onTap: () {
                                  setState(() {
                                    if (_selectedUserIds.contains(
                                      contact['id'],
                                    )) {
                                      // Убираем контакт если он уже есть
                                      _selectedUserIds.remove(contact['id']);
                                    } else {
                                      // Добавляем контакт которому хотим отправить уведомление
                                      _selectedUserIds.add(contact['id']);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        // Разделитель
                        separatorBuilder: (context, index) => Divider(
                          thickness: 0.5,
                          color: Colors.grey,
                          endIndent: 10,
                          indent: 10,
                        ),
                      )
                    : const Center(child: Text('Список пуст')),
              ),

              // Кнопка начать звонок
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.widthOf(context) * 0.8, 60),
                    side: BorderSide(
                      color: Colors.black,
                      width: 1.3,
                    ), // Обводка кнопки
                    foregroundColor: Colors.black, // Цвет текста и иконки
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: const Text('Начать звонок'),

                  onPressed: () async {
                    // Айди отправителя
                    final senderId = widget.user.uid;

                    // Имя отправителя
                    final senderName = widget.user.displayName!;

                    // Фото отправителя
                    final senderPhotoUrl = widget.user.photoURL!;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    // создание комнаты в БД
                    final roomId = await context
                        .read<VCSRepository>()
                        .createRoom();

                    if (!context.mounted) return;

                    // Закрываем кружок
                    Navigator.of(context).pop();

                    if (roomId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) =>
                                VCSBloc(context.read<VCSRepository>())..add(
                                  ConnectRequested(
                                    roomName: roomId,
                                    identity: widget.user.uid,
                                    name: widget.user.displayName!,
                                    photoUrl: widget.user.photoURL,
                                  ),
                                ),
                            child: const RoomView(),
                          ),
                        ),
                      );

                      final userRepo = context.read<UserRepository>();

                      // Отправляем уведомления всем кого добавили
                      for (var id in _selectedUserIds) {
                        userRepo.sendCallRequest(
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
