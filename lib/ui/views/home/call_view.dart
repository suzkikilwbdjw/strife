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
      appBar: AppBar(
        toolbarHeight: 130,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Strife',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 36,
              ),
              textAlign: TextAlign.right,
            ),

            const Text(
              'Видеоконференции',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),

            const SizedBox(height: 3),

            TextField(
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CreateRoomButton(
                  textEditingController: textEditingController,
                  user: FirebaseAuth.instance.currentUser!,
                ),
                SizedBox(width: 8),
                JoinRoomButton(),
              ],
            ),
            Expanded(
              child: SizedBox(
                width: 300,
                child: TextField(
                  controller: textEditingController,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
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
              'Присоедениться',
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
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
        await vcsBloc.stream.firstWhere((state) => state.isConnected == true);

        if (!context.mounted) return;

        Navigator.of(context).pop(); // закрываем индикатор

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RoomView()));
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
