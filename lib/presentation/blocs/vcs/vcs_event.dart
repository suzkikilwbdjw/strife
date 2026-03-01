import 'package:livekit_client/livekit_client.dart';

abstract class VCSEvent {}

/*=========================Внешние события================*/
class ConnectRequested extends VCSEvent {
  final String roomName;
  final String identity;
  final String name;
  final String? photoUrl;

  ConnectRequested({
    required this.roomName,
    required this.identity,
    required this.name,
    this.photoUrl,
  });
}

class DisconnectRequested extends VCSEvent {}

class ToggleMicrophoneRequested extends VCSEvent {}

class ToggleCameraRequested extends VCSEvent {}

class FlipCameraRequested extends VCSEvent {}

class ToggleRemoteAudioRequested extends VCSEvent {}

class TogglePinRequested extends VCSEvent {
  final String participantSid;

  TogglePinRequested(this.participantSid);
}

/*===========================================================*/

/*=========================Внутренние события================*/
class RoomDataChanged extends VCSEvent {}

class ConnectionQualityUpdated extends VCSEvent {
  final String participantSid;
  final ConnectionQuality quality;

  ConnectionQualityUpdated(this.participantSid, this.quality);
}

class ActiveSpeakerChanged extends VCSEvent {
  final String? participantSid;

  ActiveSpeakerChanged(this.participantSid);
}

class ReconnectingStarted extends VCSEvent {}

class ReconnectingFinished extends VCSEvent {}

/*===========================================================*/
