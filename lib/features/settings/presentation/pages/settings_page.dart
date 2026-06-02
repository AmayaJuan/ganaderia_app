import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = AuthService.instance;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    final error = await _auth.createUser(
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
      role: UserRole.productor,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.red),
      );
      return;
    }

    _usernameCtrl.clear();
    _passwordCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario creado correctamente'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    final isAdmin = _auth.isAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajustes de tu cuenta y del sistema',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuenta activa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.greenLight,
                    child: Icon(Icons.person, color: AppColors.green),
                  ),
                  title: Text(user.username),
                  subtitle: Text(isAdmin ? user.role.label : 'Sesión activa'),
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greenLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: AppColors.green),
                      SizedBox(width: 8),
                      Text(
                        'Administración de usuarios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Solo visible para administradores',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo usuario',
                      hintText: 'Ej: juan_perez',
                      prefixIcon: Icon(Icons.person_add_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Mínimo 6 caracteres',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: UserRole.productor,
                    decoration: const InputDecoration(
                      labelText: 'Rol del usuario',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.productor,
                        child: Text('Productor'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createUser,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear usuario'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Usuarios registrados',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ..._auth.listUsers().map(
                        (u) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            u.role == UserRole.admin
                                ? Icons.shield
                                : Icons.agriculture,
                            color: AppColors.green,
                          ),
                          title: Text(u.username),
                          subtitle: Text(u.role.label),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
