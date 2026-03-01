import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../data/repositories/vcs_repository.dart';
import 'vcs_event.dart';
import 'vcs_state.dart';

class VCSBloc extends Bloc<VCSEvent, VCSState> {
  final VCSRepository _repository;

  late final Room _room;
  late final EventsListener<RoomEvent> _listener;

  VCSBloc(this._repository) : super(const VCSState()) {
    _room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );

    _listener = _room.createListener();

    // Регестрация обработчиков событий
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

    // Внутренние
    on<RoomDataChanged>((event, emit) {
      _updateParticipants(emit);
    });
    on<ConnectionQualityUpdated>(_onConnectionQualityUpdated);
    on<ActiveSpeakerChanged>(_onActiveSpeakerChanged);
    on<ReconnectingStarted>(_onReconnectingStarted);
    on<ReconnectingFinished>(_onReconnectingFinished);
  }

  Future<void> _onConnect(
    ConnectRequested event,
    Emitter<VCSState> emit,
  ) async {
    try {
      final data = await _repository.fetchToken(
        room: event.roomName,
        identity: event.identity,
        name: event.name,
        photoUrl: event.photoUrl,
      );

      final serverUrl = data['serverURL'] as String;
      final token = data['participantToken'] as String;

      await _room.connect(serverUrl, token);

      _setupRoomListeners();

      add(RoomDataChanged());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDisconnect(
    DisconnectRequested event,
    Emitter<VCSState> emit,
  ) async {
    await _room.disconnect();
    emit(const VCSState());
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneRequested event,
    Emitter<VCSState> emit,
  ) async {
    final newValue = !state.isMicrophoneEnabled;

    await _room.localParticipant?.setMicrophoneEnabled(newValue);

    emit(state.copyWith(isMicrophoneEnabled: newValue));
  }

  Future<void> _onToggleCamera(
    ToggleCameraRequested event,
    Emitter<VCSState> emit,
  ) async {
    final newValue = !state.isCameraEnabled;

    await _room.localParticipant?.setCameraEnabled(newValue);

    emit(state.copyWith(isCameraEnabled: newValue));
  }

  Future<void> _onFlipCamera(
    FlipCameraRequested event,
    Emitter<VCSState> emit,
  ) async {
    final trackPub = _room.localParticipant?.videoTrackPublications.firstOrNull;
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

    for (final participant in _room.remoteParticipants.values) {
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
    _listener
      // Участник подключился
      ..on<ParticipantConnectedEvent>((event) {
        add(RoomDataChanged());
      })
      // Участник вышел
      ..on<ParticipantDisconnectedEvent>((event) {
        add(RoomDataChanged());
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
        print(
          'Participant ${event.participant.name} is speaking: ${event.participant.isSpeaking}',
        );
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
    if (_room.localParticipant == null) return;

    final participants = <Participant>[
      _room.localParticipant!,
      ..._room.remoteParticipants.values,
    ];

    final videoTracks = <String, VideoTrack>{};
    final audioTracks = <String, AudioTrack>{};
    final photoUrls = <String, String>{};

    for (final participant in participants) {
      // Видео
      for (final pub in participant.videoTrackPublications) {
        if (pub.track is VideoTrack && pub.subscribed && !pub.muted) {
          videoTracks[participant.sid] = pub.track as VideoTrack;
        }
      }

      // Фото
      final metadata = participant.metadata;
      if (metadata == null || metadata.isEmpty) {
      } else {
        final decoded = jsonDecode(metadata);
        photoUrls[participant.sid] = decoded['photoUrl'];
      }

      // Аудио
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
    await _listener.dispose();
    await _room.dispose();
    return super.close();
  }
}
