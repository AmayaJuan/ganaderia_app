import 'package:flutter/material.dart';

import '../../../../core/auth/app_user.dart';
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
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _newUserRole = UserRole.productor;
  List<AppUser> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!_auth.isAdmin) {
      setState(() => _loadingUsers = false);
      return;
    }
    final users = await _auth.listUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loadingUsers = false;
    });
  }

  Future<void> _createUser() async {
    final error = await _auth.createUser(
      nombre: _nombreCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      role: _newUserRole,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.red),
      );
      return;
    }

    _nombreCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    await _loadUsers();
    if (!mounted) return;
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
                  title: Text(user.nombre),
                  subtitle: Text('${user.email} · ${user.role.label}'),
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
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Juan Pérez',
                      prefixIcon: Icon(Icons.person_add_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'usuario@correo.com',
                      prefixIcon: Icon(Icons.email_outlined),
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
                    initialValue: _newUserRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol del usuario',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.productor,
                        child: Text('Productor'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.veterinario,
                        child: Text('Veterinario'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _newUserRole = v);
                    },
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
                  if (_loadingUsers)
                    const Center(child: CircularProgressIndicator())
                  else if (_users.isEmpty)
                    const Text(
                      'No hay usuarios en la base de datos.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    ..._users.map(
                      (u) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          u.role == UserRole.admin
                              ? Icons.shield
                              : u.role == UserRole.veterinario
                              ? Icons.medical_services
                              : Icons.agriculture,
                          color: AppColors.green,
                        ),
                        title: Text(u.nombre),
                        subtitle: Text('${u.email} · ${u.role.label}'),
                        trailing: IconButton(
                          tooltip: 'Eliminar usuario',
                          icon: const Icon(Icons.delete, color: AppColors.red),
                          onPressed: () async {
                            if (u.role == UserRole.admin) return;

                            // ignore: use_build_context_synchronously
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text('Eliminar usuario'),
                                  content: Text(
                                    '¿Seguro que deseas eliminar a ${u.nombre}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(color: AppColors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            // Evita el warning: ya no usaremos `context` después de este await
                            // (toda notificación usa `messenger`).
                            if (!mounted) return;

                            if (ok != true) return;

                            final messenger = ScaffoldMessenger.of(context);

                            final err = await _auth.deleteUser(u);
                            if (!mounted) return;
                            if (messenger.mounted != true) return;

                            if (err != null) {
                              // `messenger` captura contexto antes del await, así evitamos usar context en el gap.
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: AppColors.red,
                                ),
                              );
                              return;
                            }

                            await _loadUsers();
                            if (!mounted) return;

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Usuario eliminado correctamente',
                                ),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          },
                        ),
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
