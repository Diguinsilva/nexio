-- ================================================
-- VERIFICAR SE AS COLUNAS DE DARK MODE EXISTEM
-- ================================================
-- Execute este SQL no Supabase para verificar
-- ================================================

-- 1. Verificar se as colunas existem
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'settings'
  AND column_name IN ('dark_mode_admin', 'dark_mode_catalog')
ORDER BY column_name;

-- ================================================
-- RESULTADO ESPERADO:
-- Se as colunas existirem, você verá 2 linhas:
--   column_name       | data_type | is_nullable | column_default
--   dark_mode_admin   | boolean   | YES         | false
--   dark_mode_catalog | boolean   | YES         | false
--
-- Se não mostrar nada, as colunas NÃO existem
-- ================================================

-- 2. Ver os valores atuais (se existirem)
SELECT
  id,
  store_name,
  dark_mode_admin,
  dark_mode_catalog,
  updated_at
FROM settings
WHERE id = 1;

-- ================================================
-- CASO AS COLUNAS NÃO EXISTAM, EXECUTE:
-- ================================================
/*
ALTER TABLE settings
  ADD COLUMN dark_mode_admin BOOLEAN DEFAULT false,
  ADD COLUMN dark_mode_catalog BOOLEAN DEFAULT false;

UPDATE settings SET
  dark_mode_admin = false,
  dark_mode_catalog = false
WHERE id = 1;
*/
