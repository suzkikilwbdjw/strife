import 'package:livekit_client/livekit_client.dart';

const _undefined = Object();

class VCSState {
  final bool isConnected;

  final List<Participant> participants;

  final String? pinnedParticipantSid;
  final String? activeSpeakerSid;

  final Map<String, bool> hostSids;

  final Map<String, bool> mutedMicrophoneByHostSids;
  final Map<String, bool> mutedCameraByHostSids;

  final bool wasKicked;

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
    this.isConnected = false,
    this.participants = const [],
    this.pinnedParticipantSid,
    this.activeSpeakerSid,
    this.hostSids = const {},
    this.mutedMicrophoneByHostSids = const {},
    this.mutedCameraByHostSids = const {},
    this.wasKicked = false,
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
    bool? isConnected,
    List<Participant>? participants,
    Object? pinnedParticipantSid = _undefined,
    String? activeSpeakerSid,
    Map<String, bool>? hostSids,
    Map<String, bool>? mutedMicrophoneByHostSids,
    Map<String, bool>? mutedCameraByHostSids,
    bool? wasKicked,
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
      isConnected: isConnected ?? this.isConnected,
      participants: participants ?? this.participants,
      pinnedParticipantSid: pinnedParticipantSid == _undefined
          ? this.pinnedParticipantSid
          : (pinnedParticipantSid as String?),
      activeSpeakerSid: activeSpeakerSid ?? this.activeSpeakerSid,
      wasKicked: wasKicked ?? this.wasKicked,
      hostSids: hostSids ?? this.hostSids,
      mutedMicrophoneByHostSids:
          mutedMicrophoneByHostSids ?? this.mutedMicrophoneByHostSids,
      mutedCameraByHostSids:
          mutedCameraByHostSids ?? this.mutedCameraByHostSids,
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
