import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:strife/models/client_model.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  bool _isShowDialog = false;
  @override
  Widget build(BuildContext context) {
    return Selector<ClientModel, (String?, String?, bool)>(
      selector: (_, client) => (
        client.newParticipantDisplayName,
        client.leaveParticipantDisplayName,
        client.isReconnecting,
      ),
      builder: (context, data, child) {
        final (joined, left, isReconnecting) = data;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (joined != null) {
            Fluttertoast.showToast(
              msg: 'Участник $joined присоединился',
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 3,
            );
            context.read<ClientModel>().clearNewParticipantDisplayName();
          }

          if (left != null) {
            Fluttertoast.showToast(
              msg: 'Участник $left вышел',
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 3,
            );
            context.read<ClientModel>().clearLeaveParticipantDisplayName();
          }

          if (isReconnecting && !_isShowDialog) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
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
            _isShowDialog = true;
          }
          if (_isShowDialog && !isReconnecting) {
            _isShowDialog = false;
            Navigator.of(context).pop();
          }
        });

        return child!;
      },
      child: Scaffold(
        bottomNavigationBar: NavigationBottomAppBar(),
        body: const Center(
          child: Column(
            children: [Expanded(child: SafeArea(child: ParticipantLayout()))],
          ),
        ),
      ),
    );
  }
}

class NavigationBottomAppBar extends StatelessWidget {
  const NavigationBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnableCamera = context.select<ClientModel, bool>(
      (c) => c.isEnableCamera,
    );

    final isEnableMicrophone = context.select<ClientModel, bool>(
      (c) => c.isEnableMicrophone,
    );

    final isClientReconnecting = context.select<ClientModel, bool>(
      (c) => c.isReconnecting,
    );

    final client = context.read<ClientModel>();
    return BottomAppBar(
      child: IconTheme(
        data: IconThemeData(size: 43),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              color: isEnableCamera ? Colors.green : Colors.red,
              onPressed: isClientReconnecting
                  ? null
                  : () async {
                      await client.enableDisableCamera();
                    },

              icon: isEnableCamera
                  ? Icon(Icons.videocam)
                  : Icon(Icons.videocam_off),
            ),
            IconButton(
              color: isEnableMicrophone ? Colors.green : Colors.red,
              onPressed: isClientReconnecting
                  ? null
                  : () async {
                      await client.enableDisableMicrophone();
                    },
              icon: isEnableMicrophone ? Icon(Icons.mic) : Icon(Icons.mic_off),
            ),
            IconButton(
              color: ColorScheme.of(context).onPrimary,
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
                        onPressed: () async {
                          await client.disconnectFromRoom();
                          if (!context.mounted) return;
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
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipantLayout extends StatelessWidget {
  const ParticipantLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final participants = context.watch<ClientModel>().participants;
    switch (participants.length) {
      case 0:
        {
          return SizedBox.shrink();
        }
      case 1:
        {
          return OneParticipantView(participant: participants.first!);
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
      case <= 9:
        {
          return GridParticipantsView(
            participants: participants,
            crossAxisCount: 2,
            k: 4,
          );
        }
      default:
        {
          return SizedBox.shrink();
        }
    }
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
    return Stack(
      children: [
        UserPhoto(participant: participant),
        VideoParticipantOrNothing(participant: participant),
        BottomStatusBarLeft(participant: participant),
        BottomStatusBarRight(participant: participant),
      ],
    );
  }
}

class UserPhoto extends StatelessWidget {
  const UserPhoto({super.key, required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final client = context.read<ClientModel>();
    final photoUrl = client.photoUrlOf(participant);

    if (photoUrl == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(child: Image.network(photoUrl, scale: 1.2));
  }
}

class VideoParticipantOrNothing extends StatelessWidget {
  const VideoParticipantOrNothing({super.key, required this.participant});
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final TrackPublication<Track>? trackPublication = participant
        .trackPublications
        .values
        .where(
          (trackPublication) =>
              !trackPublication.muted &&
              trackPublication.track?.isActive == true &&
              trackPublication.track is VideoTrack,
        )
        .cast<TrackPublication<Track>>()
        .firstOrNull;
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(
          color: participant.isSpeaking ? Colors.green : Colors.white54,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: trackPublication != null
          ? VideoTrackRenderer(
              trackPublication.track as VideoTrack,
              mirrorMode: VideoViewMirrorMode.mirror,
              fit: VideoViewFit.cover,
            )
          : Container(),
    );
  }
}

class BottomStatusBarLeft extends StatelessWidget {
  const BottomStatusBarLeft({super.key, required this.participant});

  final Participant participant;

  bool hasVideo() {
    try {
      participant.videoTrackPublications.firstWhere(
        (pub) => !pub.muted && pub.subscribed && pub.track is VideoTrack,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 2,
      left: 8,
      child: Row(
        children: [
          Text(participant.name),
          Icon(hasVideo() ? Icons.videocam : Icons.videocam_off),
          Icon(
            participant.hasAudio && !participant.isMuted
                ? Icons.mic
                : Icons.mic_off,
          ),
        ],
      ),
    );
  }
}

class BottomStatusBarRight extends StatelessWidget {
  const BottomStatusBarRight({super.key, required this.participant});
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final ConnectionQuality? connectionQuality = context
        .select<ClientModel, ConnectionQuality?>(
          (c) => c.connectionQualityOf(participant),
        );

    return Positioned(
      bottom: 2,
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
