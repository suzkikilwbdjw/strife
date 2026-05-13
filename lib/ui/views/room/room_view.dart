import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_event.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/presentation/blocs/vcs/vcs_state.dart';
import 'package:strife/ui/views/chat/chat_screen.dart';
import 'package:strife/ui/views/room/participants_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

class RoomView extends StatelessWidget {
  const RoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return MultiBlocListener(
      listeners: [
        // Слушатель подключения
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) =>
              p.isConnected != c.isConnected || p.error != c.error,
          listener: (context, state) {
            if (state.error != null) {
              Navigator.of(context).pop();
              AppNotifications.showError(context, state.error!);
            }
          },
        ),

        // Слушатель переподключения
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) => p.isReconnecting != c.isReconnecting,
          listener: (context, state) {
            if (state.isReconnecting) {
              showDialog(
                context: context,
                useRootNavigator: true,
                barrierDismissible: false,
                builder: (_) => const PopScope(
                  canPop: false,
                  child: AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Переподключение...'),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              Navigator.of(
                context,
                rootNavigator: true,
              ).popUntil((route) => route.isFirst || route is! RawDialogRoute);
            }
          },
        ),

        // Слушатель кика
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) => p.wasKicked != c.wasKicked,
          listener: (context, state) {
            if (state.wasKicked) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              AppNotifications.showInfo(context, 'Вы были удалены из комнаты');
            }
          },
        ),

        // Слушатель микрофона
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) {
            if (c.isReconnecting || p.isReconnecting) return false;

            final sid = _getSid(c, uid);
            if (sid == null) return false;
            if (!_hasParticipant(p, uid)) return false;

            final hadOldValue = p.mutedMicrophoneByHostSids.containsKey(sid);
            if (!hadOldValue) return false;

            return p.mutedMicrophoneByHostSids[sid] !=
                c.mutedMicrophoneByHostSids[sid];
          },
          listener: (context, state) {
            final sid = _getSid(state, uid)!;
            final isMuted = state.mutedMicrophoneByHostSids[sid];
            if (isMuted == null) return;

            AppNotifications.showInfo(
              context,
              isMuted
                  ? 'Модератор отключил ваш микрофон'
                  : 'Модератор разрешил доступ к микрофону',
            );

            context.read<VCSBloc>().add(
              SyncHardwareStatus(isMicEnabled: false),
            );
          },
        ),

        // СЛУШАТЕЛЬ КАМЕРЫ
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) {
            if (c.isReconnecting || p.isReconnecting) return false;

            final sid = _getSid(c, uid);
            if (sid == null) return false;
            if (!_hasParticipant(p, uid)) return false;

            final hadOldValue = p.mutedCameraByHostSids.containsKey(sid);
            if (!hadOldValue) return false;

            return p.mutedCameraByHostSids[sid] != c.mutedCameraByHostSids[sid];
          },
          listener: (context, state) {
            final sid = _getSid(state, uid)!;

            final isMuted = state.mutedCameraByHostSids[sid];

            if (isMuted == null) return;
            AppNotifications.showInfo(
              context,
              isMuted
                  ? 'Модератор отключил вашу камеру'
                  : 'Модератор разрешил доступ к камере',
            );
            context.read<VCSBloc>().add(
              SyncHardwareStatus(isCamEnabled: false),
            );
          },
        ),
      ],

      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // При попытке выйти назад
          if (didPop) return;

          context.read<VCSBloc>().add(
            ToggleMinimizeRoomRequested(minimize: true),
          );

          // Закрываем страницу звонка
          Navigator.of(context).pop();
        },

        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                context.read<VCSBloc>().add(
                  ToggleMinimizeRoomRequested(minimize: true),
                );

                // Закрываем страницу звонка
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),

          bottomNavigationBar: BlocBuilder<VCSBloc, VCSState>(
            builder: (context, state) {
              if (!state.isConnected) return const SizedBox.shrink();
              return const NavigationBottomAppBar();
            },
          ),

          body: const FullVideoCallView(),
        ),
      ),
    );
  }

  // Вспомогательный метод для поиска SID
  String? _getSid(VCSState state, String? uid) {
    try {
      return state.participants.firstWhere((p) => p.identity == uid).sid;
    } catch (_) {
      return null;
    }
  }

  // Вспомогательный медот для проверки был ли участник
  bool _hasParticipant(VCSState state, String? uid) {
    return state.participants.any((p) => p.identity == uid);
  }
}

