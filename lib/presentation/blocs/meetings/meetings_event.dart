part of 'meetings_bloc.dart';

abstract class MeetingsEvent extends Equatable {
  const MeetingsEvent();

  @override
  List<Object?> get props => [];
}

class SendMeetingRequestRequested extends MeetingsEvent {
  final String senderId;
  final List<String> participantIds;
  final String senderName;
  final String senderPhotoUrl;
  final String roomId;
  final String titleMeeting;
  final DateTime meetingDateTime;

  const SendMeetingRequestRequested({
    required this.senderId,
    required this.participantIds,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.roomId,
    required this.titleMeeting,
    required this.meetingDateTime,
  });

  @override
  List<Object?> get props => [
    senderId,
    participantIds,
    senderName,
    senderPhotoUrl,
    roomId,
    titleMeeting,
    meetingDateTime,
  ];
}

class SendUpdateMeetingRequested extends MeetingsEvent {
  final String meetingId;
  final String senderId;
  final List<String> participantIds;
  final String senderName;
  final String senderPhotoUrl;
  final String titleMeeting;
  final DateTime meetingDateTime;

  const SendUpdateMeetingRequested({
    required this.meetingId,
    required this.senderId,
    required this.participantIds,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.titleMeeting,
    required this.meetingDateTime,
  });

  @override
  List<Object?> get props => [
    meetingId,
    senderId,
    participantIds,
    senderName,
    senderPhotoUrl,
    titleMeeting,
    meetingDateTime,
  ];
}

class SendCancelMeetingRequested extends MeetingsEvent {
  final String meetingId;
  final String senderId;
  final List<String> participantIds;
  final String senderName;
  final String senderPhotoUrl;
  final String roomId;
  final String titleMeeting;
  final DateTime meetingDateTime;

  const SendCancelMeetingRequested({
    required this.meetingId,
    required this.senderId,
    required this.participantIds,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.roomId,
    required this.titleMeeting,
    required this.meetingDateTime,
  });

  @override
  List<Object?> get props => [
    meetingId,
    senderId,
    participantIds,
    senderName,
    senderPhotoUrl,
    roomId,
    titleMeeting,
    meetingDateTime,
  ];
}
