-- Migration: Adicionar suporte para múltiplos webhooks SDR
-- Data: 2025-11-23
-- Descrição: Permite configurar múltiplos webhooks para receber eventos de vendas

-- Criar tabela de webhooks
CREATE TABLE IF NOT EXISTS sdr_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  webhook_url TEXT NOT NULL,
  webhook_secret TEXT,
  enabled BOOLEAN DEFAULT true,
  execution_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Campos de monitoramento (mesmo esquema do sdr_config)
  last_call TIMESTAMP WITH TIME ZONE,
  last_status TEXT, -- success, error
  last_error TEXT
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_sdr_webhooks_enabled ON sdr_webhooks(enabled);
CREATE INDEX IF NOT EXISTS idx_sdr_webhooks_order ON sdr_webhooks(execution_order);

-- RLS Policies
ALTER TABLE sdr_webhooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir leitura de sdr_webhooks"
  ON sdr_webhooks FOR SELECT
  USING (true);

CREATE POLICY "Permitir escrita de sdr_webhooks"
  ON sdr_webhooks FOR ALL
  USING (true)
  WITH CHECK (true);

-- Migrar webhook existente (se houver)
DO $$
DECLARE
  existing_config RECORD;
BEGIN
  SELECT * INTO existing_config FROM sdr_config WHERE id = 1;

  IF existing_config.webhook_url IS NOT NULL AND existing_config.webhook_url != '' THEN
    INSERT INTO sdr_webhooks (name, webhook_url, webhook_secret, enabled, execution_order)
    VALUES (
      'Webhook Principal',
      existing_config.webhook_url,
      existing_config.webhook_secret,
      existing_config.webhook_enabled,
      1
    )
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- Comentários para documentação
COMMENT ON TABLE sdr_webhooks IS 'Webhooks configurados para receber eventos de vendas do SDR';
COMMENT ON COLUMN sdr_webhooks.name IS 'Nome identificador do webhook (ex: n8n Principal, Backup, Analytics)';
COMMENT ON COLUMN sdr_webhooks.execution_order IS 'Ordem de execução (menor = primeiro). Webhooks são chamados em paralelo se tiverem a mesma ordem';
COMMENT ON COLUMN sdr_webhooks.last_call IS 'Timestamp da última tentativa de chamada';
COMMENT ON COLUMN sdr_webhooks.last_status IS 'Status da última chamada: success ou error';
COMMENT ON COLUMN sdr_webhooks.last_error IS 'Mensagem de erro da última chamada (se houver)';
