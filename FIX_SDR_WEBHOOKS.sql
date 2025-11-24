-- =====================================================
-- FIX: Sistema de Webhooks SDR
-- Data: 23/11/2025
-- =====================================================
-- PROBLEMA: Tabela sdr_webhooks não existe, causando erro 400
-- SOLUÇÃO: Criar tabela e migrar dados existentes
-- =====================================================

-- 1. Criar tabela de webhooks (se não existir)
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

-- 2. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_sdr_webhooks_enabled ON sdr_webhooks(enabled);
CREATE INDEX IF NOT EXISTS idx_sdr_webhooks_order ON sdr_webhooks(execution_order);

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE sdr_webhooks ENABLE ROW LEVEL SECURITY;

-- 4. Dropar políticas antigas (se existirem)
DROP POLICY IF EXISTS "Permitir leitura de sdr_webhooks" ON sdr_webhooks;
DROP POLICY IF EXISTS "Permitir escrita de sdr_webhooks" ON sdr_webhooks;

-- 5. Criar políticas de acesso permissivas
CREATE POLICY "Permitir leitura de sdr_webhooks"
  ON sdr_webhooks FOR SELECT
  USING (true);

CREATE POLICY "Permitir escrita de sdr_webhooks"
  ON sdr_webhooks FOR ALL
  USING (true)
  WITH CHECK (true);

-- 6. Migrar webhook existente de sdr_config para sdr_webhooks (se houver)
DO $$
DECLARE
  existing_config RECORD;
  webhook_exists BOOLEAN;
BEGIN
  -- Verificar se sdr_config existe
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sdr_config') THEN

    -- Buscar configuração existente
    SELECT * INTO existing_config FROM sdr_config WHERE id = 1;

    -- Se houver webhook configurado
    IF existing_config.webhook_url IS NOT NULL AND existing_config.webhook_url != '' THEN

      -- Verificar se já foi migrado
      SELECT EXISTS (
        SELECT 1 FROM sdr_webhooks WHERE webhook_url = existing_config.webhook_url
      ) INTO webhook_exists;

      -- Migrar apenas se ainda não existir
      IF NOT webhook_exists THEN
        INSERT INTO sdr_webhooks (name, webhook_url, webhook_secret, enabled, execution_order)
        VALUES (
          'Webhook Principal (Migrado)',
          existing_config.webhook_url,
          existing_config.webhook_secret,
          COALESCE(existing_config.webhook_enabled, true),
          1
        );

        RAISE NOTICE 'Webhook migrado de sdr_config para sdr_webhooks com sucesso!';
      ELSE
        RAISE NOTICE 'Webhook já existe em sdr_webhooks, pulando migração.';
      END IF;
    ELSE
      RAISE NOTICE 'Nenhum webhook encontrado em sdr_config para migrar.';
    END IF;
  ELSE
    RAISE NOTICE 'Tabela sdr_config não encontrada, pulando migração.';
  END IF;
END $$;

-- 7. Verificar e mostrar resultado
DO $$
DECLARE
  webhook_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO webhook_count FROM sdr_webhooks;
  RAISE NOTICE '✅ Script executado com sucesso!';
  RAISE NOTICE '📊 Total de webhooks configurados: %', webhook_count;

  IF webhook_count = 0 THEN
    RAISE NOTICE '⚠️  Nenhum webhook configurado. Adicione um webhook pela interface.';
  ELSE
    RAISE NOTICE '✅ Sistema de webhooks está pronto para uso!';
  END IF;
END $$;

-- 8. Comentários para documentação
COMMENT ON TABLE sdr_webhooks IS 'Webhooks configurados para receber eventos de vendas do SDR';
COMMENT ON COLUMN sdr_webhooks.name IS 'Nome identificador do webhook (ex: n8n Principal, Backup, Analytics)';
COMMENT ON COLUMN sdr_webhooks.webhook_url IS 'URL completa do webhook n8n';
COMMENT ON COLUMN sdr_webhooks.webhook_secret IS 'Token secreto enviado no header X-Webhook-Secret';
COMMENT ON COLUMN sdr_webhooks.enabled IS 'Se false, o webhook não recebe eventos';
COMMENT ON COLUMN sdr_webhooks.execution_order IS 'Ordem de execução (menor = primeiro). Webhooks com mesma ordem executam em paralelo';
COMMENT ON COLUMN sdr_webhooks.last_call IS 'Timestamp da última tentativa de chamada';
COMMENT ON COLUMN sdr_webhooks.last_status IS 'Status da última chamada: success ou error';
COMMENT ON COLUMN sdr_webhooks.last_error IS 'Mensagem de erro da última chamada (se houver)';

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
-- PRÓXIMOS PASSOS:
-- 1. Execute este script no SQL Editor do Supabase
-- 2. Verifique se a tabela sdr_webhooks foi criada
-- 3. Adicione um webhook pela interface (SDR Config)
-- 4. Teste o webhook clicando em "Testar"
-- =====================================================
