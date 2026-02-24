import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;

class ClientModel extends ChangeNotifier {
  //Создание и настройка комнаты
  final _room = Room(
    roomOptions: RoomOptions(adaptiveStream: true, dynacast: true),
  );

  // Ошибка
  Object? _error;

  //Адресс server.mjs
  final _httpUrl = Uri.parse('http://62.109.2.27:3000/getToken');

  //Токен доступа
  String? _token;

  //Cписок треков
  List<Participant?> _participants = [];

  //Индификаторы клиента
  String? _participantName;
  String? _participantIdentity;
  String? _participantRoom;

  String? _newParticipantDisplayName;
  String? _leaveParticipantDisplayName;

  String? _pinnedParticipantSid;

  final Map<String, VideoTrack?> _videoTracksBySid = {};

  //Условные
  bool _isReconnecting = false;
  bool _isEnableCamera = false;
  bool _isEnableMicrophone = false;

  final Map<String?, ConnectionQuality?> _connectionQualities = {};
  String? _participantPhotoUrl;

  //Listener
  late final EventsListener<RoomEvent> _listener = _room.createListener();

  //Геттеры
  Object? get error => _error;
  String? get participantName => _participantName;
  String? get participantIdentity => _participantIdentity;
  String? get participantRoom => _participantRoom;
  List<Participant<TrackPublication<Track>>?> get participants => _participants;
  bool get isReconnecting => _isReconnecting;
  String? get newParticipantDisplayName => _newParticipantDisplayName;
  String? get leaveParticipantDisplayName => _leaveParticipantDisplayName;
  bool get isEnableCamera => _isEnableCamera;
  bool get isEnableMicrophone => _isEnableMicrophone;
  String? get participantPhotoUrl => _participantPhotoUrl;
  Participant? getActiveSpeaker() => activeSpeaker;
  String? get pinnedParticipantSid => _pinnedParticipantSid;

  Participant? get activeSpeaker {
    try {
      return _participants.firstWhere((p) => p != null && p.isSpeaking);
    } catch (_) {
      return null;
    }
  }

  Participant? get pinnedParticipant {
    if (_pinnedParticipantSid == null) return null;
    try {
      return _participants.firstWhere((p) => p?.sid == _pinnedParticipantSid);
    } catch (_) {
      return null;
    }
  }
  //

  //Сетеры
  void setParticipantName(String participantName) {
    _participantName = participantName;
  }

  void setParticipantIdemtity(String participantIdentity) {
    _participantIdentity = participantIdentity;
  }

  void setParticipantRoom(String participantRoom) {
    _participantRoom = participantRoom;
  }

  void setParticipantPhotoUrl(String participantPhotoUrl) {
    _participantPhotoUrl = participantPhotoUrl;
  }
  //

  void clearNewParticipantDisplayName() {
    _newParticipantDisplayName = null;
    notifyListeners();
  }

  void clearLeaveParticipantDisplayName() {
    _leaveParticipantDisplayName = null;
    notifyListeners();
  }

  void _sucsesReconncet() {
    _isReconnecting = false;
    notifyListeners();
  }

  void _startReconnecting() {
    _isReconnecting = true;
    notifyListeners();
  }

  void _updatePhotoCache(Participant participant) {
    final metadata = participant.metadata;

    if (metadata == null || metadata.isEmpty) {
      _photoCache[participant.sid] = null;
      return;
    }

    try {
      final decoded = jsonDecode(metadata);
      _photoCache[participant.sid] = decoded['photoUrl'];
    } catch (_) {
      _photoCache[participant.sid] = null;
    }
  }

  ConnectionQuality? connectionQualityOf(Participant participant) {
    return _connectionQualities[participant.sid];
  }

  final Map<String, String?> _photoCache = {};

  String? photoUrlOf(Participant participant) {
    return _photoCache[participant.sid];
  }

