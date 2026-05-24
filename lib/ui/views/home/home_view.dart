import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/home/home_bloc.dart';
import 'package:strife/presentation/blocs/home/home_event.dart';
import 'package:strife/presentation/blocs/home/home_state.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/views/home/calls_view.dart';
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
  late final PageController _pageController;

  double _pipTop = 80.0;
  double _pipLeft = 200.0;
  bool _isPipInitialized = false;

  bool _animatePipIn = false;

  @override
  void initState() {
    super.initState();
    // Получаем текущий индекс из Блока для инициализации страницы
    final initialTab = context.read<NavigationBloc>().state.currentTabIndex;

    _pageController = PageController(initialPage: initialTab);

    // Загружаем контакты
    context.read<ContactsBloc>().add(
      LoadContactsRequested(
        currentUserId: FirebaseAuth.instance.currentUser!.uid,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (!_isPipInitialized) {
      _pipTop = screenSize.height - 300;
      _pipLeft = screenSize.width - 150;
      _isPipInitialized = true;
    }

    return BlocListener<NavigationBloc, NavigationState>(
      listenWhen: (previous, current) =>
          previous.currentTabIndex != current.currentTabIndex,
      listener: (context, state) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentTabIndex) {
          _pageController.animateToPage(
            state.currentTabIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                context.read<NavigationBloc>().add(ChangeTab(index));
              },
              children: const [
                CallsView(),
                ChatsView(),
                MeetingsView(),
                ContactsView(),
                ProfileView(),
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

        bottomNavigationBar: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            final currentIndex = state.currentTabIndex;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Передаем currentIndex в каждый айтем меню для проверки активности
                  _buildNavItem(
                    0,
                    Icons.phone_outlined,
                    Icons.phone,
                    'Звонки',
                    currentIndex,
                  ),
                  _buildNavItem(
                    1,
                    Icons.messenger_outline,
                    Icons.messenger,
                    'Чаты',
                    currentIndex,
                  ),
                  _buildNavItem(
                    2,
                    Icons.calendar_today_outlined,
                    Icons.calendar_today,
                    'Встречи',
                    currentIndex,
                  ),
                  _buildNavItem(
                    3,
                    Icons.contacts_outlined,
                    Icons.contacts,
                    'Контакты',
                    currentIndex,
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_3_outlined,
                    Icons.person_3,
                    'Профиль',
                    currentIndex,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    const brandColor = Color(0xFFB91ED0);

    return GestureDetector(
      onTap: () {
        context.read<NavigationBloc>().add(ChangeTab(index));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? brandColor : Colors.black45,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? brandColor : Colors.black45,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
        child: RepaintBoundary(
          child: VideoTrackRenderer(trackToRender, fit: VideoViewFit.cover),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.videocam_off, color: Colors.white54, size: 32),
    );
  }
}
