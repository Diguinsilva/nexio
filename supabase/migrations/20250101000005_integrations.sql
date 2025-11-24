-- =====================================================
-- NEXIO.AI - SISTEMA DE INTEGRAÇÕES MODULAR
-- Migration 5: Tabelas de Integrações Plugáveis
-- =====================================================

-- Tabela de tipos de integrações disponíveis
CREATE TABLE IF NOT EXISTS integration_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug VARCHAR(50) UNIQUE NOT NULL, -- 'whatsapp', 'transcription', 'crm', 'email'
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL, -- 'messaging', 'ai', 'crm', 'analytics'
  icon VARCHAR(100), -- URL do ícone
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de provedores para cada tipo de integração
CREATE TABLE IF NOT EXISTS integration_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_type_id UUID NOT NULL REFERENCES integration_types(id) ON DELETE CASCADE,
  slug VARCHAR(50) UNIQUE NOT NULL, -- 'evolution_api', 'zapi', 'uazapi', 'minimax', 'whisper'
  name VARCHAR(100) NOT NULL, -- 'Evolution API', 'Zapi', 'Minimax'
  description TEXT,
  logo_url VARCHAR(255),
  documentation_url VARCHAR(255),
  pricing_info JSONB, -- informações de preço
  config_schema JSONB NOT NULL, -- JSON Schema dos campos de configuração necessários
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de integrações configuradas por tenant
CREATE TABLE IF NOT EXISTS tenant_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES integration_providers(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL, -- nome customizado pelo usuário
  credentials JSONB NOT NULL, -- credenciais criptografadas
  config JSONB DEFAULT '{}'::jsonb, -- configurações adicionais
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false, -- se é o provedor padrão para aquele tipo
  last_sync_at TIMESTAMPTZ,
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'error', 'disabled'
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Um tenant não pode ter dois provedores do mesmo tipo como default
  UNIQUE(tenant_id, provider_id)
);

-- Índices para performance
CREATE INDEX idx_tenant_integrations_tenant ON tenant_integrations(tenant_id);
CREATE INDEX idx_tenant_integrations_provider ON tenant_integrations(provider_id);
CREATE INDEX idx_tenant_integrations_active ON tenant_integrations(tenant_id, is_active);

-- Logs de uso das integrações (para billing futuro)
CREATE TABLE IF NOT EXISTS integration_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_integration_id UUID NOT NULL REFERENCES tenant_integrations(id) ON DELETE CASCADE,
  operation VARCHAR(100) NOT NULL, -- 'send_message', 'transcribe_audio', etc
  status VARCHAR(50) NOT NULL, -- 'success', 'error'
  metadata JSONB, -- dados adicionais da operação
  credits_used INTEGER DEFAULT 1, -- para futuro sistema de créditos
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_integration_usage_logs_tenant ON integration_usage_logs(tenant_integration_id, created_at DESC);

-- =====================================================
-- DADOS INICIAIS: Tipos de Integrações
-- =====================================================

INSERT INTO integration_types (slug, name, description, category, icon) VALUES
('whatsapp', 'WhatsApp', 'Integração com WhatsApp Business para envio e recebimento de mensagens', 'messaging', '💬'),
('transcription', 'Transcrição de Áudio', 'Conversão de áudio para texto (STT - Speech to Text)', 'ai', '🎙️'),
('tts', 'Text-to-Speech', 'Conversão de texto para áudio', 'ai', '🔊'),
('llm', 'Modelo de Linguagem (LLM)', 'Geração de texto com IA (GPT, Claude, etc)', 'ai', '🤖'),
('scraping', 'Web Scraping', 'Extração de dados de sites e mapas', 'data', '🔍'),
('crm', 'CRM Externo', 'Sincronização com CRMs externos', 'crm', '📊'),
('email', 'E-mail Marketing', 'Envio de e-mails em massa', 'messaging', '📧');

-- =====================================================
-- DADOS INICIAIS: Provedores WhatsApp
-- =====================================================

