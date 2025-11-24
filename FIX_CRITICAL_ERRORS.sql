-- ========================================
-- FIX CRITICAL ERRORS
-- ========================================
-- Data: 2025-11-23
-- Descrição: Corrige erros críticos no sistema:
--   1. Adiciona coluna 'company' faltante na tabela leads
--   2. Adiciona policy RLS INSERT para installment_settings
--   3. Garante que dark_mode_admin e dark_mode_catalog existam
-- ========================================

-- ----------------------------------------
-- FIX 1: Adicionar coluna 'company' em leads
-- ----------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'company'
  ) THEN
    ALTER TABLE leads ADD COLUMN company VARCHAR(255);
    RAISE NOTICE 'Coluna company adicionada à tabela leads';
  ELSE
    RAISE NOTICE 'Coluna company já existe na tabela leads';
  END IF;
END $$;

-- ----------------------------------------
-- FIX 2: Adicionar policy RLS INSERT para installment_settings
-- ----------------------------------------
DO $$
BEGIN
  -- Primeiro, verificar se a policy já existe
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'installment_settings'
    AND policyname = 'Apenas autenticados podem inserir configurações de parcelamento'
  ) THEN
    -- Criar policy para INSERT
    CREATE POLICY "Apenas autenticados podem inserir configurações de parcelamento"
      ON installment_settings FOR INSERT
      TO authenticated
      WITH CHECK (true);
    RAISE NOTICE 'Policy INSERT criada para installment_settings';
  ELSE
    RAISE NOTICE 'Policy INSERT já existe para installment_settings';
  END IF;
END $$;

-- ----------------------------------------
-- FIX 3: Garantir dark_mode_admin e dark_mode_catalog em settings
-- ----------------------------------------
DO $$
BEGIN
  -- dark_mode_admin
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'settings' AND column_name = 'dark_mode_admin'
  ) THEN
    ALTER TABLE settings ADD COLUMN dark_mode_admin BOOLEAN DEFAULT false;
    RAISE NOTICE 'Coluna dark_mode_admin adicionada à tabela settings';
  ELSE
    RAISE NOTICE 'Coluna dark_mode_admin já existe na tabela settings';
  END IF;

  -- dark_mode_catalog
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'settings' AND column_name = 'dark_mode_catalog'
  ) THEN
    ALTER TABLE settings ADD COLUMN dark_mode_catalog BOOLEAN DEFAULT false;
    RAISE NOTICE 'Coluna dark_mode_catalog adicionada à tabela settings';
  ELSE
    RAISE NOTICE 'Coluna dark_mode_catalog já existe na tabela settings';
  END IF;
END $$;

-- ----------------------------------------
-- Adicionar comentários explicativos
-- ----------------------------------------
COMMENT ON COLUMN leads.company IS 'Nome da empresa do lead (opcional)';
COMMENT ON COLUMN settings.dark_mode_admin IS 'Ativa dark mode no painel administrativo';
COMMENT ON COLUMN settings.dark_mode_catalog IS 'Ativa dark mode no catálogo para visitantes';

-- ----------------------------------------
-- Verificação final
-- ----------------------------------------
SELECT
  'VERIFICAÇÃO DE CORREÇÕES' as status,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'company') as leads_company_existe,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'installment_settings' AND policyname LIKE '%inserir%') as installment_insert_policy_existe,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'settings' AND column_name = 'dark_mode_admin') as dark_mode_admin_existe,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'settings' AND column_name = 'dark_mode_catalog') as dark_mode_catalog_existe;

-- ========================================
-- INSTRUÇÕES DE USO
-- ========================================
-- Execute este arquivo no Supabase SQL Editor:
-- 1. Copie todo o conteúdo deste arquivo
-- 2. Acesse Supabase Dashboard > SQL Editor
-- 3. Cole e execute
-- 4. Verifique os resultados na seção VERIFICAÇÃO DE CORREÇÕES
-- ========================================
