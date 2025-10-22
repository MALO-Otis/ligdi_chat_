import '../models/message.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  final String baseUrl; // e.g., http://localhost:4000
  late IO.Socket socket;
  final String? token;

  SocketService({required this.baseUrl, this.token});

  void connect({required String conversationId, required void Function(ChatMessage msg) onNewMessage}) {
    final builder = IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect();
    if (token != null && token!.isNotEmpty) {
      builder.setQuery({'token': token});
    }
    socket = IO.io(baseUrl, builder.build());
    socket.connect();
    socket.onConnect((_) {
      socket.emit('join', conversationId);
    });
    socket.on('message:new', (data) {
      try {
        final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
        onNewMessage(msg);
      } catch (_) {}
    });
  }

  void sendText({required String conversationId, required String senderId, required String text}) {
    socket.emit('message:send', {
      'conversationId': conversationId,
      'senderId': senderId,
      'type': 'TEXT',
      'text': text,
    });
  }

  void dispose() {
    socket.dispose();
  }
}
