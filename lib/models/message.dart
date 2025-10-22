enum MessageType { text, audio, video, file }

MessageType parseMessageType(String s) {
  switch (s.toUpperCase()) {
    case 'AUDIO':
      return MessageType.audio;
    case 'VIDEO':
      return MessageType.video;
    case 'FILE':
      return MessageType.file;
    default:
      return MessageType.text;
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final int? durationMs;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.durationMs,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        type: parseMessageType((json['type'] as String?) ?? 'TEXT'),
        text: json['text'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        durationMs: json['durationMs'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
