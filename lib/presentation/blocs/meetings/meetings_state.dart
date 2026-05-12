class MeetingsState {
  final String? error;
  final bool isLoading;

  const MeetingsState({this.error, this.isLoading = false});

  MeetingsState copyWith({String? error, bool? isLoading}) {
    return MeetingsState(error: error, isLoading: isLoading ?? this.isLoading);
  }
}
