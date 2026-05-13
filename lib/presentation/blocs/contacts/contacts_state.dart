enum ContactStatus { initial, loading, inviteSuccess, failure }

class ContactsState {
  final bool isSubmitted;
  final ContactStatus status;
  final String? error;

  // Контакты
  final List<Map<String, dynamic>> allContacts; // ID, имена, фото
  // Отфильтрованные контакты
  final List<Map<String, dynamic>> filteredContacts;
  // Запрос на поиск
  final String searchQuery;

  const ContactsState({
    this.status = ContactStatus.initial,
    this.isSubmitted = false,
    this.allContacts = const [],
    this.filteredContacts = const [],
    this.searchQuery = '',
    this.error,
  });

  ContactsState copyWith({
    ContactStatus? status,
    bool? isSubmitted,
    List<Map<String, dynamic>>? allContacts,
    List<Map<String, dynamic>>? filteredContacts,
    String? searchQuery,
    String? error,
  }) {
    return ContactsState(
      status: status ?? this.status,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}
