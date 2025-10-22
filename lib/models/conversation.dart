class Conversation {
  final String id;
  final bool isGroup;

  Conversation({required this.id, required this.isGroup});

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        isGroup: (json['isGroup'] as bool?) ?? false,
      );
}
