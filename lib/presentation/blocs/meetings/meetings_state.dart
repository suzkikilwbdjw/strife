class MeetingsState {
  final String? error;
  final bool isLoading;
  final bool isCancelled;

  const MeetingsState({
    this.error,
    this.isLoading = false,
    this.isCancelled = false,
  });

  MeetingsState copyWith({String? error, bool? isLoading, bool? isCancelled}) {
    return MeetingsState(
      error: error,
      isLoading: isLoading ?? this.isLoading,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}
