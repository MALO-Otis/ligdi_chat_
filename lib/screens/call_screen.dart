import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class CallScreen extends StatefulWidget {
  final IO.Socket socket;
  final String conversationId;
  const CallScreen({super.key, required this.socket, required this.conversationId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late WebRTCService _svc;

  @override
  void initState() {
    super.initState();
    _svc = WebRTCService(socket: widget.socket, conversationId: widget.conversationId);
    _start();
  }

  Future<void> _start() async {
    await _svc.initRenderers();
    await _svc.startCall(isCaller: true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appel vidéo')),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_svc.remoteRenderer)),
          SizedBox(height: 160, child: RTCVideoView(_svc.localRenderer, mirror: true)),
        ],
      ),
    );
  }
}
