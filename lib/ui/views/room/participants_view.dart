import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
import 'package:strife/ui/widgets/contact_widget.dart';
import 'package:strife/ui/widgets/participant_in_room_widget.dart';

class ParticipantsView extends StatelessWidget {
  final ScrollController scrollController;

  const ParticipantsView({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    // Получаем список участников звонка из VCSBloc
    final participants = context.select(
      (VCSBloc bloc) => bloc.state.participants,
    );

    final count = participants.length;
    final roomId = context.select((VCSBloc bloc) => bloc.roomId);

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

          // Левосторонний заголовок со счетчиком в стиле Strife
          Row(
            children: [
              const Text(
                'Участники',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '($count)',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Список участников звонка
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height *
                    0.4, // Список занимает максимум 40% экрана
              ),
              child: ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                itemCount: count,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ParticipantWidget(participant: participants[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Нижняя панель с кнопками
          Row(
            children: [
              // Кнопка cкопировать ссылку
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.link_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                  label: const Text(
                    'Ссылка',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Кнопка пригласить контакты
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null || roomId == null) return;

                    // Загружаем список контактов перед открытием
                    context.read<ContactsBloc>().add(
                      LoadContactsRequested(currentUserId: currentUser.uid),
                    );
                    context.read<ContactsBloc>().add(
                      const SearchContactsRequested(searchQuery: ''),
                    );

                    // Закрываем шторку участников перед открытием шторки приглашений
                    Navigator.pop(context);

                    // Открываем диалоговое окно с приглашением
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) => SingleChildScrollView(
                        child: InviteContactSheet(
                          user: currentUser,
                          roomId: roomId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    'Пригласить',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class InviteContactSheet extends StatefulWidget {
  final User user;
  final String roomId;

  const InviteContactSheet({
    super.key,
    required this.user,
    required this.roomId,
  });

  @override
  State<InviteContactSheet> createState() => _InviteContactSheetState();
}

class _InviteContactSheetState extends State<InviteContactSheet> {
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
    // Сбрасываем поиск при закрытии шторки, чтобы вернуть полный список контактов
    _contactsBloc.add(ResetContactsStatusRequested());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<ContactsBloc, bool>(
      (bloc) => bloc.state.status == ContactStatus.loading,
    );
    final contacts = context.watch<ContactsBloc>().state.filteredContacts;

    return BlocListener<ContactsBloc, ContactsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ContactStatus.failure) {
          AppNotifications.showError(context, state.error ?? 'Ошибка');
        } else if (state.status == ContactStatus.inviteSuccess) {
          AppNotifications.showSuccess(context, 'Приглашения отправлены');
          context.read<ContactsBloc>().add(ResetContactsStatusRequested());
          Navigator.pop(context);
        }
      },
      child: Padding(
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
              'Пригласить контакты',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите участников из списка ваших контактов, чтобы отправить им приглашение в текущую комнату.',
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

            InviteButton(
              isLoading: isLoading,
              selectedUserIds: _selectedUserIds,
              widget: widget,
              contacts: contacts,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class InviteButton extends StatelessWidget {
  const InviteButton({
    super.key,
    required this.isLoading,
    required Set<String> selectedUserIds,
    required this.widget,
    required this.contacts,
  }) : _selectedUserIds = selectedUserIds;

  final bool isLoading;
  final Set<String> _selectedUserIds;
  final InviteContactSheet widget;
  final List<Map<String, dynamic>> contacts;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading || _selectedUserIds.isEmpty
          ? null
          : () {
              final senderId = widget.user.uid;
              final senderName = widget.user.displayName ?? 'User';
              final senderPhotoUrl = widget.user.photoURL ?? '';

              // Рассылаем уведомления выбранным контактам
              final notificationRepository = context
                  .read<NotificationRepository>();
              for (var id in _selectedUserIds) {
                final contactData = contacts.firstWhere((c) => c['id'] == id);

                final Map<String, Map<String, dynamic>> participantsInfo = {
                  widget.user.uid: {
                    'displayName': widget.user.displayName,
                    'photoUrl': widget.user.photoURL,
                  },
                  id: {
                    'displayName': contactData['displayName'],
                    'photoUrl': contactData['photoUrl'],
                  },
                };

                notificationRepository.sendCallRequest(
                  recipientId: id,
                  roomId: widget.roomId,
                  senderId: senderId,
                  senderPhotoUrl: senderPhotoUrl,
                  senderName: senderName,
                  participantsInfo: participantsInfo,
                );
              }

              AppNotifications.showSuccess(context, 'Приглашения отправлены');
              Navigator.pop(context);
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              _selectedUserIds.isNotEmpty
                  ? 'Пригласить (${_selectedUserIds.length})'
                  : 'Пригласить',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }
}
