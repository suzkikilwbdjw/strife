import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/presentation/blocs/vcs/vcs_state.dart';
import 'package:strife/themes/gradient_theme.dart';

class RoomView extends StatelessWidget {
  const RoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<VCSBloc, VCSState>(
      listenWhen: (previous, current) =>
          previous.isReconnecting != current.isReconnecting,
      listener: (context, state) {
        if (state.isReconnecting) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Dialog(
              backgroundColor: Colors.transparent,
              child: SizedBox(
                height: 100,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Переподключение к комнате...'),
                      SizedBox(width: 8),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),

        bottomNavigationBar: NavigationBottomAppBar(),

        body: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 20, 40, 153),
          ),
          child: const SafeArea(child: ParticipantLayout()),
        ),
      ),
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
                      onPressed: state.isReconnecting
                          ? null
                          : () => bloc.add(ToggleMicrophoneRequested()),
                      icon: state.isMicrophoneEnabled
                          ? const Icon(Icons.mic_none_outlined)
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
                      onPressed: state.isReconnecting
                          ? null
                          : () => bloc.add(ToggleCameraRequested()),
                      icon: state.isCameraEnabled
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
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Нет'),
                              ),
                              TextButton(
                                onPressed: () {
                                  bloc.add(DisconnectRequested());
                                  // Закрываем диалог
                                  Navigator.of(context).pop();
                                  //Закрываем страницу
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Да'),
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
                          : () => bloc.add(FlipCameraRequested()),
                      icon: const Icon(Icons.flip_camera_ios_outlined),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                spacing: 24,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF474747),
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                    ),
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Чат'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF474747),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    onPressed: () {},
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
      case <= 8:
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
                  child: ParticipantTile(participant: others[index]!),
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
                  child: ParticipantTile(participant: others[index]!),
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
  const ParticipantTile({super.key, required this.participant});

  final Participant participant;

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
          decoration: BoxDecoration(
            gradient: !hasVideo
                ? Theme.of(context).extension<GradientTheme>()!.mainGradient
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
                if (!hasVideo)
                  UserPhoto(participant: participant)
                else
                  VideoParticipant(participant: participant),

                if (isPinned)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.push_pin, color: Colors.deepPurpleAccent),
                  ),

                BottomStatusBarLeft(participant: participant),

                BottomStatusBarRight(participant: participant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserPhoto extends StatelessWidget {
  const UserPhoto({super.key, required this.participant});

  final Participant participant;

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
          radius: 40,
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
      absorbing: true,
      child: VideoTrackRenderer(
        track,
        mirrorMode: VideoViewMirrorMode.auto,
        fit: VideoViewFit.cover,
      ),
    );
  }
}

class BottomStatusBarLeft extends StatelessWidget {
  const BottomStatusBarLeft({super.key, required this.participant});

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
      bottom: 4,
      left: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: EdgeInsets.only(left: 4, top: 3, bottom: 3, right: 4),
        child: Row(
          spacing: 4,
          children: [
            Text(participant.name, style: TextStyle(color: Colors.white)),
            Icon(
              hasVideo ? Icons.videocam_outlined : Icons.videocam_off_outlined,
              color: Colors.white,
              size: 20,
            ),
            Icon(
              hasAudio ? Icons.mic_none_outlined : Icons.mic_off_outlined,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class BottomStatusBarRight extends StatelessWidget {
  const BottomStatusBarRight({super.key, required this.participant});
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final connectionQuality = context.select(
      (VCSBloc bloc) => bloc.state.connectionQualities[participant.sid],
    );

    return Positioned(
      bottom: 4,
      right: 6,
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
