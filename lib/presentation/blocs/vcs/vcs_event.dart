import 'package:livekit_client/livekit_client.dart';

abstract class VCSEvent {}

/*=========================Внешние события================*/
// Событие для подключение
class ConnectRequested extends VCSEvent {
  final String roomId;
  final String identity;
  final String name;
  final String? photoUrl;

  ConnectRequested({
    required this.roomId,
    required this.identity,
    required this.name,
    this.photoUrl,
  });
}

// Событие если выгнали из комнаты
class KickedFromRoomRequested extends VCSEvent {}

// Событие для отключения
class DisconnectRequested extends VCSEvent {}

// Событие вкл/выкл микрофона
class ToggleMicrophoneRequested extends VCSEvent {}

// Событие вкл/выкл камеры
class ToggleCameraRequested extends VCSEvent {}

// Событие переворота камеры
class FlipCameraRequested extends VCSEvent {}

// Событие замутился
class ToggleRemoteAudioRequested extends VCSEvent {}

class TogglePinRequested extends VCSEvent {
  final String participantSid;

  TogglePinRequested(this.participantSid);
}

// Событие отключения доступа к микрофонy участнику
class MuteParticipantRequested extends VCSEvent {
  final String participantIdentity;
  MuteParticipantRequested(this.participantIdentity);
}

// Событие разрешения доступа к микрофону участника
class UnmuteParticipantRequested extends VCSEvent {
  final String participantIdentity;
  UnmuteParticipantRequested(this.participantIdentity);
}

// Событие отключение доступа камеры участнику
class DisableCameraParticipantRequested extends VCSEvent {
  final String participantIdentity;
  DisableCameraParticipantRequested(this.participantIdentity);
}

// Событие разрешения доступа к камерe участнику
class EnableCameraParticipantRequested extends VCSEvent {
  final String participantIdentity;
  EnableCameraParticipantRequested(this.participantIdentity);
}

// Событие выгнать участника из комнаты
class KickParticipantRequested extends VCSEvent {
  final String participantIdentity;
  KickParticipantRequested(this.participantIdentity);
}

// Событие передавть права участнику
class TransferHostRequested extends VCSEvent {
  final String participantIdentity;
  TransferHostRequested(this.participantIdentity);
}

class SyncHardwareStatus extends VCSEvent {
  final bool? isMicEnabled;
  final bool? isCamEnabled;

  SyncHardwareStatus({this.isMicEnabled, this.isCamEnabled});
}

class ToggleMinimizeRoomRequested extends VCSEvent {
  final bool minimize;

  ToggleMinimizeRoomRequested({required this.minimize});
}

// Событие при завершении комнаты хостом
class RoomTerminatedByHostRequested extends VCSEvent {
  RoomTerminatedByHostRequested();
}

// Событие для завершения комнаты хостом
class RoomTerminateRequested extends VCSEvent {
  final String roomId;

  RoomTerminateRequested({required this.roomId});
}

class AddParticipantRequested extends VCSEvent {
  final String roomId;
  final String participantId;

  AddParticipantRequested({required this.roomId, required this.participantId});
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
