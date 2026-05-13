abstract class ContactsEvent {}

class ResetContactsStatusRequested extends ContactsEvent {}

// Событие для отправки запроса в контакты
class SendFriendRequestRequested extends ContactsEvent {
  final String senderId;
  final String recipientEmail;
  final String senderName;
  final String senderPhotoUrl;

  SendFriendRequestRequested({
    required this.senderId,
    required this.recipientEmail,
    required this.senderName,
    required this.senderPhotoUrl,
  });
}

// Событие для отправки уведомления контаку о приглашении его в звонок
class SendCallRequestRequested extends ContactsEvent {
  final String senderId;
  final String recipientId;
  final String senderName;
  final String senderPhotoUrl;
  final String roomId;

  SendCallRequestRequested({
    required this.senderId,
    required this.recipientId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.roomId,
  });
}

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

// Событие для удаления контакта
class RemoveContactsRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;

  RemoveContactsRequested({
    required this.currentUserId,
    required this.contactId,
  });
}

class UpdateContactsListRequested extends ContactsEvent {
  final List<Map<String, dynamic>> fullContacts;

  UpdateContactsListRequested({required this.fullContacts});
}

class SearchContactsRequested extends ContactsEvent {
  final String searchQuery;

  SearchContactsRequested({required this.searchQuery});
}

class ToggleFavoriteRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;
  final bool isFavorite;
  ToggleFavoriteRequested({
    required this.currentUserId,
    required this.contactId,
    required this.isFavorite,
  });
}
