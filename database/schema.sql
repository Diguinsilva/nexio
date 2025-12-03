-- =====================================================
-- NEXIO - Schema SQL para Dashboard de Leads
-- =====================================================

-- ENUMS (Tipos Enumerados)
-- =====================================================

-- Segmento
CREATE TYPE segmento_enum AS ENUM (
  'E-commerce',
  'Saúde/Medicina',
  'Educação',
  'Alimentação',
  'Beleza/Estética',
  'Imobiliária',
  'Advocacia',
  'Consultoria',
  'Tecnologia',
  'Moda/Fashion',
  'Arquitetura',
  'Outros'
);

-- Prioridade
CREATE TYPE prioridade_enum AS ENUM (
  'Alta',
  'Média',
  'Baixa'
);

-- Fonte de Importação
CREATE TYPE fonte_importacao_enum AS ENUM (
  'PEG',
  'Linkedin',
  'Interno',
  'Meta Ads',
  'Google Ads',
  'Site/Landing Page',
  'Indicação',
  'WhatsApp',
  'TikTok Ads',
  'E-mail Marketing',
  'Evento/Feira'
);

-- Estágio do Lead
CREATE TYPE estagio_lead_enum AS ENUM (
  'Lead novo',
  'Em contato',
  'Interessado',
  'Proposta enviada',
  'Fechado',
  'Perdido',
  'Remarketing'
);

-- Cargo (Role)
CREATE TYPE cargo_enum AS ENUM (
  'Proprietário/Dono',
  'Gerente Comercial',
  'Vendedor',
  'Representante Comercial',
  'Consultor de Vendas'
);

-- Status do Lead
CREATE TYPE status_lead_enum AS ENUM (
  'Quente 🔥',
  'Morno 🌡️',
  'Frio ❄️'
);

-- =====================================================
-- TABELAS
-- =====================================================

-- Tabela: companies (Empresas)
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  website TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela: users (Usuários)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  department TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela: leads (Principal)
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,

  -- Informações básicas
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company_name TEXT,

  -- Classificação
  segmento segmento_enum,
  prioridade prioridade_enum DEFAULT 'Média',
  status status_lead_enum DEFAULT 'Morno 🌡️',
  estagio estagio_lead_enum DEFAULT 'Lead novo',

  -- Origem
  fonte_importacao fonte_importacao_enum,

  -- Dados de contato
  cargo cargo_enum,
  whatsapp TEXT,
  website TEXT,

  -- Dados de negociação
  valor_projeto NUMERIC(12, 2) DEFAULT 0,
  descricao TEXT,
  observacoes TEXT,

  -- Datas importantes
  data_primeiro_contato TIMESTAMPTZ,
  data_ultima_interacao TIMESTAMPTZ,
  data_fechamento TIMESTAMPTZ,

  -- Controle
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Índices para performance
  INDEX idx_leads_company_id (company_id),
  INDEX idx_leads_estagio (estagio),
  INDEX idx_leads_created_at (created_at),
  INDEX idx_leads_status (status)
);

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================

-- Habilitar RLS nas tabelas
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Políticas para companies
CREATE POLICY "Users can view their own company"
  ON companies FOR SELECT
  USING (id IN (
    SELECT company_id FROM users WHERE auth_user_id = auth.uid()
  ));

-- Políticas para users
CREATE POLICY "Users can view users from their company"
  ON users FOR SELECT
  USING (company_id IN (
    SELECT company_id FROM users WHERE auth_user_id = auth.uid()
  ));

-- Políticas para leads
CREATE POLICY "Users can view leads from their company"
  ON leads FOR SELECT
  USING (company_id IN (
    SELECT company_id FROM users WHERE auth_user_id = auth.uid()
  ));

CREATE POLICY "Users can insert leads for their company"
  ON leads FOR INSERT
  WITH CHECK (company_id IN (
    SELECT company_id FROM users WHERE auth_user_id = auth.uid()
  ));

CREATE POLICY "Users can update leads from their company"
  ON leads FOR UPDATE
  USING (company_id IN (
    SELECT company_id FROM users WHERE auth_user_id = auth.uid()
  ));

CREATE POLICY "Users can delete leads from their company"
  ON leads FOR DELETE
  USING (company_id IN (
    SELECT company_id FROM users WHERE auth_user_id = auth.uid()
  ));

-- =====================================================
-- FUNÇÕES E TRIGGERS
-- =====================================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar updated_at
CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- DADOS DE EXEMPLO (Opcional para testes)
-- =====================================================

-- Inserir empresa de exemplo
INSERT INTO companies (id, name, email, phone) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Empresa Exemplo', 'contato@exemplo.com', '(11) 99999-9999');

-- Inserir alguns leads de exemplo
INSERT INTO leads (company_id, name, email, phone, estagio, status, valor_projeto, created_at) VALUES
  ('00000000-0000-0000-0000-000000000001', 'João Silva', 'joao@email.com', '(11) 91111-1111', 'Lead novo', 'Quente 🔥', 5000.00, NOW() - INTERVAL '1 day'),
  ('00000000-0000-0000-0000-000000000001', 'Maria Santos', 'maria@email.com', '(11) 92222-2222', 'Em contato', 'Quente 🔥', 8000.00, NOW() - INTERVAL '2 days'),
  ('00000000-0000-0000-0000-000000000001', 'Pedro Oliveira', 'pedro@email.com', '(11) 93333-3333', 'Interessado', 'Morno 🌡️', 12000.00, NOW() - INTERVAL '3 days'),
  ('00000000-0000-0000-0000-000000000001', 'Ana Costa', 'ana@email.com', '(11) 94444-4444', 'Proposta enviada', 'Quente 🔥', 15000.00, NOW() - INTERVAL '5 days'),
  ('00000000-0000-0000-0000-000000000001', 'Carlos Mendes', 'carlos@email.com', '(11) 95555-5555', 'Fechado', 'Quente 🔥', 10000.00, NOW() - INTERVAL '7 days');
