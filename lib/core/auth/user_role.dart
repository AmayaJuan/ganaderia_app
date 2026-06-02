enum UserRole {
  admin,
  productor;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.productor:
        return 'Productor';
    }
  }

  String get storageValue => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.productor,
    );
  }
}
