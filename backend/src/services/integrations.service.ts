import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { WhatsAppFactory } from '../integrations/whatsapp/WhatsAppFactory';
import { TranscriptionFactory } from '../integrations/transcription/TranscriptionFactory';
import { IWhatsAppProvider } from '../integrations/whatsapp/IWhatsAppProvider';
import { ITranscriptionProvider } from '../integrations/transcription/ITranscriptionProvider';

/**
 * Serviço central de integrações
 * Busca configurações do tenant no banco e inicializa provedores
 */
export class IntegrationsService {
  private supabase: SupabaseClient;
  private cache: Map<string, any> = new Map(); // Cache de provedores por tenant

  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );
  }

  /**
   * Obtém provedor WhatsApp ativo do tenant
   */
  async getWhatsAppProvider(tenantId: string): Promise<IWhatsAppProvider> {
    const cacheKey = `whatsapp:${tenantId}`;

    // Verificar cache
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    // Buscar integração ativa do tipo WhatsApp
    const { data, error } = await this.supabase
      .rpc('get_active_provider', {
        p_tenant_id: tenantId,
        p_integration_type: 'whatsapp'
      });

    if (error || !data || data.length === 0) {
      throw new Error('No active WhatsApp integration found for this tenant');
    }

    const config = data[0];
    const provider = await WhatsAppFactory.createProvider(
      config.provider_slug,
      config.credentials
    );

    // Cachear por 5 minutos
    this.cache.set(cacheKey, provider);
    setTimeout(() => this.cache.delete(cacheKey), 5 * 60 * 1000);

    return provider;
  }

  /**
   * Obtém provedor de transcrição ativo do tenant
   */
  async getTranscriptionProvider(tenantId: string): Promise<ITranscriptionProvider> {
    const cacheKey = `transcription:${tenantId}`;

    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    const { data, error } = await this.supabase
      .rpc('get_active_provider', {
        p_tenant_id: tenantId,
        p_integration_type: 'transcription'
      });

    if (error || !data || data.length === 0) {
      throw new Error('No active transcription integration found for this tenant');
    }

    const config = data[0];
    const provider = await TranscriptionFactory.createProvider(
      config.provider_slug,
      config.credentials
    );

    this.cache.set(cacheKey, provider);
    setTimeout(() => this.cache.delete(cacheKey), 5 * 60 * 1000);

    return provider;
  }

  /**
   * Lista todas as integrações do tenant
   */
  async listTenantIntegrations(tenantId: string) {
    const { data, error } = await this.supabase
      .from('tenant_integrations')
      .select(`
        *,
        provider:integration_providers(
          slug,
          name,
          logo_url,
          integration_type:integration_types(slug, name, icon)
        )
      `)
      .eq('tenant_id', tenantId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to list integrations: ${error.message}`);
    }

    return data;
  }

  /**
   * Cria nova integração para tenant
   */
  async createIntegration(
    tenantId: string,
    providerSlug: string,
    name: string,
    credentials: Record<string, any>,
    setAsDefault = true
  ) {
    // Buscar provider_id pelo slug
    const { data: provider, error: providerError } = await this.supabase
      .from('integration_providers')
      .select('id, integration_type_id')
      .eq('slug', providerSlug)
      .single();

    if (providerError || !provider) {
      throw new Error(`Provider "${providerSlug}" not found`);
    }

    // Se setAsDefault, desmarcar outras integrações do mesmo tipo
    if (setAsDefault) {
      await this.supabase
        .from('tenant_integrations')
        .update({ is_default: false })
        .eq('tenant_id', tenantId)
        .eq('provider_id', provider.id);
    }

    // Criar integração
    const { data, error } = await this.supabase
      .from('tenant_integrations')
      .insert({
        tenant_id: tenantId,
        provider_id: provider.id,
        name,
        credentials,
        is_default: setAsDefault,
        is_active: true,
        status: 'active',
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create integration: ${error.message}`);
    }

    // Limpar cache desse tenant
    this.clearTenantCache(tenantId);

    return data;
  }

  /**
   * Atualiza integração
   */
  async updateIntegration(
    integrationId: string,
    updates: {
      name?: string;
      credentials?: Record<string, any>;
      is_active?: boolean;
      is_default?: boolean;
    }
  ) {
    const { data, error } = await this.supabase
      .from('tenant_integrations')
      .update(updates)
      .eq('id', integrationId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update integration: ${error.message}`);
    }

    // Limpar cache
    if (data) {
      this.clearTenantCache(data.tenant_id);
    }

    return data;
  }

  /**
   * Deleta integração
   */
  async deleteIntegration(integrationId: string) {
    const { error } = await this.supabase
      .from('tenant_integrations')
      .delete()
      .eq('id', integrationId);

    if (error) {
      throw new Error(`Failed to delete integration: ${error.message}`);
    }
  }

  /**
   * Testa integração (verifica se credenciais estão corretas)
   */
  async testIntegration(
    providerSlug: string,
    credentials: Record<string, any>
  ): Promise<{ success: boolean; message: string }> {
    try {
      // Tentar criar provider baseado no slug
      if (providerSlug.includes('whatsapp') || ['evolution_api', 'zapi', 'uazapi', 'twilio'].includes(providerSlug)) {
        const provider = await WhatsAppFactory.createProvider(providerSlug, credentials);
        const status = await provider.getStatus();

        return {
          success: status.connected,
          message: status.connected ? 'Conectado com sucesso!' : 'Não conectado. Verifique as credenciais.',
        };
      }

      if (providerSlug.includes('transcription') || ['minimax', 'openai_whisper'].includes(providerSlug)) {
        const provider = await TranscriptionFactory.createProvider(providerSlug, credentials);

        return {
          success: true,
          message: 'Credenciais válidas!',
        };
      }

      return {
        success: false,
        message: 'Tipo de provedor desconhecido',
      };
    } catch (error: any) {
      return {
        success: false,
        message: error.message,
      };
    }
  }

  /**
   * Registra uso de integração (para billing)
   */
  async logUsage(
    tenantIntegrationId: string,
    operation: string,
    status: 'success' | 'error',
    metadata?: Record<string, any>
  ) {
    await this.supabase
      .from('integration_usage_logs')
      .insert({
        tenant_integration_id: tenantIntegrationId,
        operation,
        status,
        metadata,
        credits_used: 1,
      });
  }

  /**
   * Limpa cache de um tenant
   */
  private clearTenantCache(tenantId: string) {
    const keysToDelete: string[] = [];

    this.cache.forEach((_, key) => {
      if (key.includes(tenantId)) {
        keysToDelete.push(key);
      }
    });

    keysToDelete.forEach(key => this.cache.delete(key));
  }

  /**
   * Lista provedores disponíveis para configurar
   */
  async listAvailableProviders(integrationType?: string) {
    let query = this.supabase
      .from('integration_providers')
      .select(`
        *,
        integration_type:integration_types(slug, name, category)
      `)
      .eq('is_active', true);

    if (integrationType) {
      query = query.eq('integration_type.slug', integrationType);
    }

    const { data, error } = await query.order('name');

    if (error) {
      throw new Error(`Failed to list providers: ${error.message}`);
    }

    return data;
  }
}

// Exportar instância singleton
export const integrationsService = new IntegrationsService();
