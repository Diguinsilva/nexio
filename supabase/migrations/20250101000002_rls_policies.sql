-- Nexio.AI - Row Level Security (RLS) Policies
-- Migration: 20250101000002_rls_policies.sql
-- Description: Políticas de segurança para multi-tenancy

-- =====================================================
-- HABILITAR RLS EM TODAS AS TABELAS
-- =====================================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE n8n_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrichment_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_jobs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- FUNÇÃO HELPER: Pegar tenant_id do JWT
-- =====================================================
CREATE OR REPLACE FUNCTION auth.tenant_id()
RETURNS UUID AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID,
    (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
  );
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT AS $$
  SELECT COALESCE(
    auth.jwt() -> 'app_metadata' ->> 'role',
    auth.jwt() -> 'user_metadata' ->> 'role',
    'user'
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- =====================================================
-- POLÍTICAS: TENANTS
-- =====================================================
-- Usuários podem ver apenas seu próprio tenant
CREATE POLICY "Users can view their own tenant"
  ON tenants FOR SELECT
  USING (id = auth.tenant_id());

-- Apenas admins podem atualizar tenant
CREATE POLICY "Admins can update their tenant"
  ON tenants FOR UPDATE
  USING (
    id = auth.tenant_id() AND
    auth.user_role() IN ('admin', 'superadmin')
  );

-- =====================================================
-- POLÍTICAS: USERS
-- =====================================================
-- Usuários podem ver membros do seu tenant
CREATE POLICY "Users can view members of their tenant"
  ON users FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Usuários podem atualizar seu próprio perfil
CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

-- Admins podem criar/atualizar/deletar usuários do tenant
CREATE POLICY "Admins can manage users in their tenant"
  ON users FOR ALL
  USING (
    tenant_id = auth.tenant_id() AND
    auth.user_role() IN ('admin', 'superadmin')
  );

-- =====================================================
-- POLÍTICAS: LEADS
-- =====================================================
-- Usuários podem ver leads do seu tenant
CREATE POLICY "Users can view leads of their tenant"
  ON leads FOR SELECT
  USING (
    tenant_id = auth.tenant_id() AND
    deleted_at IS NULL
  );

-- Usuários podem criar leads no seu tenant
CREATE POLICY "Users can create leads in their tenant"
  ON leads FOR INSERT
  WITH CHECK (tenant_id = auth.tenant_id());

-- Usuários podem atualizar leads do seu tenant
CREATE POLICY "Users can update leads in their tenant"
  ON leads FOR UPDATE
  USING (tenant_id = auth.tenant_id());

-- Apenas admins podem deletar leads (soft delete)
CREATE POLICY "Admins can delete leads in their tenant"
  ON leads FOR DELETE
  USING (
    tenant_id = auth.tenant_id() AND
    auth.user_role() IN ('admin', 'superadmin')
  );

-- =====================================================
-- POLÍTICAS: CONVERSATIONS
-- =====================================================
-- Usuários podem ver conversas de leads do seu tenant
CREATE POLICY "Users can view conversations of their tenant"
  ON conversations FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Usuários podem criar conversas no seu tenant
CREATE POLICY "Users can create conversations in their tenant"
  ON conversations FOR INSERT
  WITH CHECK (tenant_id = auth.tenant_id());

-- Usuários podem atualizar conversas do seu tenant (ex: marcar como lida)
CREATE POLICY "Users can update conversations in their tenant"
  ON conversations FOR UPDATE
  USING (tenant_id = auth.tenant_id());

-- =====================================================
-- POLÍTICAS: N8N_JOBS
-- =====================================================
-- Usuários podem ver jobs do seu tenant
CREATE POLICY "Users can view n8n jobs of their tenant"
  ON n8n_jobs FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Sistema (service role) pode criar/atualizar jobs
-- (Será usado pelo backend com service_role_key)
CREATE POLICY "Service role can manage n8n jobs"
  ON n8n_jobs FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- POLÍTICAS: ENRICHMENT_LOGS
-- =====================================================
-- Usuários podem ver logs de enriquecimento do seu tenant
CREATE POLICY "Users can view enrichment logs of their tenant"
  ON enrichment_logs FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Sistema pode criar logs de enriquecimento
CREATE POLICY "Service role can create enrichment logs"
  ON enrichment_logs FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- POLÍTICAS: AUDIT_LOGS
-- =====================================================
-- Admins podem ver logs de auditoria do seu tenant
CREATE POLICY "Admins can view audit logs of their tenant"
  ON audit_logs FOR SELECT
  USING (
    tenant_id = auth.tenant_id() AND
    auth.user_role() IN ('admin', 'superadmin')
  );

-- Sistema pode criar logs de auditoria
CREATE POLICY "Service role can create audit logs"
  ON audit_logs FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- POLÍTICAS: TASKS
-- =====================================================
-- Usuários podem ver tarefas do seu tenant
CREATE POLICY "Users can view tasks of their tenant"
  ON tasks FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Usuários podem criar tarefas no seu tenant
CREATE POLICY "Users can create tasks in their tenant"
  ON tasks FOR INSERT
  WITH CHECK (tenant_id = auth.tenant_id());

-- Usuários podem atualizar tarefas atribuídas a eles
CREATE POLICY "Users can update their assigned tasks"
  ON tasks FOR UPDATE
  USING (
    tenant_id = auth.tenant_id() AND
    (assigned_to = auth.uid() OR auth.user_role() IN ('admin', 'superadmin'))
  );

-- Admins podem deletar tarefas
CREATE POLICY "Admins can delete tasks in their tenant"
  ON tasks FOR DELETE
  USING (
    tenant_id = auth.tenant_id() AND
    auth.user_role() IN ('admin', 'superadmin')
  );

-- =====================================================
-- POLÍTICAS: IMPORT_JOBS
-- =====================================================
-- Usuários podem ver jobs de importação do seu tenant
CREATE POLICY "Users can view import jobs of their tenant"
  ON import_jobs FOR SELECT
  USING (tenant_id = auth.tenant_id());

-- Usuários podem criar jobs de importação no seu tenant
CREATE POLICY "Users can create import jobs in their tenant"
  ON import_jobs FOR INSERT
  WITH CHECK (tenant_id = auth.tenant_id());

-- Sistema pode atualizar status de jobs de importação
CREATE POLICY "Service role can update import jobs"
  ON import_jobs FOR UPDATE
  USING (true);

-- =====================================================
-- GRANT PERMISSIONS (Service Role)
-- =====================================================
-- Permitir que service_role bypass RLS quando necessário
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Permitir authenticated users acesso às tabelas
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =====================================================
-- COMENTÁRIOS
-- =====================================================
COMMENT ON FUNCTION auth.tenant_id() IS 'Extrai tenant_id do JWT do usuário autenticado';
COMMENT ON FUNCTION auth.user_role() IS 'Extrai role do JWT do usuário autenticado';
