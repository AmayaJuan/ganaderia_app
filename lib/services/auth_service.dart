import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/app_user.dart';
import '../core/auth/user_role.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _usersKey = 'app_users_v1';
  static const _sessionKey = 'app_session_user';

  AppUser? _currentUser;
  List<AppUser> _users = [];

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> init() async {
    await _loadUsers();
    await _restoreSession();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);

    if (raw == null || raw.isEmpty) {
      _users = _defaultUsers();
      await _saveUsers();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _users = decoded
            .whereType<Map>()
            .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      _users = _defaultUsers();
      await _saveUsers();
    }

    if (_users.isEmpty) {
      _users = _defaultUsers();
      await _saveUsers();
    }
  }

  List<AppUser> _defaultUsers() => const [
        AppUser(
          username: 'admin',
          password: 'admin123',
          role: UserRole.admin,
        ),
        AppUser(
          username: 'productor',
          password: 'productor123',
          role: UserRole.productor,
        ),
      ];

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, raw);
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_sessionKey);
    if (username == null) return;

    try {
      _currentUser = _users.firstWhere((u) => u.username == username);
    } catch (_) {
      _currentUser = null;
    }
  }

  Future<bool> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final normalized = username.trim().toLowerCase();

    AppUser? user;
    try {
      user = _users.firstWhere(
        (u) =>
            u.username.toLowerCase() == normalized &&
            u.password == password.trim(),
      );
    } catch (_) {
      return false;
    }

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, user.username);
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  List<AppUser> listUsers() => List.unmodifiable(_users);

  Future<String?> createUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    if (!isAdmin) {
      return 'Solo un administrador puede crear usuarios.';
    }

    final normalized = username.trim().toLowerCase();
    if (normalized.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres.';
    }
    if (password.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (_users.any((u) => u.username.toLowerCase() == normalized)) {
      return 'Ese nombre de usuario ya existe.';
    }

    _users.add(
      AppUser(
        username: normalized,
        password: password.trim(),
        role: role,
      ),
    );
    await _saveUsers();
    return null;
  }
}
