-- =====================================================
-- MIGRATION: Adicionar Suporte a Cores nos Produtos
-- Execute no SQL Editor do Supabase Dashboard
-- =====================================================

-- Adicionar coluna colors (array de strings) se não existir
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='products' AND column_name='colors') THEN
    ALTER TABLE products ADD COLUMN colors TEXT[] DEFAULT '{}';
  END IF;
END $$;

-- Adicionar coluna color_stock (JSONB) para controlar estoque por cor, se não existir
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='products' AND column_name='color_stock') THEN
    ALTER TABLE products ADD COLUMN color_stock JSONB DEFAULT '{}';
  END IF;
END $$;

-- Comentários para documentar as colunas
COMMENT ON COLUMN products.colors IS 'Array de cores disponíveis para o produto (ex: ["Preto", "Branco", "Azul"])';
COMMENT ON COLUMN products.color_stock IS 'Estoque por cor em formato JSON (ex: {"Preto": 10, "Branco": 5, "Azul": 3})';

-- Exemplo de como usar:
-- UPDATE products SET colors = '{"Preto", "Branco", "Vermelho"}' WHERE id = 1;
-- UPDATE products SET color_stock = '{"Preto": 10, "Branco": 5, "Vermelho": 3}' WHERE id = 1;

-- Verificar colunas adicionadas
SELECT
  table_name,
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'products'
  AND column_name IN ('colors', 'color_stock')
ORDER BY column_name;
