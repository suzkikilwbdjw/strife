import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_state.dart';
import 'package:strife/themes/gradient_theme.dart';
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

  // Для получения адреса почты
  final TextEditingController textEditingController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Устанавливаем поиск по контактам в ноль
    context.read<ContactsBloc>().add(SearchContactsRequested(searchQuery: ''));
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
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: <Widget>[
                    // Кнопка "Все контакты"
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showFavorites = false),

                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: !_showFavorites ? mainGradient : null,
                            color: _showFavorites
                                ? const Color(0xFFD9D9D9)
                                : null,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Все контакты',
                              style: TextStyle(
                                color: !_showFavorites
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Кнопка "Избранные"
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showFavorites = true),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: _showFavorites ? mainGradient : null,
                            color: !_showFavorites
                                ? const Color(0xFFD9D9D9)
                                : null,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showFavorites ? Icons.star : Icons.star_border,
                                size: 18,
                                color: _showFavorites
                                    ? Colors.white
                                    : Colors.black54,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                'Избранные',
                                style: TextStyle(
                                  color: _showFavorites
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
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

              const Divider(height: 1, thickness: 1, color: Colors.black12),

              // Список контактов
              Expanded(
                child: displayedContacts.isEmpty
                    ? Center(
                        child: Text(
                          _showFavorites
                              ? 'Нет избранных контактов'
                              : 'Список пуст',
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedContacts.length,
                        itemBuilder: (context, index) => ContactWidget(
                          userData: displayedContacts[index],
                          trailing: _buildDefaultTrailing(
                            context,
                            displayedContacts[index],
                          ),
                        ),
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
  ) {
    final isFavorite = userData['isFavorite'] ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Кнопка видеовызова
        _buildCircleButton(
          icon: Icons.videocam_outlined,
          onPressed: () {
            // Lогика вызова
          },
        ),
        const SizedBox(width: 8),
        // Меню
        _buildCircleButton(
          child: PopupMenuButton(
            icon: const Icon(Icons.more_vert_outlined),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.purple.shade700,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(
                  isFavorite ? 'Удалить из избранных' : 'Добавить в избранное',
                  style: const TextStyle(color: Colors.white),
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
                child: const Text(
                  'Удалить из контактов',
                  style: TextStyle(color: Colors.white),
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
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    IconData? icon,
    VoidCallback? onPressed,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
      ),
      child:
          child ??
          IconButton(
            icon: Icon(icon, color: Colors.purple),
            onPressed: onPressed,
          ),
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
