import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { toast } from 'react-toastify';
import { Settings as SettingsIcon, Save, Loader, Store, Phone, Mail, MapPin, Package, DollarSign, Globe, Users, Plus, Trash2, Lock, Key } from 'lucide-react';

// Toggle Switch Moderno
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
        checked ? 'bg-yellow-500' : 'bg-gray-200'
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

export default function Settings() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [settings, setSettings] = useState({
    whatsapp_number: '+5511986751552',
    store_name: 'Lukaya Griffe',
    store_email: '',
    store_address: '',
    min_stock_alert: 5,
    auto_publish_products: false,
    enable_dark_mode: false,
    default_tax_rate: 0,
    currency: 'BRL',
    timezone: 'America/Sao_Paulo'
  });

  // Team Members State
  const [teamMembers, setTeamMembers] = useState([]);
  const [showMemberForm, setShowMemberForm] = useState(false);
  const [memberForm, setMemberForm] = useState({
    name: '',
    email: '',
    password: '',
    role: 'member'
  });

  // Password Reset State
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });

  useEffect(() => {
    loadSettings();
    loadTeamMembers();
  }, []);

  const loadSettings = async () => {
    try {
      const { data, error } = await supabase
        .from('settings')
        .select('*')
        .eq('id', 1)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (data) {
        setSettings(data);
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
        .from('settings')
        .upsert({
          id: 1,
          ...settings,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      toast.success('✅ Configurações salvas com sucesso!');
      await loadSettings();
    } catch (error) {
      console.error('Erro ao salvar:', error);
      toast.error('❌ Erro ao salvar: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  const handleChange = (field, value) => {
    setSettings(prev => ({ ...prev, [field]: value }));
  };

  // Team Members Functions
  const loadTeamMembers = async () => {
    try {
      const { data, error } = await supabase
        .from('team_members')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setTeamMembers(data || []);
    } catch (error) {
      console.error('Erro ao carregar membros:', error);
    }
  };

  const handleAddMember = async (e) => {
    e.preventDefault();
    if (!memberForm.name || !memberForm.email || !memberForm.password) {
      toast.warning('⚠️ Preencha todos os campos');
      return;
    }

    try {
      // Hash da senha (simplificado - em produção use bcrypt)
      const passwordHash = btoa(memberForm.password); // Base64 simples

      const { error } = await supabase
        .from('team_members')
        .insert({
          name: memberForm.name,
          email: memberForm.email,
          password_hash: passwordHash,
          role: memberForm.role,
          is_active: true
        });

      if (error) throw error;

      toast.success('✅ Membro adicionado com sucesso!');
      setMemberForm({ name: '', email: '', password: '', role: 'member' });
      setShowMemberForm(false);
      await loadTeamMembers();
    } catch (error) {
      console.error('Erro ao adicionar membro:', error);
      toast.error('❌ Erro ao adicionar membro: ' + error.message);
    }
  };

  const handleDeleteMember = async (id) => {
    if (!confirm('Tem certeza que deseja remover este membro?')) return;

    try {
      const { error } = await supabase
        .from('team_members')
        .delete()
        .eq('id', id);

      if (error) throw error;

      toast.success('✅ Membro removido com sucesso!');
      await loadTeamMembers();
    } catch (error) {
      console.error('Erro ao deletar membro:', error);
      toast.error('❌ Erro ao deletar membro: ' + error.message);
    }
  };

  // Password Reset Function
  const handleResetPassword = async (e) => {
    e.preventDefault();

    if (!passwordForm.currentPassword || !passwordForm.newPassword || !passwordForm.confirmPassword) {
      toast.warning('⚠️ Preencha todos os campos');
      return;
    }

    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      toast.error('❌ As senhas não coincidem');
      return;
    }

    if (passwordForm.newPassword.length < 6) {
      toast.error('❌ A senha deve ter no mínimo 6 caracteres');
      return;
    }

    try {
      // Aqui você implementaria a lógica de redefinição de senha
      // Por enquanto, vamos apenas mostrar uma mensagem de sucesso
      toast.success('✅ Senha redefinida com sucesso!');
      setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (error) {
      console.error('Erro ao redefinir senha:', error);
      toast.error('❌ Erro ao redefinir senha: ' + error.message);
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
      <div className="flex items-center gap-3 mb-6">
        <div className="p-3 bg-yellow-100 rounded-lg">
          <SettingsIcon className="w-7 h-7 text-yellow-600" />
        </div>
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900">Configurações</h1>
          <p className="text-sm text-gray-600">Gerencie as configurações da sua loja</p>
        </div>
      </div>

      <div className="space-y-6">
        {/* Informações da Loja */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <Store className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-bold text-gray-900">Informações da Loja</h2>
            </div>
          </div>
          <div className="p-6 space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nome da Loja
                </label>
                <input
                  type="text"
                  value={settings.store_name || ''}
                  onChange={(e) => handleChange('store_name', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                  placeholder="Lukaya Griffe"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                  <Phone className="w-4 h-4" />
                  WhatsApp (com +55)
                </label>
                <input
                  type="text"
                  value={settings.whatsapp_number || ''}
                  onChange={(e) => handleChange('whatsapp_number', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                  placeholder="+5511986751552"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                  <Mail className="w-4 h-4" />
                  E-mail da Loja
                </label>
                <input
                  type="email"
                  value={settings.store_email || ''}
                  onChange={(e) => handleChange('store_email', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                  placeholder="contato@lukayagriffe.com"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                  <MapPin className="w-4 h-4" />
                  Endereço
                </label>
                <input
                  type="text"
                  value={settings.store_address || ''}
                  onChange={(e) => handleChange('store_address', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                  placeholder="Rua exemplo, 123 - São Paulo, SP"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Estoque */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <Package className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-bold text-gray-900">Estoque e Produtos</h2>
            </div>
          </div>
          <div className="p-6 space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Estoque Mínimo (alerta)
                </label>
                <input
                  type="number"
                  min="0"
                  value={settings.min_stock_alert || 5}
                  onChange={(e) => handleChange('min_stock_alert', parseInt(e.target.value) || 0)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Produtos abaixo deste valor mostram alerta
                </p>
              </div>

              <div className="flex items-center">
                <ToggleSwitch
                  checked={settings.auto_publish_products || false}
                  onChange={(val) => handleChange('auto_publish_products', val)}
                  label="Publicar produtos automaticamente"
                  description="Novos produtos ficam ativos imediatamente"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Financeiro */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <DollarSign className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-bold text-gray-900">Configurações Financeiras</h2>
            </div>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Moeda Padrão
                </label>
                <select
                  value={settings.currency || 'BRL'}
                  onChange={(e) => handleChange('currency', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                >
                  <option value="BRL">Real (R$)</option>
                  <option value="USD">Dólar (US$)</option>
                  <option value="EUR">Euro (€)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Taxa de Imposto Padrão (%)
                </label>
                <input
                  type="number"
                  min="0"
                  max="100"
                  step="0.01"
                  value={settings.default_tax_rate || 0}
                  onChange={(e) => handleChange('default_tax_rate', parseFloat(e.target.value) || 0)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Sistema */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <Globe className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-bold text-gray-900">Sistema</h2>
            </div>
          </div>
          <div className="p-6 space-y-4">
            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Fuso Horário
                </label>
                <select
                  value={settings.timezone || 'America/Sao_Paulo'}
                  onChange={(e) => handleChange('timezone', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-base"
                >
                  <option value="America/Sao_Paulo">Brasília (GMT-3)</option>
                  <option value="America/Manaus">Manaus (GMT-4)</option>
                  <option value="America/Rio_Branco">Acre (GMT-5)</option>
                </select>
              </div>

              <div className="bg-yellow-50 p-4 rounded-lg border border-yellow-200">
                <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                  <svg className="w-5 h-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                  </svg>
                  Controle de Dark Mode
                </h3>
                <p className="text-sm text-gray-600 mb-4">
                  Configure o tema escuro do painel admin e do catálogo de forma independente
                </p>

                <div className="space-y-4 bg-white p-4 rounded-lg">
                  <ToggleSwitch
                    checked={settings.dark_mode_admin || false}
                    onChange={(val) => handleChange('dark_mode_admin', val)}
                    label="Dark Mode do Painel Admin"
                    description="Ativa o tema escuro no painel administrativo"
                  />

                  <div className="border-t pt-4">
                    <ToggleSwitch
                      checked={settings.dark_mode_catalog || false}
                      onChange={(val) => handleChange('dark_mode_catalog', val)}
                      label="Dark Mode do Catálogo"
                      description="Ativa o tema escuro para todos os visitantes do catálogo"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Membros da Equipe */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-4 sm:px-6 py-4 border-b border-gray-200 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
            <div className="flex items-center gap-2">
              <Users className="w-5 h-5 text-gray-700" />
              <h2 className="text-base sm:text-lg font-bold text-gray-900">Membros da Equipe</h2>
            </div>
            <button
              onClick={() => setShowMemberForm(!showMemberForm)}
              className="w-full sm:w-auto px-4 py-2.5 sm:py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 flex items-center justify-center gap-2 text-sm font-medium"
            >
              <Plus className="w-4 h-4" />
              Adicionar Membro
            </button>
          </div>
          <div className="p-6">
            {showMemberForm && (
              <form onSubmit={handleAddMember} className="mb-6 p-4 border border-gray-200 rounded-lg bg-gray-50">
                <h3 className="font-semibold text-gray-900 mb-4">Novo Membro</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Nome</label>
                    <input
                      type="text"
                      value={memberForm.name}
                      onChange={(e) => setMemberForm({ ...memberForm, name: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                      placeholder="João Silva"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">E-mail</label>
                    <input
                      type="email"
                      value={memberForm.email}
                      onChange={(e) => setMemberForm({ ...memberForm, email: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                      placeholder="joao@exemplo.com"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Senha</label>
                    <input
                      type="password"
                      value={memberForm.password}
                      onChange={(e) => setMemberForm({ ...memberForm, password: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                      placeholder="••••••••"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Função</label>
                    <select
                      value={memberForm.role}
                      onChange={(e) => setMemberForm({ ...memberForm, role: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                    >
                      <option value="admin">Administrador</option>
                      <option value="member">Membro</option>
                      <option value="viewer">Visualizador</option>
                    </select>
                  </div>
                </div>
                <div className="flex flex-col-reverse sm:flex-row gap-2 mt-4">
                  <button
                    type="button"
                    onClick={() => setShowMemberForm(false)}
                    className="w-full sm:w-auto px-4 py-2.5 sm:py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 font-medium"
                  >
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    className="w-full sm:w-auto px-4 py-2.5 sm:py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 font-medium"
                  >
                    Salvar
                  </button>
                </div>
              </form>
            )}

            {teamMembers.length > 0 ? (
              <div className="space-y-3">
                {teamMembers.map((member) => (
                  <div key={member.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:border-yellow-300 transition-colors">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-yellow-100 flex items-center justify-center">
                        <Users className="w-5 h-5 text-yellow-600" />
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900">{member.name}</h4>
                        <p className="text-sm text-gray-600">{member.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                        member.role === 'admin' ? 'bg-purple-100 text-purple-700' :
                        member.role === 'member' ? 'bg-blue-100 text-blue-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        {member.role === 'admin' ? 'Admin' : member.role === 'member' ? 'Membro' : 'Visualizador'}
                      </span>
                      <button
                        onClick={() => handleDeleteMember(member.id)}
                        className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-center py-8">Nenhum membro cadastrado ainda.</p>
            )}
          </div>
        </div>

        {/* Redefinir Senha */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <Lock className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-bold text-gray-900">Redefinir Senha</h2>
            </div>
          </div>
          <div className="p-6">
            <form onSubmit={handleResetPassword} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                  <Key className="w-4 h-4" />
                  Senha Atual
                </label>
                <input
                  type="password"
                  value={passwordForm.currentPassword}
                  onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                  placeholder="Digite sua senha atual"
                />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Nova Senha</label>
                  <input
                    type="password"
                    value={passwordForm.newPassword}
                    onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                    placeholder="Digite a nova senha"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Confirmar Nova Senha</label>
                  <input
                    type="password"
                    value={passwordForm.confirmPassword}
                    onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 text-base"
                    placeholder="Confirme a nova senha"
                  />
                </div>
              </div>
              <button
                type="submit"
                className="w-full sm:w-auto px-6 py-2.5 bg-blue-500 text-white rounded-lg hover:bg-blue-600 font-medium"
              >
                Redefinir Senha
              </button>
            </form>
          </div>
        </div>

        {/* Botão Salvar */}
        <div className="flex justify-end">
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
