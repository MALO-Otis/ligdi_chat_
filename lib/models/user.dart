class AppUser {
  final String id;
  final String username;

  AppUser({required this.id, required this.username});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String,
      );
}
