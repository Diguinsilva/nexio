-- =====================================================
-- MIGRAÇÃO: DARK MODE INDEPENDENTE PARA ADMIN E CATÁLOGO
-- =====================================================
-- Descrição: Adiciona colunas para controlar dark mode
--            do painel admin e do catálogo separadamente
-- Data: 2025-11-23
-- =====================================================

-- 1. Adicionar colunas para controle de dark mode
ALTER TABLE settings
  ADD COLUMN IF NOT EXISTS dark_mode_admin BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS dark_mode_catalog BOOLEAN DEFAULT false;

-- 2. Comentários nas colunas
COMMENT ON COLUMN settings.dark_mode_admin IS 'Ativa dark mode no painel administrativo';
COMMENT ON COLUMN settings.dark_mode_catalog IS 'Ativa dark mode no catálogo para visitantes';

-- 3. Atualizar registro existente (se houver)
UPDATE settings
SET
  dark_mode_admin = COALESCE(dark_mode, false),
  dark_mode_catalog = COALESCE(dark_mode, false)
WHERE id = 1;

-- =====================================================
-- VERIFICAÇÃO
-- =====================================================
SELECT
  id,
  store_name,
  dark_mode,
  dark_mode_admin,
  dark_mode_catalog,
  updated_at
FROM settings
WHERE id = 1;

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================
-- 1. A coluna 'dark_mode' antiga pode ser mantida para compatibilidade
-- 2. O sistema usa 'dark_mode_admin' para o painel admin
-- 3. O sistema usa 'dark_mode_catalog' para o catálogo público
-- 4. O usuário final NÃO pode mais alternar o dark mode - apenas admin
-- 5. Execute esta migração via Supabase SQL Editor
-- =====================================================
