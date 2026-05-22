import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';

part 'meetings_state.dart';
part 'meetings_event.dart';

class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  final NotificationRepository _notificationRepository;
  final UserRepository _userRepository;

  StreamSubscription? _meetingsSubscription;

  MeetingsBloc({
    required NotificationRepository notificationRepository,
    required UserRepository userRepository,
  }) : _userRepository = userRepository,
       _notificationRepository = notificationRepository,
       super(const MeetingsState()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<LoadMeetingsRequested>(_loadMeetings);
    on<SendMeetingRequestRequested>(_sendMeetingRequest);
    on<SendUpdateMeetingRequested>(_sendUpdateMeetingRequest);
    on<SendCancelMeetingRequested>(_sendCancleMeetingRequest);
    on<UpdateMeetingsRequested>(_updateMeetings);
    on<SearchMeetingsRequested>(_searchMeetings);
  }

  Future<void> _searchMeetings(
    SearchMeetingsRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(
        state.copyWith(filteredMeetings: state.allMeetings, searchQuery: ''),
      );
    } else {
      final filtred = state.allMeetings.where((meeting) {
        final titleMeeting = meeting['titleMeeting'].toString().toLowerCase();
        return titleMeeting.contains(query);
      }).toList();
      emit(state.copyWith(filteredMeetings: filtred, searchQuery: query));
    }
  }

  Future<void> _updateMeetings(
    UpdateMeetingsRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(
      state.copyWith(
        allMeetings: event.fullMeetings,
        filteredMeetings: state.searchQuery.isEmpty
            ? event.fullMeetings
            : event.fullMeetings
                  .where(
                    (meeting) => meeting['titleMeeting']
                        .toString()
                        .toLowerCase()
                        .contains(state.searchQuery),
                  )
                  .toList(),
      ),
    );
  }

  Future<void> _loadMeetings(
    LoadMeetingsRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    try {
      await _meetingsSubscription?.cancel();
      emit(state.copyWith(isLoading: true, error: null));

      // Инициируем подписку на встречи
      _meetingsSubscription = _userRepository
          .getMeetingsStream(event.userId)
          .listen((allMeetings) {
            add(UpdateMeetingsRequested(fullMeetings: allMeetings));
          });
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _sendCancleMeetingRequest(
    SendCancelMeetingRequested event,
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

  @override
  Future<void> close() {
    _meetingsSubscription?.cancel();
    return super.close();
  }
}
