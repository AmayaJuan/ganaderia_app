-- EJECUTA TODO ESTO en Supabase → SQL Editor (Run)
-- Arregla el login: permisos + lectura del perfil

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.usuario TO authenticated;

-- Opción A (rápida): desactiva RLS en usuario para que entre ya
ALTER TABLE public.usuario DISABLE ROW LEVEL SECURITY;
