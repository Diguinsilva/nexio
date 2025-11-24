import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { toast } from 'react-toastify';
import {
  Webhook,
  Save,
  Loader,
  CheckCircle,
  XCircle,
  Zap,
  AlertCircle,
  Key,
  Link as LinkIcon,
  BookOpen,
  Trash2,
  Plus,
  Edit2,
  X
} from 'lucide-react';

// Toggle Switch Component
const ToggleSwitch = ({ checked, onChange, label, description }) => (
  <div className="flex items-center justify-between py-2">
    <div className="flex-1">
      <p className="text-sm font-medium text-gray-900">{label}</p>
      {description && <p className="text-xs text-gray-500 mt-0.5">{description}</p>}
    </div>
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2 ${
        checked ? 'bg-green-500' : 'bg-gray-200'
      }`}
    >
      <span
        className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
          checked ? 'translate-x-6' : 'translate-x-1'
        }`}
      />
    </button>
  </div>
);

// Card individual de webhook
const WebhookCard = ({ webhook, onUpdate, onDelete, onTest }) => {
  const [editing, setEditing] = useState(false);
  const [formData, setFormData] = useState(webhook);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      const { error } = await supabase
        .from('sdr_webhooks')
        .update({
          name: formData.name,
          webhook_url: formData.webhook_url,
          webhook_secret: formData.webhook_secret,
          enabled: formData.enabled,
          execution_order: formData.execution_order,
          updated_at: new Date().toISOString()
        })
        .eq('id', webhook.id);

      if (error) throw error;

      toast.success(`✅ Webhook "${formData.name}" atualizado!`);
      setEditing(false);
      onUpdate();
    } catch (error) {
      console.error('Erro ao salvar:', error);
      toast.error('❌ Erro ao salvar: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  const handleToggle = async (enabled) => {
    try {
      const { error } = await supabase
        .from('sdr_webhooks')
        .update({ enabled, updated_at: new Date().toISOString() })
        .eq('id', webhook.id);

      if (error) throw error;

      toast.success(`✅ Webhook ${enabled ? 'ativado' : 'desativado'}!`);
      onUpdate();
    } catch (error) {
      console.error('Erro ao atualizar:', error);
      toast.error('❌ Erro: ' + error.message);
    }
  };

  const handleTest = async () => {
    setTesting(true);
    try {
      await onTest(webhook.id);
    } finally {
      setTesting(false);
    }
  };

  const isRecent = webhook.last_call &&
    (new Date() - new Date(webhook.last_call)) < 24 * 60 * 60 * 1000; // 24h

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      {/* Header */}
      <div className={`px-6 py-4 border-b flex items-center justify-between ${
        webhook.enabled ? 'bg-green-50 border-green-200' : 'bg-gray-50 border-gray-200'
      }`}>
        <div className="flex items-center gap-3">
          <Webhook className={`w-5 h-5 ${webhook.enabled ? 'text-green-600' : 'text-gray-400'}`} />
          <div>
            <h3 className="font-bold text-gray-900">{webhook.name}</h3>
            <p className="text-xs text-gray-500">Ordem: {webhook.execution_order}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setEditing(!editing)}
            className="p-2 hover:bg-white rounded-lg transition-colors"
            title="Editar"
          >
            {editing ? <X className="w-4 h-4" /> : <Edit2 className="w-4 h-4" />}
          </button>
          <ToggleSwitch
            checked={webhook.enabled}
            onChange={handleToggle}
            label=""
          />
        </div>
      </div>

      {/* Body */}
      <div className="p-6 space-y-4">
        {editing ? (
          /* Modo de edição */
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Nome</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
                placeholder="n8n Principal"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                <LinkIcon className="w-4 h-4" />
                URL do Webhook
              </label>
              <input
                type="url"
                value={formData.webhook_url}
                onChange={(e) => setFormData({ ...formData, webhook_url: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 font-mono text-sm"
                placeholder="https://seu-n8n.com/webhook/..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                <Key className="w-4 h-4" />
                Secret/Token (opcional)
              </label>
              <input
                type="password"
                value={formData.webhook_secret || ''}
                onChange={(e) => setFormData({ ...formData, webhook_secret: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 font-mono text-sm"
                placeholder="seu-token-secreto"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Ordem de Execução</label>
              <input
                type="number"
                value={formData.execution_order}
                onChange={(e) => setFormData({ ...formData, execution_order: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
                min="0"
              />
              <p className="text-xs text-gray-500 mt-1">Webhooks com mesma ordem são executados em paralelo</p>
            </div>

            <div className="flex flex-col sm:flex-row gap-2 pt-2">
              <button
                onClick={handleSave}
                disabled={saving}
                className="w-full sm:flex-1 px-4 py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 flex items-center justify-center gap-2 font-medium disabled:opacity-50"
              >
                {saving ? <Loader className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                Salvar
              </button>
              <button
                onClick={() => {
                  setEditing(false);
                  setFormData(webhook);
                }}
                className="w-full sm:w-auto px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancelar
              </button>
            </div>
          </>
        ) : (
          /* Modo de visualização */
          <>
            <div className="space-y-2">
              <div>
                <p className="text-xs text-gray-500">URL</p>
                <p className="text-sm font-mono text-gray-900 break-all">{webhook.webhook_url}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Secret</p>
                <p className="text-sm text-gray-700">{webhook.webhook_secret ? '••••••••••••••••' : 'Não configurado'}</p>
              </div>
            </div>

            {/* Status da última chamada */}
            {webhook.last_call && isRecent && (
              <div className={`p-3 rounded-lg border ${
                webhook.last_status === 'success'
                  ? 'bg-green-50 border-green-200'
                  : 'bg-red-50 border-red-200'
              }`}>
                <div className="flex items-center gap-2 mb-1">
                  {webhook.last_status === 'success' ? (
                    <CheckCircle className="w-4 h-4 text-green-600" />
                  ) : (
                    <XCircle className="w-4 h-4 text-red-600" />
                  )}
                  <p className={`text-sm font-medium ${
                    webhook.last_status === 'success' ? 'text-green-900' : 'text-red-900'
                  }`}>
                    {webhook.last_status === 'success' ? 'Última chamada: Sucesso' : 'Última chamada: Erro'}
                  </p>
                </div>
                <p className="text-xs text-gray-600">
                  {new Date(webhook.last_call).toLocaleString('pt-BR')}
                </p>
                {webhook.last_error && (
                  <p className="text-xs font-mono text-red-700 mt-2 bg-white p-2 rounded border border-red-200">
                    {webhook.last_error}
                  </p>
                )}
              </div>
            )}

            <div className="flex flex-col sm:flex-row gap-2 pt-2">
              <button
                onClick={handleTest}
                disabled={testing}
                className="w-full sm:flex-1 px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 flex items-center justify-center gap-2 font-medium disabled:opacity-50"
              >
                {testing ? <Loader className="w-4 h-4 animate-spin" /> : <Zap className="w-4 h-4" />}
                Testar
              </button>
              <button
                onClick={() => onDelete(webhook.id, webhook.name)}
                className="w-full sm:w-auto px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 flex items-center justify-center gap-2 font-medium"
              >
                <Trash2 className="w-4 h-4" />
                Deletar
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default function SDRConfigMultiple() {
  const [loading, setLoading] = useState(true);
  const [webhooks, setWebhooks] = useState([]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newWebhook, setNewWebhook] = useState({
    name: '',
    webhook_url: '',
    webhook_secret: '',
    enabled: true,
    execution_order: 1
  });

  useEffect(() => {
    loadWebhooks();
  }, []);

  const loadWebhooks = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('sdr_webhooks')
        .select('*')
        .order('execution_order', { ascending: true });

      if (error) throw error;

      setWebhooks(data || []);
    } catch (error) {
      console.error('Erro ao carregar webhooks:', error);
      toast.error('❌ Erro ao carregar webhooks');
    } finally {
      setLoading(false);
    }
  };

  const handleAddWebhook = async () => {
    if (!newWebhook.name || !newWebhook.webhook_url) {
      toast.warning('⚠️ Preencha nome e URL');
      return;
    }

    try {
      const { error } = await supabase
        .from('sdr_webhooks')
        .insert([newWebhook]);

      if (error) throw error;

      toast.success(`✅ Webhook "${newWebhook.name}" adicionado!`);
      setShowAddForm(false);
      setNewWebhook({
        name: '',
        webhook_url: '',
        webhook_secret: '',
        enabled: true,
        execution_order: 1
      });
      loadWebhooks();
    } catch (error) {
      console.error('Erro ao adicionar:', error);
      toast.error('❌ Erro ao adicionar: ' + error.message);
    }
  };

  const handleDeleteWebhook = async (id, name) => {
    if (!confirm(`Tem certeza que deseja deletar o webhook "${name}"?`)) {
      return;
    }

    try {
      const { error } = await supabase
        .from('sdr_webhooks')
        .delete()
        .eq('id', id);

      if (error) throw error;

      toast.success(`✅ Webhook "${name}" deletado!`);
      loadWebhooks();
    } catch (error) {
      console.error('Erro ao deletar:', error);
      toast.error('❌ Erro ao deletar: ' + error.message);
    }
  };

  const handleTestWebhook = async (webhookId) => {
    const webhook = webhooks.find(w => w.id === webhookId);

    const testPayload = {
      event_type: 'test',
      test: true,
      message: 'Este é um webhook de teste do Lukaya Griffe ERP',
      timestamp: new Date().toISOString(),
      data: {
        product_id: 1,
        product_name: 'Produto Teste',
        quantity: 1,
        total_value: 100.00,
        customer: {
          phone: '+5511999999999',
          name: 'Cliente Teste'
        },
        payment_method: 'pix',
        source: 'test'
      }
    };

    try {
      const supabaseUrl = supabase.supabaseUrl;
      const functionUrl = `${supabaseUrl}/functions/v1/send-webhook`;
      const { data: { session } } = await supabase.auth.getSession();

      const response = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${session?.access_token || ''}`
        },
        body: JSON.stringify({
          payload: testPayload,
          webhook_id: webhookId
        })
      });

      const result = await response.json();

      if (result.success) {
        toast.success(`✅ Webhook "${webhook.name}" testado com sucesso!`);
      } else {
        toast.error(`❌ Erro ao testar "${webhook.name}": ${result.error || 'Erro desconhecido'}`);
      }

      loadWebhooks();
    } catch (error) {
      console.error('Erro ao testar webhook:', error);
      toast.error('❌ Erro ao testar: ' + error.message);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader className="w-8 h-8 animate-spin text-yellow-500" />
      </div>
    );
  }

  return (
    <div className="p-4 md:p-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-purple-100 rounded-lg">
            <Webhook className="w-7 h-7 text-purple-600" />
          </div>
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-gray-900">Configurações SDR</h1>
            <p className="text-sm text-gray-600">Gerencie múltiplos webhooks para integração de vendas</p>
          </div>
        </div>
        <button
          onClick={() => setShowAddForm(!showAddForm)}
          className="w-full md:w-auto px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 flex items-center justify-center gap-2 font-medium shadow-sm"
        >
          <Plus className="w-5 h-5" />
          Adicionar
        </button>
      </div>

      <div className="space-y-6">
        {/* Formulário de novo webhook */}
        {showAddForm && (
          <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-6">
            <h3 className="font-bold text-blue-900 mb-4 flex items-center gap-2">
              <Plus className="w-5 h-5" />
              Novo Webhook
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Nome</label>
                <input
                  type="text"
                  value={newWebhook.name}
                  onChange={(e) => setNewWebhook({ ...newWebhook, name: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
                  placeholder="n8n Principal"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">URL do Webhook</label>
                <input
                  type="url"
                  value={newWebhook.webhook_url}
                  onChange={(e) => setNewWebhook({ ...newWebhook, webhook_url: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 font-mono text-sm"
                  placeholder="https://seu-n8n.com/webhook/..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Secret/Token (opcional)</label>
                <input
                  type="password"
                  value={newWebhook.webhook_secret}
                  onChange={(e) => setNewWebhook({ ...newWebhook, webhook_secret: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 font-mono text-sm"
                  placeholder="seu-token-secreto"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Ordem de Execução</label>
                <input
                  type="number"
                  value={newWebhook.execution_order}
                  onChange={(e) => setNewWebhook({ ...newWebhook, execution_order: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
                  min="0"
                />
              </div>

              <div className="flex flex-col sm:flex-row gap-2 pt-2">
                <button
                  onClick={handleAddWebhook}
                  className="w-full sm:flex-1 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 flex items-center justify-center gap-2 font-medium"
                >
                  <Plus className="w-5 h-5" />
                  Adicionar Webhook
                </button>
                <button
                  onClick={() => setShowAddForm(false)}
                  className="w-full sm:w-auto px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Lista de webhooks */}
        {webhooks.length === 0 ? (
          <div className="bg-gray-50 border-2 border-dashed border-gray-300 rounded-xl p-12 text-center">
            <Webhook className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="font-bold text-gray-900 mb-2">Nenhum webhook configurado</h3>
            <p className="text-sm text-gray-600 mb-4">Clique em "Adicionar" para criar seu primeiro webhook</p>
          </div>
        ) : (
          <div className="space-y-4">
            {webhooks.map((webhook) => (
              <WebhookCard
                key={webhook.id}
                webhook={webhook}
                onUpdate={loadWebhooks}
                onDelete={handleDeleteWebhook}
                onTest={handleTestWebhook}
              />
            ))}
          </div>
        )}

        {/* Documentação */}
        <div className="bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-xl p-6">
          <h3 className="font-bold text-purple-900 mb-4 flex items-center gap-2">
            <BookOpen className="w-5 h-5" />
            Como Funciona
          </h3>
          <div className="space-y-2 text-sm text-purple-800">
            <p>
              <strong>Múltiplos Webhooks:</strong> Você pode configurar vários webhooks para receber os mesmos eventos (útil para backup, analytics, etc).
            </p>
            <p>
              <strong>Ordem de Execução:</strong> Webhooks com a mesma ordem são executados em paralelo. Use ordens diferentes para execução sequencial.
            </p>
            <p>
              <strong>Ativo/Inativo:</strong> Desative temporariamente um webhook sem deletá-lo.
            </p>
            <p className="pt-2 font-semibold">
              Quando uma venda é detectada, todos os webhooks ativos são chamados automaticamente!
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
