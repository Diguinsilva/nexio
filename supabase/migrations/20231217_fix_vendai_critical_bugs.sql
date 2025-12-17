-- =====================================================
-- Migration: Fix vend.AI Critical Bugs
-- Data: 2023-12-17
-- Descrição: Correções para ICP read-only e contador de leads
-- =====================================================

-- =====================================================
-- PARTE 1: Estrutura de tabelas
-- =====================================================

-- Tabela companies (garantir que existe com campos necessários)
CREATE TABLE IF NOT EXISTS companies (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    plan_type TEXT DEFAULT 'Performance',
    plan_monthly_limit INTEGER DEFAULT 70,
    leads_extracted_this_month INTEGER DEFAULT 0,
    last_extraction_month TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adicionar campos se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='companies' AND column_name='leads_extracted_this_month') THEN
        ALTER TABLE companies ADD COLUMN leads_extracted_this_month INTEGER DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='companies' AND column_name='last_extraction_month') THEN
        ALTER TABLE companies ADD COLUMN last_extraction_month TEXT;
    END IF;
END $$;

-- Tabela users
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
    email TEXT,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela icp_configuration (configuração do ICP)
CREATE TABLE IF NOT EXISTS icp_configuration (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE NOT NULL,

    -- Dados demográficos
    idade_min INTEGER,
    idade_max INTEGER,
    renda_min DECIMAL(10,2),
    renda_max DECIMAL(10,2),
    genero TEXT,
    escolaridade TEXT,
    estados TEXT[],
    regioes TEXT[],

    -- Dados empresariais
    tamanho_empresa TEXT,
    tempo_mercado TEXT,
    empresa_funcionarios INTEGER,

    -- Segmentos e canais
    nicho TEXT[],
    nichos TEXT[], -- alias para compatibilidade
    canais TEXT[],

    -- Preferências de contato
    preferencia_contato TEXT,
    horario TEXT,
    linguagem TEXT,
    ciclo_compra TEXT,

    -- Comportamento
    comprou_online BOOLEAN DEFAULT FALSE,
    influenciador BOOLEAN DEFAULT FALSE,

    -- Budget
    budget_min DECIMAL(10,2),
    budget_max DECIMAL(10,2),

    -- Dores e objetivos
    dores TEXT,
    objetivos TEXT,

    -- Configurações de entrega
    leads_por_dia_max INTEGER DEFAULT 3,
    leads_desejados INTEGER, -- alias para compatibilidade
    usar_ia BOOLEAN DEFAULT TRUE,
    entregar_fins_semana BOOLEAN DEFAULT FALSE,
    prioridade TEXT DEFAULT 'Média',
    notificar_novos_leads BOOLEAN DEFAULT TRUE,

    -- Auditoria
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),

    UNIQUE(company_id)
);

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_icp_configuration_company_id ON icp_configuration(company_id);

