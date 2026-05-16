import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    final creatorId = meetingInfo['senderId'];

    final title = meetingInfo['titleMeeting'];

    final date = meetingInfo['dateMeeting'];
    final DateTime tempDate = DateTime.parse(date);
    final String formattedDate = DateFormat('dd.MM.yyyy').format(tempDate);

    final time = meetingInfo['timeMeeting'];
    final participants = meetingInfo['participantIds'] as List;

    return Container(
      // Настройка размеров и отступов карточки
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FA), // Светлый фон
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Название встречи
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              // Кнопка редактирования
              if (creatorId == FirebaseAuth.instance.currentUser!.uid)
                IconButton(
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          NewMeetingSheet(initialMeeting: meetingInfo),
                    );
                  },
                  icon: const Icon(Icons.mode_edit_outline_outlined),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Ряд с информацией
          Row(
            children: [
              _buildInfoItem(Icons.calendar_month_outlined, formattedDate),
              const SizedBox(width: 16),
              _buildInfoItem(Icons.access_time, time),
              const SizedBox(width: 16),
              _buildInfoItem(
                Icons.person_outline,
                participants.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Кнопка 'Присоединиться'
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                final roomId = meetingInfo['roomId'];

                // Проверка существует ли комната
                final exists = await context
                    .read<VCSRepository>()
                    .checkRoomExists(roomId);
                if (!context.mounted) return;

                Navigator.of(context).pop(); // закрыли loader

                if (exists) {
                  final User user = FirebaseAuth.instance.currentUser!;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                            VCSBloc(context.read<VCSRepository>())..add(
                              ConnectRequested(
                                roomId: roomId,
                                identity: user.uid,
                                name: user.displayName!,
                                photoUrl: user.photoURL!,
                              ),
                            ),
                        child: const RoomView(),
                      ),
                    ),
                  );
                } else {
                  // Ошибка в случае неправельного id комнаты
                  if (!context.mounted) return;

                  Navigator.of(context).pop(); // закрываем лоадер

                  // Показываем ошибку пользователю
                  AppNotifications.showError(
                    context,
                    'Введен неверный id комнаты',
                  );

                  return;
                }
              },
              icon: const Icon(
                Icons.videocam_outlined,
                color: Colors.white,
                size: 28,
              ),
              label: const Text(
                'Присоединиться',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC137DF), // Фиолетовый цвет
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Присодениться к встрече можно только за 10 минут до начала
  bool canJoin(DateTime meetingDate, TimeOfDay meetingTime) {
    final now = DateTime.now();
    final start = DateTime(
      meetingDate.year,
      meetingDate.month,
      meetingDate.day,
      meetingTime.hour,
      meetingTime.minute,
    );

    return now.isAfter(start.subtract(const Duration(minutes: 10)));
  }

  // Вспомогательный метод для элементов информации
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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

  // Выбранное время встречи
  TimeOfDay? _selectedTime;

  // Выбранная дата встречи
  DateTime? _selectedDate;

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

      // Дата
      if (meeting['dateMeeting'] != null) {
        _selectedDate = DateTime.parse(meeting['dateMeeting']);
        _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);
      }

      //  Время
      if (meeting['timeMeeting'] != null) {
        final String timeStr = meeting['timeMeeting'];

        // Убираем лишние пробелы и переводим в верхний регистр
        final cleanTime = timeStr.trim().toUpperCase();

        // Определяем, есть ли там AM/PM
        bool isPM = cleanTime.contains('PM');
        bool isAM = cleanTime.contains('AM');

        // Убираем буквы, оставляем только цифры и двоеточие
        final parts = cleanTime
            .replaceAll('AM', '')
            .replaceAll('PM', '')
            .trim()
            .split(':');

        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          // Корректируем часы для 12-часового формата
          if (isPM && hour < 12) hour += 12;
          if (isAM && hour == 12) hour = 0;

          _selectedTime = TimeOfDay(hour: hour, minute: minute);

          _timeController.text = timeStr;
        }
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
      listener: (context, state) {
        if (state.error != null) {
          AppNotifications.showError(context, state.error!);
        } else if (!state.isLoading) {
          widget.initialMeeting == null
              ? AppNotifications.showSuccess(context, 'Встреча создана')
              : AppNotifications.showSuccess(context, 'Встреча обновлена');

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

                const SizedBox(height: 24),

                // Название встречи
                _buildInputField(
                  'Название встречи',
                  'Планерка команды',
                  controller: _titleController,
                  prefix: const Icon(Icons.edit_outlined),
                ),

                const SizedBox(height: 16),

                // Участники
                _buildParticipantsField(),

                const SizedBox(height: 16),

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

                const SizedBox(height: 16),

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
                            final user = FirebaseAuth.instance.currentUser!;

                            final senderId = user.uid;
                            final senderName = user.displayName!;
                            final senderPhotoUrl = user.photoURL!;

                            final String dateIso = _selectedDate!
                                .toIso8601String()
                                .split('T')[0];

                            final String timeString = _selectedTime!.format(
                              context,
                            );

                            if (widget.initialMeeting != null) {
                              context.read<MeetingsBloc>().add(
                                SendUpdateMeetingRequested(
                                  meetingId: widget.initialMeeting!['id'],
                                  senderId: senderId,
                                  participantIds: _selectedUserIds.keys
                                      .toList(),
                                  senderName: senderName,
                                  senderPhotoUrl: senderPhotoUrl,
                                  titleMeeting: _titleController.text.trim(),
                                  dateMeeting: dateIso,
                                  timeMeeting: timeString,
                                ),
                              );
                            } else {
                              final roomId = await context
                                  .read<VCSRepository>()
                                  .createRoom(
                                    roomName: 'test',
                                    creatorId: senderId,
                                  );

                              if (!context.mounted) return;

                              context.read<MeetingsBloc>().add(
                                SendMeetingRequestRequested(
                                  senderId: senderId,
                                  participantIds: _selectedUserIds.keys
                                      .toList(),
                                  senderName: senderName,
                                  senderPhotoUrl: senderPhotoUrl,
                                  roomId: roomId,
                                  titleMeeting: _titleController.text.trim(),
                                  dateMeeting: dateIso,
                                  timeMeeting: timeString,
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

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB91ED0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final timeOfDay = await showTimePicker(
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

    if (timeOfDay != null && timeOfDay != _selectedTime) {
      setState(() {
        _selectedTime = timeOfDay;
        _timeController.text = _selectedTime!.format(context);
      });
    }
  }

  Widget _buildParticipantsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Участники',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),

        const SizedBox(height: 8),

        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showContactsPicker(context),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
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
                          style: TextStyle(fontSize: 15, color: Colors.black54),
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
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),

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

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,

            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFB91ED0),
                width: 1.5,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
        return StatefulBuilder(
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              padding: const EdgeInsets.symmetric(vertical: 4),
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
        );
      },
    );
  }
}
