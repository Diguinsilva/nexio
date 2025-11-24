-- ========================================
-- MIGRATION: Sistema de Parcelamento
-- ========================================
-- Adiciona configuração de parcelamento personalizável
-- por produto e configurações globais da loja

-- 1. Tabela de configurações globais de parcelamento
CREATE TABLE IF NOT EXISTS installment_settings (
  id INTEGER PRIMARY KEY DEFAULT 1,

  -- Configurações padrão
  default_max_installments INTEGER DEFAULT 6,
  default_interest_rate DECIMAL(5,2) DEFAULT 0.00,
  min_installment_value DECIMAL(10,2) DEFAULT 20.00,

  -- Opções de parcelamento disponíveis (JSONB)
  -- Exemplo: [{"installments": 3, "interest_rate": 0}, {"installments": 6, "interest_rate": 0}, {"installments": 12, "interest_rate": 2.5}]
  installment_options JSONB DEFAULT '[
    {"installments": 1, "interest_rate": 0, "label": "À vista"},
    {"installments": 2, "interest_rate": 0, "label": "2x sem juros"},
    {"installments": 3, "interest_rate": 0, "label": "3x sem juros"},
    {"installments": 6, "interest_rate": 0, "label": "6x sem juros"},
    {"installments": 10, "interest_rate": 2.49, "label": "10x com juros"},
    {"installments": 12, "interest_rate": 2.99, "label": "12x com juros"}
  ]'::jsonb,

  -- Habilitar/desabilitar parcelamento
  installment_enabled BOOLEAN DEFAULT true,

  -- Exibir comparativo de preços (de X por X)
  show_price_comparison BOOLEAN DEFAULT true,

  -- Metadados
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir configuração padrão
INSERT INTO installment_settings (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- 2. Adicionar campos de parcelamento na tabela products
ALTER TABLE products
ADD COLUMN IF NOT EXISTS custom_installment_enabled BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS custom_max_installments INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS custom_installment_options JSONB DEFAULT NULL;

-- 3. Função para calcular valor da parcela com juros
CREATE OR REPLACE FUNCTION calculate_installment_value(
  p_price DECIMAL(10,2),
  p_installments INTEGER,
  p_interest_rate DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_monthly_rate DECIMAL(10,6);
  v_installment_value DECIMAL(10,2);
BEGIN
  -- Se não há juros, divisão simples
  IF p_interest_rate = 0 THEN
    RETURN ROUND(p_price / p_installments, 2);
  END IF;

  -- Calcular com juros compostos: PMT = PV * i * (1+i)^n / ((1+i)^n - 1)
  v_monthly_rate := p_interest_rate / 100;
  v_installment_value := p_price * v_monthly_rate * POWER(1 + v_monthly_rate, p_installments)
                         / (POWER(1 + v_monthly_rate, p_installments) - 1);

  RETURN ROUND(v_installment_value, 2);
END;
$$;

-- 4. View para obter opções de parcelamento de cada produto
CREATE OR REPLACE VIEW product_installment_options AS
SELECT
  p.id AS product_id,
  p.name AS product_name,
  p.price,

  -- Usar configuração customizada se existir, senão usar global
  COALESCE(p.custom_installment_enabled, s.installment_enabled) AS installment_enabled,
  COALESCE(p.custom_max_installments, s.default_max_installments) AS max_installments,
  COALESCE(p.custom_installment_options, s.installment_options) AS installment_options,

  s.min_installment_value,
  s.show_price_comparison
FROM products p
CROSS JOIN installment_settings s
WHERE p.status = 'active';

-- 5. Políticas RLS
ALTER TABLE installment_settings ENABLE ROW LEVEL SECURITY;

-- Todos podem ver as configurações
CREATE POLICY "Configurações de parcelamento são públicas"
  ON installment_settings FOR SELECT
  TO public
  USING (true);

-- Apenas autenticados podem atualizar
CREATE POLICY "Apenas autenticados podem atualizar configurações de parcelamento"
  ON installment_settings FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 6. Índices para performance
CREATE INDEX IF NOT EXISTS idx_products_custom_installment
  ON products(custom_installment_enabled)
  WHERE custom_installment_enabled IS NOT NULL;

-- 7. Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_installment_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_installment_settings_timestamp
  BEFORE UPDATE ON installment_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_installment_settings_timestamp();

-- ========================================
-- EXEMPLOS DE USO
-- ========================================

-- Exemplo 1: Buscar opções de parcelamento de um produto
-- SELECT * FROM product_installment_options WHERE product_id = 1;

-- Exemplo 2: Calcular valor de parcela com juros
-- SELECT calculate_installment_value(1200.00, 12, 2.99); -- R$ 1200 em 12x com 2.99% ao mês

-- Exemplo 3: Configurar parcelamento customizado para um produto específico
-- UPDATE products
-- SET custom_installment_enabled = true,
--     custom_max_installments = 12,
--     custom_installment_options = '[
--       {"installments": 1, "interest_rate": 0, "label": "À vista com 10% de desconto"},
--       {"installments": 12, "interest_rate": 0, "label": "12x sem juros - PROMOÇÃO"}
--     ]'::jsonb
-- WHERE id = 123;

COMMENT ON TABLE installment_settings IS 'Configurações globais do sistema de parcelamento';
COMMENT ON FUNCTION calculate_installment_value IS 'Calcula o valor da parcela com ou sem juros usando Price (PMT)';
COMMENT ON VIEW product_installment_options IS 'View que combina configurações globais e customizadas de parcelamento por produto';
