-- Perfil del administrador (rol según tu CHECK: administrador, no admin)
INSERT INTO usuario (id, nombre, email, rol)
SELECT id, 'Admin Sistema', 'admin@ganaderia.com', 'administrador'
FROM auth.users
WHERE email = 'admin@ganaderia.com'
ON CONFLICT (id) DO UPDATE
  SET nombre = EXCLUDED.nombre,
      email = EXCLUDED.email,
      rol = EXCLUDED.rol;
