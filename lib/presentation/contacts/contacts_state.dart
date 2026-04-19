class ContactsState {
  final bool isSubmitted;

  // Контакты
  final List<Map<String, dynamic>> allContacts; // ID, имена, фото
  // Отфильтрованные контакты
  final List<Map<String, dynamic>> filteredContacts;
  // Запрос на поиск
  final String searchQuery;

  const ContactsState({
    this.isSubmitted = false,
    this.allContacts = const [],
    this.filteredContacts = const [],
    this.searchQuery = '',
  });

  ContactsState copyWith({
    bool? isSubmitted,
    List<Map<String, dynamic>>? allContacts,
    List<Map<String, dynamic>>? filteredContacts,
    String? searchQuery,
  }) {
    return ContactsState(
      isSubmitted: isSubmitted ?? this.isSubmitted,
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
