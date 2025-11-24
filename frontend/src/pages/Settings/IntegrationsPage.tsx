import { useState, useEffect } from 'react';
import axios from 'axios';

interface Integration {
  id: string;
  name: string;
  is_active: boolean;
  is_default: boolean;
  status: string;
  provider: {
    slug: string;
    name: string;
    logo_url?: string;
    integration_type: {
      slug: string;
      name: string;
      icon: string;
    };
  };
}

interface Provider {
  id: string;
  slug: string;
  name: string;
  description: string;
  logo_url?: string;
  config_schema: any;
  pricing_info: any;
  integration_type: {
    slug: string;
    name: string;
    category: string;
  };
}

export default function IntegrationsPage() {
  const [integrations, setIntegrations] = useState<Integration[]>([]);
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [integrationsRes, providersRes] = await Promise.all([
        axios.get('/api/integrations'),
        axios.get('/api/integrations/providers'),
      ]);

      setIntegrations(integrationsRes.data.data || []);
      setProviders(providersRes.data.data || []);
    } catch (error) {
      console.error('Error loading integrations:', error);
    } finally {
      setLoading(false);
    }
  };

  const groupedIntegrations = integrations.reduce((acc, integration) => {
    const type = integration.provider.integration_type.name;
    if (!acc[type]) acc[type] = [];
    acc[type].push(integration);
    return acc;
  }, {} as Record<string, Integration[]>);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-lg">Carregando integrações...</div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Integrações
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Conecte serviços externos ao seu CRM. Escolha os provedores que deseja usar.
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="bg-gradient-primary text-white px-6 py-3 rounded-lg font-semibold hover:opacity-90 transition-opacity"
        >
          + Adicionar Integração
        </button>
      </div>

      {/* Integrações Configuradas */}
      {Object.keys(groupedIntegrations).length === 0 ? (
        <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-lg border-2 border-dashed border-gray-300 dark:border-gray-700">
          <div className="text-6xl mb-4">🔌</div>
          <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
            Nenhuma integração configurada
          </h3>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Comece adicionando sua primeira integração para conectar o WhatsApp, transcrição, etc.
          </p>
          <button
            onClick={() => setShowAddModal(true)}
            className="bg-primary text-white px-6 py-3 rounded-lg font-semibold hover:bg-primary-600 transition-colors"
          >
            Adicionar Primeira Integração
          </button>
        </div>
      ) : (
        <div className="space-y-8">
          {Object.entries(groupedIntegrations).map(([type, items]) => (
            <div key={type}>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                <span>{items[0].provider.integration_type.icon}</span>
                {type}
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {items.map((integration) => (
                  <IntegrationCard
                    key={integration.id}
                    integration={integration}
                    onUpdate={loadData}
                  />
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Provedores Disponíveis */}
      <div className="mt-12">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          Provedores Disponíveis
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {providers.map((provider) => (
            <ProviderCard
              key={provider.id}
              provider={provider}
              onAdd={() => {
                // TODO: Abrir modal de configuração
                setShowAddModal(true);
              }}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

// Componente de card de integração
function IntegrationCard({ integration, onUpdate }: { integration: Integration; onUpdate: () => void }) {
  const [isUpdating, setIsUpdating] = useState(false);

  const toggleActive = async () => {
    setIsUpdating(true);
    try {
      await axios.patch(`/api/integrations/${integration.id}`, {
        is_active: !integration.is_active,
      });
      onUpdate();
    } catch (error) {
      console.error('Error updating integration:', error);
    } finally {
      setIsUpdating(false);
    }
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          {integration.provider.logo_url && (
            <img
              src={integration.provider.logo_url}
              alt={integration.provider.name}
              className="w-10 h-10 rounded"
            />
          )}
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-white">
              {integration.name}
            </h3>
            <p className="text-sm text-gray-500">{integration.provider.name}</p>
          </div>
        </div>
        <div className="flex gap-2">
          {integration.is_default && (
            <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">
              Padrão
            </span>
          )}
          <span
            className={`text-xs px-2 py-1 rounded ${
              integration.is_active
                ? 'bg-green-100 text-green-700'
                : 'bg-gray-100 text-gray-700'
            }`}
          >
            {integration.is_active ? 'Ativo' : 'Inativo'}
          </span>
        </div>
      </div>

      <div className="flex gap-2">
        <button
          onClick={toggleActive}
          disabled={isUpdating}
          className="flex-1 px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors disabled:opacity-50"
        >
          {isUpdating ? 'Atualizando...' : integration.is_active ? 'Desativar' : 'Ativar'}
        </button>
        <button className="px-4 py-2 bg-primary text-white rounded hover:bg-primary-600 transition-colors">
          Editar
        </button>
      </div>
    </div>
  );
}

// Componente de card de provedor disponível
function ProviderCard({ provider, onAdd }: { provider: Provider; onAdd: () => void }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 hover:shadow-lg transition-shadow">
      <div className="flex items-center gap-3 mb-4">
        {provider.logo_url && (
          <img
            src={provider.logo_url}
            alt={provider.name}
            className="w-12 h-12 rounded"
          />
        )}
        <div>
          <h3 className="font-semibold text-gray-900 dark:text-white">
            {provider.name}
          </h3>
          <span className="text-xs text-gray-500">
            {provider.integration_type.category}
          </span>
        </div>
      </div>

      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
        {provider.description}
      </p>

      {provider.pricing_info && (
        <div className="text-xs text-gray-500 mb-4">
          💰 {provider.pricing_info.monthly_cost || provider.pricing_info.cost_per_minute}
        </div>
      )}

      <button
        onClick={onAdd}
        className="w-full px-4 py-2 bg-primary text-white rounded hover:bg-primary-600 transition-colors"
      >
        Configurar
      </button>
    </div>
  );
}
