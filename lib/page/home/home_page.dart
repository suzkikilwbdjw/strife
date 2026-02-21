import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:strife/page/room/room_page.dart';
import 'package:strife/models/client_model.dart';
import 'package:provider/provider.dart';
import 'package:strife/themes/gradient_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final TextEditingController textEditingController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Strife',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 40,
              ),
              textAlign: TextAlign.right,
            ),
            Text(
              'Видеоконференции',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.normal,
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_outlined),
            label: 'Звонки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.messenger_outline),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Встречи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            label: 'Контакты',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
        child: Icon(Icons.output),
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
                  user: user,
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
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final client = ClientModel();

        client.setParticipantIdemtity(textEditingController.text);
        client.setParticipantName(user.displayName!);
        client.setParticipantPhotoUrl(user.photoURL!);
        //client.setParticipantRoom();

        final isConnected = await client.connectToRoom();

        if (!context.mounted) return;

        FocusScope.of(context).unfocus();

        if (isConnected) {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: client,
                child: RoomPage(),
              ),
            ),
          );
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось создать комнату: ${client.error}'),
            ),
          );
        }
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
