class UserModel {
  final String username;
  final String password;
  final String email;
  final DateTime createdAt;
  final String role; // Tambahkan role

  UserModel({
    required this.username,
    required this.password,
    required this.email,
    required this.createdAt,
    this.role = 'user', // Default role adalah user
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'],
      password: map['password'],
      email: map['email'],
      createdAt: DateTime.parse(map['createdAt']),
      role: map['role'] ?? 'user',
    );
  }
}