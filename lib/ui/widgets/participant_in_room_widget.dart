import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/contacts/contacts_bloc.dart';
import 'package:strife/presentation/contacts/contacts_event.dart';

class ParticipantWidget extends StatelessWidget {
  const ParticipantWidget({super.key, required this.participant});
  final Participant participant;
  @override
  Widget build(BuildContext context) {
    final photoUrl = context.select<VCSBloc, String?>(
      (bloc) => bloc.state.photoUrls[participant.sid],
    );

    if (photoUrl == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(photoUrl),
        ),
        title: Text(participant.name, style: TextStyle(color: Colors.white)),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.purple,
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('Назначить главным')),
            PopupMenuItem(
              child: Text('Добавить в контакты'),
              onTap: () {
                // Получаем id текущего пользователя
                final String? myUid = FirebaseAuth.instance.currentUser?.uid;

                // Получаем id, выбранного пользователя
                final String contactId = participant.identity;

                if (myUid != null) {
                  // Добавляем пользователя в контакты
                  context.read<ContactsBloc>().add(
                    AddContactsRequested(
                      currentUserId: myUid,
                      contactId: contactId,
                    ),
                  );
                }
              },
            ),
            const PopupMenuItem(child: Text('Отключить микрофон')),
            const PopupMenuItem(child: Text('Отключить видео')),
            const PopupMenuItem(child: Text('Исключить')),
          ],
        ),
      ),
    );
  }
}
