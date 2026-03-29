class ContactsState {
  final bool isSubmitted;

  // Контакты
  final List<String> myContactsId;
  const ContactsState({this.isSubmitted = false, this.myContactsId = const []});

  ContactsState copyWith({bool? isSubmitted, List<String>? myContactsId}) {
    return ContactsState(
      isSubmitted: isSubmitted ?? this.isSubmitted,
      myContactsId: myContactsId ?? this.myContactsId,
    );
  }
}
