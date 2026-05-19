import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/presentation/blocs/meetings/meetings_event.dart';
import 'package:strife/presentation/blocs/meetings/meetings_state.dart';

class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  final NotificationRepository _notificationRepository;

  MeetingsBloc(this._notificationRepository) : super(const MeetingsState()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<SendMeetingRequestRequested>(_sendMeetingRequest);
    on<SendUpdateMeetingRequested>(_sendUpdateMeetingRequest);
    on<SendCancleMeetingRequested>(_sendCancleMeetingRequest);
  }

  Future<void> _sendCancleMeetingRequest(
    SendCancleMeetingRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, isCancelled: false));
      _notificationRepository.sendCancleMeetingRequest(
        senderId: event.senderId,
        senderPhotoUrl: event.senderPhotoUrl,
        meetingId: event.meetingId,
        titleMeeting: event.titleMeeting,
        meetingDateTime: event.meetingDateTime,
        participantIds: event.participantIds,
        senderName: event.senderName,
        roomId: event.roomId,
      );
      emit(state.copyWith(isLoading: false, isCancelled: true));
    } catch (e) {
      emit(
        state.copyWith(
          error: e.toString(),
          isLoading: false,
          isCancelled: false,
        ),
      );
    }
  }

  Future<void> _sendUpdateMeetingRequest(
    SendUpdateMeetingRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      _notificationRepository.sendUpdateMeetingRequest(
        senderId: event.senderId,
        senderPhotoUrl: event.senderPhotoUrl,
        meetingId: event.meetingId,
        titleMeeting: event.titleMeeting,
        meetingDateTime: event.meetingDateTime,
        participantIds: event.participantIds,
        senderName: event.senderName,
      );
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _sendMeetingRequest(
    SendMeetingRequestRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      _notificationRepository.sendMeetingRequest(
        senderId: event.senderId,
        participantIds: event.participantIds,
        senderName: event.senderName,
        senderPhotoUrl: event.senderPhotoUrl,
        roomId: event.roomId,
        titleMeeting: event.titleMeeting,
        meetingDateTime: event.meetingDateTime,
      );

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
}
