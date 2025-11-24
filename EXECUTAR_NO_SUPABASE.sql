-- ================================================
-- EXECUTE ESTE SQL NO SUPABASE AGORA!
-- ================================================
-- Acesse: Supabase Dashboard > SQL Editor
-- Cole este código e clique em RUN
-- ================================================

-- 1. Adicionar colunas de dark mode
ALTER TABLE settings
  ADD COLUMN IF NOT EXISTS dark_mode_admin BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS dark_mode_catalog BOOLEAN DEFAULT false;

-- 2. Atualizar registro existente
UPDATE settings
SET
  dark_mode_admin = false,
  dark_mode_catalog = false
WHERE id = 1;

-- 3. Verificar se funcionou
SELECT
  id,
  store_name,
  dark_mode_admin,
  dark_mode_catalog,
  updated_at
FROM settings
WHERE id = 1;

-- ================================================
-- RESULTADO ESPERADO:
-- Deve mostrar as colunas dark_mode_admin e dark_mode_catalog
-- ambas com valor 'false'
-- ================================================
