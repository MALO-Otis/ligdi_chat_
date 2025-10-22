import 'dart:io';
import 'call_screen.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../models/conversation.dart';
import '../services/api_client.dart';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/socket_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// ignore_for_file: unused_import



class ChatScreen extends StatefulWidget {
  final String apiBase; // e.g. http://localhost:4000
  const ChatScreen({super.key, required this.apiBase});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _apiPicker = TextEditingController();
  final _meCtrl = TextEditingController();
  final _peerCtrl = TextEditingController();
  final _textCtrl = TextEditingController();

  final _audio = AudioService();
  final _player = AudioPlayer();
  final _picker = ImagePicker();

  late ApiClient api;
  SocketService? socket;

  AppUser? me;
  AppUser? peer;
  Conversation? conv;
  final List<ChatMessage> messages = [];

  bool _recording = false;

  @override
  void initState() {
    super.initState();
    api = ApiClient(baseUrl: widget.apiBase);
    _apiPicker.text = widget.apiBase;
  }

  @override
  void dispose() {
    socket?.dispose();
    _player.dispose();
    _apiPicker.dispose();
    _meCtrl.dispose();
    _peerCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    try {
      final meName = _meCtrl.text.trim();
      final peerName = _peerCtrl.text.trim();
      if (meName.isEmpty || peerName.isEmpty) return;
      // Create users
      final meJson = await api.createUser(meName);
      final peerJson = await api.createUser(peerName);
      me = AppUser.fromJson(meJson);
      peer = AppUser.fromJson(peerJson);
  // Find or create conversation 1:1
  final convJson = await api.findOrCreateConversation([me!.id, peer!.id]);
      conv = Conversation.fromJson(convJson);
      // Load messages
      final list = await api.getMessages(conv!.id);
      messages
        ..clear()
        ..addAll(list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList());
      // Socket
      socket?.dispose();
      socket = SocketService(baseUrl: _apiPicker.text.trim());
      socket!.connect(conversationId: conv!.id, onNewMessage: (msg) {
        setState(() => messages.add(msg));
      });
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _sendText() async {
    if (me == null || conv == null) return;
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;
    _textCtrl.clear();
    // Send via REST for persistence + via socket for realtime
    await api.sendTextMessage(conversationId: conv!.id, senderId: me!.id, text: txt);
  }

  // Toggle record kept for reference (not used since we use long-press)
  // Removed: long-press mic is used instead of toggle

  Future<void> _pickVideo() async {
    if (me == null || conv == null) return;
    final cam = await Permission.camera.request();
    final storage = await Permission.photos.request();
    if (!cam.isGranted || !storage.isGranted) return;
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x != null) {
      await api.uploadMedia(
        endpoint: '/upload/video',
        conversationId: conv!.id,
        senderId: me!.id,
        filePath: x.path,
      );
    }
  }

  void _openCall() {
    if (socket == null || conv == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CallScreen(socket: socket!.socket, conversationId: conv!.id),
    ));
  }

  Widget _bubble(ChatMessage m) {
    final isMe = m.senderId == me?.id;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? context.bubbleMe : context.bubbleOther;
    Widget child;
    switch (m.type) {
      case MessageType.text:
  child = Text(m.text ?? '', style: const TextStyle(fontSize: 16, color: Colors.white));
        break;
      case MessageType.audio:
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, color: AppTheme.brandYellow),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                final url = '${widget.apiBase}${m.mediaUrl}';
                _player.play(UrlSource(url));
              },
              child: const Text('Lire', style: TextStyle(color: AppTheme.brandYellow)),
            ),
          ],
        );
        break;
      case MessageType.video:
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, color: AppTheme.brandYellow),
            const SizedBox(width: 8),
            Text('Vidéo', style: const TextStyle(color: Colors.white70)),
          ],
        );
        break;
    }
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.bolt, color: AppTheme.brandYellow),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Ligdi Chat'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _apiPicker,
                        decoration: const InputDecoration(labelText: 'API Base (ex: http://10.0.2.2:4000)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        api = ApiClient(baseUrl: _apiPicker.text.trim());
                        setState(() {});
                      },
                      child: const Text('Set API'),
                    )
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _meCtrl, decoration: const InputDecoration(labelText: 'Mon pseudo'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _peerCtrl, decoration: const InputDecoration(labelText: 'Contact pseudo'))),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _startChat, child: const Text('Démarrer')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            if (conv != null)
              _inputBar(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (_, i) => _bubble(messages[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
    child: Row(children: [
      IconButton(onPressed: _openCall, icon: const Icon(Icons.video_call)),
      IconButton(onPressed: _pickVideo, icon: const Icon(Icons.attach_file)),
      Expanded(
        child: TextField(
          controller: _textCtrl,
          decoration: const InputDecoration(hintText: 'Message...'),
          onSubmitted: (_) => _sendText(),
        ),
      ),
      GestureDetector(
        onLongPress: () async {
          if (me == null || conv == null) return;
          final mic = await Permission.microphone.request();
          if (!mic.isGranted) return;
          await _audio.start();
          setState(() => _recording = true);
        },
        onLongPressUp: () async {
          if (!_recording) return;
          final path = await _audio.stop();
          setState(() => _recording = false);
          if (path != null && me != null && conv != null) {
            await api.uploadMedia(
              endpoint: '/upload/audio',
              conversationId: conv!.id,
              senderId: me!.id,
              filePath: path,
            );
          }
        },
        child: Icon(_recording ? Icons.stop_circle : Icons.mic, color: _recording ? Colors.redAccent : AppTheme.brandYellow),
      ),
      const SizedBox(width: 8),
      IconButton(onPressed: _sendText, icon: const Icon(Icons.send)),
    ]));
  }
}
