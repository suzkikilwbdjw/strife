import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_state.dart';
import 'package:strife/presentation/blocs/meetings/meetings_bloc.dart';
import 'package:strife/presentation/blocs/meetings/meetings_event.dart';
import 'package:strife/presentation/blocs/meetings/meetings_state.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
import 'package:strife/ui/widgets/contact_widget.dart';

class MeetingsView extends StatefulWidget {
  const MeetingsView({super.key});

  @override
  State<MeetingsView> createState() => _MeetingsViewState();
}

class _MeetingsViewState extends State<MeetingsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
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

        title: MeetingsAppBar(),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<UserRepository>().getMettingsStream(
          FirebaseAuth.instance.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          // Обработка ошибки
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          // Затем состояние ожидания
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Проверяем наличие данных
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('У вас пока нет активных встреч'));
          }

          final meetings = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];

              return MeetingCard(meetingInfo: meeting);
            },
          );
        },
      ),
    );
  }
}

class MeetingsAppBar extends StatelessWidget {
  const MeetingsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Встречи',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 26,
              ),
            ),

            // Кнопка добавить встречу
            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28.0,
              ),
              tooltip: 'Новая встреча',
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => const NewMeetingSheet(),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Строка поиска встреч
        TextField(
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white, // Белый курсор
          onChanged: (value) {
            // context.read<MeetingsBloc>().add(SearchMeetingsRequested(query: value));
          },
          decoration: InputDecoration(
            labelText: 'Поиск встреч',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'Введите название...',
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

class MeetingCard extends StatelessWidget {
  final Map<String, dynamic> meetingInfo;

  const MeetingCard({super.key, required this.meetingInfo});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB91ED0);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final creatorId = meetingInfo['senderId'];
    final title = meetingInfo['titleMeeting'] ?? 'Без названия';

    // Парсинг даты и времени
    final meetingDateTime = (meetingInfo['meetingDateTime'] as Timestamp)
        .toDate();
    final formattedDate = DateFormat('dd.MM.yyyy').format(meetingDateTime);
    final formattedTime = DateFormat('HH:mm').format(meetingDateTime);

    final participants = meetingInfo['participantIds'] as List;

    // Определение статусов встречи
    final String status = meetingInfo['status'];
    final bool isStarted = status == 'started';
    final bool isCompleted = status == 'completed';
    final bool isCancelled = status == 'cancelled';
    final bool isNotStarted = status == 'not_started';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isStarted
              ? brandColor.withValues(alpha: 0.06)
              : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStarted
                ? brandColor.withValues(alpha: 0.2)
                : brandColor.withValues(alpha: 0.03),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок карточки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Кнопка редактирования только для создателя встречи
                if (creatorId == myUid &&
                    !isCompleted &&
                    !isStarted &&
                    !isCancelled)
                  IconButton(
                    icon: const Icon(
                      Icons.mode_edit_outline_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (context) =>
                            NewMeetingSheet(initialMeeting: meetingInfo),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Ряд с метаданными встречи (Дата, Время, Участники)
            Row(
              children: [
                _buildInfoItem(
                  Icons.calendar_today_outlined,
                  formattedDate,
                  isStarted,
                  brandColor,
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.access_time_rounded,
                  formattedTime,
                  isStarted,
                  brandColor,
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.people_alt_outlined,
                  participants.length.toString(),
                  isStarted,
                  brandColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isCompleted)
              // Встреча завершена
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Встреча завершена',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (isNotStarted)
              // Встреча запланирована, но еще не началась
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_clock_outlined, size: 18),
                label: const Text(
                  'Не началась',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              )
            else if (isStarted)
              // Встреча активна прямо сейчас
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.video_call_rounded, size: 22),
                label: const Text(
                  'Войти в звонок',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final roomId = meetingInfo['roomId'];
                  final bool exists = await context
                      .read<VCSRepository>()
                      .checkRoomExists(roomId);

                  if (!context.mounted) return;

                  if (exists) {
                    final User user = FirebaseAuth.instance.currentUser!;
                    final vcsBloc = context.read<VCSBloc>();

                    vcsBloc.add(
                      ConnectRequested(
                        roomId: roomId,
                        identity: user.uid,
                        name: user.displayName ?? 'User',
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
                  } else {
                    AppNotifications.showError(
                      context,
                      'Эта комната конференции больше не существует',
                    );
                  }
                },
              )
            else if (isCancelled)
              // Встреча отменена
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Встреча отменена',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Красивый хелпер метаданных
  Widget _buildInfoItem(
    IconData icon,
    String text,
    bool isStarted,
    Color brandColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isStarted ? brandColor.withValues(alpha: 0.7) : Colors.black45,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isStarted ? brandColor : Colors.black54,
            fontSize: 13,
            fontWeight: isStarted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class NewMeetingSheet extends StatefulWidget {
  const NewMeetingSheet({super.key, this.initialMeeting});

  final Map<String, dynamic>? initialMeeting;

  @override
  State<NewMeetingSheet> createState() => _NewMeetingSheetState();
}

class _NewMeetingSheetState extends State<NewMeetingSheet> {
  // Выбранные пользователя, которые будут приглашены в звонок
  final Map<String, dynamic> _selectedUserIds = {};

  DateTime? _selectedDate; // Отдельно дата
  TimeOfDay? _selectedTime; // Отдельно время
  DateTime? _selectedDateTime; // Полная дата+время

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Ключ для управления формой
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialMeeting != null) {
      final meeting = widget.initialMeeting!;

      // Заголовок
      _titleController.text = meeting['titleMeeting'] ?? '';

      // Время и дата
      if (meeting['meetingDateTime'] != null) {
        // Выставление текущей даты встрeчи
        _selectedDateTime = (meeting['meetingDateTime'] as Timestamp).toDate();

        // Выставление даты в поле ввода
        _dateController.text = DateFormat(
          'dd.MM.yyyy',
        ).format(_selectedDateTime!);

        // Выставление времени в поле ввода
        _timeController.text = DateFormat('HH:mm').format(_selectedDateTime!);

        _selectedDate = DateTime(
          _selectedDateTime!.year,
          _selectedDateTime!.month,
          _selectedDateTime!.day,
        );

        _selectedTime = TimeOfDay(
          hour: _selectedDateTime!.hour,
          minute: _selectedDateTime!.minute,
        );
      }

      // Участники
      final List<dynamic> participantIds = meeting['participantIds'] ?? [];
      _selectedUserIds.clear();

      // Получаем текущий список всех контактов из BLoC
      final allContacts = context.read<ContactsBloc>().state.allContacts;

      for (var id in participantIds) {
        // Ищем контакт в стейте по ID
        final contact = allContacts.firstWhere(
          (c) => c['id'] == id,
          orElse: () => <String, dynamic>{},
        );

        if (contact.isNotEmpty) {
          _selectedUserIds[id] = contact['photoUrl'];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<MeetingsBloc, bool>(
      (value) => value.state.isLoading,
    );

    return BlocListener<MeetingsBloc, MeetingsState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.isLoading != current.isLoading,
      listener: (context, state) {
        if (state.error != null) {
          AppNotifications.showError(context, state.error!);
          return;
        }

        if (!state.isLoading) {
          if (widget.initialMeeting == null) {
            AppNotifications.showSuccess(context, 'Встреча создана');
          } else if (state.isCancelled) {
            AppNotifications.showSuccess(context, 'Встреча отменена');
          } else {
            AppNotifications.showSuccess(context, 'Встреча обновлена');
          }
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
                // Верхний индикатор
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
                Text(
                  widget.initialMeeting == null
                      ? 'Новая встреча'
                      : 'Редактирование встречи',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.initialMeeting == null
                      ? 'Создайте новую встречу и пригласите участников.'
                      : 'Измените информацию о встрече.',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 20),

                // Название встречи
                _buildInputField(
                  'Название встречи',
                  'Планерка команды...',
                  controller: _titleController,
                  prefix: const Icon(Icons.edit_outlined),
                ),

                const SizedBox(height: 16),

                // Участники
                _buildParticipantsField(),

                const SizedBox(height: 8),

                // Дата
                _buildInputField(
                  'Дата',
                  'дд.мм.гггг',
                  controller: _dateController,
                  prefix: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    await _pickDate(context);
                  },
                ),

                const SizedBox(height: 8),

                // Время
                _buildInputField(
                  'Время',
                  '--:--',
                  controller: _timeController,
                  prefix: const Icon(Icons.access_time),
                  onTap: () async {
                    await _pickTime(context);
                  },
                ),

                const SizedBox(height: 32),

                // Кнопка
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final now = DateTime.now();

                            if (_selectedDateTime!.isBefore(now)) {
                              AppNotifications.showError(
                                context,
                                'Нельзя создать встречу в прошлом',
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser!;

                            final senderId = user.uid;
                            final senderName = user.displayName!;
                            final senderPhotoUrl = user.photoURL!;

                            final titleMeeting = _titleController.text.trim();
                            final meetingDateTime = _selectedDateTime!;
                            final participantIds = _selectedUserIds.keys
                                .toList();

                            if (widget.initialMeeting != null) {
                              final meetingId = widget.initialMeeting!['id'];

                              // Проверка на то что изменились ли какие значения
                              // Достаем старый список из Firestore и приводим его к List<String>
                              final oldParticipants = List<String>.from(
                                widget.initialMeeting!['participantIds'] ?? [],
                              );

                              // Сравниваем их как множества
                              final bool isParticipantsChanged =
                                  Set.from(oldParticipants).length !=
                                      Set.from(participantIds).length ||
                                  !Set.from(
                                    oldParticipants,
                                  ).containsAll(participantIds);

                              // Приводим старую дату из Timestamp к DateTime
                              final DateTime oldDateTime =
                                  (widget.initialMeeting!['meetingDateTime']
                                          as Timestamp)
                                      .toDate();

                              // Сравнение времени
                              final bool isDateChanged =
                                  oldDateTime.millisecondsSinceEpoch !=
                                  meetingDateTime.millisecondsSinceEpoch;

                              // Сравнение текста
                              final bool isTitleChanged =
                                  widget.initialMeeting!['titleMeeting'] !=
                                  titleMeeting;

                              final isChange =
                                  isTitleChanged ||
                                  isDateChanged ||
                                  isParticipantsChanged;

                              if (isChange) {
                                context.read<MeetingsBloc>().add(
                                  SendUpdateMeetingRequested(
                                    meetingId: meetingId,
                                    senderId: senderId,
                                    participantIds: participantIds,
                                    senderName: senderName,
                                    senderPhotoUrl: senderPhotoUrl,
                                    titleMeeting: titleMeeting,
                                    meetingDateTime: meetingDateTime,
                                  ),
                                );
                              } else {
                                Navigator.pop(context);
                              }
                            } else {
                              final roomId = await context
                                  .read<VCSRepository>()
                                  .createRoom(
                                    roomName: 'test',
                                    creatorId: senderId,
                                    type: 'meeting',
                                  );

                              if (!context.mounted) return;

                              context.read<MeetingsBloc>().add(
                                SendMeetingRequestRequested(
                                  senderId: senderId,
                                  participantIds: participantIds,
                                  senderName: senderName,
                                  senderPhotoUrl: senderPhotoUrl,
                                  roomId: roomId,
                                  titleMeeting: titleMeeting,
                                  meetingDateTime: meetingDateTime,
                                ),
                              );
                            }
                          }
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
                      : Text(
                          widget.initialMeeting == null
                              ? 'Создать встречу'
                              : 'Сохранить изменения',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                if (widget.initialMeeting != null) ...[
                  const SizedBox(height: 12),
                  // Кнопка oтменить встречу
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text(
                      'Отменить встречу',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final User user = FirebaseAuth.instance.currentUser!;

    final meetingId = widget.initialMeeting!['id'];
    final roomId = widget.initialMeeting!['roomId'];

    final senderId = user.uid;
    final senderName = user.displayName!;
    final senderPhotoUrl = user.photoURL!;

    final titleMeeting = _titleController.text.trim();
    final meetingDateTime = _selectedDateTime!;
    final participantIds = _selectedUserIds.keys.toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 12,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Предупреждающая красная иконка
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'Отмена встречи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Вы действительно хотите отменить и полностью удалить эту встречу? Это действие нельзя будет отменить.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Красная кнопка подтверждения
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                // Закрываем диалоговое окно
                Navigator.of(dialogContext).pop();

                context.read<MeetingsBloc>().add(
                  SendCancleMeetingRequested(
                    meetingId: meetingId,
                    roomId: roomId,
                    senderId: senderId,
                    titleMeeting: titleMeeting,
                    meetingDateTime: meetingDateTime,
                    senderName: senderName,
                    senderPhotoUrl: senderPhotoUrl,
                    participantIds: participantIds,
                  ),
                );
              },
              child: const Text(
                'Да, отменить',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),

            // Кнопка назад
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Назад',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateControllers() {
    if (_selectedDate != null) {
      _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);
    }
    if (_selectedTime != null) {
      _timeController.text = _selectedTime!.format(context);
    }
  }

  void _updateFullDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      _selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      _selectedDateTime = null;
    }
  }

  // Только выбор даты
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFB91ED0)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _updateControllers();
        _updateFullDateTime();
      });
    }
  }

  // Только выбор времени
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFB91ED0)),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _updateControllers();
        _updateFullDateTime();
      });
    }
  }

  Widget _buildParticipantsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showContactsPicker(context),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black54),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_outlined, color: Colors.black54),

                const SizedBox(width: 12),

                Expanded(
                  child: _selectedUserIds.isEmpty
                      ? const Text(
                          'Выбрать участников',
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedUserIds.values.map((photoUrl) {
                            return CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: NetworkImage(photoUrl),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Вспомогательный метод для создания полей
  Widget _buildInputField(
    String label,
    String hint, {
    VoidCallback? onTap,
    TextEditingController? controller,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          onTap: onTap,
          readOnly: onTap != null,

          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Поле не заполнено';
            }
            return null;
          },

          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showContactsPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setModalState) {
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
                    // Верхний индикатор
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
                      'Выбор участников',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Выберите пользователей, которых хотите пригласить во встречу.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 20),

                    // Поиск
                    TextField(
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
                        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                      ),
                      child: BlocBuilder<ContactsBloc, ContactsState>(
                        builder: (context, state) {
                          final contacts = state.filteredContacts;

                          if (contacts.isEmpty) {
                            return const SizedBox(
                              height: 120,
                              child: Center(
                                child: Text(
                                  'Контакты не найдены',
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];

                              final isSelected = _selectedUserIds.containsKey(
                                contact['id'],
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                                            ).withValues(alpha: 0.25)
                                          : const Color(
                                              0xFFB91ED0,
                                            ).withValues(alpha: 0.06),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    splashColor: const Color(
                                      0xFFB91ED0,
                                    ).withValues(alpha: 0.1),
                                    highlightColor: const Color(
                                      0xFFB91ED0,
                                    ).withValues(alpha: 0.04),
                                    onTap: () {
                                      setModalState(() {
                                        final id = contact['id'];

                                        if (_selectedUserIds.containsKey(id)) {
                                          _selectedUserIds.remove(id);
                                        } else {
                                          _selectedUserIds[id] =
                                              contact['photoUrl'];
                                        }
                                      });

                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      child: ContactWidget(
                                        userData: contact,
                                        trailing: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
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
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Кнопка подтверждения
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedUserIds.isEmpty
                            ? 'Закрыть'
                            : 'Готово (${_selectedUserIds.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
