-- =====================================================
-- FIX: Erro 401 na tabela SETTINGS
-- =====================================================
-- Data: 2025-11-23
-- Descrição: Adicionar política RLS para leitura pública de settings
-- =====================================================

-- A tabela 'settings' está sendo consultada no catálogo público
-- a cada 5 segundos, mas não tem política RLS permitindo acesso anônimo

-- ========================================
-- PARTE 1: DIAGNÓSTICO
-- ========================================

-- 1.1 Verificar se a tabela settings existe
SELECT
  table_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_tables
      WHERE schemaname = 'public' AND tablename = 'settings'
    )
    THEN '✅ TABELA EXISTE'
    ELSE '❌ TABELA NÃO EXISTE'
  END as status
FROM (SELECT 'settings' as table_name) t;

-- 1.2 Verificar se RLS está habilitado
SELECT
  tablename,
  CASE
    WHEN rowsecurity THEN '✅ RLS HABILITADO'
    ELSE '❌ RLS DESABILITADO'
  END as status_rls
FROM pg_tables
WHERE tablename = 'settings'
  AND schemaname = 'public';

-- 1.3 Verificar políticas RLS existentes para settings
SELECT
  policyname as politica,
  cmd as operacao,
  roles as roles,
  CASE
    WHEN qual IS NULL THEN 'SEM FILTRO (true)'
    ELSE 'COM FILTRO'
  END as filtro_using
FROM pg_policies
WHERE tablename = 'settings'
ORDER BY cmd;

-- ========================================
-- PARTE 2: CORREÇÃO
-- ========================================

-- 2.1 Garantir permissões GRANT
GRANT SELECT ON settings TO anon, authenticated;
GRANT ALL ON settings TO authenticated;

-- 2.2 Habilitar RLS (se não estiver habilitado)
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- 2.3 REMOVER políticas antigas (evitar conflitos)
DROP POLICY IF EXISTS "Permitir leitura pública de configurações" ON settings;
DROP POLICY IF EXISTS "Permitir leitura de settings" ON settings;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON settings;
DROP POLICY IF EXISTS "Permitir escrita de settings" ON settings;
DROP POLICY IF EXISTS "Enable read access for all users" ON settings;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON settings;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON settings;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON settings;

-- 2.4 CRIAR política de leitura pública para settings
CREATE POLICY "Public read access for settings"
ON settings
FOR SELECT
TO anon, authenticated
USING (true);

-- 2.5 CRIAR políticas de escrita apenas para authenticated
CREATE POLICY "Authenticated insert for settings"
ON settings
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated update for settings"
ON settings
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Authenticated delete for settings"
ON settings
FOR DELETE
TO authenticated
USING (true);

-- ========================================
-- PARTE 3: VERIFICAÇÃO
-- ========================================

-- 3.1 Confirmar que as políticas foram criadas
SELECT
  '✅ SETTINGS' as tabela,
  COUNT(*) as total_policies,
  STRING_AGG(policyname || ' (' || cmd || ')', ', ') as politicas
FROM pg_policies
WHERE tablename = 'settings';

-- 3.2 Testar leitura de settings (deve funcionar)
SELECT
  id,
  whatsapp_number,
  dark_mode_catalog,
  dark_mode_admin
FROM settings
WHERE id = 1;

-- 3.3 Verificar dados da tabela
SELECT
  COUNT(*) as total_registros
FROM settings;

-- ========================================
-- RESULTADO ESPERADO
-- ========================================
/*
APÓS EXECUTAR ESTE SCRIPT:

✅ RLS estará habilitado na tabela settings
✅ Usuários ANON (não autenticados) poderão LER settings
✅ Usuários AUTHENTICATED poderão fazer todas as operações (CRUD)
✅ O erro 401 ao consultar settings deve desaparecer

COMO TESTAR:
1. Execute este script completo no SQL Editor do Supabase
2. Limpe o cache do navegador (Ctrl+Shift+Del)
3. Recarregue o catálogo: https://catalogo.lukayagriffe.shop
4. Verifique o Network - não deve haver mais erros 401

CAUSA DO ERRO:
- A aplicação carrega settings a cada 5 segundos (loadSettings)
- Isso acontece tanto no modo admin quanto no catálogo público
- Sem política RLS permitindo leitura anônima, retorna 401
*/
