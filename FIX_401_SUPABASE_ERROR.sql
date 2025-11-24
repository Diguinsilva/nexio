-- =====================================================
-- FIX: Erro 401 (Unauthorized) do Supabase
-- =====================================================
-- Data: 2025-11-23
-- Descrição: Script para diagnosticar e corrigir erro 401
-- =====================================================

-- ========================================
-- PARTE 1: DIAGNÓSTICO
-- ========================================

-- 1.1 Verificar se RLS está habilitado nas tabelas principais
SELECT
  tablename,
  CASE
    WHEN rowsecurity THEN '✅ RLS HABILITADO'
    ELSE '❌ RLS DESABILITADO'
  END as status_rls
FROM pg_tables
WHERE tablename IN ('products', 'categories', 'banners', 'settings')
  AND schemaname = 'public'
ORDER BY tablename;

-- 1.2 Verificar políticas RLS existentes para products
SELECT
  policyname as politica,
  cmd as operacao,
  roles as roles,
  CASE
    WHEN qual IS NULL THEN 'SEM FILTRO (true)'
    ELSE 'COM FILTRO'
  END as filtro_using
FROM pg_policies
WHERE tablename = 'products'
ORDER BY cmd;

-- 1.3 Verificar políticas RLS existentes para categories
SELECT
  policyname as politica,
  cmd as operacao,
  roles as roles,
  CASE
    WHEN qual IS NULL THEN 'SEM FILTRO (true)'
    ELSE 'COM FILTRO'
  END as filtro_using
FROM pg_policies
WHERE tablename = 'categories'
ORDER BY cmd;

-- 1.4 Verificar políticas RLS existentes para banners
SELECT
  policyname as politica,
  cmd as operacao,
  roles as roles,
  CASE
    WHEN qual IS NULL THEN 'SEM FILTRO (true)'
    ELSE 'COM FILTRO'
  END as filtro_using
FROM pg_policies
WHERE tablename = 'banners'
ORDER BY cmd;

-- 1.5 Verificar permissões GRANT
SELECT
  grantee as usuario_role,
  privilege_type as permissao,
  table_name as tabela
FROM information_schema.table_privileges
WHERE table_name IN ('products', 'categories', 'banners', 'settings')
  AND table_schema = 'public'
  AND grantee IN ('anon', 'authenticated', 'public')
ORDER BY table_name, grantee;

-- ========================================
-- PARTE 2: CORREÇÃO
-- ========================================

-- 2.1 Garantir que as tabelas tenham permissões GRANT corretas
GRANT SELECT ON products TO anon, authenticated;
GRANT ALL ON products TO authenticated;

GRANT SELECT ON categories TO anon, authenticated;
GRANT ALL ON categories TO authenticated;

GRANT SELECT ON banners TO anon, authenticated;
GRANT ALL ON banners TO authenticated;

-- 2.2 Habilitar RLS nas tabelas (se não estiver habilitado)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- 2.3 REMOVER TODAS as políticas antigas (para evitar conflitos)
DROP POLICY IF EXISTS "Permitir leitura pública de produtos" ON products;
DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON products;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON products;
DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON products;
DROP POLICY IF EXISTS "Enable read access for all users" ON products;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON products;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON products;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON products;

DROP POLICY IF EXISTS "Permitir leitura pública de categorias" ON categories;
DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON categories;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON categories;
DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON categories;
DROP POLICY IF EXISTS "Enable read access for all users" ON categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON categories;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON categories;

DROP POLICY IF EXISTS "Permitir leitura pública de banners" ON banners;
DROP POLICY IF EXISTS "Permitir inserção para usuários autenticados" ON banners;
DROP POLICY IF EXISTS "Permitir atualização para usuários autenticados" ON banners;
DROP POLICY IF EXISTS "Permitir exclusão para usuários autenticados" ON banners;
DROP POLICY IF EXISTS "Enable read access for all users" ON banners;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON banners;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON banners;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON banners;

-- 2.4 CRIAR políticas corretas para PRODUCTS

-- LEITURA PÚBLICA (anon + authenticated podem ler)
CREATE POLICY "Public read access for products"
ON products
FOR SELECT
TO anon, authenticated
USING (true);

-- ESCRITA apenas para authenticated
CREATE POLICY "Authenticated insert for products"
ON products
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated update for products"
ON products
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Authenticated delete for products"
ON products
FOR DELETE
TO authenticated
USING (true);

-- 2.5 CRIAR políticas corretas para CATEGORIES

-- LEITURA PÚBLICA
CREATE POLICY "Public read access for categories"
ON categories
FOR SELECT
TO anon, authenticated
USING (true);

-- ESCRITA apenas para authenticated
CREATE POLICY "Authenticated insert for categories"
ON categories
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated update for categories"
ON categories
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Authenticated delete for categories"
ON categories
FOR DELETE
TO authenticated
USING (true);

-- 2.6 CRIAR políticas corretas para BANNERS

-- LEITURA PÚBLICA
CREATE POLICY "Public read access for banners"
ON banners
FOR SELECT
TO anon, authenticated
USING (true);

-- ESCRITA apenas para authenticated
CREATE POLICY "Authenticated insert for banners"
ON banners
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated update for banners"
ON banners
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Authenticated delete for banners"
ON banners
FOR DELETE
TO authenticated
USING (true);

-- ========================================
-- PARTE 3: VERIFICAÇÃO FINAL
-- ========================================

-- 3.1 Confirmar que as políticas foram criadas
SELECT
  '✅ PRODUCTS' as tabela,
  COUNT(*) as total_policies,
  STRING_AGG(policyname || ' (' || cmd || ')', ', ') as politicas
FROM pg_policies
WHERE tablename = 'products'
UNION ALL
SELECT
  '✅ CATEGORIES',
  COUNT(*),
  STRING_AGG(policyname || ' (' || cmd || ')', ', ')
FROM pg_policies
WHERE tablename = 'categories'
UNION ALL
SELECT
  '✅ BANNERS',
  COUNT(*),
  STRING_AGG(policyname || ' (' || cmd || ')', ', ')
FROM pg_policies
WHERE tablename = 'banners';

-- 3.2 Testar leitura de products (deve funcionar)
SELECT
  COUNT(*) as total_produtos,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as produtos_ativos
FROM products;

-- 3.3 Testar leitura de categories (deve funcionar)
SELECT
  COUNT(*) as total_categorias,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as categorias_ativas
FROM categories;

-- ========================================
-- RESULTADO ESPERADO
-- ========================================
/*
APÓS EXECUTAR ESTE SCRIPT:

✅ RLS estará habilitado em products, categories e banners
✅ Usuários ANON (não autenticados) poderão LER (SELECT) essas tabelas
✅ Usuários AUTHENTICATED poderão fazer todas as operações (CRUD)
✅ O erro 401 deve desaparecer no catálogo público

SE O ERRO PERSISTIR:
1. Verifique se a ANON KEY está correta em src/config/env.js
2. Limpe o cache do navegador (Ctrl+Shift+Del)
3. Verifique se o Supabase URL está correto
4. Verifique os logs do navegador para outros erros

CAUSA DO ERRO 401:
- RLS estava habilitado MAS sem políticas permitindo acesso público
- Ou políticas existiam mas não incluíam o role 'anon' explicitamente
- Solução: Criar políticas com TO anon, authenticated USING (true)
*/
