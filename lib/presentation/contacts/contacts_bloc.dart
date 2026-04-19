import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/presentation/contacts/contacts_event.dart';
import 'package:strife/presentation/contacts/contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final UserRepository _repository;
  StreamSubscription? _contactsSubscription;

  ContactsBloc(this._repository) : super(const ContactsState()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<AddContactsRequested>(_onAddContacts);
    on<LoadContactsRequested>(_onLoadContacts);
    on<RemoveContactsRequested>(_onRemoveContacts);
    on<UpdateContactsListRequested>(_onUpdateContactsList);
    on<SearchContactsRequested>(_onSearchContacts);
    on<ToggleFavoriteRequested>(_toggleFavorite);
  }

  Future<void> _toggleFavorite(
    ToggleFavoriteRequested event,
    Emitter<ContactsState> emit,
  ) async {
    await _repository.toggleFavorite(
      event.currentUserId,
      event.contactId,
      event.isFavorite,
    );
  }

  Future<void> _onUpdateContactsList(
    UpdateContactsListRequested event,
    Emitter<ContactsState> emit,
  ) async {
    emit(
      state.copyWith(
        allContacts: event.fullContacts,
        filteredContacts: state.searchQuery.isEmpty
            ? event.fullContacts
            : event.fullContacts
                  .where(
                    (c) => c['displayName'].toString().toLowerCase().contains(
                      state.searchQuery,
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Future<void> _onSearchContacts(
    SearchContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final query = event.searchQuery.toLowerCase();

    if (query.isEmpty) {
      // Если строка пустая, показываем всех без фильтрации
      emit(
        state.copyWith(filteredContacts: state.allContacts, searchQuery: ''),
      );
    } else {
      final filtered = state.allContacts.where((contact) {
        final name = contact['displayName'].toString().toLowerCase();
        return name.contains(query);
      }).toList();

      emit(state.copyWith(filteredContacts: filtered, searchQuery: query));
    }
  }

  Future<void> _onLoadContacts(
    LoadContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    await _contactsSubscription?.cancel();

    // Подписываемся на стрим ID контактов
    _contactsSubscription = _repository
        .contactsStream(event.currentUserId)
        .listen((contactInfos) async {
          // Для каждого ID получаем данные пользователя
          final List<Map<String, dynamic>> fullContacts = [];

          for (var info in contactInfos) {
            final userId = info['id'];

            final isFavorite = info['isFavorite'];

            final userData = await _repository.getUserData(userId);

            fullContacts.add({
              ...userData,
              'id': userId,
              'isFavorite': isFavorite,
            });
          }

          add(UpdateContactsListRequested(fullContacts: fullContacts));
        });
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

    final updatedList = state.allContacts
        .where((contact) => contact['id'] != event.contactId)
        .toList();

    emit(state.copyWith(allContacts: updatedList));
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}
