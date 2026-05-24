part of 'meetings_bloc.dart';

abstract class MeetingsEvent extends Equatable {
  const MeetingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMeetingsRequested extends MeetingsEvent {
  final String userId;

  const LoadMeetingsRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateMeetingsRequested extends MeetingsEvent {
  final List<Map<String, dynamic>> fullMeetings;

  const UpdateMeetingsRequested({required this.fullMeetings});

  @override
  List<Object?> get props => [fullMeetings];
}

class SearchMeetingsRequested extends MeetingsEvent {
  final String query;

  const SearchMeetingsRequested({required this.query});

  @override
  List<Object?> get props => [query];
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
