-- ========================================
-- MIGRATION: Sistema Kanban de Leads
-- ========================================
-- Sistema completo de gestão de leads com pipeline visual
-- drag-and-drop entre colunas

-- 1. Tabela de colunas do Kanban (personalizáveis)
CREATE TABLE IF NOT EXISTS kanban_columns (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  color VARCHAR(20) DEFAULT 'gray',
  icon VARCHAR(50),
  order_index INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT true,

  -- Identificadores especiais para lógica de negócio
  column_type VARCHAR(50), -- 'new_lead', 'catalog_sent', 'negotiating', 'closed_won', 'closed_lost'

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(order_index)
);

-- 2. Tabela de Leads
CREATE TABLE IF NOT EXISTS leads (
  id BIGSERIAL PRIMARY KEY,

  -- Informações básicas
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  email VARCHAR(255),
  source VARCHAR(100), -- 'whatsapp', 'website', 'instagram', 'facebook', 'indicacao', 'outro'

  -- Pipeline
  column_id BIGINT,
  order_in_column INTEGER DEFAULT 0,

  -- Informações de contato
  last_contact_date TIMESTAMPTZ,
  next_followup_date TIMESTAMPTZ,

  -- Dados do negócio
  estimated_value DECIMAL(10,2),
  products_interested TEXT[], -- Array de nomes de produtos
  notes TEXT,

  -- Histórico de interações
  interactions_count INTEGER DEFAULT 0,
  catalogs_sent_count INTEGER DEFAULT 0,

  -- Metadados
  assigned_to BIGINT, -- ID do vendedor/SDR (pode ser user_id se implementar multi-usuário)
  tags TEXT[], -- Tags para categorização: ['vip', 'urgente', 'cold', etc]

  -- Status e datas
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'won', 'lost', 'archived'
  won_at TIMESTAMPTZ,
  lost_at TIMESTAMPTZ,
  lost_reason TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(phone) -- Evitar leads duplicados pelo telefone
);

-- Adicionar colunas necessárias caso não existam (para migração de tabelas existentes)
DO $$
BEGIN
  -- column_id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'column_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN column_id BIGINT;
  END IF;

  -- order_in_column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'order_in_column'
  ) THEN
    ALTER TABLE leads ADD COLUMN order_in_column INTEGER DEFAULT 0;
  END IF;

  -- last_contact_date
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'last_contact_date'
  ) THEN
    ALTER TABLE leads ADD COLUMN last_contact_date TIMESTAMPTZ;
  END IF;

  -- next_followup_date
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'next_followup_date'
  ) THEN
    ALTER TABLE leads ADD COLUMN next_followup_date TIMESTAMPTZ;
  END IF;

  -- estimated_value
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'estimated_value'
  ) THEN
    ALTER TABLE leads ADD COLUMN estimated_value DECIMAL(10,2);
  END IF;

  -- products_interested
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'products_interested'
  ) THEN
    ALTER TABLE leads ADD COLUMN products_interested TEXT[];
  END IF;

  -- notes
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'notes'
  ) THEN
    ALTER TABLE leads ADD COLUMN notes TEXT;
  END IF;

  -- company
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'company'
  ) THEN
    ALTER TABLE leads ADD COLUMN company VARCHAR(255);
  END IF;

  -- interactions_count
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'interactions_count'
  ) THEN
    ALTER TABLE leads ADD COLUMN interactions_count INTEGER DEFAULT 0;
  END IF;

  -- catalogs_sent_count
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'catalogs_sent_count'
  ) THEN
    ALTER TABLE leads ADD COLUMN catalogs_sent_count INTEGER DEFAULT 0;
  END IF;

  -- assigned_to
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'assigned_to'
  ) THEN
    ALTER TABLE leads ADD COLUMN assigned_to BIGINT;
  END IF;

  -- tags
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'tags'
  ) THEN
    ALTER TABLE leads ADD COLUMN tags TEXT[];
  END IF;

  -- status
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'status'
  ) THEN
    ALTER TABLE leads ADD COLUMN status VARCHAR(50) DEFAULT 'active';
  END IF;

  -- won_at
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'won_at'
  ) THEN
    ALTER TABLE leads ADD COLUMN won_at TIMESTAMPTZ;
  END IF;

  -- lost_at
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'lost_at'
  ) THEN
    ALTER TABLE leads ADD COLUMN lost_at TIMESTAMPTZ;
  END IF;

  -- lost_reason
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'lost_reason'
  ) THEN
    ALTER TABLE leads ADD COLUMN lost_reason TEXT;
  END IF;
