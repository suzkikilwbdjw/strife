/*import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MeetingConfigurationModel extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.relay.metered.ca:80'},
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': '379b52b6b3a2174f4380a197',
        'credential': 'CrCTWbiICMa+EbQH',
      },
      {
        'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
        'username': '379b52b6b3a2174f4380a197',
        'credential': 'CrCTWbiICMa+EbQH',
      },
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username': '379b52b6b3a2174f4380a197',
        'credential': 'CrCTWbiICMa+EbQH',
      },
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': '379b52b6b3a2174f4380a197',
        'credential': 'CrCTWbiICMa+EbQH',
      },
    ],
  };

  RTCPeerConnection? _connection;
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  final List<RTCVideoRenderer?> _remoteRenderers = [];
  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];
  StreamSubscription? _iceSubUser1;
  StreamSubscription? _iceSubUser2;

  Map<String, dynamic> get configuration => _configuration;
  RTCPeerConnection? get connection => _connection;
  MediaStream? get localStream => _localStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  List<RTCVideoRenderer?> get remoteRenderers => _remoteRenderers;
  List<RTCIceCandidate> get pendingCandidates => _pendingCandidates;
  bool get remoteDescriptionSet => _remoteDescriptionSet;
  StreamSubscription? get iceSubUser1 => _iceSubUser1;
  StreamSubscription? get iceSubUser2 => _iceSubUser2;

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _connection?.close();
    _connection?.dispose();
    _localRenderer?.dispose();
    for (var remoteRenderer in _remoteRenderers) {
      remoteRenderer!.dispose();
    }
    _iceSubUser1?.cancel();
    _iceSubUser2?.cancel();
    super.dispose();
  }

  Future<void> _cleanOldData() async {
    final batch = _db.batch();

    var cands1 = await _db.collection('rooms/room1/candidates/user1/ice').get();
    var cands2 = await _db.collection('rooms/room1/candidates/user2/ice').get();

    for (var doc in cands1.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in cands2.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_db.doc('rooms/room1/offer/user1'));
    batch.delete(_db.doc('rooms/room1/answer/user2'));

    await batch.commit();
  }

  Future<void> _openCamera() async {
    try {
      _localRenderer ??= RTCVideoRenderer();
      await _localRenderer!.initialize();
      if (_localStream != null) _localRenderer!.srcObject = _localStream;
      notifyListeners();
    } catch (e) {
      print('Open camera Error: $e');
    }
  }

  Future<void> _getMedia() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': 'user',
          'width': 720,
          'height': 1280,
          'framRate': 30,
        },
      });
    } catch (e) {
      print('Get media Error: $e');
    }
  }

  Future<bool> createRoom() async {
    try {
      await _cleanOldData();
      await _getMedia();
      await _openCamera();

      _connection = await createPeerConnection(_configuration);

      // ICE кандидаты
      _connection!.onIceCandidate = (candidate) async {
        if (candidate.candidate == null) return;

        await _db
            .collection('rooms')
            .doc('room1')
            .collection('candidates')
            .doc('user1')
            .collection('ice')
            .add({
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            })
            .then((_) {
              print('ICE Candidate added: ${candidate.candidate}');
            });
      };

      await _listenIceFromUser2();

      await _initRemoteRenderer();

      // Получаем треки
      _connection!.onTrack = (event) {
        for (var track in event.streams.first.getVideoTracks()) {
          _createRendererForTrack(track);
        }
        /*_remoteRenderers[0]!.srcObject = event.streams.first;
        print('Удаленной трек получен');
        notifyListeners();*/
      };

      //  Добавляем треки
      for (final track in _localStream!.getTracks()) {
        final sender = await _connection!.addTrack(track, _localStream!);
        print('Трек добавлен к соединению by user1: ${sender.senderId}');
      }

      // Offer
      final offer = await _connection!.createOffer();
      await _connection!.setLocalDescription(offer);
      print('Локальный оффер со стороны user1 установлен ${offer.sdp}');

      await _sendOffer(offer);

      //Ждем ответ
      _waitForAnswer();

      _connection!.onConnectionState = (state) {
        print('Connection state user1: $state');
      };
      _connection!.onIceConnectionState = (state) {
        print('Ice candidate connection state user1: $state');
      };
      return true;
    } catch (e) {
      print('createOffer error: $e');
      return false;
    }
  }

  Future<void> _initRemoteRenderer() async {
    _remoteRenderers.insert(0, RTCVideoRenderer());
    await _remoteRenderers[0]!.initialize();
    notifyListeners();
  }

  void _waitForAnswer() async {
    final answer = await _pullAnswer();
    await _connection!.setRemoteDescription(answer!);
    _remoteDescriptionSet = true;
    print('Установлен setRemoteDescription со стороны user1');

    // pending ICE
    for (final c in _pendingCandidates) {
      await _connection!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  Future<void> _listenIceFromUser2() async {
    _iceSubUser2 = _db
        .collection('rooms')
        .doc('room1')
        .collection('candidates')
        .doc('user2')
        .collection('ice')
        .snapshots()
        .listen((querySnapshot) async {
          for (final change in querySnapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data == null) continue;

              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );

              if (_remoteDescriptionSet) {
                print(
                  'ICE Candidate from user 2 has been received ${candidate.candidate}',
                );
                await _connection!.addCandidate(candidate);
              } else {
                _pendingCandidates.add(candidate);
              }
            }
          }
        });
  }

  Future<RTCSessionDescription?> _pullAnswer() async {
    final doc = await _db
        .collection('rooms')
        .doc('room1')
        .collection('answer')
        .doc('user2')
        .snapshots()
        .firstWhere((snapshot) => snapshot.exists && snapshot.data() != null);

    final data = doc.data() as Map<String, dynamic>;
    print('Answer has been received: ${data['sdp']}');
    return RTCSessionDescription(data['sdp'], data['type']);
  }

  Future<void> _sendOffer(RTCSessionDescription offer) async {
    final Map<String, dynamic> dataOffer = {
      'type': offer.type,
      'sdp': offer.sdp,
    };
    await _db
        .collection('rooms')
        .doc('room1')
        .collection('offer')
        .doc('user1')
        .set(dataOffer)
        .then((_) {
          print('Offer отправлен');
        });
  }

  Future<bool> joinRoom() async {
    try {
      // Ждем offer от user1
      final offer = await _waitForOffer();
      print('Offer получен от user1 ${offer!.sdp}');

      _connection = await createPeerConnection(_configuration);

      await _getMedia();
      await _openCamera();

      // ICE кандидаты
      _connection!.onIceCandidate = (candidate) async {
        if (candidate.candidate == null) return;

        await _db
            .collection('rooms')
            .doc('room1')
            .collection('candidates')
            .doc('user2')
            .collection('ice')
            .add({
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            })
            .then((_) {
              print('ICE кандидаты добавлены в БД by user2');
            });
      };

      //Слушаем ice кандидатов от user1
      await _listenIceFromUser1();

      //Инициализация удаленного соединения
      await _initRemoteRenderer();

      //Получаем удаленные треки
      _connection!.onTrack = (event) {
        _remoteRenderers[0]!.srcObject = event.streams.first;
        notifyListeners();
      };

      // Принимаем offer
      await _connection!.setRemoteDescription(offer);
      _remoteDescriptionSet = true;

      // pending ICE
      for (final c in _pendingCandidates) {
        await _connection!.addCandidate(c);
      }
      _pendingCandidates.clear();

      // Добавляем локальные треки
      for (final track in _localStream!.getTracks()) {
        await _connection!.addTrack(track, _localStream!);
      }

      // Создаем аnswer
      final answer = await _connection!.createAnswer();
      await _connection!.setLocalDescription(answer);

      await _sendAnswer(answer);

      _connection!.onConnectionState = (state) {
        print('Connection state user2: $state');
      };
      _connection!.onIceConnectionState = (state) {
        print('Ice candidate connection state user2: $state');
      };
      return true;
    } catch (e) {
      print('createAnswer error: $e');
      return false;
    }
  }

  Future<void> _listenIceFromUser1() async {
    _iceSubUser1 = _db
        .collection('rooms')
        .doc('room1')
        .collection('candidates')
        .doc('user1')
        .collection('ice')
        .snapshots()
        .listen((querySnapshot) async {
          for (final change in querySnapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data == null) continue;

              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );

              if (_remoteDescriptionSet) {
                await _connection!.addCandidate(candidate);
              } else {
                _pendingCandidates.add(candidate);
              }
            }
          }
        });
  }

  Future<void> _sendAnswer(RTCSessionDescription answer) async {
    final Map<String, dynamic> dataAnswer = {
      'type': answer.type,
      'sdp': answer.sdp,
    };
    await _db
        .collection('rooms')
        .doc('room1')
        .collection('answer')
        .doc('user2')
        .set(dataAnswer);
  }

  Future<RTCSessionDescription?> _waitForOffer() async {
    final doc = await _db
        .collection('rooms')
        .doc('room1')
        .collection('offer')
        .doc('user1')
        .snapshots()
        .firstWhere((snapshot) => snapshot.exists && snapshot.data() != null);
    final data = doc.data() as Map<String, dynamic>;
    return RTCSessionDescription(data['sdp'], data['type']);
  }

  void _createRendererForTrack(MediaStreamTrack track) {}
}
*/
