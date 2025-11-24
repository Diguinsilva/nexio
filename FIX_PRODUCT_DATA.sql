-- ========================================
-- SCRIPT DE CORREÇÃO: Dados Inconsistentes de Produtos
-- ========================================
-- Corrige produtos com configurações de desconto/preço incorretas

-- 1. DIAGNÓSTICO: Ver produtos com problemas
-- ========================================

-- Produtos com desconto mas sem original_price
SELECT id, name, price, original_price, discount_percentage
FROM products
WHERE discount_percentage > 0
  AND (original_price IS NULL OR original_price = 0);

-- Produtos com original_price menor que price (inconsistente)
SELECT id, name, price, original_price, discount_percentage
FROM products
WHERE original_price IS NOT NULL
  AND original_price < price;

-- Produtos com discount_percentage mas cálculo incorreto
SELECT id, name, price, original_price, discount_percentage,
       ROUND(((original_price - price) / original_price * 100)::numeric, 2) AS calculated_discount
FROM products
WHERE original_price IS NOT NULL
  AND original_price > 0
  AND discount_percentage IS NOT NULL
  AND discount_percentage > 0
  AND ABS(discount_percentage - ((original_price - price) / original_price * 100)) > 0.5;

-- 2. CORREÇÕES AUTOMÁTICAS
-- ========================================

-- Correção 1: Produtos com desconto mas sem original_price
-- Ação: Calcular original_price baseado no desconto
UPDATE products
SET original_price = ROUND((price / (1 - discount_percentage / 100.0))::numeric, 2)
WHERE discount_percentage > 0
  AND (original_price IS NULL OR original_price = 0)
  AND price > 0;

-- Correção 2: Produtos com original_price = price mas com desconto
-- Ação: Zerar o desconto (não há desconto real)
UPDATE products
SET discount_percentage = 0,
    original_price = NULL
WHERE original_price = price
  AND discount_percentage > 0;

-- Correção 3: Produtos com original_price < price (impossível)
-- Ação: Inverter os valores
UPDATE products
SET price = original_price,
    original_price = price,
    discount_percentage = ROUND(((price - original_price) / price * 100)::numeric, 0)
WHERE original_price IS NOT NULL
  AND original_price < price
  AND original_price > 0;

-- Correção 4: Recalcular discount_percentage baseado nos preços
UPDATE products
SET discount_percentage = ROUND(((original_price - price) / original_price * 100)::numeric, 0)
WHERE original_price IS NOT NULL
  AND original_price > price
  AND discount_percentage IS NOT NULL
  AND ABS(discount_percentage - ((original_price - price) / original_price * 100)) > 0.5;

-- Correção 5: Remover descontos irrelevantes (< 1%)
UPDATE products
SET discount_percentage = 0,
    original_price = NULL
WHERE discount_percentage IS NOT NULL
  AND discount_percentage < 1
  AND discount_percentage > 0;

-- Correção 6: Limitar desconto máximo a 99%
UPDATE products
SET discount_percentage = 99
WHERE discount_percentage > 99;

-- Correção 7: Garantir que preços sejam positivos
UPDATE products
SET price = ABS(price)
WHERE price < 0;

UPDATE products
SET original_price = ABS(original_price)
WHERE original_price < 0;

-- Correção 8: Arredondar preços para 2 casas decimais
UPDATE products
SET price = ROUND(price::numeric, 2),
    original_price = ROUND(original_price::numeric, 2)
WHERE price IS NOT NULL OR original_price IS NOT NULL;

-- 3. FUNÇÃO DE VALIDAÇÃO DE PRODUTO
-- ========================================

CREATE OR REPLACE FUNCTION validate_product_pricing(p_product_id BIGINT)
RETURNS TABLE(
  is_valid BOOLEAN,
  issues TEXT[]
) AS $$
DECLARE
  v_product RECORD;
  v_issues TEXT[] := '{}';
