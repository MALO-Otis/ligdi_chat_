import 'call_screen.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../models/conversation.dart';
import '../services/api_client.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';
import '../services/socket_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatPage extends StatefulWidget {
  final ApiClient api;
  final AuthService auth;
  final Conversation conversation;
  final AppUser peer;
  const ChatPage({super.key, required this.api, required this.auth, required this.conversation, required this.peer});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textCtrl = TextEditingController();
  final _player = AudioPlayer();
  final _picker = ImagePicker();
  final _audio = AudioService();

  late SocketService socket;
  final List<ChatMessage> messages = [];
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    // Ensure API has token
    widget.api.setAuthToken(widget.auth.token);
    // Load initial messages
    _load();
    // Connect socket
    socket = SocketService(baseUrl: widget.api.baseUrl, token: widget.auth.token);
    socket.connect(conversationId: widget.conversation.id, onNewMessage: (m) {
      setState(() => messages.add(m));
    });
    // Incoming call: auto-open as callee
    socket.socket.on('webrtc:offer', (data) {
      if (!mounted) return;
      final cid = (data is Map && data['conversationId'] is String) ? data['conversationId'] as String : widget.conversation.id;
      if (cid != widget.conversation.id) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CallScreen(socket: socket.socket, conversationId: widget.conversation.id, isCaller: false),
      ));
    });
  }

  Future<void> _load() async {
    final list = await widget.api.getMessages(widget.conversation.id);
    setState(() {
      messages
        ..clear()
        ..addAll(list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList());
    });
  }

  @override
  void dispose() {
    socket.dispose();
    _player.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final me = widget.auth.currentUser;
    if (me == null) return;
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;
    _textCtrl.clear();
    await widget.api.sendTextMessage(conversationId: widget.conversation.id, senderId: me.id, text: txt);
  }

  Future<void> _pickVideo() async {
    final me = widget.auth.currentUser;
    if (me == null) return;
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x != null) {
      await widget.api.uploadMedia(
        endpoint: '/upload/video',
        conversationId: widget.conversation.id,
        senderId: me.id,
        filePath: x.path,
      );
    }
  }

  Future<void> _pickFile() async {
    final me = widget.auth.currentUser;
    if (me == null) return;
    final res = await FilePicker.platform.pickFiles(withReadStream: false);
    if (res != null && res.files.isNotEmpty && res.files.single.path != null) {
      await widget.api.uploadMedia(
        endpoint: '/upload/file',
        conversationId: widget.conversation.id,
        senderId: me.id,
        filePath: res.files.single.path!,
      );
    }
  }

  Widget _bubble(ChatMessage m) {
    final me = widget.auth.currentUser;
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
                final url = '${widget.api.baseUrl}${m.mediaUrl}';
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
            TextButton(
              onPressed: () async {
                final url = Uri.parse('${widget.api.baseUrl}${m.mediaUrl}');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: const Text('Ouvrir', style: TextStyle(color: AppTheme.brandYellow)),
            ),
          ],
        );
        break;
      case MessageType.file:
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: AppTheme.brandYellow),
            const SizedBox(width: 8),
            Flexible(
              child: Text(m.text ?? 'Fichier', style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final url = Uri.parse('${widget.api.baseUrl}${m.mediaUrl}');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: const Text('Ouvrir', style: TextStyle(color: AppTheme.brandYellow)),
            ),
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
    final me = widget.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person, size: 18)),
            const SizedBox(width: 8),
            Text(widget.peer.displayName ?? widget.peer.username),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CallScreen(socket: socket.socket, conversationId: widget.conversation.id),
              ));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _inputBar(me),
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

  Widget _inputBar(AppUser? me) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
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
            if (me == null) return;
            final mic = await Permission.microphone.request();
            if (!mic.isGranted) return;
            await _audio.start();
            setState(() => _recording = true);
          },
          onLongPressUp: () async {
            if (!_recording || me == null) return;
            final path = await _audio.stop();
            setState(() => _recording = false);
            if (path != null) {
              await widget.api.uploadMedia(
                endpoint: '/upload/audio',
                conversationId: widget.conversation.id,
                senderId: me.id,
                filePath: path,
              );
            }
          },
          child: Icon(_recording ? Icons.stop_circle : Icons.mic, color: _recording ? Colors.redAccent : AppTheme.brandYellow),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: _pickFile, icon: const Icon(Icons.attach_file)),
        IconButton(onPressed: _sendText, icon: const Icon(Icons.send)),
      ]),
    );
  }
}
