import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:permission_handler/permission_handler.dart';


class CallScreen extends StatefulWidget {
  final IO.Socket socket;
  final String conversationId;
  final bool isCaller;
  const CallScreen({super.key, required this.socket, required this.conversationId, this.isCaller = true});

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
    // Request runtime permissions before starting media
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions caméra/micro refusées')));
        Navigator.of(context).maybePop();
      }
      return;
    }

    await _svc.initRenderers();
    await _svc.startCall(isCaller: widget.isCaller);
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
