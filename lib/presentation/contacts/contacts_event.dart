abstract class ContactsEvent {}

// Событие для первичной загрузки списка
class LoadContactsRequested extends ContactsEvent {
  final String currentUserId;

  LoadContactsRequested({required this.currentUserId});
}

// Событие для добавления нового контакта
class AddContactsRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;

  AddContactsRequested({required this.currentUserId, required this.contactId});
}

class RemoveContactsRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;

  RemoveContactsRequested({
    required this.currentUserId,
    required this.contactId,
  });
}