INSERT INTO integration_providers (integration_type_id, slug, name, description, logo_url, config_schema, pricing_info) VALUES
(
  (SELECT id FROM integration_types WHERE slug = 'whatsapp'),
  'evolution_api',
  'Evolution API',
  'API WhatsApp self-hosted, gratuita e open-source. Ideal para começar.',
  'https://evolution-api.com/logo.png',
  '{
    "type": "object",
    "required": ["api_url", "api_key", "instance"],
    "properties": {
      "api_url": {
        "type": "string",
        "title": "URL da API",
        "description": "URL base da sua instância Evolution API",
        "default": "http://localhost:8080",
        "example": "https://evolution.seudominio.com"
      },
      "api_key": {
        "type": "string",
        "title": "API Key",
        "description": "Chave de autenticação da API",
        "secret": true
      },
      "instance": {
        "type": "string",
        "title": "Nome da Instância",
        "description": "Nome da instância WhatsApp conectada"
      }
    }
  }',
  '{"monthly_cost": "R$ 0-50", "setup_cost": "Grátis", "notes": "Self-hosted, você paga apenas a VPS"}'
),
(
  (SELECT id FROM integration_types WHERE slug = 'whatsapp'),
  'zapi',
  'Zapi',
  'API WhatsApp brasileira, estável e confiável. R$ 50-100/mês.',
  'https://zapi.me/logo.png',
  '{
    "type": "object",
    "required": ["instance_id", "token"],
    "properties": {
      "instance_id": {
        "type": "string",
        "title": "Instance ID",
        "description": "ID da sua instância Zapi"
      },
      "token": {
        "type": "string",
        "title": "Token",
        "description": "Token de autenticação",
        "secret": true
      },
      "webhook_url": {
        "type": "string",
        "title": "Webhook URL (opcional)",
        "description": "URL para receber notificações"
      }
    }
  }',
  '{"monthly_cost": "R$ 50-100", "free_trial": "7 dias", "stability": "99.5% uptime"}'
),
(
  (SELECT id FROM integration_types WHERE slug = 'whatsapp'),
  'uazapi',
  'Uazapi',
  'API WhatsApp com recursos avançados. R$ 70-150/mês.',
  'https://uazapi.cloud/logo.png',
  '{
    "type": "object",
    "required": ["instance_id", "token"],
    "properties": {
      "instance_id": {
        "type": "string",
        "title": "Instance ID",
        "description": "ID da sua instância Uazapi"
      },
      "token": {
        "type": "string",
        "title": "Token",
        "description": "Token de autenticação",
        "secret": true
      }
    }
  }',
  '{"monthly_cost": "R$ 70-150", "features": "Grupos, listas de transmissão, campanhas"}'
),
(
  (SELECT id FROM integration_types WHERE slug = 'whatsapp'),
  'twilio',
  'Twilio',
  'API oficial WhatsApp Business. Mais caro, porém 100% confiável.',
  'https://twilio.com/logo.png',
  '{
    "type": "object",
    "required": ["account_sid", "auth_token", "whatsapp_number"],
    "properties": {
      "account_sid": {
        "type": "string",
        "title": "Account SID",
        "description": "Account SID da sua conta Twilio"
      },
      "auth_token": {
        "type": "string",
        "title": "Auth Token",
        "description": "Token de autenticação",
        "secret": true
      },
      "whatsapp_number": {
        "type": "string",
        "title": "Número WhatsApp",
        "description": "Número WhatsApp Business registrado",
        "example": "+5511999999999"
      }
    }
  }',
  '{"monthly_cost": "R$ 200-500", "pay_per_use": true, "official": true}'
);

-- =====================================================
-- DADOS INICIAIS: Provedores de Transcrição
-- =====================================================

INSERT INTO integration_providers (integration_type_id, slug, name, description, config_schema, pricing_info) VALUES
(
  (SELECT id FROM integration_types WHERE slug = 'transcription'),
  'minimax',
  'Minimax',
  'Transcrição de áudio humanizada, ideal para PT-BR.',
  '{
    "type": "object",
    "required": ["api_key"],
    "properties": {
      "api_key": {
        "type": "string",
        "title": "API Key",
        "description": "Chave da API Minimax",
        "secret": true
      },
      "model": {
        "type": "string",
        "title": "Modelo",
        "default": "speech-01",
        "enum": ["speech-01"]
      }
    }
  }',
  '{"cost_per_minute": "~R$ 0.03", "quality": "Muito humanizado para PT-BR"}'
),
(
  (SELECT id FROM integration_types WHERE slug = 'transcription'),
  'openai_whisper',
  'OpenAI Whisper',
  'Transcrição da OpenAI, precisa e rápida.',
  '{
    "type": "object",
    "required": ["api_key"],
    "properties": {
      "api_key": {
        "type": "string",
        "title": "API Key OpenAI",
        "description": "Chave da API OpenAI",
        "secret": true
      },
      "model": {
        "type": "string",
        "title": "Modelo",
        "default": "whisper-1",
        "enum": ["whisper-1"]
      }
    }
  }',
  '{"cost_per_minute": "~$0.006", "quality": "Preciso, menos humanizado"}'
),
(
  (SELECT id FROM integration_types WHERE slug = 'transcription'),
  'assemblyai',
  'AssemblyAI',
  'Transcrição profissional com análise de sentimentos.',
  '{
    "type": "object",
    "required": ["api_key"],
    "properties": {
      "api_key": {
        "type": "string",
        "title": "API Key",
        "secret": true
      }
    }
  }',
  '{"cost_per_minute": "~$0.015", "features": "Sentiment analysis, speaker diarization"}'
);

-- =====================================================
-- DADOS INICIAIS: Provedores LLM
-- =====================================================

