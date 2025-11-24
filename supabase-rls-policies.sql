-- =====================================================
-- Políticas RLS para Lukaya Griffe
-- =====================================================
-- Este script configura as políticas de Row Level Security
-- para permitir acesso público de leitura e acesso
-- autenticado/admin para escrita
-- =====================================================

-- ====================================================
-- PRODUCTS (Produtos)
-- ====================================================

-- Habilitar RLS na tabela products (caso não esteja habilitado)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Permitir leitura pública de produtos" ON products;
DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON products;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON products;
DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON products;

-- Criar novas políticas

-- Leitura pública (qualquer pessoa pode ver produtos)
CREATE POLICY "Permitir leitura pública de produtos"
ON products FOR SELECT
USING (true);

-- Inserção apenas para usuários autenticados
CREATE POLICY "Permitir inserção para usuários autenticados"
ON products FOR INSERT
TO authenticated
WITH CHECK (true);

-- Atualização apenas para usuários autenticados
CREATE POLICY "Permitir atualização para usuários autenticados"
ON products FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Exclusão apenas para usuários autenticados
CREATE POLICY "Permitir exclusão para usuários autenticados"
ON products FOR DELETE
TO authenticated
USING (true);

-- ====================================================
-- CATEGORIES (Categorias)
-- ====================================================

-- Habilitar RLS na tabela categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Permitir leitura pública de categorias" ON categories;
DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON categories;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON categories;
DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON categories;

-- Criar novas políticas

-- Leitura pública
CREATE POLICY "Permitir leitura pública de categorias"
ON categories FOR SELECT
USING (true);

-- Inserção apenas para usuários autenticados
CREATE POLICY "Permitir inserção para usuários autenticados"
ON categories FOR INSERT
TO authenticated
WITH CHECK (true);

-- Atualização apenas para usuários autenticados
CREATE POLICY "Permitir atualização para usuários autenticados"
ON categories FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Exclusão apenas para usuários autenticados
CREATE POLICY "Permitir exclusão para usuários autenticados"
ON categories FOR DELETE
TO authenticated
USING (true);

-- ====================================================
-- BANNERS
-- ====================================================

-- Habilitar RLS na tabela banners
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Permitir leitura pública de banners" ON banners;
DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON banners;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON banners;
DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON banners;

-- Criar novas políticas

-- Leitura pública
CREATE POLICY "Permitir leitura pública de banners"
ON banners FOR SELECT
USING (true);

-- Inserção apenas para usuários autenticados
CREATE POLICY "Permitir inserção para usuários autenticados"
ON banners FOR INSERT
TO authenticated
WITH CHECK (true);

-- Atualização apenas para usuários autenticados
CREATE POLICY "Permitir atualização para usuários autenticados"
ON banners FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Exclusão apenas para usuários autenticados
CREATE POLICY "Permitir exclusão para usuários autenticados"
ON banners FOR DELETE
TO authenticated
USING (true);

-- ====================================================
-- PRODUCT_VIEWS (Visualizações de produtos)
-- ====================================================

-- Habilitar RLS na tabela product_views (se existir)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'product_views') THEN
    ALTER TABLE product_views ENABLE ROW LEVEL SECURITY;

    -- Remover políticas antigas
    DROP POLICY IF EXISTS "Permitir leitura pública de visualizações" ON product_views;
    DROP POLICY IF EXISTS "Permitir inserção pública de visualizações" ON product_views;

    -- Leitura pública
    CREATE POLICY "Permitir leitura pública de visualizações"
    ON product_views FOR SELECT
    USING (true);

    -- Inserção pública (para rastrear visualizações)
    CREATE POLICY "Permitir inserção pública de visualizações"
    ON product_views FOR INSERT
    WITH CHECK (true);
  END IF;
END $$;

-- ====================================================
-- SETTINGS (Configurações)
-- ====================================================

-- Habilitar RLS na tabela settings (se existir)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'settings') THEN
    ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

    -- Remover políticas antigas
    DROP POLICY IF EXISTS "Permitir leitura pública de configurações" ON settings;
    DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON settings;

    -- Leitura pública
    CREATE POLICY "Permitir leitura pública de configurações"
    ON settings FOR SELECT
    USING (true);

    -- Atualização apenas para usuários autenticados
    CREATE POLICY "Permitir atualização para usuários autenticados"
    ON settings FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ====================================================
-- MARKETPLACE_SETTINGS (Configurações de marketplaces)
-- ====================================================

-- Habilitar RLS (se a tabela existir)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'marketplace_settings') THEN
    ALTER TABLE marketplace_settings ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Permitir leitura para usuários autenticados" ON marketplace_settings;
    DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON marketplace_settings;
    DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON marketplace_settings;
    DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON marketplace_settings;

    -- Apenas usuários autenticados podem acessar configurações de marketplace
    CREATE POLICY "Permitir leitura para usuários autenticados"
    ON marketplace_settings FOR SELECT
    TO authenticated
    USING (true);

    CREATE POLICY "Permitir inserção para usuários autenticados"
    ON marketplace_settings FOR INSERT
    TO authenticated
    WITH CHECK (true);

    CREATE POLICY "Permitir atualização para usuários autenticados"
    ON marketplace_settings FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

    CREATE POLICY "Permitir exclusão para usuários autenticados"
    ON marketplace_settings FOR DELETE
    TO authenticated
    USING (true);
  END IF;
END $$;

-- ====================================================
-- FIM DAS POLÍTICAS
-- ====================================================

-- Verificar políticas criadas
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
