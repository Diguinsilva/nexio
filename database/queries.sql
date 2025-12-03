-- =====================================================
-- NEXIO - Queries SQL para Dashboard FlutterFlow
-- =====================================================
-- Todas as queries consideram filtros de período e company_id
-- Parâmetros: $company_id, $data_inicio, $data_fim
-- =====================================================

-- =====================================================
-- 1. QUERY: Novos Leads (Card)
-- =====================================================
-- Retorna a contagem de leads novos no período
CREATE OR REPLACE FUNCTION get_novos_leads(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS TABLE (
  total_novos_leads BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT
  FROM leads
  WHERE company_id = p_company_id
    AND created_at >= p_data_inicio
    AND created_at <= p_data_fim
    AND estagio = 'Lead novo';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. QUERY: Em Atendimento (Card)
-- =====================================================
-- Retorna a contagem de leads em atendimento no período
CREATE OR REPLACE FUNCTION get_leads_em_atendimento(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS TABLE (
  total_em_atendimento BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT
  FROM leads
  WHERE company_id = p_company_id
    AND created_at >= p_data_inicio
    AND created_at <= p_data_fim
    AND estagio IN ('Em contato', 'Interessado', 'Proposta enviada');
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. QUERY: Taxa de Conversão (Card)
-- =====================================================
-- Calcula a taxa de conversão (leads convertidos / total de leads)
CREATE OR REPLACE FUNCTION get_taxa_conversao(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS TABLE (
  taxa_conversao NUMERIC,
  leads_convertidos BIGINT,
  total_leads BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND((COUNT(*) FILTER (WHERE estagio = 'Fechado')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
    END as taxa_conversao,
    COUNT(*) FILTER (WHERE estagio = 'Fechado')::BIGINT as leads_convertidos,
    COUNT(*)::BIGINT as total_leads
  FROM leads
  WHERE company_id = p_company_id
    AND created_at >= p_data_inicio
    AND created_at <= p_data_fim;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. QUERY: Faturamento (Card)
-- =====================================================
-- Retorna o faturamento total dos leads fechados
CREATE OR REPLACE FUNCTION get_faturamento(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS TABLE (
  faturamento_total NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(SUM(valor_projeto), 0) as faturamento_total
  FROM leads
  WHERE company_id = p_company_id
    AND created_at >= p_data_inicio
    AND created_at <= p_data_fim
    AND estagio = 'Fechado';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. QUERY: Performance de Lead (Gráfico de Barras)
-- =====================================================
-- Retorna dados para o gráfico comparativo
-- Tipo de agrupamento: 'dia', 'semana', 'mes', 'ano'
CREATE OR REPLACE FUNCTION get_performance_lead(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ,
  p_tipo_agrupamento TEXT
)
RETURNS TABLE (
  periodo TEXT,
  periodo_numero INT,
  leads_gerados BIGINT,
  leads_convertidos BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    CASE
      WHEN p_tipo_agrupamento = 'dia' THEN
        TO_CHAR(date_trunc('hour', l.created_at), 'HH24') || 'h'
      WHEN p_tipo_agrupamento = 'semana' THEN
        CASE EXTRACT(DOW FROM l.created_at)::INT
          WHEN 0 THEN 'Dom'
          WHEN 1 THEN 'Seg'
          WHEN 2 THEN 'Ter'
          WHEN 3 THEN 'Qua'
          WHEN 4 THEN 'Qui'
          WHEN 5 THEN 'Sex'
          WHEN 6 THEN 'Sáb'
        END
      WHEN p_tipo_agrupamento = 'mes' THEN
        'Sem ' || EXTRACT(WEEK FROM l.created_at)::TEXT
      WHEN p_tipo_agrupamento = 'ano' THEN
        CASE EXTRACT(MONTH FROM l.created_at)::INT
          WHEN 1 THEN 'Jan'
          WHEN 2 THEN 'Fev'
          WHEN 3 THEN 'Mar'
          WHEN 4 THEN 'Abr'
          WHEN 5 THEN 'Mai'
          WHEN 6 THEN 'Jun'
          WHEN 7 THEN 'Jul'
          WHEN 8 THEN 'Ago'
          WHEN 9 THEN 'Set'
          WHEN 10 THEN 'Out'
          WHEN 11 THEN 'Nov'
          WHEN 12 THEN 'Dez'
        END
    END as periodo,
    CASE
      WHEN p_tipo_agrupamento = 'dia' THEN EXTRACT(HOUR FROM l.created_at)::INT
      WHEN p_tipo_agrupamento = 'semana' THEN EXTRACT(DOW FROM l.created_at)::INT
      WHEN p_tipo_agrupamento = 'mes' THEN EXTRACT(WEEK FROM l.created_at)::INT
      WHEN p_tipo_agrupamento = 'ano' THEN EXTRACT(MONTH FROM l.created_at)::INT
    END as periodo_numero,
    COUNT(*)::BIGINT as leads_gerados,
    COUNT(*) FILTER (WHERE l.estagio = 'Fechado')::BIGINT as leads_convertidos
  FROM leads l
  WHERE l.company_id = p_company_id
    AND l.created_at >= p_data_inicio
    AND l.created_at <= p_data_fim
  GROUP BY periodo, periodo_numero
  ORDER BY periodo_numero;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. QUERY: Taxa de Conversão Geral (Gráfico Circular)
-- =====================================================
-- Retorna dados para o gráfico circular
CREATE OR REPLACE FUNCTION get_taxa_conversao_geral(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS TABLE (
  categoria TEXT,
  quantidade BIGINT,
  percentual NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH totais AS (
    SELECT
      COUNT(*) FILTER (WHERE estagio = 'Fechado')::BIGINT as convertidos,
      COUNT(*) FILTER (WHERE estagio != 'Fechado')::BIGINT as nao_convertidos,
      COUNT(*)::BIGINT as total
    FROM leads
    WHERE company_id = p_company_id
      AND created_at >= p_data_inicio
      AND created_at <= p_data_fim
  )
  SELECT
    'Convertidos'::TEXT as categoria,
    convertidos as quantidade,
    CASE WHEN total > 0 THEN ROUND((convertidos::NUMERIC / total::NUMERIC) * 100, 2) ELSE 0 END as percentual
  FROM totais
  UNION ALL
  SELECT
    'Não Convertidos'::TEXT as categoria,
    nao_convertidos as quantidade,
    CASE WHEN total > 0 THEN ROUND((nao_convertidos::NUMERIC / total::NUMERIC) * 100, 2) ELSE 0 END as percentual
  FROM totais;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. QUERY: Funil de Vendas
-- =====================================================
-- Retorna dados para o funil de vendas
CREATE OR REPLACE FUNCTION get_funil_vendas(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS TABLE (
  estagio TEXT,
  quantidade BIGINT,
  ordem INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    'Novos'::TEXT as estagio,
    COUNT(*) FILTER (WHERE l.estagio = 'Lead novo')::BIGINT as quantidade,
    1 as ordem
  FROM leads l
  WHERE l.company_id = p_company_id
    AND l.created_at >= p_data_inicio
    AND l.created_at <= p_data_fim
  UNION ALL
  SELECT
    'Em contato'::TEXT as estagio,
    COUNT(*) FILTER (WHERE l.estagio = 'Em contato')::BIGINT as quantidade,
    2 as ordem
  FROM leads l
  WHERE l.company_id = p_company_id
    AND l.created_at >= p_data_inicio
    AND l.created_at <= p_data_fim
  UNION ALL
  SELECT
    'Em negociação'::TEXT as estagio,
    COUNT(*) FILTER (WHERE l.estagio IN ('Interessado', 'Proposta enviada'))::BIGINT as quantidade,
    3 as ordem
  FROM leads l
  WHERE l.company_id = p_company_id
    AND l.created_at >= p_data_inicio
    AND l.created_at <= p_data_fim
  UNION ALL
  SELECT
    'Fechados'::TEXT as estagio,
    COUNT(*) FILTER (WHERE l.estagio = 'Fechado')::BIGINT as quantidade,
    4 as ordem
  FROM leads l
  WHERE l.company_id = p_company_id
    AND l.created_at >= p_data_inicio
    AND l.created_at <= p_data_fim
  ORDER BY ordem;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. QUERY: Dashboard Completo (Todos os dados em uma query)
-- =====================================================
-- Retorna todos os dados necessários para o dashboard
CREATE OR REPLACE FUNCTION get_dashboard_completo(
  p_company_id UUID,
  p_data_inicio TIMESTAMPTZ,
  p_data_fim TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'novos_leads', (SELECT total_novos_leads FROM get_novos_leads(p_company_id, p_data_inicio, p_data_fim)),
    'em_atendimento', (SELECT total_em_atendimento FROM get_leads_em_atendimento(p_company_id, p_data_inicio, p_data_fim)),
    'taxa_conversao', (SELECT row_to_json(t) FROM get_taxa_conversao(p_company_id, p_data_inicio, p_data_fim) t),
    'faturamento', (SELECT faturamento_total FROM get_faturamento(p_company_id, p_data_inicio, p_data_fim)),
    'funil_vendas', (SELECT json_agg(row_to_json(t)) FROM get_funil_vendas(p_company_id, p_data_inicio, p_data_fim) t)
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- EXEMPLOS DE USO:
-- =====================================================

-- Exemplo 1: Buscar novos leads de hoje
-- SELECT * FROM get_novos_leads(
--   '00000000-0000-0000-0000-000000000001',
--   CURRENT_DATE,
--   CURRENT_DATE + INTERVAL '1 day'
-- );

-- Exemplo 2: Buscar performance do último mês (agrupado por semana)
-- SELECT * FROM get_performance_lead(
--   '00000000-0000-0000-0000-000000000001',
--   DATE_TRUNC('month', CURRENT_DATE),
--   CURRENT_DATE,
--   'mes'
-- );

-- Exemplo 3: Buscar dashboard completo do último mês
-- SELECT get_dashboard_completo(
--   '00000000-0000-0000-0000-000000000001',
--   DATE_TRUNC('month', CURRENT_DATE),
--   CURRENT_DATE
-- );
