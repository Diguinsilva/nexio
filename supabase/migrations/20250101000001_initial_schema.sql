-- Nexio.AI - Initial Database Schema
-- Migration: 20250101000001_initial_schema.sql
-- Description: Cria tabelas principais do sistema

-- =====================================================
-- 1. TENANTS (Multi-tenancy)
-- =====================================================
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  subdomain VARCHAR(100) UNIQUE,
  plan VARCHAR(50) DEFAULT 'free' CHECK (plan IN ('free', 'starter', 'pro', 'enterprise')),
  settings JSONB DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_tenants_subdomain ON tenants(subdomain);
CREATE INDEX idx_tenants_is_active ON tenants(is_active);

-- =====================================================
-- 2. USERS (Usuários por tenant)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('superadmin', 'admin', 'sdr', 'vendedor', 'analista', 'user')),
  photo_url TEXT,
  bio TEXT,
  phone VARCHAR(50),
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- 3. LEADS (Leads minerados e importados)
-- =====================================================
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Dados básicos
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  email VARCHAR(255),
  company_name VARCHAR(255),

  -- Localização
  city VARCHAR(100),
  state VARCHAR(50),
  address TEXT,

  -- Dados adicionais
  age INTEGER,
  income_estimate DECIMAL(15, 2),
  score INTEGER DEFAULT 0 CHECK (score >= 0 AND score <= 100),

  -- Origem e classificação
  source VARCHAR(100) DEFAULT 'manual' CHECK (source IN ('manual', 'maps', 'csv', 'api', 'n8n')),
  source_url TEXT,
  stage VARCHAR(50) DEFAULT 'new' CHECK (stage IN ('new', 'contacted', 'qualified', 'proposal', 'closed_won', 'closed_lost', 'descartado')),
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),

  -- Tags e notas
  tags JSONB DEFAULT '[]'::jsonb,
  notes TEXT,

  -- Dados brutos (JSON flexível)
  raw_data JSONB DEFAULT '{}'::jsonb,
  enrichment_data JSONB DEFAULT '{}'::jsonb,

  -- ICP Match
  icp_match_score INTEGER DEFAULT 0 CHECK (icp_match_score >= 0 AND icp_match_score <= 100),
  icp_match_reason TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_contact_at TIMESTAMPTZ,

  -- Soft delete
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_leads_tenant_id ON leads(tenant_id);
CREATE INDEX idx_leads_stage ON leads(stage);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_source ON leads(source);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_leads_score ON leads(score DESC);
CREATE INDEX idx_leads_phone ON leads(phone);
CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_tags ON leads USING GIN(tags);

-- =====================================================
-- 4. CONVERSATIONS (Histórico WhatsApp)
-- =====================================================
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Mensagem
  message TEXT,
  message_type VARCHAR(50) DEFAULT 'text' CHECK (message_type IN ('text', 'audio', 'image', 'video', 'document', 'system')),
  direction VARCHAR(10) DEFAULT 'out' CHECK (direction IN ('in', 'out')),

  -- Mídia
  media_url TEXT,
  media_size INTEGER,
  media_duration INTEGER, -- em segundos (para áudio/vídeo)

  -- Transcrição (para áudios)
  transcript TEXT,
  transcript_confidence DECIMAL(5, 4), -- 0.0000 a 1.0000

  -- Metadata
  whatsapp_message_id VARCHAR(255) UNIQUE,
  status VARCHAR(50) DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'failed')),
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
);

CREATE INDEX idx_conversations_tenant_id ON conversations(tenant_id);
CREATE INDEX idx_conversations_lead_id ON conversations(lead_id);
CREATE INDEX idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX idx_conversations_direction ON conversations(direction);
CREATE INDEX idx_conversations_message_type ON conversations(message_type);

-- =====================================================
-- 5. N8N_JOBS (Controle de workflows)
-- =====================================================
CREATE TABLE IF NOT EXISTS n8n_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,

  workflow_name VARCHAR(255) NOT NULL,
  workflow_id VARCHAR(255),
  execution_id VARCHAR(255),

  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),

  input_data JSONB DEFAULT '{}'::jsonb,
  output_data JSONB DEFAULT '{}'::jsonb,
  error_message TEXT,

  logs TEXT,

  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_n8n_jobs_tenant_id ON n8n_jobs(tenant_id);
