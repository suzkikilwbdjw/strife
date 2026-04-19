import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/contacts/contacts_bloc.dart';
import 'package:strife/presentation/contacts/contacts_event.dart';
import 'package:strife/presentation/contacts/contacts_state.dart';
import 'package:strife/themes/gradient_theme.dart';

class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Загружаем список контактов
    Future.microtask(() {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      if (!context.mounted) return;

      context.read<ContactsBloc>().add(
        LoadContactsRequested(currentUserId: userId),
      );

      context.read<ContactsBloc>().add(
        SearchContactsRequested(searchQuery: ''),
      );
    });

    return Scaffold(
      // AppBar
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Контакты',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
              ),
              textAlign: TextAlign.right,
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
          final contacts = state.filteredContacts;

          if (contacts.isEmpty && state.searchQuery.isEmpty) {
            return const Center(child: Text('Список контактов пуст'));
          }

          if (contacts.isEmpty && state.searchQuery.isNotEmpty) {
            return const Center(child: Text('Ничего не найдено'));
          }

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
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: Theme.of(
                            context,
                          ).extension<GradientTheme>()!.mainGradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            'Все контакты',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Кнопка "Избранные"
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 18,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Избранные',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Colors.black12),

              // Список контактов
              Expanded(
                child: ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 75,
                    endIndent: 16,
                    color: Colors.white24,
                  ),
                  itemBuilder: (context, index) {
                    return ContactWidget(userData: contacts[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ContactWidget extends StatelessWidget {
  const ContactWidget({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final photoUrl = userData['photoUrl'] as String?;
    final displayName = userData['displayName'] as String? ?? 'Без имени';
    final email = userData['email'] as String? ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Аватарка
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.grey, size: 30)
            : null,
      ),

      // Отображаемое имя
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),

      // Выпадающие меню с редактирование контакта
      trailing: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          // Кнопка видеовызова
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Colors.purple),
              onPressed: () {},
            ),
          ),

          const SizedBox(width: 8),

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert_outlined),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.purple.shade700,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(
                    'Добавить в избранный',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),

                PopupMenuItem(
                  child: Text(
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
      ),

      // Адрес почты
      subtitle: email.isNotEmpty
          ? Row(
              children: [
                // Иконка почты
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 14,
                  color: Colors.black45,
                ),

                const SizedBox(width: 4),

                // Email
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
