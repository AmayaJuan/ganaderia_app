import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/ganaderia_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> onLogin() async {
    if (isLoading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage('Completa usuario y contraseña');
      return;
    }

    setState(() => isLoading = true);
    try {
      final success = await authService.login(username, password);
      if (!mounted) return;
      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        showMessage('Usuario o contraseña incorrectos');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFA32D2D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GanaderiaLogo(size: 90),
                    const SizedBox(height: 20),
                    const Text('GanaderiaApp',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF20A67A),
                        )),
                    const SizedBox(height: 6),
                    const Text('Sistema de Gestión Ganadera',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const Text('Urabá Antioqueño, Colombia',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 32),

                    // Usuario
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'Ingresa tu usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onLogin(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Ingresa tu contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() =>
                            obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón
                    ElevatedButton(
                      onPressed: isLoading ? null : onLogin,
                      child: isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : const Text('Iniciar Sesión',
                              style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 20),                   
                      
                      // Usuarios de prueba
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Usuarios de prueba:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 12)),
                            SizedBox(height: 6),
                            Text('productor / productor123',
                                style: TextStyle(fontSize: 11)),
                            Text('admin / admin123',
                                style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                  ]
                )
              )
          )
        )
      ),
     ),
    );
  }
}