END $$;

-- 3. Tabela de Interações com Leads
CREATE TABLE IF NOT EXISTS lead_interactions (
  id BIGSERIAL PRIMARY KEY,
  lead_id BIGINT NOT NULL REFERENCES leads(id) ON DELETE CASCADE,

  interaction_type VARCHAR(50) NOT NULL, -- 'call', 'whatsapp', 'email', 'meeting', 'catalog_sent', 'note'
  description TEXT,

  -- Dados específicos
  catalog_url TEXT, -- Se enviou catálogo
  products_shown TEXT[], -- Produtos mostrados

  -- Metadados
  created_by BIGINT, -- ID do usuário que registrou
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabela de histórico de movimentação no Kanban
CREATE TABLE IF NOT EXISTS lead_movements (
  id BIGSERIAL PRIMARY KEY,
  lead_id BIGINT NOT NULL REFERENCES leads(id) ON DELETE CASCADE,

  from_column_id BIGINT REFERENCES kanban_columns(id),
  to_column_id BIGINT NOT NULL REFERENCES kanban_columns(id),

  moved_by BIGINT, -- ID do usuário
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Inserir colunas padrão do Kanban
INSERT INTO kanban_columns (name, description, color, icon, order_index, column_type) VALUES
  ('Novo Lead', 'Leads que acabaram de chegar', 'blue', 'UserPlus', 0, 'new_lead'),
  ('Catálogo Enviado', 'Aguardando retorno após envio do catálogo', 'yellow', 'Send', 1, 'catalog_sent'),
  ('Em Negociação', 'Leads interessados, negociando valores', 'purple', 'MessageCircle', 2, 'negotiating'),
  ('Fechado', 'Vendas concretizadas', 'green', 'CheckCircle', 3, 'closed_won'),
  ('Perdido', 'Leads que não converteram', 'red', 'XCircle', 4, 'closed_lost')
ON CONFLICT (order_index) DO NOTHING;

-- 6. Adicionar constraints de NOT NULL e foreign key APÓS inserir as colunas padrão
DO $$
BEGIN
  -- Atualizar leads sem column_id para a primeira coluna (Novo Lead)
  UPDATE leads
  SET column_id = (SELECT id FROM kanban_columns WHERE column_type = 'new_lead' LIMIT 1)
  WHERE column_id IS NULL;

  -- Adicionar NOT NULL constraint se ainda não existir
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'column_id' AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE leads ALTER COLUMN column_id SET NOT NULL;
  END IF;

  -- Adicionar foreign key se ainda não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'leads_column_id_fkey' AND table_name = 'leads'
  ) THEN
    ALTER TABLE leads ADD CONSTRAINT leads_column_id_fkey
      FOREIGN KEY (column_id) REFERENCES kanban_columns(id) ON DELETE RESTRICT;
  END IF;
END $$;

-- 7. Função para mover lead entre colunas
CREATE OR REPLACE FUNCTION move_lead_to_column(
  p_lead_id BIGINT,
  p_to_column_id BIGINT,
  p_moved_by BIGINT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_from_column_id BIGINT;
  v_column_type VARCHAR(50);
BEGIN
  -- Pegar coluna atual
  SELECT column_id INTO v_from_column_id
  FROM leads
  WHERE id = p_lead_id;

  -- Atualizar lead
  UPDATE leads
  SET column_id = p_to_column_id,
      updated_at = NOW(),
      last_contact_date = NOW()
  WHERE id = p_lead_id;

  -- Verificar se moveu para coluna de "ganho" ou "perdido"
  SELECT column_type INTO v_column_type
  FROM kanban_columns
  WHERE id = p_to_column_id;

  IF v_column_type = 'closed_won' THEN
    UPDATE leads
    SET status = 'won',
        won_at = NOW()
    WHERE id = p_lead_id;
  ELSIF v_column_type = 'closed_lost' THEN
    UPDATE leads
    SET status = 'lost',
        lost_at = NOW(),
        lost_reason = p_notes
    WHERE id = p_lead_id;
  END IF;

  -- Registrar movimento
  INSERT INTO lead_movements (lead_id, from_column_id, to_column_id, moved_by, notes)
  VALUES (p_lead_id, v_from_column_id, p_to_column_id, p_moved_by, p_notes);
END;
$$;

-- 8. Função para registrar interação
CREATE OR REPLACE FUNCTION add_lead_interaction(
  p_lead_id BIGINT,
  p_interaction_type VARCHAR(50),
  p_description TEXT DEFAULT NULL,
  p_catalog_url TEXT DEFAULT NULL,
  p_products_shown TEXT[] DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  v_interaction_id BIGINT;
BEGIN
  -- Inserir interação
  INSERT INTO lead_interactions (
    lead_id, interaction_type, description, catalog_url, products_shown
  )
  VALUES (
    p_lead_id, p_interaction_type, p_description, p_catalog_url, p_products_shown
  )
  RETURNING id INTO v_interaction_id;

  -- Atualizar contador de interações
  UPDATE leads
  SET interactions_count = interactions_count + 1,
      last_contact_date = NOW()
  WHERE id = p_lead_id;

  -- Se enviou catálogo, incrementar contador
  IF p_interaction_type = 'catalog_sent' THEN
    UPDATE leads
    SET catalogs_sent_count = catalogs_sent_count + 1
    WHERE id = p_lead_id;
  END IF;

  RETURN v_interaction_id;
END;
$$;

-- 9. View para estatísticas do Kanban
CREATE OR REPLACE VIEW kanban_stats AS
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

-- 10. View para leads com informações enriquecidas
CREATE OR REPLACE VIEW leads_with_stats AS
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

-- 11. Políticas RLS
ALTER TABLE kanban_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_movements ENABLE ROW LEVEL SECURITY;

-- Apenas autenticados podem ver e gerenciar leads
CREATE POLICY "Apenas autenticados podem ver colunas do kanban"
  ON kanban_columns FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Apenas autenticados podem atualizar colunas"
  ON kanban_columns FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Apenas autenticados podem ver leads"
  ON leads FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Apenas autenticados podem ver interações"
  ON lead_interactions FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Apenas autenticados podem ver movimentações"
  ON lead_movements FOR SELECT
  TO authenticated
  USING (true);

-- 12. Índices para performance
CREATE INDEX IF NOT EXISTS idx_leads_column ON leads(column_id);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone);
CREATE INDEX IF NOT EXISTS idx_leads_next_followup ON leads(next_followup_date);
CREATE INDEX IF NOT EXISTS idx_lead_interactions_lead ON lead_interactions(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_movements_lead ON lead_movements(lead_id);

-- 13. Triggers
CREATE OR REPLACE FUNCTION update_lead_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_lead_timestamp
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_lead_timestamp();

CREATE TRIGGER trigger_update_kanban_column_timestamp
  BEFORE UPDATE ON kanban_columns
  FOR EACH ROW
  EXECUTE FUNCTION update_lead_timestamp();

-- ========================================
-- EXEMPLOS DE USO
-- ========================================

-- Exemplo 1: Adicionar novo lead
-- INSERT INTO leads (name, phone, email, source, column_id, estimated_value)
-- VALUES ('João Silva', '11999887766', 'joao@email.com', 'whatsapp', 1, 500.00);

-- Exemplo 2: Mover lead para próxima coluna
-- SELECT move_lead_to_column(1, 2, NULL, 'Cliente demonstrou interesse');

-- Exemplo 3: Registrar interação (envio de catálogo)
-- SELECT add_lead_interaction(
--   1,
--   'catalog_sent',
--   'Enviado catálogo completo de verão',
--   'https://catalogo.com/verao2025',
--   ARRAY['Camisa Polo', 'Bermuda Jeans']
-- );

-- Exemplo 4: Ver estatísticas do Kanban
-- SELECT * FROM kanban_stats;

-- Exemplo 5: Buscar leads com followup atrasado
-- SELECT * FROM leads_with_stats WHERE is_followup_overdue = true;

COMMENT ON TABLE leads IS 'Leads e prospects do sistema de vendas';
COMMENT ON TABLE kanban_columns IS 'Colunas personalizáveis do Kanban de leads';
COMMENT ON TABLE lead_interactions IS 'Histórico de todas as interações com leads';
COMMENT ON TABLE lead_movements IS 'Histórico de movimentação de leads entre colunas';
COMMENT ON FUNCTION move_lead_to_column IS 'Move lead entre colunas do Kanban e registra no histórico';
COMMENT ON FUNCTION add_lead_interaction IS 'Registra nova interação com lead e atualiza contadores';
