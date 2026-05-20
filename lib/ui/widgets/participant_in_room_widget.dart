import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';

class ParticipantWidget extends StatelessWidget {
  final Participant participant;

  const ParticipantWidget({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    const brandColor = Color(0xFFB91ED0);

    final photoUrl = context.select<VCSBloc, String?>(
      (bloc) => bloc.state.photoUrls[participant.sid],
    );

    final isHost = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.hostSids.contains(participant.identity),
    );

    final currentUserIsHost = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.hostSids.contains(myUid),
    );

    final userIsMutedMicrophone = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.mutedMicrophoneByHostSids[participant.sid] ?? false,
    );

    final userIsMutedCamera = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.mutedCameraByHostSids[participant.sid] ?? false,
    );

    final isAlreadyContact = context.select<ContactsBloc, bool>(
      (bloc) => bloc.state.allContacts.any(
        (contact) => contact['id'] == participant.identity,
      ),
    );

    if (photoUrl == null) return const SizedBox.shrink();

    final isMe = participant.identity == myUid;

    return Container(
      decoration: BoxDecoration(
        color: isHost
            ? brandColor.withValues(alpha: 0.08)
            : brandColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHost
              ? brandColor.withValues(alpha: 0.2)
              : brandColor.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: ListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        horizontalTitleGap: 12,

        // Аватарка участника
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.grey, size: 22)
              : null,
        ),

        // Имя и индикаторы оборудования
        title: Row(
          children: [
            Flexible(
              child: Text(
                participant.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (userIsMutedMicrophone || userIsMutedCamera)
              const SizedBox(width: 8),
            if (userIsMutedMicrophone)
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.mic_off_rounded,
                  color: Colors.redAccent,
                  size: 16,
                ),
              ),
            if (userIsMutedCamera)
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
          ],
        ),

        // Метка хоста, надпись "Вы" или кастомное меню действий
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHost)
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
              ),
            !isMe
                ? PopupMenuButton<int>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.black45,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    itemBuilder: (context) => [
                      // Опция контакты
                      PopupMenuItem(
                        value: 1,
                        child: Text(
                          isAlreadyContact
                              ? 'Удалить из контактов'
                              : 'Добавить в контакты',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          if (myUid == null) return;
                          context.read<ContactsBloc>().add(
                            isAlreadyContact
                                ? RemoveContactsRequested(
                                    currentUserId: myUid,
                                    contactId: participant.identity,
                                  )
                                : AddContactsRequested(
                                    currentUserId: myUid,
                                    contactId: participant.identity,
                                  ),
                          );
                        },
                      ),
                      // Опции для хоста (модерация)
                      if (currentUserIsHost) ...[
                        PopupMenuItem(
                          value: 2,
                          child: const Text(
                            'Назначить хостом',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            context.read<VCSBloc>().add(
                              TransferHostRequested(participant.identity),
                            );
                          },
                        ),
                        PopupMenuItem(
                          value: 3,
                          child: Text(
                            userIsMutedMicrophone
                                ? 'Разрешить микрофон'
                                : 'Отключить микрофон',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            context.read<VCSBloc>().add(
                              userIsMutedMicrophone
                                  ? UnmuteParticipantRequested(
                                      participant.identity,
                                    )
                                  : MuteParticipantRequested(
                                      participant.identity,
                                    ),
                            );
                          },
                        ),
                        PopupMenuItem(
                          value: 4,
                          child: Text(
                            userIsMutedCamera
                                ? 'Разрешить показ видео'
                                : 'Отключить показ видео',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            context.read<VCSBloc>().add(
                              userIsMutedCamera
                                  ? EnableCameraParticipantRequested(
                                      participant.identity,
                                    )
                                  : DisableCameraParticipantRequested(
                                      participant.identity,
                                    ),
                            );
                          },
                        ),
                        PopupMenuItem(
                          value: 5,
                          child: const Text(
                            'Исключить',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            context.read<VCSBloc>().add(
                              KickParticipantRequested(participant.identity),
                            );
                          },
                        ),
                      ],
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Вы',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
