import 'dart:async';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../data/repositories/vcs_repository.dart';
part 'vcs_event.dart';
part 'vcs_state.dart';

class VCSBloc extends Bloc<VCSEvent, VCSState> {
  final VCSRepository _vcsRepository;

  String? roomId;

  Room? _room;

  EventsListener<RoomEvent>? _listener;

  VCSBloc({required VCSRepository vcsRepository})
    : _vcsRepository = vcsRepository,
      super(const VCSState()) {
    // Регистрируем обработчики
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    // Внешние
    on<ConnectRequested>(_onConnect);
    on<DisconnectRequested>(_onDisconnect);
    on<ToggleMicrophoneRequested>(_onToggleMicrophone);
    on<ToggleCameraRequested>(_onToggleCamera);
    on<FlipCameraRequested>(_onFlipCamera);
    on<ToggleRemoteAudioRequested>(_onToggleRemoteAudio);
    on<TogglePinRequested>(_onTogglePin);
    on<MuteParticipantRequested>(_onMuteParticipant);
    on<UnmuteParticipantRequested>(_onUnmuteParticipant);
    on<DisableCameraParticipantRequested>(_onDisableCameraParticipant);
    on<EnableCameraParticipantRequested>(_onEnableCameraParticipant);
    on<KickParticipantRequested>(_onKickParticipant);
    on<TransferHostRequested>(_onTransferHost);
    on<KickedFromRoomRequested>(_onKickedFromRoom);
    on<SyncHardwareStatus>(_onSyncHardwareStatus);
    on<ToggleMinimizeRoomRequested>((event, emit) {
      emit(state.copyWith(isMinimized: event.minimize));
    });
    on<RoomTerminatedByHostRequested>(_onRoomTerminatedByHost);
    on<RoomTerminateRequested>(_onRoomTerminate);
    on<AddParticipantRequested>(_onAddParticipantInRoomToDB);
    on<ParticipantJoinRequested>((event, emit) {
      emit(state.copyWith(participantJoin: event.participantJoin));
    });
    on<ParticipantLeftRequested>((event, emit) {
      emit(state.copyWith(participantLeft: event.participantLeft));
    });

    // Внутренние
    on<RoomDataChanged>((event, emit) {
      _updateParticipants(emit);
    });
    on<ConnectionQualityUpdated>(_onConnectionQualityUpdated);
    on<ActiveSpeakerChanged>(_onActiveSpeakerChanged);
    on<ReconnectingStarted>(_onReconnectingStarted);
    on<ReconnectingFinished>(_onReconnectingFinished);
  }

