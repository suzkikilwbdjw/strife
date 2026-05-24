import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/models/message_model.dart';
import 'package:equatable/equatable.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;
  final NotificationRepository _notificationRepository;

  // Подписка на сообщения в чате
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  // Подписка на сам чат
  StreamSubscription<DocumentSnapshot>? _chatSubscription;

  // Подписка на чаты
  StreamSubscription<List<Map<String, dynamic>>>? _chatsSubscription;

  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? _currentChatId;

  ChatBloc({
    required ChatRepository chatRepository,
    required UserRepository userRepository,
    required NotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository,
       _chatRepository = chatRepository,
       _userRepository = userRepository,
       super(const ChatState()) {
    on<InitChat>(_onInitChat);
    on<InitChats>(_onInitChats);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<ChatDataUpdated>(_onChatDataUpdated);
    on<SendMessage>(_onSendMessage);
    on<LoadUser>(_onLoadUser);
    on<SendMessageRequested>(_onSendMessageRequest);
    on<UpdateChats>(_updateChats);
    on<SearchChats>(_searchChats);
  }

  Future<void> _searchChats(SearchChats event, Emitter<ChatState> emit) async {
    final query = event.searchQuery.toLowerCase();

    if (query.isEmpty) {
      // Если строка пустая, показываем все без фильтрации
      emit(state.copyWith(filteredChats: state.allChats, searchQuery: ''));
    } else {
      final filtered = state.allChats.where((chat) {
        final name =
            chat['participantsInfo'][(chat['participants'] as List?)
                    ?.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => currentUserId,
                    )]['displayName']
                .toString()
                .toLowerCase();
        return name.contains(query);
      }).toList();

      emit(state.copyWith(filteredChats: filtered, searchQuery: query));
    }
  }

  Future<void> _updateChats(UpdateChats event, Emitter<ChatState> emit) async {
    emit(
      state.copyWith(
        allChats: event.allChats,
        filteredChats: state.searchQuery.isEmpty
            ? event.allChats
            : event.allChats
                  .where(
                    (chat) =>
                        chat['participantsInfo'][(chat['participants'] as List?)
                                ?.firstWhere(
                                  (id) => id != currentUserId,
                                  orElse: () => currentUserId,
                                )]['displayName']
                            .toString()
                            .toLowerCase()
                            .contains(state.searchQuery),
                  )
                  .toList(),
      ),
    );
  }

  Future<void> _onInitChats(InitChats event, Emitter<ChatState> emit) async {
    try {
      emit(state.copyWith(error: null));

      await _chatsSubscription?.cancel();

      _chatsSubscription = _chatRepository.getAllMyChats(event.userId).listen((
        chats,
      ) {
        add(UpdateChats(allChats: chats));
      });
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSendMessageRequest(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentChatId == null || currentUserId == null) return;

    try {
      emit(state.copyWith(error: null));

      // Отправитель
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String senderId = currentUser.uid;
      final String senderName = currentUser.displayName ?? 'Пользователь';
      final String senderPhotoUrl = currentUser.photoURL ?? '';

      // Получатель
      final chatParts = _currentChatId!.split('_');
      final String recipientId = chatParts.firstWhere(
        (id) => id != senderId,
        orElse: () => senderId,
      );

      await _notificationRepository.sendMessageRequest(
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        textMessage: event.textMessage,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  ///  Инициализация чата
  Future<void> _onInitChat(InitChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true));

    _currentChatId = event.chatId;
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Сбрасываем старые подписки
    await _messagesSubscription?.cancel();
    await _chatSubscription?.cancel();

    // Слушаем сообщения
    _messagesSubscription = _chatRepository.getMessage(event.chatId).listen((
      messages,
    ) {
      add(MessagesUpdated(messages));
    });

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(event.chatId)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists && docSnapshot.data() != null) {
            add(ChatDataUpdated(chatData: docSnapshot.data()!));
          }
        });

    if (currentUserId != null) {
      _chatRepository.markAsRead(event.chatId, currentUserId!);
    }
  }

  void _onChatDataUpdated(ChatDataUpdated event, Emitter<ChatState> emit) {
    final chatDoc = event.chatData;

    final Map<String, dynamic> members = chatDoc['participantsInfo'] ?? {};

    final updatedCache = Map<String, Map<String, dynamic>>.from(
      state.usersCache,
    );

    members.forEach((userId, userInfo) {
      updatedCache[userId] = Map<String, dynamic>.from(userInfo as Map);
    });

    emit(state.copyWith(chatData: chatDoc, usersCache: updatedCache));
  }

  /// Обновление сообщений из стрима
  Future<void> _onMessagesUpdated(
    MessagesUpdated event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(messages: event.messages, isLoading: false));

    final bool isPrivateChat = _currentChatId!.contains('_');
    if (!isPrivateChat) {
      for (final msg in event.messages) {
        if (!state.usersCache.containsKey(msg.senderId)) {
          add(LoadUser(msg.senderId));
        }
      }
    }

    // Проверяем и помечаем прочитанными
    final hasUnread = event.messages.any(
      (msg) =>
          msg.senderId != currentUserId &&
          !(msg.readBy?.contains(currentUserId) ?? false),
    );

    if (hasUnread && currentUserId != null && _currentChatId != null) {
      await _chatRepository.markAsRead(_currentChatId!, currentUserId!);
    }
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<ChatState> emit) async {
    if (state.usersCache.containsKey(event.userId) &&
        state.usersCache[event.userId]?['loading'] != true) {
      return;
    }

    final updatedCache = Map<String, Map<String, dynamic>>.from(
      state.usersCache,
    );
    updatedCache[event.userId] = {'loading': true};
    emit(state.copyWith(usersCache: updatedCache));

    try {
      final userData = await _userRepository.getUserData(event.userId);
      updatedCache[event.userId] = userData;
      emit(state.copyWith(usersCache: updatedCache));
    } catch (_) {
      updatedCache[event.userId] = {'error': true};
      emit(state.copyWith(usersCache: updatedCache));
    }
  }

  /// Отправка сообщения без уведомления
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (event.text.trim().isEmpty) return;

    final newMessage = MessageModel(
      senderId: event.senderId,
      text: event.text,
      timestamp: DateTime.now(),
    );

    try {
      await _chatRepository.sendMessage(event.chatId, newMessage);
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка отправки сообщения'));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _chatSubscription?.cancel();
    _chatsSubscription?.cancel();
    return super.close();
  }
}
