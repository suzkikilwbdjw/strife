class ContactsState {
  final bool isSubmitted;

  // Контакты
  final Set<String> myContactsId;
  const ContactsState({this.isSubmitted = false, this.myContactsId = const {}});

  ContactsState copyWith({bool? isSubmitted, Set<String>? myContactsId}) {
    return ContactsState(
      isSubmitted: isSubmitted ?? this.isSubmitted,
      myContactsId: myContactsId ?? this.myContactsId,
    );
  }
}
