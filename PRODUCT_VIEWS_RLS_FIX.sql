-- =====================================================
-- FIX: Configurar RLS e permissões para product_views
-- Execute no SQL Editor do Supabase Dashboard
-- =====================================================

-- Habilitar RLS na tabela product_views
ALTER TABLE product_views ENABLE ROW LEVEL SECURITY;

-- Criar política para permitir INSERT público (necessário para rastrear views de visitantes)
CREATE POLICY "Permitir INSERT público em product_views"
ON product_views
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Criar política para permitir SELECT público (necessário para exibir contagem de views)
CREATE POLICY "Permitir SELECT público em product_views"
ON product_views
FOR SELECT
TO anon, authenticated
USING (true);

-- Garantir que a função increment_product_view tenha permissões corretas
-- A função já existe, mas vamos recriar para garantir as permissões
CREATE OR REPLACE FUNCTION increment_product_view(
  p_product_id BIGINT,
  p_session_id TEXT,
  p_user_agent TEXT DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL
)
RETURNS VOID
SECURITY DEFINER  -- Importante: executa com permissões do dono da função
SET search_path = public
AS $$
BEGIN
  INSERT INTO product_views (product_id, session_id, viewed_date, user_agent, ip_address)
  VALUES (p_product_id, p_session_id, CURRENT_DATE, p_user_agent, p_ip_address)
  ON CONFLICT (product_id, session_id, viewed_date) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Garantir que a view product_view_counts está acessível
GRANT SELECT ON product_view_counts TO anon, authenticated;

-- Verificar se tudo está funcionando
SELECT
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'product_views';

-- Testar inserção
SELECT increment_product_view(
  p_product_id := 1,
  p_session_id := 'test_session',
  p_user_agent := 'test_agent'
);

SELECT COUNT(*) as total_views FROM product_views;
