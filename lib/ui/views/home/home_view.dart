import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_event.dart';
import 'package:strife/presentation/blocs/vcs/vcs_state.dart';
import 'package:strife/ui/views/home/call_view.dart';
import 'package:strife/ui/views/home/chats_view.dart';
import 'package:strife/ui/views/home/contacts_view.dart';
import 'package:strife/ui/views/home/meetings_view.dart';
import 'package:strife/ui/views/home/profile_view.dart';
import 'package:strife/ui/views/room/room_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int selectedIndex = 0;
  double _pipTop = 80.0;
  double _pipLeft = 200.0;
  bool _isPipInitialized = false;

  bool _animatePipIn = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (!_isPipInitialized) {
      _pipTop = screenSize.height - 300;
      _pipLeft = screenSize.width - 150;
      _isPipInitialized = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: const <Widget>[
              CallView(),
              ChatsView(),
              ProfileView(),
              MeetingsView(),
              ContactsView(),
            ],
          ),

          BlocListener<VCSBloc, VCSState>(
            listenWhen: (p, c) => p.isMinimized != c.isMinimized,
            listener: (context, state) {
              if (state.isMinimized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _animatePipIn = true);
                  }
                });
              } else {
                setState(() => _animatePipIn = false);
              }
            },
            child: const SizedBox.shrink(),
          ),

          BlocBuilder<VCSBloc, VCSState>(
            buildWhen: (p, c) => p.isMinimized != c.isMinimized,
            builder: (context, state) {
              // Если звонок не свернут, полностью убираем дерево из Stack
              if (!state.isConnected) return const SizedBox.shrink();

              return _buildAnimatedPipWindow(state, screenSize);
            },
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
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
            icon: Icon(Icons.person_3_outlined),
            label: 'Профиль',
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
    );
  }

  Widget _buildAnimatedPipWindow(VCSState state, Size screenSize) {
    const double pipWidth = 130.0;
    const double pipHeight = 190.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      top: _pipTop - 20,
      left: _pipLeft,

      child: AnimatedScale(
        scale: _animatePipIn ? 1.0 : (state.isConnected ? 2.0 : 0.0),
        duration: const Duration(milliseconds: 280),
        curve: _animatePipIn ? Curves.easeOutBack : Curves.easeInCubic,

        child: AnimatedOpacity(
          opacity: _animatePipIn ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !state.isMinimized,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pipTop += details.delta.dy;
                  _pipLeft += details.delta.dx;

                  _pipTop = _pipTop.clamp(
                    40.0,
                    screenSize.height - (pipHeight + 50),
                  );
                  _pipLeft = _pipLeft.clamp(
                    10.0,
                    screenSize.width - (pipWidth + 10),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  final screenCenterX = screenSize.width / 2;
                  final pipCenterX = _pipLeft + (pipWidth / 2);

                  if (pipCenterX < screenCenterX) {
                    _pipLeft = 16.0;
                  } else {
                    _pipLeft = screenSize.width - (pipWidth + 16);
                  }
                });
              },
              onTap: () async {
                setState(() {
                  _animatePipIn = false;
                });

                await Future.delayed(const Duration(milliseconds: 270));

                if (!mounted) return;

                context.read<VCSBloc>().add(
                  ToggleMinimizeRoomRequested(minimize: false),
                );

                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RoomView()));
              },
              child: SizedBox(
                width: pipWidth,
                height: pipHeight,
                child: Material(
                  elevation: 12,
                  shadowColor: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMiniVideo(state),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniVideo(VCSState state) {
    VideoTrack? trackToRender;

    if (state.activeSpeakerSid != null) {
      trackToRender = state.videoTracks[state.activeSpeakerSid];
    }
    if (trackToRender == null && state.pinnedParticipantSid != null) {
      trackToRender = state.videoTracks[state.pinnedParticipantSid];
    }
    if (trackToRender == null && state.videoTracks.isNotEmpty) {
      trackToRender = state.videoTracks.values.firstOrNull;
    }

    if (trackToRender != null) {
      return AbsorbPointer(
        child: VideoTrackRenderer(trackToRender, fit: VideoViewFit.cover),
      );
    }

    return const Center(
      child: Icon(Icons.videocam_off, color: Colors.white54, size: 32),
    );
  }
}
