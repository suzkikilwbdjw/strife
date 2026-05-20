import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
import 'package:strife/ui/widgets/contact_widget.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView>
    with AutomaticKeepAliveClientMixin {
  // Флаг для показа только избранных контактов
  bool _showFavorites = false;
  final User user = FirebaseAuth.instance.currentUser!;
  // Для получения адреса почты
  final TextEditingController textEditingController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Устанавливаем поиск по контактам в ноль
    context.read<ContactsBloc>().add(
      const SearchContactsRequested(searchQuery: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final mainGradient = Theme.of(
      context,
    ).extension<GradientTheme>()!.mainGradient;

    return Scaffold(
      // Загловок
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

        title: ContactAppBar(textEditingController: textEditingController),
      ),

      body: BlocBuilder<ContactsBloc, ContactsState>(
        builder: (context, state) {
          // Получаем список контактов
          final displayedContacts = _showFavorites
              ? state.filteredContacts
                    .where((c) => c['isFavorite'] == true)
                    .toList()
              : state.filteredContacts;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      // Вкладка "Все контакты"
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showFavorites = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: !_showFavorites ? mainGradient : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Все контакты',
                                style: TextStyle(
                                  color: !_showFavorites
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Вкладка "Избранные"
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showFavorites = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: _showFavorites ? mainGradient : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showFavorites
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 16,
                                  color: _showFavorites
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Избранные',
                                  style: TextStyle(
                                    color: _showFavorites
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Список контактов
              Expanded(
                child: displayedContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showFavorites
                                  ? Icons.star_border_rounded
                                  : Icons.people_outline_rounded,
                              size: 40,
                              color: Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _showFavorites
                                  ? 'Нет избранных контактов'
                                  : 'Список контактов пуст',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayedContacts.length,
                        itemBuilder: (context, index) {
                          final contact = displayedContacts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 4.0,
                                ),
                                child: ContactWidget(
                                  userData: contact,
                                  trailing: _buildDefaultTrailing(
                                    context,
                                    contact,
                                    user,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Трейлинг
  Widget _buildDefaultTrailing(
    BuildContext context,
    Map<String, dynamic> userData,
    User user,
  ) {
    final isFavorite = userData['isFavorite'] ?? false;
    const brandColor = Color(0xFFB91ED0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kнопка видеовызова
        IconButton(
          icon: const Icon(
            Icons.videocam_outlined,
            color: brandColor,
            size: 22,
          ),
          onPressed: () async {
            final senderId = user.uid;
            final senderName = user.displayName!;
            final senderPhotoUrl = user.photoURL!;

            final roomId = await context.read<VCSRepository>().createRoom(
              roomName: 'Групповой звонок',
              creatorId: senderId,
            );

            if (!context.mounted) return;

            if (roomId.isNotEmpty) {
              final vcsBloc = context.read<VCSBloc>();

              vcsBloc.add(
                ConnectRequested(
                  roomId: roomId,
                  identity: user.uid,
                  name: user.displayName!,
                  photoUrl: user.photoURL,
                ),
              );

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
              final participantId = userData['id'];
              final Map<String, Map<String, dynamic>> participantsInfo = {
                user.uid: {
                  'displayName': user.displayName,
                  'photoUrl': user.photoURL,
                },
                participantId: {
                  'displayName': userData['displayName'],
                  'photoUrl': userData['photoUrl'],
                },
              };

              notificationRepository.sendCallRequest(
                recipientId: participantId,
                roomId: roomId,
                senderId: senderId,
                senderPhotoUrl: senderPhotoUrl,
                senderName: senderName,
                participantsInfo: participantsInfo,
              );
            } else {
              AppNotifications.showError(context, 'Не удалось создать комнату');
            }
          },
        ),

        // Кнопка выпадающего меню управления контактом
        PopupMenuButton<int>(
          icon: const Icon(
            Icons.more_vert_outlined,
            color: Colors.black45,
            size: 20,
          ),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Text(
                isFavorite ? 'Удалить из избранных' : 'Добавить в избранное',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              onTap: () {
                context.read<ContactsBloc>().add(
                  ToggleFavoriteRequested(
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    contactId: userData['id'],
                    isFavorite: !isFavorite,
                  ),
                );
              },
            ),
            PopupMenuItem(
              value: 2,
              child: const Text(
                'Удалить из контактов',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                context.read<ContactsBloc>().add(
                  RemoveContactsRequested(
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    contactId: userData['id'],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ContactAppBar extends StatelessWidget {
  const ContactAppBar({super.key, required this.textEditingController});

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Контакты',
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => AddContactSheet(
                    textEditingController: textEditingController,
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Поле поиска контактов
        TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            context.read<ContactsBloc>().add(
              SearchContactsRequested(searchQuery: value),
            );
          },
          decoration: InputDecoration(
            labelText: 'Поиск контактов',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'Введите имя или email...',
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

class AddContactSheet extends StatefulWidget {
  final TextEditingController textEditingController;

  const AddContactSheet({super.key, required this.textEditingController});

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<ContactsBloc, bool>(
      (bloc) => bloc.state.status == ContactStatus.loading,
    );

    return BlocListener<ContactsBloc, ContactsState>(
      listener: (context, state) {
        if (state.status == ContactStatus.failure) {
          AppNotifications.showError(context, state.error ?? 'Ошибка');
        } else if (state.status == ContactStatus.inviteSuccess) {
          AppNotifications.showSuccess(context, 'Запрос отправлен');
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  'Новый контакт',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Введите почту пользователя, которого хотите добавить в список контактов.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Поле ввода email
                TextFormField(
                  controller: widget.textEditingController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Электронная почта',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Введите email';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(val.trim())) {
                      return 'Введите корректный email адрес';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Kнопка отправки
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (!_formKey.currentState!.validate()) return;

                          final recipientEmail = widget
                              .textEditingController
                              .text
                              .trim();
                          final currentUser = FirebaseAuth.instance.currentUser;

                          if (currentUser == null) return;

                          context.read<ContactsBloc>().add(
                            SendFriendRequestRequested(
                              senderId: currentUser.uid,
                              recipientEmail: recipientEmail,
                              senderName: currentUser.displayName ?? 'User',
                              senderPhotoUrl: currentUser.photoURL ?? '',
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : const Text(
                          'Отправить запрос',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
