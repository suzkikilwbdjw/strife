import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:strife/data/repositories/notification_repository.dart';

import 'chat_event.dart';
import 'chat_state.dart';

import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/models/message_model.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final UserRepository userRepository;
  final NotificationRepository notificationRepository;

  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  StreamSubscription<DocumentSnapshot>? _chatSubscription;

  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? _currentChatId;

  ChatBloc({
    required this.chatRepository,
    required this.userRepository,
    required this.notificationRepository,
  }) : super(const ChatState()) {
    on<InitChat>(_onInitChat);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<ChatDataUpdated>(_onChatDataUpdated);
    on<SendMessage>(_onSendMessage);
    on<LoadUser>(_onLoadUser);
    on<SendMessageRequest>(_onSendMessageRequest);
  }

  Future<void> _onSendMessageRequest(
    SendMessageRequest event,
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

      await notificationRepository.sendMessageRequest(
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
    _messagesSubscription = chatRepository.getMessage(event.chatId).listen((
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
      chatRepository.markAsRead(event.chatId, currentUserId!);
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
      await chatRepository.markAsRead(_currentChatId!, currentUserId!);
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
      final userData = await userRepository.getUserData(event.userId);
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
      await chatRepository.sendMessage(event.chatId, newMessage);
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка отправки сообщения'));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _chatSubscription?.cancel();
    return super.close();
  }
}
