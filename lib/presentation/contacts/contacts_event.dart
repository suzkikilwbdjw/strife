abstract class ContactsEvent {}

class AddContactsRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;

  AddContactsRequested({required this.currentUserId, required this.contactId});
}
