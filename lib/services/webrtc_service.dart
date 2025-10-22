import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCService {
  final IO.Socket socket;
  final String conversationId;
  RTCPeerConnection? _pc;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  WebRTCService({required this.socket, required this.conversationId});

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> startCall({bool isCaller = true}) async {
    // Allow injecting TURN servers at build time via --dart-define
    const turnUrlsRaw = String.fromEnvironment('TURN_URLS', defaultValue: ''); // comma-separated, e.g. turn:host:3478,turns:host:5349
    const turnUser = String.fromEnvironment('TURN_USERNAME', defaultValue: '');
    const turnCred = String.fromEnvironment('TURN_CREDENTIAL', defaultValue: '');

    final List<Map<String, dynamic>> iceServers = [
      {'urls': 'stun:stun.l.google.com:19302'},
    ];
    if (turnUrlsRaw.isNotEmpty) {
      final urls = turnUrlsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (urls.isNotEmpty) {
        final m = <String, dynamic>{'urls': urls};
        if (turnUser.isNotEmpty) m['username'] = turnUser;
        if (turnCred.isNotEmpty) m['credential'] = turnCred;
        iceServers.add(m);
      }
    }

    final config = {
      'iceServers': iceServers,
    };
    _pc = await createPeerConnection(config);

    // Local media
    final stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    _localRenderer.srcObject = stream;
    for (final track in stream.getTracks()) {
      await _pc!.addTrack(track, stream);
    }

    _pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        socket.emit('webrtc:ice', {
          'conversationId': conversationId,
          'candidate': c.toMap(),
        });
      }
    };
    _pc!.onTrack = (ev) {
      if (ev.streams.isNotEmpty) {
        _remoteRenderer.srcObject = ev.streams.first;
      }
    };

    socket.on('webrtc:offer', (data) async {
      final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
      await _pc!.setRemoteDescription(sdp);
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      socket.emit('webrtc:answer', {
        'conversationId': conversationId,
        'sdp': answer.toMap(),
      });
    });

    socket.on('webrtc:answer', (data) async {
      final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
      await _pc!.setRemoteDescription(sdp);
    });

    socket.on('webrtc:ice', (data) async {
      final cand = RTCIceCandidate(data['candidate']['candidate'], data['candidate']['sdpMid'], data['candidate']['sdpMLineIndex']);
      await _pc!.addCandidate(cand);
    });

    if (isCaller) {
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      socket.emit('webrtc:offer', {
        'conversationId': conversationId,
        'sdp': offer.toMap(),
      });
    }
  }

  Future<void> dispose() async {
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    await _pc?.close();
    _pc = null;
  }
}
