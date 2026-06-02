import 'user_role.dart';

class AppUser {
  final String username;
  final String password;
  final UserRole role;

  const AppUser({
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'role': role.storageValue,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      role: UserRole.fromString((json['role'] ?? '').toString()),
    );
  }
}
