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

class _ContactsViewState extends State<ContactsView> {
  // Флаг для показа только избранных контактов
  bool _showFavorites = false;

  // Для получения адреса почты
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Загружаем данные
    context.read<ContactsBloc>().add(
      LoadContactsRequested(currentUserId: userId),
    );

    // Устанавливаем поиск по контактам в ноль
    context.read<ContactsBloc>().add(SearchContactsRequested(searchQuery: ''));
  }

  @override
  Widget build(BuildContext context) {
    final mainGradient = Theme.of(
      context,
    ).extension<GradientTheme>()!.mainGradient;

    return Scaffold(
      // AppBar
      appBar: AppBar(
        toolbarHeight: 130,
        title: Column(
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
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.right,
                ),

                // Плюсик добавления контакта
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBDBDBD).withValues(alpha: 0.4),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddContactSheet(
                          textEditingController: textEditingController,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextField(
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
                    : ListView.separated(
                        itemCount: displayedContacts.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 75,
                          endIndent: 16,
                          color: Colors.black12,
                        ),
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

  // Вспомогательный метод для круглых кнопок, чтобы не дублировать BoxDecoration
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

class AddContactSheet extends StatelessWidget {
  const AddContactSheet({super.key, required this.textEditingController});

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<ContactsBloc, bool>(
      (value) => value.state.isLoading,
    );

    return BlocListener<ContactsBloc, ContactsState>(
      // Слушаем изменения состояния
      listener: (context, state) {
        if (state.error != null) {
          // Если появилась ошибка — показываем её
          AppNotifications.showError(context, state.error!);
        } else if (!state.isLoading) {
          // Если загрузка завершилась и ошибки нет — значит успех
          AppNotifications.showSuccess(context, 'Запрос отправлен');
          Navigator.pop(context); // Закрываем шторку только при успехе
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    'Новый контакт',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Text(
                'Введите почту пользователя, которого хотите добавить',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Поле ввода email
              TextField(
                controller: textEditingController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Введите email...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null // Блокируем кнопку, пока идет загрузка
                      : () {
                          final recipientEmail = textEditingController.text
                              .trim();
                          if (recipientEmail.isEmpty) return;

                          context.read<ContactsBloc>().add(
                            SendFriendRequestRequested(
                              senderId: FirebaseAuth.instance.currentUser!.uid,
                              recipientEmail: recipientEmail,
                              senderName:
                                  FirebaseAuth
                                      .instance
                                      .currentUser
                                      ?.displayName ??
                                  'User',
                              senderPhotoUrl:
                                  FirebaseAuth.instance.currentUser?.photoURL ??
                                  '',
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Отправить запрос...',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