-- Tabela ICP_leads (leads gerados)
CREATE TABLE IF NOT EXISTS "ICP_leads" (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
    icp_id BIGINT REFERENCES icp_configuration(id) ON DELETE SET NULL,

    -- Dados do lead
    nome TEXT,
    empresa TEXT,
    company_name TEXT, -- alias para compatibilidade
    email TEXT,
    whatsapp TEXT,
    cidade TEXT,
    estado TEXT,
    segmento TEXT,
    segment TEXT, -- alias para compatibilidade

    -- Status e prioridade
    status TEXT DEFAULT 'Lead novo',
    prioridade TEXT DEFAULT 'Média',
    priority TEXT, -- alias para compatibilidade

    -- Observações
    observacoes TEXT,

    -- Auditoria
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    extracted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_icp_leads_company_id ON "ICP_leads"(company_id);
CREATE INDEX IF NOT EXISTS idx_icp_leads_icp_id ON "ICP_leads"(icp_id);
CREATE INDEX IF NOT EXISTS idx_icp_leads_created_at ON "ICP_leads"(created_at);
CREATE INDEX IF NOT EXISTS idx_icp_leads_status ON "ICP_leads"(status);

-- =====================================================
-- PARTE 2: Row Level Security (RLS)
-- =====================================================

-- Habilitar RLS nas tabelas
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE icp_configuration ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ICP_leads" ENABLE ROW LEVEL SECURITY;

-- Políticas para companies
DROP POLICY IF EXISTS "Users can view their own company" ON companies;
CREATE POLICY "Users can view their own company" ON companies
    FOR SELECT
    USING (
        id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own company" ON companies;
CREATE POLICY "Users can update their own company" ON companies
    FOR UPDATE
    USING (
        id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Políticas para users
DROP POLICY IF EXISTS "Users can view users in their company" ON users;
CREATE POLICY "Users can view users in their company" ON users
    FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Políticas para icp_configuration (READ-ONLY para usuários comuns)
DROP POLICY IF EXISTS "Users can view their company ICP config" ON icp_configuration;
CREATE POLICY "Users can view their company ICP config" ON icp_configuration
    FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- IMPORTANTE: Apenas admins podem inserir/atualizar ICP configs
-- Usuários comuns NÃO podem editar (removemos as políticas de INSERT/UPDATE)

-- Políticas para ICP_leads
DROP POLICY IF EXISTS "Users can view their company leads" ON "ICP_leads";
CREATE POLICY "Users can view their company leads" ON "ICP_leads"
    FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their company leads" ON "ICP_leads";
CREATE POLICY "Users can update their company leads" ON "ICP_leads"
    FOR UPDATE
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their company leads" ON "ICP_leads";
CREATE POLICY "Users can delete their company leads" ON "ICP_leads"
    FOR DELETE
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- =====================================================
-- PARTE 3: Funções auxiliares
-- =====================================================

-- Função para contar leads extraídos no mês atual
CREATE OR REPLACE FUNCTION count_monthly_leads_extracted(p_company_id BIGINT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
    v_current_month TEXT;
BEGIN
    -- Formato: YYYY-MM
    v_current_month := TO_CHAR(NOW(), 'YYYY-MM');

    -- Contar leads criados no mês atual
    SELECT COUNT(*)
    INTO v_count
    FROM "ICP_leads"
    WHERE company_id = p_company_id
      AND TO_CHAR(created_at, 'YYYY-MM') = v_current_month;

    RETURN COALESCE(v_count, 0);
END;
$$;

-- Função para atualizar contador de leads automaticamente
CREATE OR REPLACE FUNCTION update_company_leads_counter()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_month TEXT;
    v_count INTEGER;
BEGIN
    v_current_month := TO_CHAR(NOW(), 'YYYY-MM');

    -- Contar leads do mês atual
    SELECT count_monthly_leads_extracted(NEW.company_id)
    INTO v_count;

    -- Atualizar contador na tabela companies
    UPDATE companies
    SET
        leads_extracted_this_month = v_count,
        last_extraction_month = v_current_month,
        updated_at = NOW()
    WHERE id = NEW.company_id;

    RETURN NEW;
END;
$$;

-- Trigger para atualizar contador automaticamente ao inserir lead
DROP TRIGGER IF EXISTS trigger_update_leads_counter ON "ICP_leads";
CREATE TRIGGER trigger_update_leads_counter
    AFTER INSERT ON "ICP_leads"
    FOR EACH ROW
    EXECUTE FUNCTION update_company_leads_counter();

-- =====================================================
-- PARTE 4: Função para reset mensal automático
-- =====================================================

-- Função para resetar contadores mensais (deve ser executada via cron job)
CREATE OR REPLACE FUNCTION reset_monthly_counters_if_needed()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_month TEXT;
BEGIN
    v_current_month := TO_CHAR(NOW(), 'YYYY-MM');

    -- Resetar contador de empresas onde o mês mudou
    UPDATE companies
    SET
        leads_extracted_this_month = 0,
        last_extraction_month = v_current_month,
        updated_at = NOW()
    WHERE last_extraction_month IS NULL
       OR last_extraction_month < v_current_month;
END;
$$;

-- =====================================================
-- PARTE 5: Dados iniciais e correções
-- =====================================================

-- Corrigir contadores existentes baseado nos dados reais
DO $$
DECLARE
    r RECORD;
    v_count INTEGER;
    v_current_month TEXT;
BEGIN
    v_current_month := TO_CHAR(NOW(), 'YYYY-MM');

    FOR r IN SELECT id FROM companies
    LOOP
        -- Contar leads reais do mês
        SELECT count_monthly_leads_extracted(r.id)
        INTO v_count;

        -- Atualizar com valor correto
        UPDATE companies
        SET
            leads_extracted_this_month = v_count,
            last_extraction_month = v_current_month,
            updated_at = NOW()
        WHERE id = r.id;
    END LOOP;
END $$;

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON TABLE icp_configuration IS 'Configuração do ICP (Ideal Customer Profile) - READ-ONLY para usuários, editável apenas por admins';
COMMENT ON TABLE "ICP_leads" IS 'Leads gerados baseados na configuração do ICP';
COMMENT ON FUNCTION count_monthly_leads_extracted(BIGINT) IS 'Conta dinamicamente quantos leads foram extraídos no mês atual para uma empresa';
COMMENT ON FUNCTION update_company_leads_counter() IS 'Trigger function que atualiza automaticamente o contador de leads ao inserir novo lead';
COMMENT ON COLUMN companies.leads_extracted_this_month IS 'Contador de leads extraídos no mês atual - atualizado automaticamente';
COMMENT ON COLUMN companies.last_extraction_month IS 'Último mês de extração no formato YYYY-MM';

-- =====================================================
-- FIM DA MIGRATION
-- =====================================================