BEGIN
  SELECT * INTO v_product
  FROM products
  WHERE id = p_product_id;

  -- Validação 1: Preço deve ser positivo
  IF v_product.price <= 0 THEN
    v_issues := array_append(v_issues, 'Preço deve ser maior que zero');
  END IF;

  -- Validação 2: Se tem desconto, deve ter original_price
  IF v_product.discount_percentage > 0 AND (v_product.original_price IS NULL OR v_product.original_price = 0) THEN
    v_issues := array_append(v_issues, 'Desconto configurado mas sem preço original');
  END IF;

  -- Validação 3: original_price deve ser maior que price
  IF v_product.original_price IS NOT NULL AND v_product.original_price <= v_product.price THEN
    v_issues := array_append(v_issues, 'Preço original deve ser maior que preço atual');
  END IF;

  -- Validação 4: discount_percentage deve bater com o cálculo
  IF v_product.original_price IS NOT NULL AND v_product.original_price > 0 AND v_product.discount_percentage > 0 THEN
    DECLARE
      v_calculated_discount NUMERIC;
    BEGIN
      v_calculated_discount := ROUND(((v_product.original_price - v_product.price) / v_product.original_price * 100)::numeric, 0);
      IF ABS(v_product.discount_percentage - v_calculated_discount) > 1 THEN
        v_issues := array_append(v_issues, format('Desconto informado (%s%%) não bate com cálculo (%s%%)', v_product.discount_percentage, v_calculated_discount));
      END IF;
    END;
  END IF;

  -- Validação 5: Desconto não pode ser maior que 99%
  IF v_product.discount_percentage > 99 THEN
    v_issues := array_append(v_issues, 'Desconto não pode ser maior que 99%');
  END IF;

  RETURN QUERY SELECT (array_length(v_issues, 1) IS NULL OR array_length(v_issues, 1) = 0), v_issues;
END;
$$ LANGUAGE plpgsql;

-- 4. VALIDAR TODOS OS PRODUTOS
-- ========================================

-- Ver todos os produtos com problemas
SELECT p.id, p.name, v.*
FROM products p,
LATERAL validate_product_pricing(p.id) v
WHERE v.is_valid = false;

-- 5. TRIGGER PARA VALIDAÇÃO AUTOMÁTICA
-- ========================================

CREATE OR REPLACE FUNCTION trigger_validate_product_pricing()
RETURNS TRIGGER AS $$
DECLARE
  v_validation RECORD;
BEGIN
  -- Auto-corrigir problemas básicos antes de salvar

  -- Se tem desconto mas não tem original_price, calcular
  IF NEW.discount_percentage > 0 AND (NEW.original_price IS NULL OR NEW.original_price = 0) THEN
    NEW.original_price := ROUND((NEW.price / (1 - NEW.discount_percentage / 100.0))::numeric, 2);
  END IF;

  -- Se original_price = price, zerar desconto
  IF NEW.original_price = NEW.price AND NEW.discount_percentage > 0 THEN
    NEW.discount_percentage := 0;
    NEW.original_price := NULL;
  END IF;

  -- Recalcular desconto se necessário
  IF NEW.original_price IS NOT NULL AND NEW.original_price > NEW.price THEN
    NEW.discount_percentage := ROUND(((NEW.original_price - NEW.price) / NEW.original_price * 100)::numeric, 0);
  END IF;

  -- Garantir preços positivos
  NEW.price := ABS(NEW.price);
  IF NEW.original_price IS NOT NULL THEN
    NEW.original_price := ABS(NEW.original_price);
  END IF;

  -- Arredondar para 2 casas decimais
  NEW.price := ROUND(NEW.price::numeric, 2);
  IF NEW.original_price IS NOT NULL THEN
    NEW.original_price := ROUND(NEW.original_price::numeric, 2);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger (desabilitado por padrão, habilitar se desejar validação automática)
-- DROP TRIGGER IF EXISTS trigger_validate_pricing ON products;
-- CREATE TRIGGER trigger_validate_pricing
--   BEFORE INSERT OR UPDATE ON products
--   FOR EACH ROW
--   EXECUTE FUNCTION trigger_validate_product_pricing();

-- ========================================
-- RELATÓRIO FINAL
-- ========================================

-- Contar produtos corrigidos vs produtos com problemas
SELECT
  'Total de produtos' AS metric,
  COUNT(*) AS value
FROM products
UNION ALL
SELECT
  'Produtos com desconto' AS metric,
  COUNT(*) AS value
FROM products
WHERE discount_percentage > 0
UNION ALL
SELECT
  'Produtos com original_price' AS metric,
  COUNT(*) AS value
FROM products
WHERE original_price IS NOT NULL
UNION ALL
SELECT
  'Produtos com problemas detectados' AS metric,
  COUNT(*) AS value
FROM (
  SELECT p.id
  FROM products p,
  LATERAL validate_product_pricing(p.id) v
  WHERE v.is_valid = false
) AS problematic_products;

COMMENT ON FUNCTION validate_product_pricing IS 'Valida a consistência dos dados de precificação de um produto';
