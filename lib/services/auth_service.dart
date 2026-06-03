import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/admin_credentials.dart';
import '../core/auth/app_user.dart';
import '../core/auth/user_role.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _supabase = Supabase.instance.client;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isVeterinario => _currentUser?.role == UserRole.veterinario;
  bool get isProductor => _currentUser?.role == UserRole.productor;

  /// Admin: elimina un usuario tanto de `auth.users` (si está disponible)
  /// como de la tabla `usuario` para que deje de aparecer en la app.
  ///
  /// Nota: si tu proyecto bloquea el método de admin en el cliente,
  /// entonces asegúrate de tener un RPC/endpoint seguro en Supabase.
  Future<String?> deleteUser(AppUser user) async {
    if (!isAdmin) {
      return 'Solo un administrador puede eliminar usuarios.';
    }
    if (user.id.isEmpty) {
      return 'Usuario inválido.';
    }

    // El admin por defecto NO se borra desde la app.
    // (Aunque alguien tenga rol admin en tabla `usuario`, protegemos la cuenta default.)
    if (user.email.trim().toLowerCase() ==
        AdminCredentials.email.trim().toLowerCase()) {
      return 'No puedes eliminar el administrador por defecto.';
    }

    // Protección extra: tampoco permitir eliminar administradores manualmente.
    if (user.role == UserRole.admin) {
      return 'No puedes eliminar el administrador desde la app.';
    }

    final uid = user.id;

    // 1) Eliminar de la tabla usuario (evita que siga apareciendo).
    try {
      await _supabase.from('usuario').delete().eq('id', uid);
    } catch (e) {
      return 'No se pudo borrar de tabla usuario: $e';
    }

    // 2) Eliminar del auth (si el cliente permite la operación).
    try {
      // Esto funciona solo si Supabase permite admin operations desde el cliente.
      await _supabase.auth.admin.deleteUser(uid);
    } catch (e) {
      return 'Se borró tabla usuario, pero falló admin.deleteUser: $e';
    }


    // 3) Si el usuario eliminado era el actual, cerrar sesión.
    if (_currentUser?.id == uid) {
      await logout();
    }

    return null;
  }

  Future<void> init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadCurrentUser(session.user.id);
      if (_currentUser != null) return;
    }

    var error = await login(AdminCredentials.email, AdminCredentials.password);
    if (error == null) return;

    if (_isInvalidCredentials(error)) {
      error = await _bootstrapAdmin();
      if (error == null) {
        await login(AdminCredentials.email, AdminCredentials.password);
      }
    }
  }

  Future<void> _loadCurrentUser(String uid) async {
    try {
      final data = await _supabase
          .from('usuario')
          .select('id, nombre, email, rol')
          .eq('id', uid)
          .single();

      _currentUser = AppUser(
        id: data['id'] as String,
        nombre: data['nombre'] as String,
        email: data['email'] as String,
        password: '',
        role: UserRole.fromString(data['rol'] as String),
      );
    } catch (_) {
      _currentUser = null;
    }
  }

  Future<void> _ensureUserProfile(
    User user, {
    required String nombre,
    required String email,
    required UserRole role,
  }) async {
    try {
      await _supabase.from('usuario').insert({
        'id': user.id,
        'nombre': nombre,
        'email': email,
        'rol': role.storageValue,
      });
    } catch (_) {
      // Ya existe o RLS; se intenta cargar de nuevo.
    }
    await _loadCurrentUser(user.id);
  }

  Future<void> _ensureAdminProfile(User user) async {
    await _ensureUserProfile(
      user,
      nombre: 'Administrador',
      email: AdminCredentials.email,
      role: UserRole.admin,
    );
  }

  Future<String?> _bootstrapAdmin() async {
    try {
      final res = await _supabase.auth.signUp(
        email: AdminCredentials.email,
        password: AdminCredentials.password,
        data: const {'nombre': 'Administrador'},
      );

      final user = res.user;
      if (user == null) {
        return 'No se pudo crear la cuenta de administrador.';
      }

      if (res.session != null) {
        await _ensureAdminProfile(user);
        if (_currentUser != null) return null;
        return _missingProfileMessage(AdminCredentials.email);
      }

      return _emailNotConfirmedMessage(AdminCredentials.email);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        return _emailNotConfirmedMessage(AdminCredentials.email);
      }
      return _mapAuthError(e, email: AdminCredentials.email);
    } catch (_) {
      return 'Error al preparar la cuenta de administrador.';
    }
  }

  Future<String?> register({
    required String nombre,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (nombre.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }
    if (!email.contains('@')) {
      return 'Correo electrónico inválido.';
    }
    if (password.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    try {
      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (res.user == null) return 'No se pudo crear la cuenta.';

      try {
        await _supabase.from('usuario').insert({
          'id': res.user!.id,
          'nombre': nombre.trim(),
          'email': email.trim(),
          'rol': role.storageValue,
        });
      } catch (_) {
        return 'Usuario creado en Auth pero no se pudo guardar en la tabla usuario. Revisa RLS en Supabase.';
      }

      if (res.session == null) {
        return 'Usuario creado. Debes confirmar su correo en Supabase (Users → Confirm user) '
            'o desactivar "Confirm email" en Providers → Email para que pueda entrar.';
      }

      _currentUser = AppUser(
        id: res.user!.id,
        nombre: nombre.trim(),
        email: email.trim(),
        password: '',
        role: role,
      );

      return null;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return 'Este correo ya está registrado.';
      }
      return e.message;
    } catch (_) {
      return 'Error inesperado. Intenta de nuevo.';
    }
  }

  /// Solo administrador: crea usuario sin cerrar su sesión.
  Future<String?> createUser({
    required String nombre,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (!isAdmin) {
      return 'Solo un administrador puede crear usuarios.';
    }
    if (role == UserRole.admin) {
      return 'No puedes crear otro administrador desde la app.';
    }

    final session = _supabase.auth.currentSession;
    final error = await register(
      nombre: nombre,
      email: email,
      password: password,
      role: role,
    );

    if (session != null) {
      await _supabase.auth.setSession(session.refreshToken!);
      await _loadCurrentUser(session.user.id);
    }

    return error;
  }

  Future<List<AppUser>> listUsers() async {
    try {
      final data = await _supabase
          .from('usuario')
          .select('id, nombre, email, rol')
          .order('nombre');

      return (data as List)
          .map(
            (row) => AppUser(
              id: row['id'] as String,
              nombre: row['nombre'] as String,
              email: row['email'] as String,
              password: '',
              role: UserRole.fromString(row['rol'] as String),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Inicia sesión. Devuelve `null` si fue exitoso; si no, el mensaje de error.
  Future<String?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = res.user;
      if (user == null) return 'No se pudo iniciar sesión.';

      await _loadCurrentUser(user.id);

      if (_currentUser == null) {
        final isAdminEmail =
            normalizedEmail == AdminCredentials.email.toLowerCase();
        final defaultName =
            user.userMetadata?['nombre'] as String? ??
            normalizedEmail.split('@').first;

        await _ensureUserProfile(
          user,
          nombre: defaultName,
          email: user.email ?? email.trim(),
          role: isAdminEmail ? UserRole.admin : UserRole.productor,
        );
      }

      if (_currentUser == null) {
        return _missingProfileMessage(email.trim());
      }

      return null;
    } on AuthException catch (e) {
      return _mapAuthError(e, email: email.trim());
    } catch (_) {
      return 'Error de conexión. Revisa tu internet e intenta de nuevo.';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
  }

  static String _emailNotConfirmedMessage(String email) =>
      'El correo $email no está confirmado. En Supabase: Authentication → Users → '
      'menú ⋮ del usuario → Confirm user. O desactiva "Confirm email" en Providers → Email.';

  static String _missingProfileMessage(String email) =>
      'Sesión iniciada, pero falta el perfil de $email en la tabla usuario. '
      'Entra como admin y créalo en Configuración, o ejecuta en SQL Editor:\n'
      "INSERT INTO usuario (id, nombre, email, rol) SELECT id, 'Nombre', '$email', "
      "'productor_ganadero' FROM auth.users WHERE email = '$email';";

  bool _isInvalidCredentials(String message) {
    final lower = message.toLowerCase();
    return lower.contains('incorrect') ||
        (lower.contains('invalid') && lower.contains('credential'));
  }

  String _mapAuthError(AuthException e, {required String email}) {
    final code = e.code?.toLowerCase() ?? '';
    final message = e.message.toLowerCase();

    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return _emailNotConfirmedMessage(email);
    }
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    return e.message;
  }
}
