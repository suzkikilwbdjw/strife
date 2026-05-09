import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/widgets/contact_widget.dart';

class MeetingsView extends StatelessWidget {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Встречи',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 32,
              ),
              textAlign: TextAlign.right,
            ),

            OutlinedButton(
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => NewMeetingSheet(),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Новая встреча',
                style: TextStyle(color: Colors.black, fontSize: 16),
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
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) => Text('Список пуст'),
      ),
    );
  }
}

class NewMeetingSheet extends StatelessWidget {
  const NewMeetingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        // Делаем отступ сверху, чтобы модалка не прилипала к краю экрана
        margin: const EdgeInsets.only(top: 50),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с крестиком
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 30), // Для центровки заголовка
                const Text(
                  'Новая встреча',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Поля ввода
            _buildInputField('Название встречи', 'Планерка команды'),
            _buildInputField(
              'Участники',
              'Выбрать контакты',
              icon: Icons.person_outline,
              onTap: () => _showContactsPicker(context),
            ),
            _buildInputField(
              'Дата',
              'дд.мм.гггг',
              icon: Icons.calendar_today_outlined,
            ),
            _buildInputField('Время', '--:--', icon: Icons.access_time),

            const SizedBox(height: 40),

            // Кнопка "Начать звонок"
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Создать встречу',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Вспомогательный метод для создания полей
  Widget _buildInputField(
    String label,
    String hint, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 8),

          TextField(
            onTap: onTap,
            readOnly: onTap != null,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintStyle: TextStyle(
                color: onTap != null ? Colors.black : Colors.grey.shade400,
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
        ],
      ),
    );
  }

  void _showContactsPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          maxChildSize: 0.4,
          minChildSize: 0.3,
          builder: (_, scrollController) {
            // Получаем актуальный список контактов
            final contacts = context
                .watch<ContactsBloc>()
                .state
                .filteredContacts;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: <Widget>[
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

                  // Отображение списка контактов
                  Expanded(
                    child: contacts.isNotEmpty
                        ? ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 4.0,
                            ),
                            itemCount: contacts.length,
                            controller: scrollController,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];

                              // Сам участник
                              return ContactWidget(userData: contact);
                            },
                            separatorBuilder: (context, index) => Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 24,
                            ),
                          )
                        : Center(child: Text('Список пуст')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
