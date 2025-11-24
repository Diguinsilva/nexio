-- ========================================
-- FIX: Erro de View no Kanban
-- ========================================
-- Data: 2025-11-23
-- Descrição: Corrige o erro "cannot change name of view column"
--            que ocorre ao tentar modificar a estrutura das views
-- ========================================
-- Erro original:
-- ERROR: 42P16: cannot change name of view column "column_name" to "company"
-- HINT: Use ALTER VIEW ... RENAME COLUMN ... to change name of view column instead.
-- ========================================

-- ========================================
-- SOLUÇÃO: Recriar as views completamente
-- ========================================
-- O PostgreSQL não permite alterar a estrutura de uma view com
-- CREATE OR REPLACE VIEW se isso resultar em mudança de nomes de colunas.
-- A solução é DROP e recriar.

-- ----------------------------------------
-- 1. Remover views existentes
-- ----------------------------------------
DROP VIEW IF EXISTS leads_with_stats CASCADE;
DROP VIEW IF EXISTS kanban_stats CASCADE;

-- ----------------------------------------
-- 2. Recriar view kanban_stats
-- ----------------------------------------
CREATE VIEW kanban_stats AS
SELECT
  kc.id AS column_id,
  kc.name AS column_name,
  kc.color,
  COUNT(l.id) AS leads_count,
  SUM(COALESCE(l.estimated_value, 0)) AS total_estimated_value,
  AVG(COALESCE(l.estimated_value, 0)) AS avg_estimated_value,
  COUNT(CASE WHEN l.next_followup_date < NOW() THEN 1 END) AS overdue_followups
FROM kanban_columns kc
LEFT JOIN leads l ON l.column_id = kc.id AND l.status = 'active'
WHERE kc.is_active = true
GROUP BY kc.id, kc.name, kc.color, kc.order_index
ORDER BY kc.order_index;

-- ----------------------------------------
-- 3. Recriar view leads_with_stats
-- ----------------------------------------
CREATE VIEW leads_with_stats AS
SELECT
  l.*,
  kc.name AS column_name,
  kc.color AS column_color,
  kc.column_type,
  (SELECT COUNT(*) FROM lead_interactions li WHERE li.lead_id = l.id) AS total_interactions,
  (SELECT MAX(created_at) FROM lead_interactions li WHERE li.lead_id = l.id) AS last_interaction_date,
  EXTRACT(DAY FROM NOW() - l.created_at) AS days_since_created,
  CASE
    WHEN l.next_followup_date < NOW() THEN true
    ELSE false
  END AS is_followup_overdue
FROM leads l
JOIN kanban_columns kc ON kc.id = l.column_id;

-- ----------------------------------------
-- 4. Garantir que a coluna 'company' existe
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
-- 5. Adicionar comentários
-- ----------------------------------------
COMMENT ON VIEW kanban_stats IS 'Estatísticas agregadas por coluna do Kanban';
COMMENT ON VIEW leads_with_stats IS 'View enriquecida de leads com estatísticas e informações da coluna';
COMMENT ON COLUMN leads.company IS 'Nome da empresa do lead (opcional)';

-- ----------------------------------------
-- 6. Verificação final
-- ----------------------------------------
-- Verificar se as views foram criadas corretamente
SELECT
  'VERIFICAÇÃO DE VIEWS' as status,
  (SELECT COUNT(*) FROM information_schema.views WHERE table_name = 'kanban_stats') as kanban_stats_existe,
  (SELECT COUNT(*) FROM information_schema.views WHERE table_name = 'leads_with_stats') as leads_with_stats_existe,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'company') as company_existe;

-- Testar as views
SELECT * FROM kanban_stats LIMIT 5;
SELECT * FROM leads_with_stats LIMIT 5;

-- ========================================
-- INSTRUÇÕES DE USO
-- ========================================
-- Execute este arquivo no Supabase SQL Editor:
-- 1. Copie todo o conteúdo deste arquivo
-- 2. Acesse Supabase Dashboard > SQL Editor
-- 3. Cole e execute
-- 4. Verifique se não há mais erros de view
-- ========================================

-- ========================================
-- PREVENÇÃO DE ERROS FUTUROS
-- ========================================
/*
Para evitar este erro no futuro:

1. Sempre use DROP VIEW ... CASCADE antes de recriar views com
   estrutura diferente

2. Não use CREATE OR REPLACE VIEW quando houver mudanças em:
   - Nomes de colunas
   - Tipos de dados
   - Ordem de colunas

3. Ao adicionar novas colunas na tabela base, recrie a view
   completamente se ela usar SELECT *

4. Documente todas as mudanças de schema em migrations separadas
*/
