abstract class MeetingsEvent {}

class SendMeetingRequestRequested extends MeetingsEvent {
  SendMeetingRequestRequested({
    required this.senderId,
    required this.participantIds,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.roomId,
    required this.titleMeeting,
    required this.dateMeeting,
    required this.timeMeeting,
  });

  final String senderId;
  final List<String> participantIds;
  final String senderName;
  final String senderPhotoUrl;
  final String roomId;
  final String titleMeeting;
  final String dateMeeting;
  final String timeMeeting;
}

class SendUpdateMeetingRequested extends MeetingsEvent {
  SendUpdateMeetingRequested({
    required this.meetingId,
    required this.senderId,
    required this.participantIds,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.titleMeeting,
    required this.dateMeeting,
    required this.timeMeeting,
  });
  final String meetingId;
  final String senderId;
  final List<String> participantIds;
  final String senderName;
  final String senderPhotoUrl;
  final String titleMeeting;
  final String dateMeeting;
  final String timeMeeting;
}
