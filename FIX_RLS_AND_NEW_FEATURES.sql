-- =====================================================
-- MIGRATION: Corrigir RLS e Adicionar Novas Features
-- Execute no SQL Editor do Supabase Dashboard
-- =====================================================

-- =====================================================
-- 0. CRIAR TABELA PRODUCT_VIEWS (SE NÃO EXISTIR)
-- =====================================================

-- Criar tabela product_views
CREATE TABLE IF NOT EXISTS product_views (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  viewed_date DATE NOT NULL DEFAULT CURRENT_DATE,
  user_agent TEXT,
  ip_address TEXT,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índice único (1 view por session por produto por dia)
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_view_per_session_day
ON product_views (product_id, session_id, viewed_date);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_product_views_product_id ON product_views(product_id);
CREATE INDEX IF NOT EXISTS idx_product_views_session_id ON product_views(session_id);
CREATE INDEX IF NOT EXISTS idx_product_views_viewed_at ON product_views(viewed_at);
CREATE INDEX IF NOT EXISTS idx_product_views_viewed_date ON product_views(viewed_date);

-- =====================================================
-- 1. CRIAR TABELAS CUSTOMERS, SALES, SALE_ITEMS
-- =====================================================

-- IMPORTANTE: Primeiro criar tabelas básicas sem colunas source
CREATE TABLE IF NOT EXISTS customers (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  email TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sales (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_method TEXT,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sale_items (
  id BIGSERIAL PRIMARY KEY,
  sale_id BIGINT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agora adicionar colunas source em tabelas existentes (se não existirem)
DO $$
BEGIN
  -- Adicionar coluna source em customers se não existir
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='customers' AND column_name='source') THEN
    ALTER TABLE customers ADD COLUMN source TEXT DEFAULT 'whatsapp';
  END IF;

  -- Adicionar colunas utm em customers se não existirem
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='customers' AND column_name='utm_source') THEN
    ALTER TABLE customers ADD COLUMN utm_source TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='customers' AND column_name='utm_medium') THEN
    ALTER TABLE customers ADD COLUMN utm_medium TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='customers' AND column_name='utm_campaign') THEN
    ALTER TABLE customers ADD COLUMN utm_campaign TEXT;
  END IF;

  -- Adicionar coluna source em sales se não existir
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='sales' AND column_name='source') THEN
    ALTER TABLE sales ADD COLUMN source TEXT DEFAULT 'whatsapp';
  END IF;

  -- Adicionar colunas utm em sales se não existirem
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='sales' AND column_name='utm_source') THEN
    ALTER TABLE sales ADD COLUMN utm_source TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='sales' AND column_name='utm_medium') THEN
    ALTER TABLE sales ADD COLUMN utm_medium TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='sales' AND column_name='utm_campaign') THEN
    ALTER TABLE sales ADD COLUMN utm_campaign TEXT;
  END IF;
END $$;

-- Criar índices
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_source ON customers(source);

CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status);
CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at);
CREATE INDEX IF NOT EXISTS idx_sales_source ON sales(source);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items(product_id);

