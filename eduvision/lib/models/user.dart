class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? username;
  final String? role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.username,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      username: json['username'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'username': username,
      'role': role,
    };
  }
}
