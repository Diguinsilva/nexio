-- ========================================
-- DIAGNÓSTICO DE RLS (Row Level Security)
-- ========================================
-- Data: 2025-11-23
-- Descrição: Queries para diagnosticar problemas com RLS
-- ========================================

-- ========================================
-- 1. VERIFICAR POLÍTICAS RLS EXISTENTES
-- ========================================

-- Verificar políticas para tabela 'leads'
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
WHERE tablename = 'leads'
ORDER BY policyname;

-- Verificar políticas para tabela 'kanban_columns'
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
WHERE tablename = 'kanban_columns'
ORDER BY policyname;

-- Verificar políticas para tabela 'lead_interactions'
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
WHERE tablename = 'lead_interactions'
ORDER BY policyname;

-- Verificar políticas para tabela 'lead_movements'
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
WHERE tablename = 'lead_movements'
ORDER BY policyname;

-- ========================================
-- 2. VERIFICAR STATUS DE RLS NAS TABELAS
-- ========================================
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename IN ('leads', 'kanban_columns', 'lead_interactions', 'lead_movements')
ORDER BY tablename;

-- ========================================
-- 3. VERIFICAR PERMISSÕES DO USUÁRIO ATUAL
-- ========================================
SELECT
  current_user as usuario_atual,
  current_role as role_atual,
  session_user as sessao_usuario;

-- ========================================
-- 4. LISTAR TODAS AS POLÍTICAS RLS DO SCHEMA PUBLIC
-- ========================================
SELECT
  tablename,
  policyname,
  cmd as operacao,
  roles,
  CASE
    WHEN qual IS NULL THEN 'SEM RESTRIÇÃO'
    ELSE 'COM RESTRIÇÃO'
  END as tem_filtro_using,
  CASE
    WHEN with_check IS NULL THEN 'SEM RESTRIÇÃO'
    ELSE 'COM RESTRIÇÃO'
  END as tem_filtro_with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- ========================================
-- 5. VERIFICAR GRANTS E PERMISSÕES
-- ========================================
SELECT
  table_schema,
  table_name,
  privilege_type,
  grantee
FROM information_schema.table_privileges
WHERE table_name IN ('leads', 'kanban_columns', 'lead_interactions', 'lead_movements')
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;

-- ========================================
-- 6. VERIFICAR SE HÁ LEADS VISÍVEIS
-- ========================================
-- Esta query mostrará quantos leads você consegue ver
-- Se retornar 0, pode ser problema de RLS
SELECT
  COUNT(*) as total_leads_visiveis,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as leads_ativos,
  COUNT(CASE WHEN status = 'won' THEN 1 END) as leads_ganhos,
  COUNT(CASE WHEN status = 'lost' THEN 1 END) as leads_perdidos
FROM leads;

-- ========================================
-- 7. VERIFICAR COLUNAS DO KANBAN VISÍVEIS
-- ========================================
SELECT
  id,
  name,
  color,
  order_index,
  is_active,
  column_type
FROM kanban_columns
ORDER BY order_index;

-- ========================================
-- 8. TESTAR OPERAÇÕES ESPECÍFICAS
-- ========================================

-- Tentar inserir um lead de teste (será revertido)
BEGIN;

-- Teste de INSERT
INSERT INTO leads (name, phone, column_id)
VALUES ('TESTE DIAGNÓSTICO', '00000000000',
  (SELECT id FROM kanban_columns WHERE column_type = 'new_lead' LIMIT 1)
);

-- Verificar se foi inserido
SELECT id, name, phone FROM leads WHERE name = 'TESTE DIAGNÓSTICO';

-- Reverter teste
ROLLBACK;

-- ========================================
-- 9. VERIFICAR FUNÇÕES RPC
-- ========================================
SELECT
  routine_name,
  routine_type,
  data_type as tipo_retorno,
  routine_definition
FROM information_schema.routines
WHERE routine_name IN ('move_lead_to_column', 'add_lead_interaction')
  AND routine_schema = 'public';

-- ========================================
-- 10. DIAGNÓSTICO DE ERROS COMUNS
-- ========================================

-- Verificar se há policies conflitantes
SELECT
  tablename,
  COUNT(*) as qtd_policies,
  STRING_AGG(policyname, ', ') as policies
FROM pg_policies
WHERE tablename IN ('leads', 'kanban_columns', 'lead_interactions', 'lead_movements')
GROUP BY tablename;

-- ========================================
-- RESULTADO ESPERADO
-- ========================================
/*
Se tudo estiver funcionando corretamente, você deve ver:

1. Políticas RLS para todas as tabelas (leads, kanban_columns, lead_interactions, lead_movements)
2. RLS habilitado em todas essas tabelas
3. Permissões adequadas para o role 'authenticated'
4. Leads e colunas visíveis
5. Capacidade de inserir dados (no teste dentro da transação)

SE HOUVER PROBLEMAS:
- Nenhuma política: As políticas não foram criadas
- RLS desabilitado: Executar ALTER TABLE ... ENABLE ROW LEVEL SECURITY
- Sem permissões: Verificar GRANT
- Leads não visíveis: Problema com a política USING
- Não consegue inserir: Problema com a política WITH CHECK
*/