  Future<void> _onAddParticipantInRoomToDB(
    AddParticipantRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      emit(state.copyWith(error: null));

      _vcsRepository.addParticipant(
        roomId: event.roomId,
        participantId: event.participantId,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSyncHardwareStatus(
    SyncHardwareStatus event,
    Emitter<VCSState> emit,
  ) async {
    emit(
      state.copyWith(
        isMicrophoneEnabled: event.isMicEnabled ?? state.isMicrophoneEnabled,
        isCameraEnabled: event.isCamEnabled ?? state.isCameraEnabled,
      ),
    );
  }

  Future<void> _onKickedFromRoom(
    KickedFromRoomRequested event,
    Emitter<VCSState> emit,
  ) async {
    emit(state.copyWith(leaveReason: RoomLeaveReason.kicked));
  }

  Future<void> _onRoomTerminatedByHost(
    RoomTerminatedByHostRequested event,
    Emitter<VCSState> emit,
  ) async {
    emit(state.copyWith(leaveReason: RoomLeaveReason.terminatedByHost));
  }

  Future<void> _onRoomTerminate(
    RoomTerminateRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      emit(state.copyWith(error: null));

      await _vcsRepository.terminateRoom(event.roomId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMuteParticipant(
    MuteParticipantRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _vcsRepository.muteParticipant(
        roomId: _room!.name!,
        participantIdentity: event.participantIdentity,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUnmuteParticipant(
    UnmuteParticipantRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _vcsRepository.unmuteParticipant(
        roomId: _room!.name!,
        participantIdentity: event.participantIdentity,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDisableCameraParticipant(
    DisableCameraParticipantRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _vcsRepository.disableCamera(
        roomId: _room!.name!,
        participantIdentity: event.participantIdentity,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onEnableCameraParticipant(
    EnableCameraParticipantRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _vcsRepository.enableCamera(
        roomId: _room!.name!,
        participantIdentity: event.participantIdentity,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onKickParticipant(
    KickParticipantRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _vcsRepository.kickParticipant(
        roomId: _room!.name!,
        participantIdentity: event.participantIdentity,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onTransferHost(
    TransferHostRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _vcsRepository.transferHost(
        roomId: _room!.name!,
        newHostId: event.participantIdentity,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onConnect(
    ConnectRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      emit(state.copyWith(error: null));
      if (_room != null) {
        await _listener?.dispose();
        await _room?.disconnect();
        await _room?.dispose();
      }

      // Создаем экземпляр комнаты
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: false,
          dynacast: true,
          defaultVideoPublishOptions: VideoPublishOptions(
            videoCodec: 'v8',
            simulcast: true,
            videoEncoding: VideoEncoding(
              maxFramerate: 30,
              maxBitrate: 3_000_000,
            ),
          ),
        ),
      );

      _listener = _room?.createListener();
      _setupRoomListeners(); // Настраиваем подписки LiveKit

      final data = await _vcsRepository.fetchToken(
        roomId: event.roomId,
        identity: event.identity,
        name: event.name,
        photoUrl: event.photoUrl,
      );

      // Подключаемся к комнате
      await _room?.connect(data['serverURL'], data['participantToken']);

      add(RoomDataChanged());
      emit(state.copyWith(isConnected: true));

      roomId = _room?.name;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDisconnect(
    DisconnectRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      await _listener?.dispose();
      _listener = null;

      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }
    } catch (_) {
    } finally {
      roomId = null;

      emit(const VCSState());
    }
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      emit(state.copyWith(error: null));
      final newValue = !state.isMicrophoneEnabled;

      await _room!.localParticipant?.setMicrophoneEnabled(newValue);

      emit(state.copyWith(isMicrophoneEnabled: newValue));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onToggleCamera(
    ToggleCameraRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      emit(state.copyWith(error: null));
      final newValue = !state.isCameraEnabled;

      await _room?.localParticipant?.setCameraEnabled(
        newValue,
        cameraCaptureOptions: CameraCaptureOptions(
          params: VideoParametersPresets.h1080_169,
        ),
      );
      emit(state.copyWith(isCameraEnabled: newValue));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFlipCamera(
    FlipCameraRequested event,
    Emitter<VCSState> emit,
  ) async {
    final trackPub =
        _room?.localParticipant?.videoTrackPublications.firstOrNull;
    final track = trackPub?.track;

    if (track is LocalVideoTrack) {
      final devices = await Hardware.instance.enumerateDevices();
      final videoDevices = devices
          .where((d) => d.kind == 'videoinput')
          .toList();

      if (videoDevices.length < 2) return;

      final currentId = track.mediaStreamTrack.getSettings()['deviceId'];
      final nextDevice = videoDevices.firstWhere(
        (d) => d.deviceId != currentId,
        orElse: () => videoDevices.first,
      );

      await track.switchCamera(nextDevice.deviceId);
    }
  }

  Future<void> _onReconnectingStarted(
    ReconnectingStarted event,
    Emitter<VCSState> emit,
  ) async {
    emit(state.copyWith(isReconnecting: true));
  }

  Future<void> _onReconnectingFinished(
    ReconnectingFinished event,
    Emitter<VCSState> emit,
  ) async {
    emit(state.copyWith(isReconnecting: false));
  }

  Future<void> _onToggleRemoteAudio(
    ToggleRemoteAudioRequested event,
    Emitter<VCSState> emit,
  ) async {
    final newValue = !state.isRemoteAudioEnabled;

    for (final participant in _room!.remoteParticipants.values) {
      for (final pub in participant.audioTrackPublications) {
        if (pub.track != null) {
          newValue ? await pub.track!.enable() : await pub.track!.disable();
        }
      }
    }

    emit(state.copyWith(isRemoteAudioEnabled: newValue));
  }

  void _onTogglePin(TogglePinRequested event, Emitter<VCSState> emit) {
    final newSid = state.pinnedParticipantSid == event.participantSid
        ? null
        : event.participantSid;

    emit(state.copyWith(pinnedParticipantSid: newSid));
  }

  void _setupRoomListeners() {
    _listener!
      ..on<ParticipantMetadataUpdatedEvent>((event) {
        add(RoomDataChanged());
      })
      ..on<RoomDisconnectedEvent>((event) async {
        // Если участника выгнали
        if (event.reason == DisconnectReason.participantRemoved) {
          add(KickedFromRoomRequested());
          return;
        }

        // Во всех остальных случаях проверяем базу данных
        try {
          // Запрашиваем актуальный статус комнаты из вашего VCSRepository
          final isCompleted = await _vcsRepository.isRoomCompleted(roomId!);
          if (isCompleted) {
            add(RoomTerminatedByHostRequested());
          }
        } catch (_) {}
      })
      // Участник подключился
      ..on<ParticipantConnectedEvent>((event) {
        add(RoomDataChanged());
        add(
          AddParticipantRequested(
            roomId: roomId!,
            participantId: event.participant.identity,
          ),
        );
        add(ParticipantJoinRequested(participantJoin: event.participant));
      })
      // Участник вышел
      ..on<ParticipantDisconnectedEvent>((event) {
        add(RoomDataChanged());
        add(ParticipantLeftRequested(participantLeft: event.participant));
      })
      // Переподключение началось
      ..on<RoomReconnectingEvent>((event) {
        add(ReconnectingStarted());
      })
      // Переподключение завершилось
      ..on<RoomReconnectedEvent>((event) {
        add(ReconnectingFinished());
        add(RoomDataChanged());
      })
      // Active speaker изменился
      ..on<ActiveSpeakersChangedEvent>((event) {
        final speaker = event.speakers.firstOrNull;
        add(ActiveSpeakerChanged(speaker?.sid));
      })
      //
      ..on<SpeakingChangedEvent>((event) {
        add(RoomDataChanged());
      })
      // Качество соединения изменилось
      ..on<ParticipantConnectionQualityUpdatedEvent>((event) {
        add(
          ConnectionQualityUpdated(
            event.participant.sid,
            event.connectionQuality,
          ),
        );
      })
      // Любые изменения треков
      ..on<LocalTrackPublishedEvent>((_) => add(RoomDataChanged()))
      ..on<LocalTrackUnpublishedEvent>((_) => add(RoomDataChanged()))
      ..on<TrackUnpublishedEvent>((_) => add(RoomDataChanged()))
      ..on<TrackPublishedEvent>((_) => add(RoomDataChanged()))
      ..on<TrackSubscribedEvent>((_) => add(RoomDataChanged()))
      ..on<TrackUnsubscribedEvent>((_) => add(RoomDataChanged()))
      ..on<TrackMutedEvent>((_) => add(RoomDataChanged()))
      ..on<TrackUnmutedEvent>((_) => add(RoomDataChanged()));
  }

  void _updateParticipants(Emitter<VCSState> emit) {
    if (_room!.localParticipant == null) return;

    final participants = <Participant>[
      _room!.localParticipant!,
      ..._room!.remoteParticipants.values,
    ];

    final videoTracks = <String, VideoTrack>{};
    final audioTracks = <String, AudioTrack>{};
    final photoUrls = <String, String>{};
    final hostSids = <String>[];
    final mutedMicrophoneByHostSids = <String, bool>{};
    final mutedCameraByHostSids = <String, bool>{};

    for (final participant in participants) {
      Map<String, dynamic> decoded = {};

      final metadata = participant.metadata;
      if (metadata != null && metadata.isNotEmpty) {
        decoded = jsonDecode(metadata);
      }

      // фото / host / mute
      photoUrls[participant.sid] = decoded['photoUrl'] ?? '';
      if (decoded['isHost'] == true) hostSids.add(participant.identity);
      mutedMicrophoneByHostSids[participant.sid] =
          decoded['mutedByHost'] == true;
      mutedCameraByHostSids[participant.sid] =
          decoded['cameraMutedByHost'] == true;

      // только для локального пользователя
      final isLocal =
          participant.identity == FirebaseAuth.instance.currentUser!.uid;

      if (isLocal) {
        final isMutedByHost = decoded['mutedByHost'] == true;

        if (isMutedByHost &&
            _room!.localParticipant?.isMicrophoneEnabled() == true) {
          _room!.localParticipant?.setMicrophoneEnabled(false);
        }

        final isCameraMutedByHost = decoded['cameraMutedByHost'] == true;

        if (isCameraMutedByHost &&
            _room!.localParticipant?.isCameraEnabled() == true) {
          _room!.localParticipant?.setCameraEnabled(false);
        }
      }

      // video
      for (final pub in participant.videoTrackPublications) {
        if (pub.track is VideoTrack && pub.subscribed && !pub.muted) {
          videoTracks[participant.sid] = pub.track as VideoTrack;
        }
      }

      // audio
      for (final pub in participant.audioTrackPublications) {
        if (pub.track is AudioTrack && pub.subscribed && !pub.muted) {
          audioTracks[participant.sid] = pub.track as AudioTrack;
        }
      }
    }

    emit(
      state.copyWith(
        participants: participants,
        videoTracks: videoTracks,
        audioTracks: audioTracks,
        photoUrls: photoUrls,
        hostSids: hostSids,
        mutedMicrophoneByHostSids: mutedMicrophoneByHostSids,
        mutedCameraByHostSids: mutedCameraByHostSids,
      ),
    );
  }

  // Обработчик ActiveSpeakerChanged
  void _onActiveSpeakerChanged(
    ActiveSpeakerChanged event,
    Emitter<VCSState> emit,
  ) {
    emit(state.copyWith(activeSpeakerSid: event.participantSid));
  }

  // Обработчик ConnectionQualityUpdated
  void _onConnectionQualityUpdated(
    ConnectionQualityUpdated event,
    Emitter<VCSState> emit,
  ) {
    final updatedMap = Map<String, ConnectionQuality>.from(
      state.connectionQualities,
    );

    updatedMap[event.participantSid] = event.quality;

    emit(state.copyWith(connectionQualities: updatedMap));
  }

  @override
  Future<void> close() async {
    await _listener?.dispose();
    await _room?.dispose();
    return super.close();
  }
}