CREATE INDEX idx_n8n_jobs_lead_id ON n8n_jobs(lead_id);
CREATE INDEX idx_n8n_jobs_status ON n8n_jobs(status);
CREATE INDEX idx_n8n_jobs_workflow_name ON n8n_jobs(workflow_name);
CREATE INDEX idx_n8n_jobs_created_at ON n8n_jobs(created_at DESC);

-- =====================================================
-- 6. ENRICHMENT_LOGS (Histórico de enriquecimento)
-- =====================================================
CREATE TABLE IF NOT EXISTS enrichment_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,

  provider VARCHAR(100) NOT NULL, -- 'clearbit', 'cnpj', 'serpapi', etc
  status VARCHAR(50) DEFAULT 'success' CHECK (status IN ('success', 'failed', 'partial')),

  request_data JSONB DEFAULT '{}'::jsonb,
  result JSONB DEFAULT '{}'::jsonb,
  error_message TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_enrichment_logs_tenant_id ON enrichment_logs(tenant_id);
CREATE INDEX idx_enrichment_logs_lead_id ON enrichment_logs(lead_id);
CREATE INDEX idx_enrichment_logs_provider ON enrichment_logs(provider);
CREATE INDEX idx_enrichment_logs_created_at ON enrichment_logs(created_at DESC);

-- =====================================================
-- 7. AUDIT_LOGS (Auditoria de ações)
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  action VARCHAR(100) NOT NULL, -- 'lead.create', 'lead.update', 'lead.delete', 'conversation.send', etc
  resource_type VARCHAR(100), -- 'lead', 'conversation', 'user', etc
  resource_id UUID,

  ip_address INET,
  user_agent TEXT,

  meta JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- =====================================================
-- 8. TASKS (Tarefas do Kanban/SDR)
-- =====================================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,

  title VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(50) DEFAULT 'follow_up' CHECK (type IN ('follow_up', 'call', 'email', 'proposal', 'meeting', 'other')),
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),

  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_tenant_id ON tasks(tenant_id);
CREATE INDEX idx_tasks_lead_id ON tasks(lead_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- =====================================================
-- 9. IMPORT_JOBS (Jobs de importação CSV/planilha)
-- =====================================================
CREATE TABLE IF NOT EXISTS import_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,

  file_name VARCHAR(255),
  file_url TEXT,
  file_size INTEGER,

  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),

  total_rows INTEGER DEFAULT 0,
  processed_rows INTEGER DEFAULT 0,
  success_rows INTEGER DEFAULT 0,
  failed_rows INTEGER DEFAULT 0,

  mapping JSONB DEFAULT '{}'::jsonb, -- Mapeamento de colunas
  errors JSONB DEFAULT '[]'::jsonb,

  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_import_jobs_tenant_id ON import_jobs(tenant_id);
CREATE INDEX idx_import_jobs_status ON import_jobs(status);
CREATE INDEX idx_import_jobs_created_at ON import_jobs(created_at DESC);

-- =====================================================
-- 10. UPDATED_AT TRIGGER (Auto-update timestamp)
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 11. SEED DATA (Dados iniciais para desenvolvimento)
-- =====================================================
-- Inserir tenant de demonstração
INSERT INTO tenants (id, name, subdomain, plan, is_active)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'Demo Tenant', 'demo', 'pro', TRUE)
ON CONFLICT DO NOTHING;

-- Inserir usuário admin de demonstração (senha deve ser criada via Supabase Auth)
INSERT INTO users (id, tenant_id, email, name, role, is_active)
VALUES
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'admin@demo.nexio.ai', 'Admin Demo', 'admin', TRUE)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE tenants IS 'Tabela de tenants para multi-tenancy';
COMMENT ON TABLE users IS 'Usuários do sistema por tenant';
COMMENT ON TABLE leads IS 'Leads minerados, importados ou criados manualmente';
COMMENT ON TABLE conversations IS 'Histórico de conversas do WhatsApp';
COMMENT ON TABLE n8n_jobs IS 'Controle de execuções de workflows n8n';
COMMENT ON TABLE enrichment_logs IS 'Log de enriquecimento de dados de leads';
COMMENT ON TABLE audit_logs IS 'Auditoria de todas ações do sistema';
COMMENT ON TABLE tasks IS 'Tarefas do Kanban e follow-ups';
COMMENT ON TABLE import_jobs IS 'Jobs de importação de planilhas CSV/Excel';