  bool hasVideoOf(Participant participant) {
    try {
      return participant.trackPublications.values.any(
        (pub) =>
            pub.kind == TrackType.VIDEO &&
            !pub.muted &&
            pub.subscribed &&
            pub.track != null,
      );
    } catch (_) {
      return false;
    }
  }

  VideoTrack? videoTrackOf(Participant participant) {
    final pub = participant.trackPublications.values.where((pub) {
      return pub.kind == TrackType.VIDEO && pub.track is VideoTrack;
    }).firstOrNull;

    if (pub?.track != null) {
      return pub!.track as VideoTrack;
    }

    // Если в списке публикаций пусто, проверяем ваш кэш по SID
    return _videoTracksBySid[participant.sid];
  }

  void togglePin(Participant participant) {
    if (_pinnedParticipantSid == participant.sid) {
      _pinnedParticipantSid = null;
    } else {
      _pinnedParticipantSid = participant.sid;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _photoCache.clear();
    _listener.dispose();
    _room.dispose();
    super.dispose();
  }

  // Метод подключения к команте
  Future<bool> connectToRoom() async {
    try {
      //Запрос токена у сервера
      final response = await http.post(
        _httpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_name': _participantRoom,
          'participant_identity': _participantIdentity,
          'participant_name': _participantName,
          'photo_url': _participantPhotoUrl,
        }),
      );

      final data = jsonDecode(response.body);
      _token = data['participantToken'] as String;

      // Отображения токена
      print('Токен: $_token');

      //Подключение к комнате
      await _room.connect(data['serverURL'], _token!);
      print('Успешное подключение к комнaте');

      //Вывод текущего пользователя
      print('Текущий пользователь: ${_room.localParticipant}');

      // Изменение числа участников
      _changeParticipants();

      for (var p in _participants) {
        if (p != null) {
          _updatePhotoCache(p);
        }
      }

      //Обработка изменений комнаты и треков
      _handlingEventRoomAndTrack();

      return true;
    } catch (e) {
      _error = e;
      print('Ошибка в методе connectToRoom: $e');
      return false;
    }
  }

  void _handlingEventRoomAndTrack() {
    _listener
      ..on<RoomConnectedEvent>((e) {
        print('(event) Комната подключена. Имя комнаты: ${e.room.name}');
      })
      ..on<RoomDisconnectedEvent>((e) {
        print('(event) Отключение от комнаты (причина): ${e.reason}');
      })
      ..on<ParticipantConnectedEvent>((e) {
        _updatePhotoCache(e.participant);

        _newParticipantDisplayName = e.participant.name;

        _videoTracksBySid[e.participant.sid] =
            e.participant.videoTrackPublications.firstOrNull?.track;

        if (_pinnedParticipantSid == e.participant.sid) {
          _pinnedParticipantSid = null;
        }

        _changeParticipants();

        print('(event) Подключен участник: ${e.participant.name}');
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        if (_isReconnecting) {
          print(
            '(event) Участник вышел в процессе реконнетка: ${e.participant.name}',
          );
          return;
        }
        _videoTracksBySid[e.participant.sid] =
            e.participant.videoTrackPublications.firstOrNull?.track;
        print('(event) Участник вышел: ${e.participant.name}');
        _leaveParticipantDisplayName = e.participant.name;
        _changeParticipants();
      })
      ..on<LocalTrackPublishedEvent>((e) {
        _videoTracksBySid[e.participant.sid] =
            e.participant.videoTrackPublications.firstOrNull?.track;
        notifyListeners();
        print('(event) Локальный трек опубликован');
      })
      ..on<TrackPublishedEvent>((e) async {
        _videoTracksBySid[e.participant.sid] =
            e.participant.videoTrackPublications.firstOrNull?.track;
        notifyListeners();
        print('(event) Удаленный трек опубликован');
      })
      ..on<LocalTrackUnpublishedEvent>((e) {
        notifyListeners();
        print('(event) Локальный участник перестал публиковать трек');
      })
      ..on<TrackUnpublishedEvent>((e) {
        notifyListeners();
        print('(event) Удаленный участник перестал публиковать трек');
      })
      ..on<TrackMutedEvent>((e) {
        notifyListeners();
        print('(event) Трек был замьючен');
      })
      ..on<TrackUnmutedEvent>((e) {
        notifyListeners();
        print('(event) Трек был анмьючен');
      })
      ..on<RoomReconnectingEvent>((e) async {
        _startReconnecting();

        await _room.localParticipant!.unpublishAllTracks();

        print('(event) Попытка переподключения к комнате');
      })
      ..on<RoomReconnectedEvent>((e) async {
        print('(event) Успешное переподключение к комнате');

        if (_isEnableCamera) {
          await enableDisableCamera();
        }

        if (_isEnableMicrophone) {
          await enableDisableMicrophone();
        }
        _sucsesReconncet();
        _changeParticipants();
      })
      ..on<TrackSubscribedEvent>((e) {
        _videoTracksBySid[e.participant.sid] =
            e.participant.videoTrackPublications.firstOrNull?.track;
        print('(event) Локальный участник подписался на трек');
        notifyListeners();
      })
      ..on<TrackUnsubscribedEvent>((e) {
        _videoTracksBySid.remove(e.participant.sid);
        print('(event) Подписанный ранее трек был отписан');
        notifyListeners();
      })
      ..on<ParticipantConnectionQualityUpdatedEvent>((e) {
        _connectionQualities[e.participant.sid] = e.connectionQuality;
        notifyListeners();
        print(
          '(event) Изменение в качестве соединения: ${e.connectionQuality}',
        );
      })
      ..on<ActiveSpeakersChangedEvent>((e) {
        notifyListeners();
        print('(event) Изменено число говорящих');
      })
      ..on<ParticipantMetadataUpdatedEvent>((e) {
        _updatePhotoCache(e.participant);
        notifyListeners();
      });
  }

  void _changeParticipants() {
    _participants = [
      _room.localParticipant,
      ..._room.remoteParticipants.values,
    ];
    notifyListeners();
  }

  //Вкючить камеру (предоставление разрешения)/выключить камеру
  Future<void> enableDisableCamera() async {
    try {
      if (_room.localParticipant!.isCameraEnabled() == false) {
        print('Включение камеры...');
        await _room.localParticipant!.setCameraEnabled(
          true,
          cameraCaptureOptions: CameraCaptureOptions(
            params: VideoParametersPresets.h1080_169,
          ),
        );
        _isEnableCamera = true;
        print('Камера включена');
      } else {
        print('Выключение камеры...');
        await _room.localParticipant!.setCameraEnabled(false);
        _isEnableCamera = false;
        print('Камера выключена');
      }
    } catch (e) {
      print('Ошибка включения/выключения камеры: $e');
    }
  }

  //Включить микрофон (предоставление разрешения)/выключить микрофон
  Future<void> enableDisableMicrophone() async {
    try {
      if (_room.localParticipant!.isMicrophoneEnabled() == false) {
        print('Включение микрофона...');
        await _room.localParticipant!.setMicrophoneEnabled(true);
        _isEnableMicrophone = true;
        print('Успешное включение микрофона');
      } else {
        print('Выключение микрофона...');
        await _room.localParticipant!.setMicrophoneEnabled(false);
        _isEnableMicrophone = false;
        print('Успешное выключение микрофона');
      }
    } catch (e) {
      print('Ошибка включения/выключение микрофона: $e');
    }
  }

  Future<void> disconnectFromRoom() async {
    try {
      print('Отключение от команты...');
      await _room.disconnect();
      print('Успешное отключение от комнаты');
    } catch (e) {
      _error = e;
      print('Ошибка отключения от комнаты: $e');
    }
  }
}
