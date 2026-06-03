-- Perfil para un usuario creado solo en Authentication (Auth)
-- Cambia el correo, nombre y rol según necesites:
--   administrador | productor_ganadero | veterinario

INSERT INTO usuario (id, nombre, email, rol)
SELECT id, 'Juan Pérez', 'juan@ganaderia.com', 'productor_ganadero'
FROM auth.users
WHERE email = 'juan@ganaderia.com'
ON CONFLICT (id) DO UPDATE
  SET nombre = EXCLUDED.nombre,
      email = EXCLUDED.email,
      rol = EXCLUDED.rol;
