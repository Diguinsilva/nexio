-- Nexio.AI - Database Functions
-- Migration: 20250101000003_functions.sql
-- Description: Funções úteis para queries e lógica de negócio

-- =====================================================
-- 1. FUNÇÃO: Buscar leads com filtros avançados
-- =====================================================
CREATE OR REPLACE FUNCTION search_leads(
  p_tenant_id UUID,
  p_search_term TEXT DEFAULT NULL,
  p_stage TEXT DEFAULT NULL,
  p_source TEXT DEFAULT NULL,
  p_min_score INTEGER DEFAULT NULL,
  p_tags JSONB DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  phone VARCHAR,
  email VARCHAR,
  city VARCHAR,
  score INTEGER,
  stage VARCHAR,
  source VARCHAR,
  tags JSONB,
  created_at TIMESTAMPTZ,
  last_contact_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.name,
    l.phone,
    l.email,
    l.city,
    l.score,
    l.stage,
    l.source,
    l.tags,
    l.created_at,
    l.last_contact_at
  FROM leads l
  WHERE
    l.tenant_id = p_tenant_id
    AND l.deleted_at IS NULL
    AND (p_search_term IS NULL OR (
      l.name ILIKE '%' || p_search_term || '%' OR
      l.phone ILIKE '%' || p_search_term || '%' OR
      l.email ILIKE '%' || p_search_term || '%' OR
      l.company_name ILIKE '%' || p_search_term || '%'
    ))
    AND (p_stage IS NULL OR l.stage = p_stage)
    AND (p_source IS NULL OR l.source = p_source)
    AND (p_min_score IS NULL OR l.score >= p_min_score)
    AND (p_tags IS NULL OR l.tags @> p_tags)
  ORDER BY l.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 2. FUNÇÃO: Estatísticas do Dashboard
-- =====================================================
CREATE OR REPLACE FUNCTION get_dashboard_stats(p_tenant_id UUID)
RETURNS JSON AS $$
DECLARE
  v_stats JSON;
BEGIN
  SELECT json_build_object(
    'total_leads', COUNT(*),
    'leads_today', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE),
    'leads_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
    'leads_this_month', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'),
    'by_stage', (
      SELECT json_object_agg(stage, count)
      FROM (
        SELECT stage, COUNT(*) as count
        FROM leads
        WHERE tenant_id = p_tenant_id AND deleted_at IS NULL
        GROUP BY stage
      ) stage_counts
    ),
    'by_source', (
      SELECT json_object_agg(source, count)
      FROM (
        SELECT source, COUNT(*) as count
        FROM leads
        WHERE tenant_id = p_tenant_id AND deleted_at IS NULL
        GROUP BY source
      ) source_counts
    ),
    'avg_score', ROUND(AVG(score), 2),
    'high_score_leads', COUNT(*) FILTER (WHERE score >= 70),
    'conversion_rate', ROUND(
      CAST(COUNT(*) FILTER (WHERE stage IN ('proposal', 'closed_won')) AS DECIMAL) /
      NULLIF(COUNT(*), 0) * 100, 2
    )
  ) INTO v_stats
  FROM leads
  WHERE tenant_id = p_tenant_id AND deleted_at IS NULL;

  RETURN v_stats;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 3. FUNÇÃO: Calcular ICP Match Score
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_icp_match(
  p_lead_id UUID,
  p_ideal_age_min INTEGER DEFAULT 25,
  p_ideal_age_max INTEGER DEFAULT 55,
  p_ideal_income_min DECIMAL DEFAULT 5000,
  p_ideal_cities TEXT[] DEFAULT NULL,
  p_required_tags TEXT[] DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_lead RECORD;
  v_score INTEGER := 0;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_max_score INTEGER := 100;
BEGIN
  SELECT * INTO v_lead FROM leads WHERE id = p_lead_id;

  IF NOT FOUND THEN
    RETURN json_build_object('score', 0, 'reasons', ARRAY['Lead não encontrado']);
  END IF;

  -- Pontuação por idade
  IF v_lead.age IS NOT NULL THEN
    IF v_lead.age BETWEEN p_ideal_age_min AND p_ideal_age_max THEN
      v_score := v_score + 25;
      v_reasons := array_append(v_reasons, format('Idade ideal (%s anos)', v_lead.age));
    ELSE
      v_reasons := array_append(v_reasons, format('Idade fora do ideal (%s anos)', v_lead.age));
    END IF;
  END IF;

  -- Pontuação por renda
  IF v_lead.income_estimate IS NOT NULL THEN
    IF v_lead.income_estimate >= p_ideal_income_min THEN
      v_score := v_score + 25;
      v_reasons := array_append(v_reasons, format('Renda adequada (R$ %.2f)', v_lead.income_estimate));
    ELSE
      v_reasons := array_append(v_reasons, format('Renda baixa (R$ %.2f)', v_lead.income_estimate));
    END IF;
  END IF;

  -- Pontuação por cidade
  IF p_ideal_cities IS NOT NULL AND v_lead.city IS NOT NULL THEN
    IF v_lead.city = ANY(p_ideal_cities) THEN
      v_score := v_score + 25;
      v_reasons := array_append(v_reasons, format('Cidade ideal (%s)', v_lead.city));
    ELSE
      v_reasons := array_append(v_reasons, format('Cidade não prioritária (%s)', v_lead.city));
    END IF;
  END IF;

  -- Pontuação por tags
  IF p_required_tags IS NOT NULL THEN
    DECLARE
      v_tag TEXT;
      v_tags_match INTEGER := 0;
    BEGIN
      FOREACH v_tag IN ARRAY p_required_tags LOOP
        IF v_lead.tags ? v_tag THEN
          v_tags_match := v_tags_match + 1;
        END IF;
      END LOOP;

      IF v_tags_match = array_length(p_required_tags, 1) THEN
        v_score := v_score + 25;
        v_reasons := array_append(v_reasons, 'Todas tags requeridas presentes');
      ELSIF v_tags_match > 0 THEN
        v_score := v_score + 10;
        v_reasons := array_append(v_reasons, format('%s de %s tags presentes', v_tags_match, array_length(p_required_tags, 1)));
      END IF;
    END;
  END IF;

  -- Atualizar lead com score calculado
  UPDATE leads
  SET
    icp_match_score = v_score,
    icp_match_reason = array_to_string(v_reasons, '; ')
  WHERE id = p_lead_id;

  RETURN json_build_object(
    'score', v_score,
    'reasons', v_reasons
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. FUNÇÃO: Deduplicate leads por telefone
-- =====================================================
CREATE OR REPLACE FUNCTION deduplicate_leads_by_phone(p_tenant_id UUID)
RETURNS TABLE (
  phone VARCHAR,
  kept_id UUID,
  duplicate_ids UUID[]
) AS $$
BEGIN
  RETURN QUERY
  WITH duplicates AS (
    SELECT
      l.phone,
      array_agg(l.id ORDER BY l.created_at ASC) as all_ids
    FROM leads l
    WHERE
      l.tenant_id = p_tenant_id
      AND l.phone IS NOT NULL
      AND l.deleted_at IS NULL
    GROUP BY l.phone
    HAVING COUNT(*) > 1
  )
  SELECT
    d.phone,
    d.all_ids[1] as kept_id,
    d.all_ids[2:array_length(d.all_ids, 1)] as duplicate_ids
  FROM duplicates d;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. FUNÇÃO: Obter próximos follow-ups
-- =====================================================
CREATE OR REPLACE FUNCTION get_upcoming_followups(
  p_tenant_id UUID,
  p_days_ahead INTEGER DEFAULT 7
)
RETURNS TABLE (
  lead_id UUID,
  lead_name VARCHAR,
  lead_phone VARCHAR,
  last_contact_at TIMESTAMPTZ,
  days_since_contact INTEGER,
  suggested_action TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.name,
    l.phone,
    l.last_contact_at,
    EXTRACT(DAY FROM NOW() - l.last_contact_at)::INTEGER as days_since_contact,
    CASE
      WHEN EXTRACT(DAY FROM NOW() - l.last_contact_at) >= 7 THEN 'Follow-up urgente'
      WHEN EXTRACT(DAY FROM NOW() - l.last_contact_at) >= 3 THEN 'Follow-up programado'
      ELSE 'Contato recente'
    END as suggested_action
  FROM leads l
  WHERE
    l.tenant_id = p_tenant_id
    AND l.deleted_at IS NULL
    AND l.stage NOT IN ('closed_won', 'closed_lost', 'descartado')
    AND l.last_contact_at IS NOT NULL
    AND l.last_contact_at <= NOW() - INTERVAL '1 day' * (p_days_ahead - 7)
  ORDER BY l.last_contact_at ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 6. FUNÇÃO: Exportar leads para CSV format
-- =====================================================
CREATE OR REPLACE FUNCTION export_leads_csv(
  p_tenant_id UUID,
  p_stage TEXT DEFAULT NULL
)
RETURNS TABLE (
  name TEXT,
  phone TEXT,
  email TEXT,
  company_name TEXT,
  city TEXT,
  state TEXT,
  score TEXT,
  stage TEXT,
  created_at TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.name::TEXT,
    l.phone::TEXT,
    l.email::TEXT,
    l.company_name::TEXT,
    l.city::TEXT,
    l.state::TEXT,
    l.score::TEXT,
    l.stage::TEXT,
    to_char(l.created_at, 'YYYY-MM-DD HH24:MI:SS')::TEXT
  FROM leads l
  WHERE
    l.tenant_id = p_tenant_id
    AND l.deleted_at IS NULL
    AND (p_stage IS NULL OR l.stage = p_stage)
  ORDER BY l.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 7. FUNÇÃO: Atualizar last_contact_at ao criar conversa
-- =====================================================
CREATE OR REPLACE FUNCTION update_lead_last_contact()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE leads
  SET last_contact_at = NEW.created_at
  WHERE id = NEW.lead_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMENTÁRIOS
-- =====================================================
COMMENT ON FUNCTION search_leads IS 'Busca leads com filtros avançados (texto, stage, source, score, tags)';
COMMENT ON FUNCTION get_dashboard_stats IS 'Retorna estatísticas agregadas para o dashboard';
COMMENT ON FUNCTION calculate_icp_match IS 'Calcula score de match com ICP (Ideal Customer Profile)';
COMMENT ON FUNCTION deduplicate_leads_by_phone IS 'Identifica leads duplicados por telefone';
COMMENT ON FUNCTION get_upcoming_followups IS 'Lista leads que precisam de follow-up';
COMMENT ON FUNCTION export_leads_csv IS 'Exporta leads em formato CSV';
COMMENT ON FUNCTION update_lead_last_contact IS 'Atualiza last_contact_at quando conversa é criada';
