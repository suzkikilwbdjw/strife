import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/contacts/contacts_bloc.dart';
import 'package:strife/presentation/contacts/contacts_event.dart';
import 'package:strife/presentation/contacts/contacts_state.dart';
import 'package:strife/themes/gradient_theme.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  // Флаг для показа только избранных контактов
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    // Загружаем данные
    final userId = FirebaseAuth.instance.currentUser!.uid;
    context.read<ContactsBloc>().add(
      LoadContactsRequested(currentUserId: userId),
    );
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
                        itemBuilder: (context, index) =>
                            ContactWidget(userData: displayedContacts[index]),
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
    final isFavorite = userData['isFavorite'] ?? false;

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
      title: Row(
        children: [
          Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(width: 4),

          if (isFavorite) const Icon(Icons.star, color: Colors.amberAccent),
        ],
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
              // Обводка
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
                // Добавление в избранное
                PopupMenuItem(
                  child: !isFavorite
                      ? const Text(
                          'Добавить в избранное',
                          style: TextStyle(color: Colors.white),
                        )
                      : const Text(
                          'Удалить из избранных',
                          style: TextStyle(color: Colors.white),
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

                // Удаление контакта
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
