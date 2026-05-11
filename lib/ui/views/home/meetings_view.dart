import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<UserRepository>().getMettingsStream(
          FirebaseAuth.instance.currentUser!.uid,
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
          final meetings = snapshot.data!;

          if (meetings.isEmpty) {
            return const Center(child: Text('У вас пока нет активных встреч'));
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];

              return MettingCard(mettingInfo: meeting);
            },
          );
        },
      ),
    );
  }
}

class MettingCard extends StatelessWidget {
  final Map<String, dynamic> mettingInfo;

  const MettingCard({super.key, required this.mettingInfo});

  @override
  Widget build(BuildContext context) {
    final title = mettingInfo['titleMeeting'];

    final date = mettingInfo['dateMeeting'];
    final DateTime tempDate = DateTime.parse(date);
    final String formattedDate = DateFormat('dd.MM.yyyy').format(tempDate);

    final time = mettingInfo['timeMeeting'];
    final participants = mettingInfo['participantIds'] as List;

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
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              IconButton(
                onPressed: () {},
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
                final roomId = mettingInfo['roomId'];

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
                                roomName: roomId,
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

    // Разрешаем вход за 10 минут до
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
  const NewMeetingSheet({super.key});

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

  final TextEditingController _textEditingController = TextEditingController();

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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: SingleChildScrollView(
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
              _buildInputField(
                'Название встречи',
                'Планерка команды',
                textEditingController: _textEditingController,
              ),
              _buildParticipantsField(),
              _buildInputField(
                'Дата',
                _selectedDate != null
                    ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                    : 'дд.мм.гггг',
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  await _pickDate(context);
                },
              ),
              _buildInputField(
                'Время',
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : '--:--',
                icon: Icons.access_time,
                onTap: () async {
                  await _pickTime(context);
                },
              ),

              const SizedBox(height: 40),

              // Кнопка 'Создать встречу'
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () async {
                    if (_textEditingController.text.isEmpty ||
                        _selectedDate == null ||
                        _selectedTime == null) {
                      return;
                    }
                    final user = FirebaseAuth.instance.currentUser!;

                    final senderId = user.uid;
                    final senderName = user.displayName!;
                    final senderPhotoUrl = user.photoURL!;
                    final String dateIso = _selectedDate!
                        .toIso8601String()
                        .split('T')[0];
                    final String timeString = _selectedTime!.format(context);

                    final roomId = await context
                        .read<VCSRepository>()
                        .createRoom();

                    if (!context.mounted) return;

                    // Отправляем уведомления о том что они приглашены на встречу
                    await context
                        .read<NotificationRepository>()
                        .sendMeetingRequest(
                          senderId: senderId,
                          participantIds: _selectedUserIds.keys.toList(),
                          senderName: senderName,
                          senderPhotoUrl: senderPhotoUrl,
                          roomId: roomId,
                          titleMeeting: _textEditingController.text,
                          dateMeeting: dateIso,
                          timeMeeting: timeString,
                        );
                  },
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
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Нельзя выбрать дату в прошлом
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
      });
    }
  }

  Widget _buildParticipantsField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбрать участников',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),

          const SizedBox(height: 8.0),

          // Поле с выбором участников
          GestureDetector(
            onTap: () => _showContactsPicker(context),
            child: Container(
              constraints: const BoxConstraints(minHeight: 55),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 8.0),
                  Expanded(
                    child: _selectedUserIds.isEmpty
                        ? Text(
                            'Выбрать контакты',
                            style: TextStyle(fontSize: 16.0),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _selectedUserIds.values.map((photoUrl) {
                              // Аватар участника
                              return CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(photoUrl),
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                          ),
                  ),
                  const Icon(Icons.person_outline, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный метод для создания полей
  Widget _buildInputField(
    String label,
    String hint, {
    IconData? icon,
    VoidCallback? onTap,
    TextEditingController? textEditingController,
    Widget? prefix,
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
            controller: textEditingController,
            onTap: onTap,
            readOnly: onTap != null,
            decoration: InputDecoration(
              prefixIcon: prefix,
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
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.6,
              minChildSize: 0.6,
              builder: (_, scrollController) {
                // Получаем актуальный список контактов
                final contacts = context
                    .watch<ContactsBloc>()
                    .state
                    .filteredContacts;

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      // Заголовок с крестиком
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 30), // Для центровки заголовка
                          const Text(
                            'Выбрать участников',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      // Поиск контактов
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
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
                                  vertical: 4.0,
                                ),
                                itemCount: contacts.length,
                                controller: scrollController,
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];

                                  // Сам участник
                                  return ContactWidget(
                                    userData: contact,
                                    trailing: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF8E9FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        child:
                                            _selectedUserIds.keys.contains(
                                              contact['id'],
                                            )
                                            ? const Icon(Icons.check)
                                            : const Icon(Icons.add),
                                        onTap: () {
                                          setModalState(() {
                                            final id = contact['id'];
                                            if (_selectedUserIds.containsKey(
                                              id,
                                            )) {
                                              // Убираем контакт если он уже есть
                                              _selectedUserIds.remove(id);
                                            } else {
                                              // Добавляем контакт которому хотим отправить уведомление
                                              _selectedUserIds.addAll({
                                                id: contact['photoUrl'],
                                              });
                                            }
                                          });
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) => Divider(
                                  endIndent: 8,
                                  indent: 8,
                                  thickness: 0.6,
                                  color: Colors.grey,
                                  height: 24,
                                ),
                              )
                            : Center(child: const Text('Список пуст')),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
