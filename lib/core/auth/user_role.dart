enum UserRole {
  admin,
  productor,
  veterinario;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.productor:
        return 'Productor Ganadero';
      case UserRole.veterinario:
        return 'Veterinario';
    }
  }

  /// Valores de la columna `usuario.rol` en Supabase.
  String get storageValue {
    switch (this) {
      case UserRole.admin:
        return 'administrador';
      case UserRole.productor:
        return 'productor_ganadero';
      case UserRole.veterinario:
        return 'veterinario';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'administrador':
      case 'admin':
        return UserRole.admin;
      case 'productor_ganadero':
      case 'productor':
        return UserRole.productor;
      case 'veterinario':
        return UserRole.veterinario;
      default:
        return UserRole.productor;
    }
  }
}
