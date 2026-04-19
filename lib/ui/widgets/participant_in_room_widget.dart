import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_event.dart';

class ParticipantWidget extends StatelessWidget {
  const ParticipantWidget({super.key, required this.participant});
  final Participant participant;
  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null) {
      context.read<ContactsBloc>().add(
        LoadContactsRequested(currentUserId: myUid),
      );
    }

    final photoUrl = context.select<VCSBloc, String?>(
      (bloc) => bloc.state.photoUrls[participant.sid],
    );

    // Являеся ли участник хостом (пометка звездой)
    final isHost = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.hostSids[participant.sid] ?? false,
    );

    // Является ли локальный участник хостом (То есть "я")
    final currentUserIsHost = context.select<VCSBloc, bool>(
      (bloc) =>
          bloc.state.hostSids[bloc.state.participants
              .firstWhere(
                (p) => p.identity == FirebaseAuth.instance.currentUser!.uid,
              )
              .sid] ??
          false,
    );

    // Отключени ли доступ yчастникa k микрофон админом
    final userIsMutedMicrophone = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.mutedMicrophoneByHostSids[participant.sid] ?? false,
    );

    // Отключени ли доступ yчастника k камере админом
    final userIsMutedCamera = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.mutedCameraByHostSids[participant.sid] ?? false,
    );

    // Находится ли участник уже в контактах
    final isAlreadyContact = context.select<ContactsBloc, bool>(
      (bloc) => bloc.state.allContacts.any(
        (contact) => contact['id'] == participant.identity,
      ),
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
        title: Row(
          children: [
            Text(participant.name, style: TextStyle(color: Colors.white)),
            if (userIsMutedMicrophone)
              const Icon(Icons.mic_off_outlined, color: Colors.red),
            if (userIsMutedCamera)
              const Icon(Icons.videocam_off_outlined, color: Colors.red),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHost)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.stars, color: Colors.amber, size: 20),
              ),
            participant.identity != FirebaseAuth.instance.currentUser!.uid
                ? PopupMenuButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.purple,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () {
                          final String? myUid =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (myUid == null) return;

                          if (!isAlreadyContact) {
                            // Если нет в контактах
                            context.read<ContactsBloc>().add(
                              AddContactsRequested(
                                currentUserId: myUid,
                                contactId: participant.identity,
                              ),
                            );
                          } else {
                            // Если есть в контактах
                            context.read<ContactsBloc>().add(
                              RemoveContactsRequested(
                                currentUserId: myUid,
                                contactId: participant.identity,
                              ),
                            );
                          }
                        },
                        child: !isAlreadyContact
                            ? Text('Добавить в контакты')
                            : Text('Удалить из контактов'),
                      ),
                      if (currentUserIsHost) ...[
                        PopupMenuItem(
                          child: Text('Назначить главным'),
                          onTap: () {
                            context.read<VCSBloc>().add(
                              TransferHostRequested(participant.identity),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: !userIsMutedMicrophone
                              ? const Text('Отключить доступ к микрофону')
                              : const Text('Разрешить доступ к микрофону'),
                          onTap: () {
                            if (!userIsMutedMicrophone) {
                              context.read<VCSBloc>().add(
                                MuteParticipantRequested(participant.identity),
                              );
                            } else {
                              context.read<VCSBloc>().add(
                                UnmuteParticipantRequested(
                                  participant.identity,
                                ),
                              );
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: !userIsMutedCamera
                              ? const Text('Отключить доступ к показу видео')
                              : const Text('Разрешить доступ к показу видео'),
                          onTap: () {
                            if (!userIsMutedCamera) {
                              context.read<VCSBloc>().add(
                                DisableCameraParticipantRequested(
                                  participant.identity,
                                ),
                              );
                            } else {
                              context.read<VCSBloc>().add(
                                EnableCameraParticipantRequested(
                                  participant.identity,
                                ),
                              );
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Исключить'),
                          onTap: () {
                            context.read<VCSBloc>().add(
                              KickParticipantRequested(participant.identity),
                            );
                          },
                        ),
                      ],
                    ],
                  )
                : Text(
                    'Вы',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
          ],
        ),
      ),
    );
  }
}
