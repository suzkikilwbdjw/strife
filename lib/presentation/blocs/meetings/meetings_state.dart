part of 'meetings_bloc.dart';

class MeetingsState extends Equatable {
  final String? error;
  final bool isLoading;
  final bool isCancelled;

  // Встречи
  final List<Map<String, dynamic>> allMeetings;

  // Отфильтрованные встречи
  final List<Map<String, dynamic>> filteredMeetings;
  final String searchQuery;

  const MeetingsState({
    this.error,
    this.isLoading = false,
    this.isCancelled = false,
    this.allMeetings = const [],
    this.filteredMeetings = const [],
    this.searchQuery = '',
  });

  MeetingsState copyWith({
    String? error,
    bool? isLoading,
    bool? isCancelled,
    List<Map<String, dynamic>>? allMeetings,
    List<Map<String, dynamic>>? filteredMeetings,
    String? searchQuery,
  }) {
    return MeetingsState(
      error: error,
      isLoading: isLoading ?? this.isLoading,
      isCancelled: isCancelled ?? this.isCancelled,
      allMeetings: allMeetings ?? this.allMeetings,
      filteredMeetings: filteredMeetings ?? this.filteredMeetings,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    error,
    isLoading,
    isCancelled,
    searchQuery,
    allMeetings,
    filteredMeetings,
  ];
}
