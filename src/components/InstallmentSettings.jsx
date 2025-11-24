import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { toast } from 'react-toastify';
import {
  CreditCard,
  Save,
  Plus,
  Trash2,
  DollarSign,
  Percent,
  AlertCircle,
  Eye,
  EyeOff
} from 'lucide-react';

const InstallmentSettings = () => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [settings, setSettings] = useState({
    default_max_installments: 6,
    default_interest_rate: 0,
    min_installment_value: 20,
    installment_enabled: true,
    show_price_comparison: true,
    installment_options: []
  });

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('installment_settings')
        .select('*')
        .eq('id', 1)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (data) {
        setSettings({
          ...data,
          installment_options: data.installment_options || []
        });
      }
    } catch (error) {
      console.error('Erro ao carregar configurações:', error);
      toast.error('Erro ao carregar configurações de parcelamento');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const { error } = await supabase
        .from('installment_settings')
        .upsert({
          id: 1,
          default_max_installments: settings.default_max_installments,
          default_interest_rate: settings.default_interest_rate,
          min_installment_value: settings.min_installment_value,
          installment_enabled: settings.installment_enabled,
          show_price_comparison: settings.show_price_comparison,
          installment_options: settings.installment_options,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      toast.success('✅ Configurações de parcelamento salvas!');
    } catch (error) {
      console.error('Erro ao salvar:', error);
      toast.error('Erro ao salvar configurações');
    } finally {
      setSaving(false);
    }
  };

  const addInstallmentOption = () => {
    setSettings({
      ...settings,
      installment_options: [
        ...settings.installment_options,
        {
          installments: 1,
          interest_rate: 0,
          label: 'Nova opção'
        }
      ]
    });
  };

  const updateInstallmentOption = (index, field, value) => {
    const newOptions = [...settings.installment_options];
    newOptions[index] = {
      ...newOptions[index],
      [field]: value
    };
    setSettings({
      ...settings,
      installment_options: newOptions
    });
  };

  const removeInstallmentOption = (index) => {
    setSettings({
      ...settings,
      installment_options: settings.installment_options.filter((_, i) => i !== index)
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-yellow-500"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-4 sm:p-6">
      <div className="mb-4 sm:mb-6">
        <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-2">
          <CreditCard className="w-6 h-6 sm:w-7 sm:h-7 text-yellow-500" />
          Configurações de Parcelamento
        </h2>
        <p className="text-sm sm:text-base text-gray-600 mt-1">
          Configure as opções de parcelamento exibidas no catálogo
        </p>
      </div>

      <div className="space-y-4 sm:space-y-6">
        {/* Toggle de Parcelamento Ativo */}
        <div className="bg-white rounded-lg shadow-sm p-4 sm:p-6 border border-gray-200">
          <div className="flex items-start sm:items-center justify-between gap-4">
            <div className="flex-1">
              <h3 className="text-base sm:text-lg font-semibold text-gray-900 flex items-center gap-2">
                {settings.installment_enabled ? (
                  <Eye className="w-5 h-5 text-green-500" />
                ) : (
                  <EyeOff className="w-5 h-5 text-gray-400" />
                )}
                Sistema de Parcelamento
              </h3>
              <p className="text-sm text-gray-600 mt-1">
                {settings.installment_enabled
                  ? 'Parcelamento está ativo e sendo exibido no catálogo'
                  : 'Parcelamento está desativado'}
              </p>
            </div>
            <button
              onClick={() =>
                setSettings({ ...settings, installment_enabled: !settings.installment_enabled })
              }
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                settings.installment_enabled ? 'bg-green-500' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  settings.installment_enabled ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        </div>

        {/* Comparativo de Preços */}
        <div className="bg-white rounded-lg shadow-sm p-4 sm:p-6 border border-gray-200">
          <div className="flex items-start sm:items-center justify-between gap-4">
            <div className="flex-1">
              <h3 className="text-base sm:text-lg font-semibold text-gray-900">
                Comparativo de Preços
              </h3>
              <p className="text-sm text-gray-600 mt-1">
                Exibir formato "De R$ X por R$ X" quando houver desconto
              </p>
            </div>
            <button
              onClick={() =>
                setSettings({ ...settings, show_price_comparison: !settings.show_price_comparison })
              }
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                settings.show_price_comparison ? 'bg-green-500' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  settings.show_price_comparison ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        </div>

        {/* Configurações Padrão */}
        <div className="bg-white rounded-lg shadow-sm p-4 sm:p-6 border border-gray-200">
          <h3 className="text-base sm:text-lg font-semibold text-gray-900 mb-4">
            Configurações Padrão
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Parcelas Máximas Padrão
              </label>
              <input
                type="number"
                min="1"
                max="24"
                value={settings.default_max_installments}
                onChange={(e) =>
                  setSettings({ ...settings, default_max_installments: parseInt(e.target.value) || 1 })
                }
                className="w-full px-4 py-2.5 sm:py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Taxa de Juros Padrão (% a.m.)
              </label>
              <div className="relative">
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  max="100"
                  value={settings.default_interest_rate}
                  onChange={(e) =>
                    setSettings({ ...settings, default_interest_rate: parseFloat(e.target.value) || 0 })
                  }
                  className="w-full px-4 py-2.5 sm:py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base"
                />
                <Percent className="absolute right-3 top-2.5 w-5 h-5 text-gray-400" />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Valor Mínimo da Parcela
              </label>
              <div className="relative">
                <span className="absolute left-3 top-2.5 text-gray-500">R$</span>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  value={settings.min_installment_value}
                  onChange={(e) =>
                    setSettings({ ...settings, min_installment_value: parseFloat(e.target.value) || 1 })
                  }
                  className="w-full pl-10 pr-4 py-2.5 sm:py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Opções de Parcelamento */}
        <div className="bg-white rounded-lg shadow-sm p-4 sm:p-6 border border-gray-200">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-0 mb-4">
            <div className="flex-1">
              <h3 className="text-base sm:text-lg font-semibold text-gray-900">
                Opções de Parcelamento
              </h3>
              <p className="text-sm text-gray-600 mt-1">
                Configure as opções que serão exibidas no checkout
              </p>
            </div>
            <button
              onClick={addInstallmentOption}
              className="w-full sm:w-auto flex items-center justify-center gap-2 px-4 py-2.5 sm:py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 transition-colors font-medium"
            >
              <Plus className="w-4 h-4" />
              Adicionar Opção
            </button>
          </div>

          {settings.installment_options.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <AlertCircle className="w-12 h-12 mx-auto mb-2 text-gray-300" />
              <p>Nenhuma opção de parcelamento configurada</p>
              <p className="text-sm mt-1">Clique em "Adicionar Opção" para começar</p>
            </div>
          ) : (
            <div className="space-y-3">
              {settings.installment_options.map((option, index) => (
                <div
                  key={index}
                  className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 p-4 border border-gray-200 rounded-lg hover:border-yellow-300 transition-colors"
                >
                  <div className="flex-1 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
                    <div>
                      <label className="block text-xs text-gray-600 mb-1">Parcelas</label>
                      <input
                        type="number"
                        min="1"
                        max="24"
                        value={option.installments}
                        onChange={(e) =>
                          updateInstallmentOption(index, 'installments', parseInt(e.target.value) || 1)
                        }
                        className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 rounded-lg text-sm sm:text-base"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-600 mb-1">Juros (% a.m.)</label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        max="100"
                        value={option.interest_rate}
                        onChange={(e) =>
                          updateInstallmentOption(index, 'interest_rate', parseFloat(e.target.value) || 0)
                        }
                        className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 rounded-lg text-sm sm:text-base"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-600 mb-1">Rótulo</label>
                      <input
                        type="text"
                        value={option.label}
                        onChange={(e) => updateInstallmentOption(index, 'label', e.target.value)}
                        placeholder="Ex: 6x sem juros"
                        className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 rounded-lg text-sm sm:text-base"
                      />
                    </div>
                  </div>
                  <button
                    onClick={() => removeInstallmentOption(index)}
                    className="w-full sm:w-auto p-2.5 sm:p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors font-medium flex items-center justify-center gap-2"
                  >
                    <Trash2 className="w-5 h-5" />
                    <span className="sm:hidden">Remover</span>
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Preview */}
        {settings.installment_options.length > 0 && (
          <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-lg p-4 sm:p-6 border border-gray-200">
            <h3 className="text-base sm:text-lg font-semibold text-gray-900 mb-4">
              Preview - Como será exibido:
            </h3>
            <div className="bg-white rounded-lg p-4 shadow-sm">
              <p className="text-2xl font-bold text-gray-900 mb-2">R$ 1.200,00</p>
              {settings.show_price_comparison && (
                <p className="text-sm text-gray-500 line-through mb-3">De R$ 1.500,00</p>
              )}
              {settings.installment_enabled && settings.installment_options.slice(0, 3).map((option, idx) => (
                <p key={idx} className="text-sm text-gray-600">
                  {option.label || `${option.installments}x de R$ ${(1200 / option.installments).toFixed(2)}`}
                  {option.interest_rate > 0 && ` (juros: ${option.interest_rate}% a.m.)`}
                </p>
              ))}
            </div>
          </div>
        )}

        {/* Botão Salvar */}
        <div className="flex flex-col-reverse sm:flex-row justify-end gap-3">
          <button
            onClick={loadSettings}
            className="w-full sm:w-auto px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
          >
            Cancelar
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
          >
            {saving ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
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
};

export default InstallmentSettings;
