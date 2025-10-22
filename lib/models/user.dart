class AppUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  AppUser({required this.id, required this.username, this.displayName, this.avatarUrl});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
