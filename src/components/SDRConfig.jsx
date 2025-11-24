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
  Trash2
} from 'lucide-react';

// Toggle Switch Component
const ToggleSwitch = ({ checked, onChange, label, description }) => (
  <div className="flex items-center justify-between py-3">
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

export default function SDRConfig() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);
  const [config, setConfig] = useState({
    webhook_url: '',
    webhook_secret: '',
    webhook_enabled: false,
    last_webhook_call: null,
    last_webhook_status: null,
    last_webhook_error: null
  });

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('sdr_config')
        .select('*')
        .eq('id', 1)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (data) {
        setConfig(data);
      }
    } catch (error) {
      console.error('Erro ao carregar configurações:', error);
      toast.error('❌ Erro ao carregar configurações');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const { error } = await supabase
        .from('sdr_config')
        .upsert({
          id: 1,
          webhook_url: config.webhook_url,
          webhook_secret: config.webhook_secret,
          webhook_enabled: config.webhook_enabled,
          // Limpar erros antigos ao salvar novas configurações
          last_webhook_call: null,
          last_webhook_status: null,
          last_webhook_error: null,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      toast.success('✅ Configurações salvas com sucesso!');
      await loadConfig();
    } catch (error) {
      console.error('Erro ao salvar:', error);
      toast.error('❌ Erro ao salvar: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  const handleTestWebhook = async () => {
    if (!config.webhook_url) {
      toast.warning('⚠️ Configure a URL do webhook primeiro');
      return;
    }

    setTesting(true);
    try {
      // Criar payload de teste
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

      // Chamar Edge Function ao invés de chamar webhook direto (evita CORS)
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
          webhook_url: config.webhook_url,
          webhook_secret: config.webhook_secret
        })
      });

      const result = await response.json();

      if (result.success) {
        toast.success('✅ Webhook testado com sucesso! O n8n respondeu: ' + (result.data?.message || 'OK'));
      } else {
        toast.error(`❌ Erro ao testar webhook: ${result.error || 'Erro desconhecido'}`);
      }

      await loadConfig();
    } catch (error) {
      console.error('Erro ao testar webhook:', error);
      toast.error('❌ Erro ao testar webhook: ' + error.message);

      // Atualizar com erro
      await supabase
        .from('sdr_config')
        .update({
          last_webhook_call: new Date().toISOString(),
          last_webhook_status: 'error',
          last_webhook_error: error.message,
          updated_at: new Date().toISOString()
        })
        .eq('id', 1);

      await loadConfig();
    } finally {
      setTesting(false);
    }
  };

  const handleChange = (field, value) => {
    setConfig(prev => ({ ...prev, [field]: value }));
  };

  const handleClearError = async () => {
    try {
      const { error } = await supabase
        .from('sdr_config')
        .update({
          last_webhook_call: null,
          last_webhook_status: null,
          last_webhook_error: null,
          updated_at: new Date().toISOString()
        })
        .eq('id', 1);

      if (error) throw error;

      toast.success('✅ Erro limpo com sucesso!');
      await loadConfig();
    } catch (error) {
      console.error('Erro ao limpar:', error);
      toast.error('❌ Erro ao limpar: ' + error.message);
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
    <div className="p-4 sm:p-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3 mb-4 sm:mb-6">
        <div className="p-2 sm:p-3 bg-purple-100 rounded-lg">
          <Webhook className="w-6 h-6 sm:w-7 sm:h-7 text-purple-600" />
        </div>
        <div className="flex-1 min-w-0">
          <h1 className="text-xl sm:text-2xl md:text-3xl font-bold text-gray-900">Configurações SDR</h1>
          <p className="text-xs sm:text-sm text-gray-600">Webhook n8n para integração de vendas do WhatsApp</p>
        </div>
      </div>

      <div className="space-y-4 sm:space-y-6">
        {/* Status Card */}
        {config.last_webhook_call && (
          <div className={`rounded-xl p-4 sm:p-6 border-2 ${
            config.last_webhook_status === 'success'
              ? 'bg-green-50 border-green-200'
              : 'bg-red-50 border-red-200'
          }`}>
            <div className="flex flex-col sm:flex-row items-start gap-3 sm:gap-4">
              {config.last_webhook_status === 'success' ? (
                <CheckCircle className="w-6 h-6 text-green-600 flex-shrink-0" />
              ) : (
                <XCircle className="w-6 h-6 text-red-600 flex-shrink-0" />
              )}
              <div className="flex-1 min-w-0">
                <h3 className={`font-bold text-base sm:text-lg mb-1 ${
                  config.last_webhook_status === 'success' ? 'text-green-900' : 'text-red-900'
                }`}>
                  {config.last_webhook_status === 'success' ? 'Webhook Conectado' : 'Erro no Webhook'}
                </h3>
                <p className={`text-sm ${
                  config.last_webhook_status === 'success' ? 'text-green-700' : 'text-red-700'
                }`}>
                  Última chamada: {new Date(config.last_webhook_call).toLocaleString('pt-BR')}
                </p>
                {config.last_webhook_error && (
                  <div className="mt-3 p-3 bg-white rounded border border-red-200">
                    <p className="text-sm font-mono text-red-800">{config.last_webhook_error}</p>
                  </div>
                )}
              </div>
              <button
                onClick={handleClearError}
                className="w-full sm:w-auto px-3 py-2.5 sm:py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center justify-center gap-2 text-sm font-medium text-gray-700 transition-colors"
                title="Limpar mensagem de erro"
              >
                <Trash2 className="w-4 h-4" />
                Limpar
              </button>
            </div>
          </div>
        )}

        {/* Webhook Configuration */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-bold text-gray-900">Configuração do Webhook</h2>
            </div>
          </div>
          <div className="p-6 space-y-6">
            {/* Enable/Disable */}
            <ToggleSwitch
              checked={config.webhook_enabled || false}
              onChange={(val) => handleChange('webhook_enabled', val)}
              label="Webhook Ativo"
              description="Ativar integração com n8n para receber vendas do WhatsApp"
            />

            {/* Webhook URL */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                <LinkIcon className="w-4 h-4" />
                URL do Webhook n8n
              </label>
              <input
                type="url"
                value={config.webhook_url || ''}
                onChange={(e) => handleChange('webhook_url', e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors font-mono text-sm sm:text-base"
                placeholder="https://seu-n8n.com/webhook/lukaya-vendas"
              />
              <p className="text-xs text-gray-500 mt-2">
                Cole aqui a URL do webhook gerada no seu workflow do n8n
              </p>
            </div>

            {/* Webhook Secret */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                <Key className="w-4 h-4" />
                Secret/Token (opcional)
              </label>
              <input
                type="password"
                value={config.webhook_secret || ''}
                onChange={(e) => handleChange('webhook_secret', e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors font-mono text-sm sm:text-base"
                placeholder="seu-token-secreto-aqui"
              />
              <p className="text-xs text-gray-500 mt-2">
                Token de segurança para validar as chamadas (será enviado no header X-Webhook-Secret)
              </p>
            </div>

            {/* Test Button */}
            <div className="pt-4 border-t border-gray-200">
              <button
                onClick={handleTestWebhook}
                disabled={testing || !config.webhook_url}
                className="w-full sm:w-auto px-6 py-3 bg-purple-500 text-white rounded-lg hover:bg-purple-600 active:bg-purple-700 flex items-center justify-center gap-2 font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md"
              >
                {testing ? (
                  <>
                    <Loader className="w-5 h-5 animate-spin" />
                    Testando...
                  </>
                ) : (
                  <>
                    <Zap className="w-5 h-5" />
                    Testar Webhook
                  </>
                )}
              </button>
              <p className="text-xs text-gray-500 mt-2">
                Envia um payload de teste para verificar se o webhook está funcionando
              </p>
            </div>
          </div>
        </div>

        {/* Setup Instructions */}
        <div className="bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-xl p-4 sm:p-6">
          <h3 className="text-base sm:text-lg font-bold text-purple-900 mb-4 flex items-center gap-2">
            <BookOpen className="w-5 h-5" />
            Como Configurar no n8n
          </h3>
          <div className="space-y-4">
            <div className="bg-white rounded-lg p-4 border border-purple-100">
              <p className="text-sm font-semibold text-purple-900 mb-2">📌 Passo 1: Criar Webhook no n8n</p>
              <ol className="text-sm text-gray-700 space-y-1 ml-4 list-decimal">
                <li>Abra seu n8n e crie um novo workflow</li>
                <li>Adicione o nó <code className="bg-gray-100 px-1.5 py-0.5 rounded text-xs">Webhook</code></li>
                <li>Configure o método como <strong>POST</strong></li>
                <li>Copie a URL gerada (ex: <code className="bg-gray-100 px-1.5 py-0.5 rounded text-xs">https://seu-n8n.com/webhook/abc123</code>)</li>
                <li>Cole essa URL no campo acima ⬆️</li>
              </ol>
            </div>

            <div className="bg-white rounded-lg p-4 border border-purple-100">
              <p className="text-sm font-semibold text-purple-900 mb-2">📦 Exemplo de Payload Enviado (JSON)</p>
              <pre className="bg-gray-900 text-green-400 p-3 rounded text-xs overflow-x-auto font-mono">
{`{
  "event_type": "sale_confirmed",
  "test": false,
  "timestamp": "2025-01-23T10:30:00Z",
  "data": {
    "product_id": 42,
    "product_name": "Kenner Slide",
    "quantity": 2,
    "total_value": 400.00,
    "customer": {
      "phone": "+5511987654321",
      "name": "João Silva"
    },
    "payment_method": "pix",
    "source": "whatsapp"
  }
}`}
              </pre>
            </div>

            <div className="bg-white rounded-lg p-4 border border-purple-100">
              <p className="text-sm font-semibold text-purple-900 mb-2">✅ Resposta Esperada do Webhook</p>
              <p className="text-xs text-gray-600 mb-2">Seu n8n deve retornar HTTP 200 com um JSON assim:</p>
              <pre className="bg-gray-900 text-green-400 p-3 rounded text-xs overflow-x-auto font-mono">
{`{
  "success": true,
  "message": "Venda registrada com sucesso",
  "sale_id": 123
}`}
              </pre>
              <p className="text-xs text-amber-700 mt-2 flex items-center gap-1">
                <AlertCircle className="w-3 h-3 flex-shrink-0" />
                Se retornar outro status (405, 404, 500), o teste falhará
              </p>
            </div>

            <div className="bg-white rounded-lg p-4 border border-purple-100">
              <p className="text-sm font-semibold text-purple-900 mb-2">🔒 Token de Segurança (Opcional)</p>
              <p className="text-xs text-gray-700">
                Se configurar um token secreto, ele será enviado no header <code className="bg-gray-100 px-1.5 py-0.5 rounded">X-Webhook-Secret</code>.
                No n8n, você pode validar assim:
              </p>
              <pre className="bg-gray-900 text-green-400 p-3 rounded text-xs overflow-x-auto font-mono mt-2">
{`// No nó "IF" do n8n:
{{ $headers['x-webhook-secret'] === 'seu-token' }}`}
              </pre>
            </div>
          </div>
        </div>

        {/* How it Works */}
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 sm:p-6">
          <h3 className="text-base sm:text-lg font-bold text-blue-900 mb-3 flex items-center gap-2">
            <AlertCircle className="w-5 h-5" />
            Como Funciona
          </h3>
          <div className="space-y-2 text-sm text-blue-800">
            <p>
              <strong>1. SDR Detecta Venda:</strong> Quando o SDR identifica uma venda confirmada (comprovante, endereço + pagamento na entrega, ou registro manual), ele envia os dados para o webhook.
            </p>
            <p>
              <strong>2. n8n Processa:</strong> O n8n recebe os dados, valida o token (se configurado) e processa a venda.
            </p>
            <p>
              <strong>3. Registra no ERP:</strong> O workflow do n8n chama a API do Supabase para registrar a venda, atualizar estoque e criar o registro do cliente.
            </p>
            <p className="pt-2 font-semibold">
              Payload enviado inclui: tipo de evento, dados do produto, cliente (nome, telefone, endereço), método de pagamento e origem.
            </p>
          </div>
        </div>

        {/* Save Button */}
        <div className="flex justify-end gap-3">
          <button
            onClick={handleSave}
            disabled={saving}
            className="w-full sm:w-auto px-8 py-3 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 active:bg-yellow-700 flex items-center justify-center gap-2 font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md"
          >
            {saving ? (
              <>
                <Loader className="w-5 h-5 animate-spin" />
                Salvando...
              </>
            ) : (
              <>
                <Save className="w-5 h-5" />
                Salvar Configurações
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