INSERT INTO integration_providers (integration_type_id, slug, name, description, config_schema, pricing_info) VALUES
(
  (SELECT id FROM integration_types WHERE slug = 'llm'),
  'openai_gpt4',
  'OpenAI GPT-4o',
  'Modelo de linguagem mais avançado da OpenAI.',
  '{
    "type": "object",
    "required": ["api_key"],
    "properties": {
      "api_key": {
        "type": "string",
        "title": "API Key OpenAI",
        "secret": true
      },
      "model": {
        "type": "string",
        "title": "Modelo",
        "default": "gpt-4o",
        "enum": ["gpt-4o", "gpt-4o-mini"]
      },
      "temperature": {
        "type": "number",
        "title": "Temperature",
        "default": 0.7,
        "minimum": 0,
        "maximum": 2
      }
    }
  }',
  '{"cost_per_1k_tokens": "$0.0025-0.01", "best_for": "Geração de mensagens complexas"}'
),
(
  (SELECT id FROM integration_types WHERE slug = 'llm'),
  'anthropic_claude',
  'Anthropic Claude',
  'Modelo de IA da Anthropic, excelente para conversas longas.',
  '{
    "type": "object",
    "required": ["api_key"],
    "properties": {
      "api_key": {
        "type": "string",
        "title": "API Key Anthropic",
        "secret": true
      },
      "model": {
        "type": "string",
        "default": "claude-3-5-sonnet-20241022",
        "enum": ["claude-3-5-sonnet-20241022", "claude-3-haiku-20240307"]
      }
    }
  }',
  '{"cost_per_1k_tokens": "$0.003-0.015", "context_window": "200k tokens"}'
);

-- =====================================================
-- DADOS INICIAIS: Provedores de Scraping
-- =====================================================

INSERT INTO integration_providers (integration_type_id, slug, name, description, config_schema, pricing_info) VALUES
(
  (SELECT id FROM integration_types WHERE slug = 'scraping'),
  'apify',
  'Apify',
  'Plataforma de scraping profissional com Google Maps Scraper.',
  '{
    "type": "object",
    "required": ["api_token"],
    "properties": {
      "api_token": {
        "type": "string",
        "title": "API Token",
        "description": "Token da API Apify",
        "secret": true
      },
      "actor_id": {
        "type": "string",
        "title": "Actor ID (opcional)",
        "description": "ID do actor customizado",
        "default": "compass/google-maps-scraper"
      }
    }
  }',
  '{"free_tier": "$5 de crédito", "cost_per_1k_results": "~$2-5"}'
);

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE tenant_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_usage_logs ENABLE ROW LEVEL SECURITY;

-- Usuários só veem integrações do próprio tenant
CREATE POLICY "Users can view their tenant integrations"
  ON tenant_integrations FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Usuários podem criar integrações no próprio tenant
CREATE POLICY "Users can create integrations for their tenant"
  ON tenant_integrations FOR INSERT
  WITH CHECK (tenant_id = auth.tenant_id());

-- Usuários podem atualizar integrações do próprio tenant
CREATE POLICY "Users can update their tenant integrations"
  ON tenant_integrations FOR UPDATE
  USING (tenant_id = auth.tenant_id());

-- Usuários podem deletar integrações do próprio tenant
CREATE POLICY "Users can delete their tenant integrations"
  ON tenant_integrations FOR DELETE
  USING (tenant_id = auth.tenant_id());

-- Logs são somente leitura para o tenant
CREATE POLICY "Users can view their integration logs"
  ON integration_usage_logs FOR SELECT
  USING (
    tenant_integration_id IN (
      SELECT id FROM tenant_integrations WHERE tenant_id = auth.tenant_id()
    )
  );

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Função para obter provedor ativo de um tipo
CREATE OR REPLACE FUNCTION get_active_provider(
  p_tenant_id UUID,
  p_integration_type VARCHAR
)
RETURNS TABLE (
  provider_slug VARCHAR,
  credentials JSONB,
  config JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ip.slug,
    ti.credentials,
    ti.config
  FROM tenant_integrations ti
  JOIN integration_providers ip ON ti.provider_id = ip.id
  JOIN integration_types it ON ip.integration_type_id = it.id
  WHERE ti.tenant_id = p_tenant_id
    AND it.slug = p_integration_type
    AND ti.is_active = true
    AND ti.is_default = true
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_tenant_integration_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tenant_integration_updated_at
  BEFORE UPDATE ON tenant_integrations
  FOR EACH ROW
  EXECUTE FUNCTION update_tenant_integration_updated_at();

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE integration_types IS 'Tipos de integrações disponíveis no sistema (WhatsApp, Transcrição, etc)';
COMMENT ON TABLE integration_providers IS 'Provedores específicos para cada tipo (Evolution, Zapi, Minimax, etc)';
COMMENT ON TABLE tenant_integrations IS 'Integrações configuradas e ativas por tenant';
COMMENT ON TABLE integration_usage_logs IS 'Logs de uso para billing e analytics';
