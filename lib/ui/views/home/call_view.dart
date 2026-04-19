import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/views/room/room_view.dart';

class CallView extends StatelessWidget {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textEditingController = TextEditingController();
    return Scaffold(
      // Заголовок в верху страницы
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'Strife',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 36,
              ),
            ),

            Text(
              'Видеоконференции',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),

            SizedBox(height: 24),
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

      // Основной контент
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Кнопка создания комнаты
                CreateRoomButton(
                  textEditingController: textEditingController,
                  user: FirebaseAuth.instance.currentUser!,
                ),

                const SizedBox(width: 8),

                // Кнопка присоединения к звонку
                JoinRoomButton(),

                const SizedBox(width: 8),
              ],
            ),

            const Divider(
              height: 24, // Пространство над и под линией
              thickness: 1, // Толщина самой линии
              color: Colors.grey, // Цвет
            ),

            const Text(
              'Недавние',
              style: TextStyle(color: Colors.purple, fontSize: 18),
            ),

            const Divider(
              height: 24, // Пространство над и под линией
              thickness: 1, // Толщина самой линии
              color: Colors.grey, // Цвет
            ),

            Expanded(
              child: ListView.separated(
                itemCount: 20,

                // Разделительная полоса
                separatorBuilder: (context, index) =>
                    Divider(height: 24, thickness: 1, color: Colors.grey),

                // Само создание списка элементов
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Элемент $index'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinRoomButton extends StatelessWidget {
  const JoinRoomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {},

      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),

      child: Ink(
        height: 150,
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9D9D9).withValues(alpha: 0.7),
              ),
              child: const Icon(Icons.add, size: 50),
            ),

            const SizedBox(height: 8),

            const Text(
              'Присоединиться',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateRoomButton extends StatelessWidget {
  const CreateRoomButton({
    super.key,
    required this.user,
    required this.textEditingController,
  });
  final TextEditingController textEditingController;
  final User user;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        // Открывает диалоговое окно с созданием звонка
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.6, // Откроется на 60% высоты
            maxChildSize: 0.6,
            expand: false,
            builder: (context, scrollController) => Container(
              margin: const EdgeInsets.only(top: 60),
              child: Column(
                children: <Widget>[
                  // Заголовок
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Начать звонок",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Поиск контактов

                  // Список контактов
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Контакт',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          Divider(thickness: 1, color: Colors.grey, height: 24),
                      itemCount: 20,
                    ),
                  ),

                  // Кнопка начать звонок
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(),
                      child: const Text('Начать звонок'),

                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final vcsBloc = context.read<VCSBloc>();

                        // Отправляем событие подключения
                        vcsBloc.add(
                          ConnectRequested(
                            roomName: 'test-room',
                            identity: textEditingController.text.isNotEmpty
                                ? textEditingController.text
                                : FirebaseAuth.instance.currentUser!.uid,
                            name: user.displayName ?? 'bobik',
                            photoUrl: user.photoURL,
                          ),
                        );

                        // Ждём, пока localParticipant появится в состоянии
                        await vcsBloc.stream.firstWhere(
                          (state) => state.isConnected == true,
                        );

                        if (!context.mounted) return;

                        Navigator.of(context).pop(); // закрываем индикатор

                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RoomView()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(8),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),

      child: Ink(
        width: 170,
        height: 170,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: Theme.of(context).extension<GradientTheme>()!.mainGradient,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: <Widget>[
            Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9D9D9).withValues(alpha: 0.4),
              ),
              child: const Icon(Icons.videocam_outlined, size: 50),
            ),

            const SizedBox(height: 8),

            const Text(
              'Новый звонок',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
