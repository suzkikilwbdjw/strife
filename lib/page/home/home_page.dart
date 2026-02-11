import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:strife/page/room/room_page.dart';
import 'package:strife/models/client_model.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final TextEditingController textEditingController = TextEditingController();
    return Scaffold(
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
            Image.network(user.photoURL!),
            Text('Display name: ${user.displayName}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CreateRoomButton(
                  user: user,
                  textEditingController: textEditingController,
                ),
                JoinRoomButton(user: user),
              ],
            ),
            SizedBox(
              width: 400,
              child: TextField(
                controller: textEditingController,
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinRoomButton extends StatelessWidget {
  const JoinRoomButton({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: () async {}, child: Text('Join room'));
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
      child: Text('Create room'),
    );
  }
}
