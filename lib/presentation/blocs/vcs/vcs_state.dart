import 'package:livekit_client/livekit_client.dart';

const _undefined = Object();

class VCSState {
  final List<Participant> participants;

  final String? pinnedParticipantSid;
  final String? activeSpeakerSid;

  final bool isReconnecting;
  final bool isRemoteAudioEnabled;
  final bool isCameraEnabled;
  final bool isMicrophoneEnabled;

  final Map<String, ConnectionQuality> connectionQualities;
  final Map<String, VideoTrack> videoTracks;
  final Map<String, AudioTrack> audioTracks;
  final Map<String, String> photoUrls;

  final String? error;

  const VCSState({
    this.participants = const [],
    this.pinnedParticipantSid,
    this.activeSpeakerSid,
    this.isReconnecting = false,
    this.isRemoteAudioEnabled = true,
    this.isCameraEnabled = false,
    this.isMicrophoneEnabled = false,
    this.connectionQualities = const {},
    this.videoTracks = const {},
    this.audioTracks = const {},
    this.photoUrls = const {},
    this.error,
  });

  VCSState copyWith({
    List<Participant>? participants,
    Object? pinnedParticipantSid = _undefined,
    String? activeSpeakerSid,
    bool? isReconnecting,
    bool? isRemoteAudioEnabled,
    bool? isCameraEnabled,
    bool? isMicrophoneEnabled,
    Map<String, ConnectionQuality>? connectionQualities,
    Map<String, VideoTrack>? videoTracks,
    Map<String, AudioTrack>? audioTracks,
    Map<String, String>? photoUrls,
    String? error,
  }) {
    return VCSState(
      participants: participants ?? this.participants,
      pinnedParticipantSid: pinnedParticipantSid == _undefined
          ? this.pinnedParticipantSid
          : (pinnedParticipantSid as String?),
      activeSpeakerSid: activeSpeakerSid ?? this.activeSpeakerSid,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      isRemoteAudioEnabled: isRemoteAudioEnabled ?? this.isRemoteAudioEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isMicrophoneEnabled: isMicrophoneEnabled ?? this.isMicrophoneEnabled,
      connectionQualities: connectionQualities ?? this.connectionQualities,
      videoTracks: videoTracks ?? this.videoTracks,
      audioTracks: audioTracks ?? this.audioTracks,
      photoUrls: photoUrls ?? this.photoUrls,
      error: error,
    );
  }
}
