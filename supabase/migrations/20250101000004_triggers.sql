-- Nexio.AI - Database Triggers
-- Migration: 20250101000004_triggers.sql
-- Description: Triggers para automações e auditoria

-- =====================================================
-- 1. TRIGGER: Atualizar last_contact_at ao criar conversa
-- =====================================================
CREATE TRIGGER trigger_update_lead_last_contact
  AFTER INSERT ON conversations
  FOR EACH ROW
  WHEN (NEW.direction = 'in' OR NEW.direction = 'out')
  EXECUTE FUNCTION update_lead_last_contact();

-- =====================================================
-- 2. TRIGGER: Criar audit_log ao modificar lead
-- =====================================================
CREATE OR REPLACE FUNCTION log_lead_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO audit_logs (tenant_id, user_id, action, resource_type, resource_id, meta)
    VALUES (
      NEW.tenant_id,
      NEW.created_by,
      'lead.create',
      'lead',
      NEW.id,
      json_build_object('name', NEW.name, 'source', NEW.source)
    );
    RETURN NEW;

  ELSIF (TG_OP = 'UPDATE') THEN
    -- Log apenas se mudou stage ou status
    IF (OLD.stage != NEW.stage OR OLD.status != NEW.status) THEN
      INSERT INTO audit_logs (tenant_id, user_id, action, resource_type, resource_id, meta)
      VALUES (
        NEW.tenant_id,
        auth.uid(),
        'lead.update',
        'lead',
        NEW.id,
        json_build_object(
          'old_stage', OLD.stage,
          'new_stage', NEW.stage,
          'old_status', OLD.status,
          'new_status', NEW.status
        )
      );
    END IF;
    RETURN NEW;

  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_logs (tenant_id, user_id, action, resource_type, resource_id, meta)
    VALUES (
      OLD.tenant_id,
      auth.uid(),
      'lead.delete',
      'lead',
      OLD.id,
      json_build_object('name', OLD.name, 'stage', OLD.stage)
    );
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_lead_changes
  AFTER INSERT OR UPDATE OR DELETE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION log_lead_changes();

