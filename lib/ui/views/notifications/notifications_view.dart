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

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
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
  void initState() {
    super.initState();
    // Получаем текущего пользователя
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Сразу при входе отправляем сигнал на сервер
      context.read<NotificationRepository>().markAllNotificationsAsRead(
        currentUser.uid,
      );
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
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB91ED0)),
            );
          }

          final notes = snapshot.data!;

          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Уведомлений пока нет',
                    style: TextStyle(color: Colors.black45, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          const brandColor = Color(0xFFB91ED0);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final type = note['type'];
              final senderName = note['senderName'];
              final senderId = note['senderId'];
              final bool isUnread = note['status'] == 'unread';

              return Dismissible(
                key: Key(note['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onDismissed: (direction) {
                  context.read<NotificationRepository>().hiddenNotification(
                    note['id'],
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? brandColor.withValues(alpha: 0.06)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnread
                          ? brandColor.withValues(alpha: 0.2)
                          : brandColor.withValues(alpha: 0.03),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Аватарка отправителя
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            note['senderPhotoUrl'] != null &&
                                note['senderPhotoUrl'].isNotEmpty
                            ? NetworkImage(note['senderPhotoUrl'])
                            : null,
                        child:
                            note['senderPhotoUrl'] == null ||
                                note['senderPhotoUrl'].isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 22,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Центральный блок с текстом
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: TextStyle(
                                // Выделяем жирным, если уведомление еще не прочитано
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              switch (type) {
                                'friend_request' =>
                                  'Отправил запрос на добавление в контакты',
                                'call_request' => 'Приглашение в видеозвонок',
                                'meeting_request' =>
                                  'Приглашение на запланированную встречу',
                                'update_meeting_request' =>
                                  'Информация о встрече была обновлена',
                                _ => 'Новое системное уведомление',
                              },
                              style: TextStyle(
                                color: isUnread
                                    ? Colors.black87
                                    : Colors.black54,
                                fontSize: 13,
                                fontWeight: isUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),

                            // Кнопки действия при запросе в друзья
                            if (type == 'friend_request') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Кнопка принять запрос
                                  AcceptFriendRequestButton(
                                    brandColor: brandColor,
                                    senderId: senderId,
                                    note: note,
                                  ),

                                  const SizedBox(width: 8),

                                  // Кнопка отклонить запрос
                                  RejectFriendRequestButton(note: note),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Время и индикатор для новых уведомлений
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatTimestamp(note['timestamp']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.circle,
                              color: brandColor,
                              size: 8,
                            ),
                          ],
                        ],
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

class AcceptFriendRequestButton extends StatelessWidget {
  const AcceptFriendRequestButton({
    super.key,
    required this.brandColor,
    required this.senderId,
    required this.note,
  });

  final Color brandColor;
  final dynamic senderId;
  final Map<String, dynamic> note;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          try {
            context.read<ContactsBloc>().add(
              AddContactsRequested(
                currentUserId: FirebaseAuth.instance.currentUser!.uid,
                contactId: senderId,
              ),
            );
            context.read<NotificationRepository>().hiddenNotification(
              note['id'],
            );
            if (context.mounted) {
              AppNotifications.showSuccess(
                context,
                'Контакт успешно добавлен!',
              );
            }
          } on FirebaseException catch (e) {
            AppNotifications.showError(
              context,
              e.message ?? 'Ошибка базы данных',
            );
          }
        },
        child: const Text(
          'Принять',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class RejectFriendRequestButton extends StatelessWidget {
  const RejectFriendRequestButton({super.key, required this.note});

  final Map<String, dynamic> note;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          context.read<NotificationRepository>().hiddenNotification(note['id']);
        },
        child: const Text(
          'Отклонить',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
