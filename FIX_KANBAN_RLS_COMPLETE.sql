-- ========================================
-- FIX COMPLETO: Políticas RLS do Kanban de Leads
-- ========================================
-- Este script corrige TODOS os problemas de RLS e campos do Kanban
-- Execute este script no SQL Editor do Supabase

-- 1. Garantir que o campo updated_at existe na tabela leads
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE leads ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    RAISE NOTICE 'Campo updated_at adicionado à tabela leads';
  ELSE
    RAISE NOTICE 'Campo updated_at já existe na tabela leads';
  END IF;
END $$;

-- 2. Garantir que o campo created_at existe na tabela leads
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE leads ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    RAISE NOTICE 'Campo created_at adicionado à tabela leads';
  ELSE
    RAISE NOTICE 'Campo created_at já existe na tabela leads';
  END IF;
END $$;

-- 3. REMOVER todas as políticas RLS antigas
DROP POLICY IF EXISTS "Apenas autenticados podem ver colunas do kanban" ON kanban_columns;
DROP POLICY IF EXISTS "Apenas autenticados podem atualizar colunas" ON kanban_columns;
DROP POLICY IF EXISTS "Apenas autenticados podem inserir colunas" ON kanban_columns;
DROP POLICY IF EXISTS "Apenas autenticados podem deletar colunas" ON kanban_columns;

DROP POLICY IF EXISTS "Apenas autenticados podem ver leads" ON leads;
DROP POLICY IF EXISTS "Apenas autenticados podem inserir leads" ON leads;
DROP POLICY IF EXISTS "Apenas autenticados podem atualizar leads" ON leads;
DROP POLICY IF EXISTS "Apenas autenticados podem deletar leads" ON leads;

DROP POLICY IF EXISTS "Apenas autenticados podem ver interações" ON lead_interactions;
DROP POLICY IF EXISTS "Apenas autenticados podem inserir interações" ON lead_interactions;
DROP POLICY IF EXISTS "Apenas autenticados podem atualizar interações" ON lead_interactions;
DROP POLICY IF EXISTS "Apenas autenticados podem deletar interações" ON lead_interactions;

DROP POLICY IF EXISTS "Apenas autenticados podem ver movimentações" ON lead_movements;
DROP POLICY IF EXISTS "Apenas autenticados podem inserir movimentações" ON lead_movements;
DROP POLICY IF EXISTS "Apenas autenticados podem atualizar movimentações" ON lead_movements;
DROP POLICY IF EXISTS "Apenas autenticados podem deletar movimentações" ON lead_movements;

-- 4. Habilitar RLS em todas as tabelas
ALTER TABLE kanban_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_movements ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 5. CRIAR POLÍTICAS RLS COMPLETAS
-- ========================================

-- 5.1. KANBAN_COLUMNS - Políticas completas
CREATE POLICY "Autenticados podem ver colunas do kanban"
  ON kanban_columns FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Autenticados podem inserir colunas do kanban"
  ON kanban_columns FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Autenticados podem atualizar colunas do kanban"
  ON kanban_columns FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Autenticados podem deletar colunas do kanban"
  ON kanban_columns FOR DELETE
  TO authenticated
  USING (true);

-- 5.2. LEADS - Políticas completas
CREATE POLICY "Autenticados podem ver leads"
  ON leads FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Autenticados podem inserir leads"
  ON leads FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Autenticados podem atualizar leads"
  ON leads FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Autenticados podem deletar leads"
  ON leads FOR DELETE
  TO authenticated
  USING (true);

-- 5.3. LEAD_INTERACTIONS - Políticas completas
CREATE POLICY "Autenticados podem ver interações"
  ON lead_interactions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Autenticados podem inserir interações"
  ON lead_interactions FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Autenticados podem atualizar interações"
  ON lead_interactions FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Autenticados podem deletar interações"
  ON lead_interactions FOR DELETE
  TO authenticated
  USING (true);

-- 5.4. LEAD_MOVEMENTS - Políticas completas
CREATE POLICY "Autenticados podem ver movimentações"
  ON lead_movements FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Autenticados podem inserir movimentações"
  ON lead_movements FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Autenticados podem atualizar movimentações"
  ON lead_movements FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Autenticados podem deletar movimentações"
  ON lead_movements FOR DELETE
  TO authenticated
  USING (true);

-- ========================================
-- 6. VERIFICAÇÃO FINAL
-- ========================================

-- Verificar políticas criadas
SELECT
  schemaname,
  tablename,
  policyname,
  cmd as operation,
  roles
FROM pg_policies
WHERE tablename IN ('kanban_columns', 'leads', 'lead_interactions', 'lead_movements')
ORDER BY tablename, operation;

-- Contar políticas por tabela
SELECT
  tablename,
  COUNT(*) as total_policies
FROM pg_policies
WHERE tablename IN ('kanban_columns', 'leads', 'lead_interactions', 'lead_movements')
GROUP BY tablename
ORDER BY tablename;

-- ========================================
-- RESULTADO ESPERADO:
-- ========================================
-- Cada tabela deve ter 4 políticas (SELECT, INSERT, UPDATE, DELETE)
-- kanban_columns: 4 políticas
-- leads: 4 políticas
-- lead_interactions: 4 políticas
-- lead_movements: 4 políticas
-- TOTAL: 16 políticas
-- ========================================
