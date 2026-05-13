import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_state.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
import 'package:strife/ui/widgets/contact_widget.dart';
import 'package:strife/ui/widgets/participant_in_room_widget.dart';

class ParticipantsView extends StatelessWidget {
  const ParticipantsView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final participants = context.select(
      (VCSBloc bloc) => bloc.state.participants,
    );

    final count = context.select(
      (VCSBloc bloc) => bloc.state.participants.length,
    );

    final roomId = context.select((VCSBloc bloc) => bloc.roomId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Участники ($count)',
          style: TextStyle(color: Colors.deepPurple),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close), // Иконка крестика
            onPressed: () =>
                Navigator.of(context).pop(), // Закрывает модальное окно
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: count,
        controller: scrollController,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: ParticipantWidget(participant: participants[index]),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            // Кнопка ссылка
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {},
              icon: Icon(Icons.link),
              label: const Text('Ссылка'),
            ),
            // Кнопка пригласить участника
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                // Загружаем список контактов
                context.read<ContactsBloc>().add(
                  LoadContactsRequested(
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                );

                context.read<ContactsBloc>().add(
                  SearchContactsRequested(searchQuery: ''),
                );

                // Открывает диалоговое окно с созданием звонка
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => InviteContactSheet(
                    user: FirebaseAuth.instance.currentUser!,
                    roomId: roomId,
                  ),
                );
              },
              icon: Icon(Icons.cabin),
              label: const Text(
                'Пригласить\nконтакты',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InviteContactSheet extends StatefulWidget {
  const InviteContactSheet({
    super.key,
    required this.user,
    required this.roomId,
  });

  final User user;
  final String roomId;
  @override
  State<InviteContactSheet> createState() => _InviteContactSheet();
}

class _InviteContactSheet extends State<InviteContactSheet> {
  // Выбранные пользователя, которые будут приглашены в звонок
  final Set<String> _selectedUserIds = {};

  late ContactsBloc _contactsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contactsBloc = context.read<ContactsBloc>();
  }

  @override
  void dispose() {
    _contactsBloc.add(ResetContactsStatusRequested());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<ContactsBloc, bool>(
      (bloc) => bloc.state.status == ContactStatus.loading,
    );

    return BlocListener<ContactsBloc, ContactsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      // Слушаем изменения состояния
      listener: (context, state) {
        if (state.status == ContactStatus.failure) {
          AppNotifications.showError(context, state.error ?? 'Ошибка');
        } else if (state.status == ContactStatus.inviteSuccess) {
          AppNotifications.showSuccess(context, 'Приглашения отправлены');

          // Oтправляем событие очистки в Блок
          context.read<ContactsBloc>().add(ResetContactsStatusRequested());

          Navigator.pop(context);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.60,
        maxChildSize: 0.75,
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
                    'Пригласить контакты',
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
                      ? ListView.builder(
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
                                  child:
                                      _selectedUserIds.contains(contact['id'])
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
                        )
                      : const Center(child: Text('Список пуст')),
                ),

                // Кнопка
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
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Пригласить'),

                    onPressed: () async {
                      // Айди отправителя
                      final senderId = widget.user.uid;

                      // Имя отправителя
                      final senderName = widget.user.displayName!;

                      // Фото отправителя
                      final senderPhotoUrl = widget.user.photoURL!;

                      for (final recipientId in _selectedUserIds) {
                        context.read<ContactsBloc>().add(
                          SendCallRequestRequested(
                            senderId: senderId,
                            recipientId: recipientId,
                            senderName: senderName,
                            senderPhotoUrl: senderPhotoUrl,
                            roomId: widget.roomId,
                          ),
                        );
                      }
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
}
