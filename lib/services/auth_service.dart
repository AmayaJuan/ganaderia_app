class AuthService {
  static const users = <String, String>{
    'productor': 'productor123',
    'admin': 'admin123',
  };

  Future<bool> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500)); 
    final expected = users[username.trim().toLowerCase()];// Simula un retraso de red
    return expected != null && expected == password.trim();
  }
}