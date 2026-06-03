-- RLS segura (ejecutar DESPUÉS de que el login ya funcione)
-- Requiere la función is_administrador() para evitar bloqueos

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.usuario TO authenticated;

CREATE OR REPLACE FUNCTION public.is_administrador()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuario
    WHERE id = auth.uid() AND rol = 'administrador'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_administrador() TO authenticated;

ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuario_select_own" ON public.usuario;
DROP POLICY IF EXISTS "usuario_select_admin" ON public.usuario;
DROP POLICY IF EXISTS "usuario_insert_own" ON public.usuario;
DROP POLICY IF EXISTS "usuario_insert_admin" ON public.usuario;
DROP POLICY IF EXISTS "usuario_update_own" ON public.usuario;
DROP POLICY IF EXISTS "usuario_select" ON public.usuario;
DROP POLICY IF EXISTS "usuario_insert" ON public.usuario;
DROP POLICY IF EXISTS "usuario_update" ON public.usuario;

CREATE POLICY "usuario_select" ON public.usuario
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_administrador());

CREATE POLICY "usuario_insert" ON public.usuario
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR public.is_administrador());

CREATE POLICY "usuario_update" ON public.usuario
  FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.is_administrador())
  WITH CHECK (id = auth.uid() OR public.is_administrador());
