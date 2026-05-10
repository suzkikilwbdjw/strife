class ContactsState {
  final bool isSubmitted;
  final bool isLoading;
  final String? error;

  // Контакты
  final List<Map<String, dynamic>> allContacts; // ID, имена, фото
  // Отфильтрованные контакты
  final List<Map<String, dynamic>> filteredContacts;
  // Запрос на поиск
  final String searchQuery;

  const ContactsState({
    this.isLoading = false,
    this.isSubmitted = false,
    this.allContacts = const [],
    this.filteredContacts = const [],
    this.searchQuery = '',
    this.error,
  });

  ContactsState copyWith({
    bool? isLoading,
    bool? isSubmitted,
    List<Map<String, dynamic>>? allContacts,
    List<Map<String, dynamic>>? filteredContacts,
    String? searchQuery,
    String? error,
  }) {
    return ContactsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}
