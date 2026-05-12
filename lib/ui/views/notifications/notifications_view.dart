import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    // Преобразуем Firestore Timestamp в DateTime
    DateTime date = (timestamp as Timestamp).toDate();
    DateTime now = DateTime.now();

    // Если сегодня — показываем только время, если нет — дату
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Уведомления',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<NotificationRepository>().getNotificationsStream(
          userId,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data!;

          if (notes.isEmpty) {
            return const Center(child: Text('Уведомлений пока нет'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final type = note['type'];
              final senderName = note['senderName'] ?? 'Пользователь';
              final senderId = note['senderId'] ?? 'бебеб';

              return Dismissible(
                key: Key(note['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  context.read<NotificationRepository>().removeNotification(
                    note['id'],
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Аватарка
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(note['senderPhotoUrl']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              switch (type) {
                                'friend_request' =>
                                  'Отправил запрос на добавление в контакты',
                                'call_request' => 'Звонил вам',
                                'meeting_request' => 'Приглашение на встречу',
                                'update_meeting_request' =>
                                  'Обновление встречи',
                                _ => 'Неизвестное уведомление',
                              },
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            if (type == 'friend_request') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _ActionButton(
                                    label: 'Принять',
                                    color: Colors.green,
                                    // Обработка нажатия принять
                                    onTap: () async {
                                      try {
                                        context.read<ContactsBloc>().add(
                                          AddContactsRequested(
                                            currentUserId: FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                            contactId: senderId,
                                          ),
                                        );

                                        context
                                            .read<NotificationRepository>()
                                            .removeNotification(note['id']);

                                        if (context.mounted) {
                                          AppNotifications.showSuccess(
                                            context,
                                            'Контакт добавлен!',
                                          );
                                        }
                                      } on FirebaseException catch (e) {
                                        AppNotifications.showError(
                                          context,
                                          e.message!,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionButton(
                                    label: 'Отклонить',
                                    color: Colors.red,
                                    // Обработка нажатия отклонить
                                    onTap: () {
                                      context
                                          .read<NotificationRepository>()
                                          .removeNotification(note['id']);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Дата
                      Text(
                        formatTimestamp(note['timestamp']),
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Вспомогательный виджет кнопки
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