class FullVideoCallView extends StatelessWidget {
  const FullVideoCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Основной контент
        Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 20, 40, 153),
          ),
          child: const SafeArea(child: ParticipantLayout()),
        ),

        // Overlay загрузки
        BlocBuilder<VCSBloc, VCSState>(
          builder: (context, state) {
            if (state.isConnected) return const SizedBox.shrink();

            return Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Подключение...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class NavigationBottomAppBar extends StatelessWidget {
  const NavigationBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VCSBloc, VCSState>(
      builder: (context, state) {
        final bloc = context.read<VCSBloc>();

        final isMutedMicrophoneByHost = context.select<VCSBloc, bool>((bloc) {
          final uid = FirebaseAuth.instance.currentUser!.uid;

          final hasLocal = bloc.state.participants.any(
            (p) => p.identity == uid,
          );

          if (!hasLocal) return false;

          final sid = bloc.state.participants
              .firstWhere((p) => p.identity == uid)
              .sid;

          return bloc.state.mutedMicrophoneByHostSids[sid] ?? false;
        });

        final isMutedCameraByHost = context.select<VCSBloc, bool>((bloc) {
          final uid = FirebaseAuth.instance.currentUser!.uid;

          final hasLocal = bloc.state.participants.any(
            (p) => p.identity == uid,
          );

          if (!hasLocal) return false;

          final sid = bloc.state.participants
              .firstWhere((p) => p.identity == uid)
              .sid;

          return bloc.state.mutedCameraByHostSids[sid] ?? false;
        });

        return BottomAppBar(
          height: 144,
          color: Colors.black,
          child: Column(
            children: <Widget>[
              Row(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Микрофон (Вкл/Выкл)
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF474747),
                    child: IconButton(
                      iconSize: 28,
                      color: Colors.white,
                      onPressed: state.isReconnecting || isMutedMicrophoneByHost
                          ? null
                          : () => bloc.add(ToggleMicrophoneRequested()),
                      icon: isMutedMicrophoneByHost
                          ? const Icon(
                              Icons.mic_off_outlined,
                              color: Colors.red,
                            )
                          : state.isMicrophoneEnabled
                          ? const Icon(Icons.mic_outlined)
                          : const Icon(Icons.mic_off_outlined),
                    ),
                  ),

                  // Камеры (Вкл/Выкл)
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF474747),
                    child: IconButton(
                      iconSize: 28,
                      color: Colors.white,
                      onPressed: state.isReconnecting || isMutedCameraByHost
                          ? null
                          : () => bloc.add(ToggleCameraRequested()),
                      icon: isMutedCameraByHost
                          ? const Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.red,
                            )
                          : state.isCameraEnabled
                          ? const Icon(Icons.videocam_outlined)
                          : const Icon(Icons.videocam_off_outlined),
                    ),
                  ),

                  // Выйти из комнаты
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFA60A0A),
                    child: IconButton(
                      iconSize: 34,
                      color: Colors.white,
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: const Text(
                              'Вы действительно хотите покинуть комнату?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Нет'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Да'),
                                onPressed: () {
                                  bloc.add(DisconnectRequested());
                                  // Закрываем диалог
                                  Navigator.of(context).pop();
                                  //Закрываем страницу
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.call_end_outlined),
                    ),
                  ),

                  // Звук (Вкл/Выкл)
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF474747),
                    child: IconButton(
                      iconSize: 28,
                      color: Colors.white,
                      onPressed: state.isReconnecting
                          ? null
                          : () => bloc.add(ToggleRemoteAudioRequested()),
                      icon: Icon(
                        state.isRemoteAudioEnabled
                            ? Icons.volume_up_outlined
                            : Icons.volume_off_outlined,
                      ),
                    ),
                  ),

                  // Перевернуть камеру
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF474747),
                    child: IconButton(
                      iconSize: 28,
                      color: Colors.white,
                      onPressed: state.isReconnecting
                          ? null
                          : () => state.isCameraEnabled
                                ? bloc.add(FlipCameraRequested())
                                : null,
                      icon: const Icon(Icons.flip_camera_ios_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Нижняя панель с кнопками чат и участники
              Row(
                spacing: 24,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Чат
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF474747),
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                    ),
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BlocProvider(
                          create: (context) => ChatBloc(
                            chatRepository: context.read<ChatRepository>(),
                            userRepository: context.read<UserRepository>(),
                          )..add(InitChat(bloc.roomId!)),
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.75,
                            maxChildSize: 0.75,
                            expand: false,
                            builder: (context, scrollController) => Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                              ),
                              child: ChatScreen(
                                controller: scrollController,
                                chatId: bloc.roomId!,
                                currentUserId:
                                    FirebaseAuth.instance.currentUser!.uid,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Чат'),
                  ),
                  // Участники
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF474747),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BlocProvider.value(
                          value: bloc,
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.6,
                            maxChildSize: 0.75,
                            minChildSize: 0.4,
                            expand: false,
                            builder: (context, controller) => Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                              ),
                              child: ParticipantsView(
                                scrollController: controller,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.group_outlined, size: 25),
                    label: const Text('Участники'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ParticipantLayout extends StatelessWidget {
  const ParticipantLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final participants = context.select(
      (VCSBloc bloc) => bloc.state.participants,
    );

    final pinnedSid = context.select(
      (VCSBloc bloc) => bloc.state.pinnedParticipantSid,
    );

    final activeSpeakerSid = context.select(
      (VCSBloc bloc) => bloc.state.activeSpeakerSid,
    );

    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    final pinned = pinnedSid == null
        ? null
        : participants.firstWhere(
            (p) => p.sid == pinnedSid,
            orElse: () => participants.first,
          );

    final activeSpeaker = activeSpeakerSid == null
        ? null
        : participants.firstWhere(
            (p) => p.sid == activeSpeakerSid,
            orElse: () => participants.first,
          );

    /*===================Что будем отображать===============*/

    if (pinned != null) {
      return PinnedParticipantView(pinned: pinned, participants: participants);
    }

    if (participants.length >= 3 && activeSpeaker != null && pinned == null) {
      return ActiveSpeakerView(
        activeSpeaker: activeSpeaker,
        participants: participants,
      );
    }

    switch (participants.length) {
      case 0:
        {
          return Container();
        }
      case 1:
        {
          return OneParticipantView(participant: participants.first);
        }
      case 2:
        {
          return TwoParticipantsView(participants: participants);
        }
      case <= 4:
        {
          return GridParticipantsView(
            participants: participants,
            crossAxisCount: 2,
            k: 2,
          );
        }
      case >= 5:
        {
          return GridParticipantsView(
            participants: participants,
            crossAxisCount: 2,
            k: 4,
          );
        }
      default:
        {
          return Container();
        }
    }
  }
}

