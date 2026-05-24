import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/views/chat_screen/chat_screen.dart';
import 'package:strife/ui/views/room/layout_coordinate.dart';
import 'package:strife/ui/views/room/participants_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

class RoomView extends StatelessWidget {
  const RoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return MultiBlocListener(
      listeners: [
        // Слушатель подключения участника
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (previous, current) =>
              previous.participantJoin != current.participantJoin,
          listener: (context, state) {
            if (state.participantJoin != null && !state.isReconnecting) {
              AppNotifications.showInfo(
                context,
                'Присоединился новый участник ${state.participantJoin!.name}',
              );
            }
          },
        ),
        // Слушатель выходы участника участника
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (previous, current) =>
              previous.participantLeft != current.participantLeft,
          listener: (context, state) {
            if (state.participantLeft != null && !state.isReconnecting) {
              AppNotifications.showInfo(
                context,
                'Участник ${state.participantLeft!.name} вышел',
              );
            }
          },
        ),

        // Слушатель переподключения
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) => p.isReconnecting != c.isReconnecting,
          listener: (context, state) {
            if (state.isReconnecting && state.isConnected) {
              showDialog(
                context: context,
                useRootNavigator: true,
                barrierDismissible: false,
                builder: (_) => const PopScope(
                  canPop: false,
                  child: AlertDialog(
                    backgroundColor: Colors.transparent,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Переподключение...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

        // Слушатель обычного отключения / ошибок
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) =>
              p.isConnected != c.isConnected || p.error != c.error,
          listener: (context, state) {
            if (state.error != null) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              AppNotifications.showError(context, state.error!);
            } else if (!state.isConnected &&
                state.leaveReason == RoomLeaveReason.none) {
              // Если пользователь просто сам нажал "Выйти" и успешно отключился
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),

        // Слушатель модерации (Кик или Завершение хостом)
        BlocListener<VCSBloc, VCSState>(
          listenWhen: (p, c) => p.leaveReason != c.leaveReason,
          listener: (context, state) {
            if (state.leaveReason == RoomLeaveReason.kicked) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              AppNotifications.showInfo(
                context,
                'Вы были удалены из комнаты модератором',
              );
            } else if (state.leaveReason == RoomLeaveReason.terminatedByHost) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              AppNotifications.showInfo(
                context,
                'Организатор завершил встречу для всех участников',
              );
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
              const SyncHardwareStatus(isMicEnabled: false),
            );
          },
        ),

        // Слушатель камеры
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
              const SyncHardwareStatus(isCamEnabled: false),
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
          Navigator.of(context).popUntil((route) => route.isFirst);
        },

        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                context.read<VCSBloc>().add(
                  const ToggleMinimizeRoomRequested(minimize: true),
                );

                // Закрываем страницу звонка
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
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
          decoration: const BoxDecoration(color: Colors.black),
          child: SafeArea(child: ParticipantLayout()),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        final currentUser = FirebaseAuth.instance.currentUser;

                        if (currentUser == null) return;

                        // Проверяем, является ли текущий участник хостом
                        final bool isHost = bloc.state.hostSids.contains(
                          currentUser.uid,
                        );

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.only(
                              top: 20,
                              left: 24,
                              right: 24,
                              bottom: 12,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFB91ED0),
                                  size: 36,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isHost
                                      ? 'Управление звонком'
                                      : 'Выход из комнаты',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isHost
                                      ? 'Вы можете просто покинуть звонок или завершить конференцию для всех участников.'
                                      : 'Вы действительно хотите покинуть комнату звонка?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Пользователь хост
                                if (isHost) ...[
                                  // Кнопка завершить для всех
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      final String roomIdToTerminate =
                                          bloc.roomId!;

                                      // Локально отключаем хоста и сбрасываем VCSState в дефолт
                                      bloc.add(DisconnectRequested());

                                      // Отправляем запрос чтобы уничтожить комнату для всех остальных
                                      bloc.add(
                                        RoomTerminateRequested(
                                          roomId: roomIdToTerminate,
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Завершить для всех',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Кнопка просто выйти (оставив других говорить)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.black12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      bloc.add(DisconnectRequested());
                                    },
                                    child: const Text(
                                      'Выйти самому',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],

                                // Пользователь обычный участник
                                if (!isHost) ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      bloc.add(DisconnectRequested());
                                    },
                                    child: const Text(
                                      'Выйти',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),

                                // Кнопка oтмена
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Отмена',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Чат
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF474747),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      onPressed: () async {
                        final String currentRoomId = bloc.roomId!;
                        final myId = FirebaseAuth.instance.currentUser!.uid;
                        final List<String> participantIds = bloc
                            .state
                            .participants
                            .map((p) => p.identity)
                            .toList();

                        await context.read<ChatRepository>().syncRoomChat(
                          currentRoomId,
                          participantIds,
                        );

                        if (!context.mounted) return;

                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BlocProvider(
                            create: (context) => ChatBloc(
                              chatRepository: context.read<ChatRepository>(),
                              userRepository: context.read<UserRepository>(),
                              notificationRepository: context
                                  .read<NotificationRepository>(),
                            )..add(InitChat(bloc.roomId!)),
                            child: DraggableScrollableSheet(
                              initialChildSize: 0.75,
                              maxChildSize: 0.9,
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
                                  currentUserId: myId,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Чат', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  // Участники
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF474747),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => BlocProvider.value(
                            value: bloc,
                            child: DraggableScrollableSheet(
                              initialChildSize: 0.6,
                              maxChildSize: 0.8,
                              minChildSize: 0.4,
                              expand: false,
                              builder: (context, scrollController) =>
                                  ParticipantsView(
                                    scrollController: scrollController,
                                  ),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.group_outlined, size: 25),
                      label: const Text(
                        'Участники',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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

    // Находим индексы специального отображения
    int? pinnedIndex = pinnedSid != null
        ? participants.indexWhere((p) => p.sid == pinnedSid)
        : null;
    int? activeIndex = activeSpeakerSid != null
        ? participants.indexWhere((p) => p.sid == activeSpeakerSid)
        : null;

    if (participants.length < 3) {
      activeIndex = null;
    }
    if (pinnedIndex != null) {
      activeIndex = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final coordinates = calculateLayout(
          totalCount: participants.length,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          pinnedIndex: pinnedIndex == -1 ? null : pinnedIndex,
          activeIndex: activeIndex == -1 ? null : activeIndex,
        );

        return Stack(
          children: [
            for (int i = 0; i < participants.length; i++)
              AnimatedPositioned(
                key: ValueKey(participants[i].identity),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                left: coordinates[i].left,
                top: coordinates[i].top,
                width: coordinates[i].width,
                height: coordinates[i].height,
                child: ParticipantTile(
                  participant: participants[i],
                  isCompact: coordinates[i].isCompact,
                ),
              ),
          ],
        );
      },
    );
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

                Positioned(
                  left: 4.0,
                  bottom: 4.0,
                  right: 4.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Статус бар с именем
                      Flexible(
                        child: BottomStatusBarName(
                          participant: participant,
                          isCompact: isCompact,
                        ),
                      ),

                      // Статус бар с качеством соединения
                      BottomStatusBarQualityConnection(
                        participant: participant,
                      ),
                    ],
                  ),
                ),

                // Статус бар со статусом вкл/выкл камеры и мирко
                BottomStatusBarCameraAndMicrophone(
                  participant: participant,
                  isCompact: isCompact,
                ),
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

    return Center(
      child: CircleAvatar(
        radius: isCompact ? 30 : 40,
        backgroundImage: NetworkImage(photoUrl),
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
      child: RepaintBoundary(
        child: VideoTrackRenderer(
          track,
          mirrorMode: VideoViewMirrorMode.auto,
          fit: VideoViewFit.cover,
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Text(
        participant.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 10.0 : 14.0,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class BottomStatusBarCameraAndMicrophone extends StatelessWidget {
  const BottomStatusBarCameraAndMicrophone({
    super.key,
    required this.participant,
    required this.isCompact,
  });
  final Participant participant;
  final bool isCompact;
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
              size: isCompact ? 12 : 15,
            ),
            Icon(
              hasAudio ? Icons.mic_none_outlined : Icons.mic_off_outlined,
              color: Colors.white,
              size: isCompact ? 12 : 15,
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

    return Icon(
      switch (connectionQuality) {
        ConnectionQuality.excellent => Icons.signal_cellular_alt_rounded,
        ConnectionQuality.good => Icons.signal_cellular_alt_2_bar_rounded,
        ConnectionQuality.poor => Icons.signal_cellular_alt_1_bar_rounded,
        ConnectionQuality.lost => Icons.signal_cellular_nodata_rounded,
        ConnectionQuality.unknown => Icons.signal_cellular_nodata_rounded,
        null => Icons.signal_cellular_alt_rounded,
      },
      color: switch (connectionQuality) {
        ConnectionQuality.excellent => Colors.green,
        ConnectionQuality.good => Colors.yellow,
        ConnectionQuality.poor => Colors.red,
        ConnectionQuality.lost => Colors.red,
        ConnectionQuality.unknown => Colors.red,
        null => Colors.green,
      },
      semanticLabel: 'Качество сети',
    );
  }
}