-- Function para diminuir estoque
CREATE OR REPLACE FUNCTION decrease_product_stock(
  p_product_id BIGINT,
  p_quantity INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE products
  SET stock = GREATEST(stock - p_quantity, 0),
      updated_at = NOW()
  WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Function para aumentar estoque (devolução/cancelamento)
CREATE OR REPLACE FUNCTION increase_product_stock(
  p_product_id BIGINT,
  p_quantity INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE products
  SET stock = stock + p_quantity,
      updated_at = NOW()
  WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_updated_at
  BEFORE UPDATE ON sales
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 2. RLS POLICIES PARA SETTINGS
-- =====================================================

-- Habilitar RLS na tabela settings
ALTER TABLE IF EXISTS settings ENABLE ROW LEVEL SECURITY;

-- Policy: Todos podem ler configurações
DROP POLICY IF EXISTS "Permitir leitura de settings" ON settings;
CREATE POLICY "Permitir leitura de settings"
  ON settings FOR SELECT
  USING (true);

-- Policy: Todos podem atualizar/inserir settings
DROP POLICY IF EXISTS "Permitir escrita de settings" ON settings;
CREATE POLICY "Permitir escrita de settings"
  ON settings FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3. RLS POLICIES PARA PRODUCT_VIEWS
-- =====================================================

-- Habilitar RLS na tabela product_views
ALTER TABLE IF EXISTS product_views ENABLE ROW LEVEL SECURITY;

-- Policy: Todos podem ler visualizações
DROP POLICY IF EXISTS "Permitir leitura de product_views" ON product_views;
CREATE POLICY "Permitir leitura de product_views"
  ON product_views FOR SELECT
  USING (true);

-- Policy: Todos podem inserir visualizações
DROP POLICY IF EXISTS "Permitir insert de product_views" ON product_views;
CREATE POLICY "Permitir insert de product_views"
  ON product_views FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 4. RLS POLICIES PARA SALES, CUSTOMERS, SALE_ITEMS
-- =====================================================

-- Habilitar RLS (somente se as tabelas existirem)
ALTER TABLE IF EXISTS customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sale_items ENABLE ROW LEVEL SECURITY;

-- CUSTOMERS Policies
DROP POLICY IF EXISTS "Permitir leitura de customers" ON customers;
CREATE POLICY "Permitir leitura de customers"
  ON customers FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Permitir escrita de customers" ON customers;
CREATE POLICY "Permitir escrita de customers"
  ON customers FOR ALL
  USING (true)
  WITH CHECK (true);

-- SALES Policies
DROP POLICY IF EXISTS "Permitir leitura de sales" ON sales;
CREATE POLICY "Permitir leitura de sales"
  ON sales FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Permitir escrita de sales" ON sales;
CREATE POLICY "Permitir escrita de sales"
  ON sales FOR ALL
  USING (true)
  WITH CHECK (true);

-- SALE_ITEMS Policies
DROP POLICY IF EXISTS "Permitir leitura de sale_items" ON sale_items;
CREATE POLICY "Permitir leitura de sale_items"
  ON sale_items FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Permitir escrita de sale_items" ON sale_items;
CREATE POLICY "Permitir escrita de sale_items"
  ON sale_items FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 5. CRIAR TABELA TEAM_MEMBERS
-- =====================================================

CREATE TABLE IF NOT EXISTS team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'member', -- admin, member, viewer
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_team_members_email ON team_members(email);
CREATE INDEX IF NOT EXISTS idx_team_members_role ON team_members(role);
CREATE INDEX IF NOT EXISTS idx_team_members_is_active ON team_members(is_active);

-- RLS Policies
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir leitura de team_members" ON team_members;
CREATE POLICY "Permitir leitura de team_members"
  ON team_members FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Permitir escrita de team_members" ON team_members;
CREATE POLICY "Permitir escrita de team_members"
  ON team_members FOR ALL
  USING (true)
  WITH CHECK (true);

-- Trigger para updated_at
CREATE TRIGGER update_team_members_updated_at
  BEFORE UPDATE ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. CRIAR TABELA SDR_CONFIG (Webhook n8n)
-- =====================================================

CREATE TABLE IF NOT EXISTS sdr_config (
  id INTEGER PRIMARY KEY DEFAULT 1,
  webhook_url TEXT,
  webhook_secret TEXT,
  webhook_enabled BOOLEAN DEFAULT false,
  last_webhook_call TIMESTAMP WITH TIME ZONE,
  last_webhook_status TEXT, -- success, error
  last_webhook_error TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT sdr_config_single_row CHECK (id = 1)
);

-- Inserir configuração padrão
INSERT INTO sdr_config (id, webhook_enabled)
VALUES (1, false)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies
ALTER TABLE sdr_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir leitura de sdr_config" ON sdr_config;
CREATE POLICY "Permitir leitura de sdr_config"
  ON sdr_config FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Permitir escrita de sdr_config" ON sdr_config;
CREATE POLICY "Permitir escrita de sdr_config"
  ON sdr_config FOR ALL
  USING (true)
  WITH CHECK (true);

-- Trigger para updated_at
CREATE TRIGGER update_sdr_config_updated_at
  BEFORE UPDATE ON sdr_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. CRIAR TABELA CART_EVENTS (Rastreamento de Carrinho)
-- =====================================================

CREATE TABLE IF NOT EXISTS cart_events (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL, -- added, removed, checkout_started, checkout_completed
  quantity INTEGER DEFAULT 1,
  user_agent TEXT,
  ip_address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_cart_events_product_id ON cart_events(product_id);
CREATE INDEX IF NOT EXISTS idx_cart_events_session_id ON cart_events(session_id);
CREATE INDEX IF NOT EXISTS idx_cart_events_event_type ON cart_events(event_type);
CREATE INDEX IF NOT EXISTS idx_cart_events_created_at ON cart_events(created_at);

-- RLS Policies
ALTER TABLE cart_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir leitura de cart_events" ON cart_events;
CREATE POLICY "Permitir leitura de cart_events"
  ON cart_events FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Permitir insert de cart_events" ON cart_events;
CREATE POLICY "Permitir insert de cart_events"
  ON cart_events FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 8. VIEWS ÚTEIS PARA DASHBOARD
-- =====================================================

-- View: Produtos mais vendidos
CREATE OR REPLACE VIEW top_selling_products AS
SELECT
  p.id,
  p.name,
  p.price,
  p.image_urls,
  COUNT(si.id) as times_sold,
  SUM(si.quantity) as total_quantity_sold,
  SUM(si.total_price) as total_revenue
FROM products p
LEFT JOIN sale_items si ON p.id = si.product_id
GROUP BY p.id
ORDER BY total_quantity_sold DESC NULLS LAST;

-- View: Produtos mais adicionados ao carrinho
CREATE OR REPLACE VIEW top_cart_products AS
SELECT
  p.id,
  p.name,
  p.price,
  p.image_urls,
  COUNT(ce.id) as times_added,
  SUM(ce.quantity) as total_quantity
FROM products p
LEFT JOIN cart_events ce ON p.id = ce.product_id AND ce.event_type = 'added'
GROUP BY p.id
ORDER BY times_added DESC NULLS LAST;

-- View: Métricas de vendas por período
CREATE OR REPLACE VIEW sales_metrics AS
SELECT
  DATE(s.created_at) as sale_date,
  COUNT(DISTINCT s.id) as total_sales,
  COUNT(DISTINCT s.customer_id) as unique_customers,
  SUM(s.total_amount) as total_revenue,
  AVG(s.total_amount) as avg_order_value,
  COUNT(DISTINCT si.product_id) as unique_products_sold,
  SUM(si.quantity) as total_items_sold
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
WHERE s.status != 'cancelled'
GROUP BY DATE(s.created_at)
ORDER BY sale_date DESC;

-- =====================================================
-- 9. FUNCTION PARA REGISTRAR VENDA VIA WEBHOOK
-- =====================================================

CREATE OR REPLACE FUNCTION register_sale_from_webhook(
  p_customer_name TEXT,
  p_customer_phone TEXT,
  p_product_id BIGINT,
  p_unit_price DECIMAL(10,2),
  p_customer_email TEXT DEFAULT NULL,
  p_quantity INTEGER DEFAULT 1,
  p_payment_method TEXT DEFAULT 'pix',
  p_source TEXT DEFAULT 'whatsapp',
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_customer_id BIGINT;
  v_sale_id BIGINT;
  v_total_price DECIMAL(10,2);
BEGIN
  -- Calcular total
  v_total_price := p_unit_price * p_quantity;

  -- Criar ou buscar cliente
  INSERT INTO customers (name, phone, email, source)
  VALUES (p_customer_name, p_customer_phone, p_customer_email, p_source)
  ON CONFLICT (phone) DO UPDATE
  SET name = EXCLUDED.name,
      email = COALESCE(EXCLUDED.email, customers.email),
      updated_at = NOW()
  RETURNING id INTO v_customer_id;

  -- Criar venda
  INSERT INTO sales (customer_id, total_amount, payment_method, status, source, notes)
  VALUES (v_customer_id, v_total_price, p_payment_method, 'paid', p_source, p_notes)
  RETURNING id INTO v_sale_id;

  -- Adicionar item da venda
  INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, total_price)
  VALUES (v_sale_id, p_product_id, p_quantity, p_unit_price, v_total_price);

  -- Diminuir estoque
  PERFORM decrease_product_stock(p_product_id, p_quantity);

  -- Retornar sucesso
  RETURN jsonb_build_object(
    'success', true,
    'sale_id', v_sale_id,
    'customer_id', v_customer_id,
    'total_amount', v_total_price
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICAR
-- =====================================================

SELECT 'Settings' as table_name, COUNT(*) as rows FROM settings
UNION ALL
SELECT 'Team Members', COUNT(*) FROM team_members
UNION ALL
SELECT 'SDR Config', COUNT(*) FROM sdr_config
UNION ALL
SELECT 'Cart Events', COUNT(*) FROM cart_events;

-- Testar views
SELECT * FROM top_selling_products LIMIT 5;
SELECT * FROM top_cart_products LIMIT 5;
SELECT * FROM sales_metrics LIMIT 7;