-- =====================================================
-- 3. TRIGGER: Criar audit_log ao enviar mensagem
-- =====================================================
CREATE OR REPLACE FUNCTION log_conversation_sent()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.direction = 'out') THEN
    INSERT INTO audit_logs (tenant_id, user_id, action, resource_type, resource_id, meta)
    VALUES (
      NEW.tenant_id,
      NEW.user_id,
      'conversation.send',
      'conversation',
      NEW.id,
      json_build_object(
        'lead_id', NEW.lead_id,
        'message_type', NEW.message_type,
        'has_media', NEW.media_url IS NOT NULL
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_conversation_sent
  AFTER INSERT ON conversations
  FOR EACH ROW
  WHEN (NEW.direction = 'out')
  EXECUTE FUNCTION log_conversation_sent();

-- =====================================================
-- 4. TRIGGER: Notificar n8n quando lead é criado
-- =====================================================
-- Este trigger pode disparar um webhook ou criar um job n8n
CREATE OR REPLACE FUNCTION notify_n8n_new_lead()
RETURNS TRIGGER AS $$
BEGIN
  -- Inserir job n8n para processar lead
  INSERT INTO n8n_jobs (tenant_id, lead_id, workflow_name, status, input_data)
  VALUES (
    NEW.tenant_id,
    NEW.id,
    'lead-intake',
    'pending',
    json_build_object(
      'lead_id', NEW.id,
      'name', NEW.name,
      'phone', NEW.phone,
      'email', NEW.email,
      'source', NEW.source
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_n8n_new_lead
  AFTER INSERT ON leads
  FOR EACH ROW
  WHEN (NEW.source IN ('maps', 'csv', 'api'))
  EXECUTE FUNCTION notify_n8n_new_lead();

-- =====================================================
-- 5. TRIGGER: Auto-calcular ICP match ao criar lead
-- =====================================================
CREATE OR REPLACE FUNCTION auto_calculate_icp_match()
RETURNS TRIGGER AS $$
BEGIN
  -- Calcular ICP match com valores padrão
  -- (pode ser customizado por tenant futuramente)
  PERFORM calculate_icp_match(
    NEW.id,
    25, -- ideal_age_min
    55, -- ideal_age_max
    5000, -- ideal_income_min
    ARRAY['São Paulo', 'Rio de Janeiro', 'Belo Horizonte'], -- ideal_cities
    NULL -- required_tags
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_calculate_icp_match
  AFTER INSERT ON leads
  FOR EACH ROW
  WHEN (NEW.age IS NOT NULL OR NEW.income_estimate IS NOT NULL OR NEW.city IS NOT NULL)
  EXECUTE FUNCTION auto_calculate_icp_match();

-- =====================================================
-- 6. TRIGGER: Validar telefone brasileiro ao inserir lead
-- =====================================================
CREATE OR REPLACE FUNCTION validate_phone_format()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.phone IS NOT NULL THEN
    -- Remover caracteres não numéricos
    NEW.phone := regexp_replace(NEW.phone, '[^0-9]', '', 'g');

    -- Validar formato brasileiro (10 ou 11 dígitos)
    IF length(NEW.phone) NOT IN (10, 11) THEN
      RAISE NOTICE 'Telefone inválido (formato brasileiro): %', NEW.phone;
      -- Opcional: pode RAISE EXCEPTION para bloquear
    END IF;

    -- Adicionar +55 se não tiver código do país
    IF NOT NEW.phone ~ '^\+?55' THEN
      NEW.phone := '+55' || NEW.phone;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_phone_format
  BEFORE INSERT OR UPDATE ON leads
  FOR EACH ROW
  WHEN (NEW.phone IS NOT NULL)
  EXECUTE FUNCTION validate_phone_format();

-- =====================================================
-- 7. TRIGGER: Soft delete (marcar deleted_at ao invés de DELETE)
-- =====================================================
CREATE OR REPLACE FUNCTION soft_delete_lead()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevenir DELETE físico, fazer soft delete
  UPDATE leads
  SET
    deleted_at = NOW(),
    updated_at = NOW()
  WHERE id = OLD.id;

  -- Retornar NULL para cancelar DELETE físico
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Comentado por padrão - habilitar se quiser forçar soft delete
-- CREATE TRIGGER trigger_soft_delete_lead
--   BEFORE DELETE ON leads
--   FOR EACH ROW
--   EXECUTE FUNCTION soft_delete_lead();

-- =====================================================
-- 8. TRIGGER: Notificar via pg_notify para WebSocket real-time
-- =====================================================
CREATE OR REPLACE FUNCTION notify_lead_change()
RETURNS TRIGGER AS $$
DECLARE
  v_payload JSON;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    v_payload := json_build_object(
      'event', 'lead.created',
      'tenant_id', NEW.tenant_id,
      'lead_id', NEW.id,
      'data', row_to_json(NEW)
    );
  ELSIF (TG_OP = 'UPDATE') THEN
    v_payload := json_build_object(
      'event', 'lead.updated',
      'tenant_id', NEW.tenant_id,
      'lead_id', NEW.id,
      'data', row_to_json(NEW)
    );
  ELSIF (TG_OP = 'DELETE') THEN
    v_payload := json_build_object(
      'event', 'lead.deleted',
      'tenant_id', OLD.tenant_id,
      'lead_id', OLD.id
    );
  END IF;

  PERFORM pg_notify('lead_changes', v_payload::text);

  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_lead_change
  AFTER INSERT OR UPDATE OR DELETE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION notify_lead_change();

-- =====================================================
-- 9. TRIGGER: Notificar nova mensagem para WebSocket
-- =====================================================
CREATE OR REPLACE FUNCTION notify_new_conversation()
RETURNS TRIGGER AS $$
DECLARE
  v_payload JSON;
BEGIN
  v_payload := json_build_object(
    'event', 'conversation.new',
    'tenant_id', NEW.tenant_id,
    'lead_id', NEW.lead_id,
    'conversation_id', NEW.id,
    'direction', NEW.direction,
    'message_type', NEW.message_type,
    'has_transcript', NEW.transcript IS NOT NULL
  );

  PERFORM pg_notify('conversation_updates', v_payload::text);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_new_conversation
  AFTER INSERT ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_conversation();

-- =====================================================
-- COMENTÁRIOS
-- =====================================================
COMMENT ON TRIGGER trigger_update_lead_last_contact ON conversations IS 'Atualiza last_contact_at do lead ao criar conversa';
COMMENT ON TRIGGER trigger_log_lead_changes ON leads IS 'Registra mudanças de lead em audit_logs';
COMMENT ON TRIGGER trigger_log_conversation_sent ON conversations IS 'Registra envio de mensagem em audit_logs';
COMMENT ON TRIGGER trigger_notify_n8n_new_lead ON leads IS 'Cria job n8n ao criar lead de fontes automáticas';
COMMENT ON TRIGGER trigger_auto_calculate_icp_match ON leads IS 'Calcula ICP match score automaticamente';
COMMENT ON TRIGGER trigger_validate_phone_format ON leads IS 'Valida e formata telefone brasileiro';
COMMENT ON TRIGGER trigger_notify_lead_change ON leads IS 'Notifica mudanças de lead via pg_notify para WebSocket';
COMMENT ON TRIGGER trigger_notify_new_conversation ON conversations IS 'Notifica nova mensagem via pg_notify para WebSocket';
