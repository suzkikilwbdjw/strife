part of 'contacts_bloc.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class ResetContactsStatusRequested extends ContactsEvent {}

// Событие для отправки запроса в контакты
class SendFriendRequestRequested extends ContactsEvent {
  final String senderId;
  final String recipientEmail;
  final String senderName;
  final String senderPhotoUrl;

  const SendFriendRequestRequested({
    required this.senderId,
    required this.recipientEmail,
    required this.senderName,
    required this.senderPhotoUrl,
  });

  @override
  List<Object?> get props => [
    senderId,
    recipientEmail,
    senderName,
    senderPhotoUrl,
  ];
}

// Событие для отправки уведомления контакту о приглашении его в звонок
class SendCallRequestRequested extends ContactsEvent {
  final String senderId;
  final String recipientId;
  final String senderName;
  final String senderPhotoUrl;
  final String roomId;
  final Map<String, Map<String, dynamic>> participantsInfo;

  const SendCallRequestRequested({
    required this.senderId,
    required this.recipientId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.roomId,
    required this.participantsInfo,
  });

  @override
  List<Object?> get props => [
    senderId,
    recipientId,
    senderName,
    senderPhotoUrl,
    roomId,
    const DeepCollectionEquality().hash(participantsInfo),
  ];
}

// Событие для первичной загрузки списка
class LoadContactsRequested extends ContactsEvent {
  final String currentUserId;

  const LoadContactsRequested({required this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
}

// Событие для добавления нового контакта
class AddContactsRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;

  const AddContactsRequested({
    required this.currentUserId,
    required this.contactId,
  });

  @override
  List<Object?> get props => [currentUserId, contactId];
}

// Событие для удаления контакта
class RemoveContactsRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;

  const RemoveContactsRequested({
    required this.currentUserId,
    required this.contactId,
  });

  @override
  List<Object?> get props => [currentUserId, contactId];
}

class UpdateContactsListRequested extends ContactsEvent {
  final List<Map<String, dynamic>> fullContacts;

  const UpdateContactsListRequested({required this.fullContacts});

  @override
  List<Object?> get props => [
    const DeepCollectionEquality().hash(fullContacts),
  ];
}

class SearchContactsRequested extends ContactsEvent {
  final String searchQuery;

  const SearchContactsRequested({required this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class ToggleFavoriteRequested extends ContactsEvent {
  final String currentUserId;
  final String contactId;
  final bool isFavorite;

  const ToggleFavoriteRequested({
    required this.currentUserId,
    required this.contactId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [currentUserId, contactId, isFavorite];
}
