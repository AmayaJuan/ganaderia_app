import 'user_role.dart';

class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String password;
  final UserRole role;

  const AppUser({
    this.id = '',
    required this.nombre,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id':       id,
    'nombre':   nombre,
    'email':    email,
    'password': password,
    'role': role.storageValue,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:       (json['id']            ?? '').toString(),
      nombre:   (json['nombre']        ?? json['username'] ?? '').toString(),
      email:    (json['email']         ?? '').toString(),
      password: (json['password']      ?? '').toString(),
      role: UserRole.fromString((json['role'] ?? '').toString()),
    );
  }
}