class PinnedParticipantView extends StatelessWidget {
  const PinnedParticipantView({
    super.key,
    required this.pinned,
    required this.participants,
  });

  final Participant pinned;
  final List<Participant?> participants;

  @override
  Widget build(BuildContext context) {
    final others = participants.where((p) => p != pinned).toList();

    return Column(
      children: [
        Expanded(flex: 3, child: ParticipantTile(participant: pinned)),

        if (others.isNotEmpty)
          Flexible(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: others.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 180,
                  child: ParticipantTile(
                    participant: others[index]!,
                    isCompact: true,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class ActiveSpeakerView extends StatelessWidget {
  const ActiveSpeakerView({
    super.key,
    required this.activeSpeaker,
    required this.participants,
  });

  final Participant activeSpeaker;
  final List<Participant?> participants;

  @override
  Widget build(BuildContext context) {
    final others = participants.where((p) => p != activeSpeaker).toList();

    return Column(
      children: [
        Expanded(flex: 3, child: ParticipantTile(participant: activeSpeaker)),

        if (others.isNotEmpty)
          Flexible(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: others.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 180,
                  child: ParticipantTile(
                    participant: others[index]!,
                    isCompact: true,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class GridParticipantsView extends StatelessWidget {
  const GridParticipantsView({
    super.key,
    required this.participants,
    required this.crossAxisCount,
    required this.k,
  });

  final List<Participant?> participants;
  final int crossAxisCount;
  final int k;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          mainAxisExtent: constraints.maxHeight / k - 5,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) =>
            ParticipantTile(participant: participants[index]!),
      ),
    );
  }
}

class TwoParticipantsView extends StatelessWidget {
  const TwoParticipantsView({super.key, required this.participants});

  final List<Participant?> participants;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: participants
          .map(
            (participant) =>
                Expanded(child: ParticipantTile(participant: participant!)),
          )
          .toList(),
    );
  }
}

class OneParticipantView extends StatelessWidget {
  const OneParticipantView({super.key, required this.participant});
  final Participant participant;
  @override
  Widget build(BuildContext context) {
    return ParticipantTile(participant: participant);
  }
}

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.participant,
    this.isCompact = false,
  });

  final Participant participant;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final hasVideo = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.videoTracks.containsKey(participant.sid),
    );

    final isSpeaking = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.participants
          .firstWhere(
            (p) => p.sid == participant.sid,
            orElse: () => participant,
          )
          .isSpeaking,
    );

    final pinnedSid = context.select(
      (VCSBloc bloc) => bloc.state.pinnedParticipantSid,
    );

    final isPinned = pinnedSid == participant.sid;

    return GestureDetector(
      onLongPress: () {
        context.read<VCSBloc>().add(TogglePinRequested(participant.sid));
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          // Заливка
          decoration: BoxDecoration(
            gradient: !hasVideo
                ? LinearGradient(
                    colors: <Color>[
                      Color(0xFFFF4D8D),
                      Color(0xFFBD3EC2),
                      Color(0xFF2E0B7F),
                    ],
                    transform: GradientRotation(0.7),
                  )
                : LinearGradient(
                    colors: const <Color>[Colors.black, Colors.black],
                  ),

            border: Border.all(
              color: isSpeaking ? Colors.green : Colors.white24,
              width: 2,
            ),
            borderRadius: BorderRadiusDirectional.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(20)),
            child: Stack(
              children: [
                // Отображение фотки участника, если нету видео
                if (!hasVideo)
                  UserPhoto(participant: participant, isCompact: isCompact)
                else
                  VideoParticipant(participant: participant),

                // Отображение закрепа при закрепе
                if (isPinned)
                  const Positioned(
                    top: 4,
                    right: 8,
                    child: Icon(Icons.push_pin, color: Colors.deepPurpleAccent),
                  ),

                // Статус бар с именем
                BottomStatusBarName(
                  participant: participant,
                  isCompact: isCompact,
                ),

                // Статус бар с качеством соединения
                BottomStatusBarQualityConnection(participant: participant),

                // Статус бар со статусом вкл/выкл камеры и мирко
                BottomStatusBarCameraAndMicrophone(participant: participant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserPhoto extends StatelessWidget {
  const UserPhoto({
    super.key,
    required this.participant,
    this.isCompact = false,
  });

  final Participant participant;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.select<VCSBloc, String?>(
      (bloc) => bloc.state.photoUrls[participant.sid],
    );

    if (photoUrl == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      child: Center(
        child: CircleAvatar(
          radius: isCompact ? 25 : 40,
          backgroundImage: NetworkImage(photoUrl),
        ),
      ),
    );
  }
}

class VideoParticipant extends StatelessWidget {
  const VideoParticipant({super.key, required this.participant});
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final track = context.select<VCSBloc, VideoTrack?>(
      (bloc) => bloc.state.videoTracks[participant.sid],
    );

    if (track == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AbsorbPointer(
      child: VideoTrackRenderer(
        track,
        mirrorMode: VideoViewMirrorMode.auto,
        fit: VideoViewFit.cover,
      ),
    );
  }
}

class BottomStatusBarName extends StatelessWidget {
  const BottomStatusBarName({
    super.key,
    required this.participant,
    this.isCompact = false,
  });

  final Participant participant;
  final bool isCompact;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          spacing: 4,
          children: [
            Text(
              participant.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 10.0 : 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomStatusBarCameraAndMicrophone extends StatelessWidget {
  const BottomStatusBarCameraAndMicrophone({
    super.key,
    required this.participant,
  });
  final Participant participant;
  @override
  Widget build(BuildContext context) {
    final hasVideo = context.select<VCSBloc, bool>(
      (bloc) => bloc.state.videoTracks.containsKey(participant.sid),
    );

    final hasAudio = context.select<VCSBloc, bool>(
      (block) => block.state.audioTracks.containsKey(participant.sid),
    );

    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          spacing: 4,
          children: [
            Icon(
              hasVideo ? Icons.videocam_outlined : Icons.videocam_off_outlined,
              color: Colors.white,
              size: 16,
            ),
            Icon(
              hasAudio ? Icons.mic_none_outlined : Icons.mic_off_outlined,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class BottomStatusBarQualityConnection extends StatelessWidget {
  const BottomStatusBarQualityConnection({
    super.key,
    required this.participant,
  });
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final connectionQuality = context.select(
      (VCSBloc bloc) => bloc.state.connectionQualities[participant.sid],
    );

    return Positioned(
      bottom: 4,
      right: 8,
      child: Icon(
        switch (connectionQuality) {
          ConnectionQuality.excellent => Icons.signal_cellular_alt_rounded,
          ConnectionQuality.good => Icons.signal_cellular_alt_2_bar_rounded,
          ConnectionQuality.poor => Icons.signal_cellular_alt_1_bar_rounded,
          ConnectionQuality.lost =>
            Icons.signal_cellular_connected_no_internet_0_bar_rounded,
          ConnectionQuality.unknown =>
            Icons.signal_cellular_connected_no_internet_4_bar_rounded,
          null => Icons.signal_cellular_connected_no_internet_4_bar_rounded,
        },
        color: switch (connectionQuality) {
          ConnectionQuality.excellent => Colors.green,
          ConnectionQuality.good => Colors.yellow,
          ConnectionQuality.poor => Colors.red,
          ConnectionQuality.lost => Colors.red,
          ConnectionQuality.unknown => Colors.red,
          null => Colors.red,
        },
        semanticLabel: 'Качество сети',
      ),
    );
  }
}
