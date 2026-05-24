part of 'vcs_bloc.dart';

const _undefined = Object();

enum RoomLeaveReason { none, kicked, terminatedByHost }

class VCSState extends Equatable {
  final bool isMinimized;

  final bool isConnected;

  final List<Participant> participants;
  final Participant? participantJoin;
  final Participant? participantLeft;

  final String? pinnedParticipantSid;
  final String? activeSpeakerSid;

  final List<String> hostSids;

  final Map<String, bool> mutedMicrophoneByHostSids;
  final Map<String, bool> mutedCameraByHostSids;

  final RoomLeaveReason leaveReason;

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
    this.isMinimized = false,
    this.isConnected = false,
    this.participantJoin,
    this.participantLeft,
    this.participants = const [],
    this.pinnedParticipantSid,
    this.activeSpeakerSid,
    this.hostSids = const [],
    this.mutedMicrophoneByHostSids = const {},
    this.mutedCameraByHostSids = const {},
    this.leaveReason = RoomLeaveReason.none,
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
    bool? isMinimized,
    bool? isConnected,
    List<Participant>? participants,
    Participant? participantLeft,
    Participant? participantJoin,
    Object? pinnedParticipantSid = _undefined,
    String? activeSpeakerSid,
    List<String>? hostSids,
    Map<String, bool>? mutedMicrophoneByHostSids,
    Map<String, bool>? mutedCameraByHostSids,
    RoomLeaveReason? leaveReason,
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
      participantJoin: participantJoin ?? this.participantJoin,
      participantLeft: participantLeft ?? this.participantLeft,
      isMinimized: isMinimized ?? this.isMinimized,
      isConnected: isConnected ?? this.isConnected,
      participants: participants ?? this.participants,
      pinnedParticipantSid: pinnedParticipantSid == _undefined
          ? this.pinnedParticipantSid
          : (pinnedParticipantSid as String?),
      activeSpeakerSid: activeSpeakerSid ?? this.activeSpeakerSid,
      leaveReason: leaveReason ?? this.leaveReason,
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

  @override
  List<Object?> get props => [
    isMinimized,
    isConnected,
    participantJoin,
    participantLeft,
    participants,
    pinnedParticipantSid,
    activeSpeakerSid,
    hostSids,
    mutedMicrophoneByHostSids,
    mutedCameraByHostSids,
    leaveReason,
    isReconnecting,
    isRemoteAudioEnabled,
    isCameraEnabled,
    isMicrophoneEnabled,
    connectionQualities,
    videoTracks,
    audioTracks,
    photoUrls,
    error,
  ];
}
