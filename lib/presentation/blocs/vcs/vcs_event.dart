part of 'vcs_bloc.dart';

abstract class VCSEvent extends Equatable {
  const VCSEvent();

  @override
  List<Object?> get props => [];
}

/*=========================Внешние события================*/
// Событие для подключение
class ConnectRequested extends VCSEvent {
  final String roomId;
  final String identity;
  final String name;
  final String? photoUrl;

  const ConnectRequested({
    required this.roomId,
    required this.identity,
    required this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [roomId, identity, name, photoUrl];
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

  const TogglePinRequested(this.participantSid);

  @override
  List<Object?> get props => [participantSid];
}

// Событие отключения доступа к микрофонy участнику
class MuteParticipantRequested extends VCSEvent {
  final String participantIdentity;

  const MuteParticipantRequested(this.participantIdentity);

  @override
  List<Object?> get props => [participantIdentity];
}

// Событие разрешения доступа к микрофону участника
class UnmuteParticipantRequested extends VCSEvent {
  final String participantIdentity;

  const UnmuteParticipantRequested(this.participantIdentity);

  @override
  List<Object?> get props => [participantIdentity];
}

// Событие отключение доступа камеры участнику
class DisableCameraParticipantRequested extends VCSEvent {
  final String participantIdentity;

  const DisableCameraParticipantRequested(this.participantIdentity);

  @override
  List<Object?> get props => [participantIdentity];
}

// Событие разрешения доступа к камерe участнику
class EnableCameraParticipantRequested extends VCSEvent {
  final String participantIdentity;

  const EnableCameraParticipantRequested(this.participantIdentity);

  @override
  List<Object?> get props => [participantIdentity];
}

// Событие выгнать участника из комнаты
class KickParticipantRequested extends VCSEvent {
  final String participantIdentity;

  const KickParticipantRequested(this.participantIdentity);

  @override
  List<Object?> get props => [participantIdentity];
}

// Событие передавть права участнику
class TransferHostRequested extends VCSEvent {
  final String participantIdentity;

  const TransferHostRequested(this.participantIdentity);

  @override
  List<Object?> get props => [participantIdentity];
}

class ParticipantJoinRequested extends VCSEvent {
  final Participant participantJoin;

  const ParticipantJoinRequested({required this.participantJoin});
  @override
  List<Object?> get props => [participantJoin];
}

class ParticipantLeftRequested extends VCSEvent {
  final Participant participantLeft;

  const ParticipantLeftRequested({required this.participantLeft});
  @override
  List<Object?> get props => [participantLeft];
}

class SyncHardwareStatus extends VCSEvent {
  final bool? isMicEnabled;
  final bool? isCamEnabled;

  const SyncHardwareStatus({this.isMicEnabled, this.isCamEnabled});

  @override
  List<Object?> get props => [isMicEnabled, isCamEnabled];
}

class ToggleMinimizeRoomRequested extends VCSEvent {
  final bool minimize;

  const ToggleMinimizeRoomRequested({required this.minimize});

  @override
  List<Object?> get props => [minimize];
}

// Событие при завершении комнаты хостом
class RoomTerminatedByHostRequested extends VCSEvent {
  const RoomTerminatedByHostRequested();
}

// Событие для завершения комнаты хостом
class RoomTerminateRequested extends VCSEvent {
  final String roomId;

  const RoomTerminateRequested({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class AddParticipantRequested extends VCSEvent {
  final String roomId;
  final String participantId;

  const AddParticipantRequested({
    required this.roomId,
    required this.participantId,
  });

  @override
  List<Object?> get props => [roomId, participantId];
}

/*===========================================================*/

/*=========================Внутренние события================*/
class RoomDataChanged extends VCSEvent {}

class ConnectionQualityUpdated extends VCSEvent {
  final String participantSid;
  final ConnectionQuality quality;

  const ConnectionQualityUpdated(this.participantSid, this.quality);

  @override
  List<Object?> get props => [participantSid, quality];
}

class ActiveSpeakerChanged extends VCSEvent {
  final String? participantSid;

  const ActiveSpeakerChanged(this.participantSid);

  @override
  List<Object?> get props => [participantSid];
}

class ReconnectingStarted extends VCSEvent {}

class ReconnectingFinished extends VCSEvent {}

/*===========================================================*/
