import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/presentation/contacts/contacts_event.dart';
import 'package:strife/presentation/contacts/contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final UserRepository _repository;

  ContactsBloc(this._repository) : super(const ContactsState()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<AddContactsRequested>(_onAddContacts);
    on<LoadContactsRequested>(_onLoadContacts);
    on<RemoveContactsRequested>(_onRemoveContacts);
  }

  Future<void> _onLoadContacts(
    LoadContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final contacts = await _repository.getContacts(event.currentUserId);
    emit(state.copyWith(myContactsId: contacts));
  }

  Future<void> _onAddContacts(
    AddContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    emit(state.copyWith(isSubmitted: true));
    await _repository.addContact(event.currentUserId, event.contactId);
    emit(state.copyWith(isSubmitted: false));
  }

  Future<void> _onRemoveContacts(
    RemoveContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    await _repository.removeContact(event.currentUserId, event.contactId);

    final updatedList = List<String>.from(state.myContactsId)
      ..remove(event.contactId);

    emit(state.copyWith(myContactsId: updatedList));
  }
}
