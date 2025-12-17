// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// =====================================================
// VERSÃO CORRIGIDA - vend.AI ICP Widget
// Correções implementadas:
// 1. ICP Configuration agora é READ-ONLY
// 2. Contador de leads corrigido (conta dinamicamente do banco)
// =====================================================

import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class ICPConfigWidget extends StatefulWidget {
  const ICPConfigWidget({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  State<ICPConfigWidget> createState() => _ICPConfigWidgetState();
}

class _ICPConfigWidgetState extends State<ICPConfigWidget> {
  int? companyId;
  String? userId;
  int? icpId;
  bool isLoading = true;

  String planType = 'Performance';
  int planMonthlyLimit = 70;
  int leadsRecebidosMes = 0;
  int leadsDisponiveis = 70;

  int currentStep = 0;
  final int totalSteps = 6;

  // ===== CORREÇÃO PROBLEMA 1: Dados agora são apenas para visualização (READ-ONLY) =====
  // Removidos controllers editáveis, substituídos por variáveis simples
  String idadeMin = '';
  String idadeMax = '';
  String rendaMin = '';
  String rendaMax = '';
  String genero = '';
  String escolaridade = '';

  List<String> selectedEstados = [];
  List<String> selectedRegioes = [];
  List<String> selectedSegmentos = [];
  List<String> selectedCanais = [];

  String tamanhoEmpresa = '';
  String tempoMercado = '';
  String empresaFuncionarios = '';
  String preferenciaContato = '';
  String horario = '';
  String linguagem = '';
  String cicloCompra = '';

  bool comprouOnline = false;
  bool influenciador = false;

  String budgetMin = '';
  String budgetMax = '';
  String desafios = '';
  String objetivos = '';

  double leadsPerDay = 3;
  bool usarIA = true;
  bool entregarFds = false;
  String prioridade = 'Média';
  bool notificarNovosLeads = true;

  List<Map<String, dynamic>> leads = [];
  List<Map<String, dynamic>> filteredLeads = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  String searchQuery = '';
  String statusFilter = 'Todos';

  final estadosOpts = [
    'SP',
    'MG',
    'RJ',
    'ES',
    'PR',
    'SC',
    'RS',
    'BA',
    'PE',
    'CE'
  ];
  final regioesOpts = ['Norte', 'Nordeste', 'Centro-Oeste', 'Sudeste', 'Sul'];
  final segmentosOpts = [
    'Agricultura',
    'Pecuária',
    'Agroindústria',
    'Tecnologia para Agro',
    'Insumos Agrícolas',
    'Máquinas e Equipamentos',
    'Consultoria Agro'
  ];
  final canaisOpts = [
    'Instagram',
    'Facebook',
    'LinkedIn',
    'WhatsApp',
    'YouTube',
    'E-mail'
  ];
  final statusOpts = [
    'Todos',
    'Lead novo',
    'Em contato',
    'Interessado',
    'Proposta enviada',
    'Fechado',
    'Perdido',
    'Remarketing'
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    // Não há mais controllers para dispose
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }
      userId = user.id;
      final data = await SupaFlow.client
          .from('users')
          .select('company_id')
          .eq('auth_user_id', userId!)
          .maybeSingle();
      companyId = data?['company_id'];
      if (companyId != null) {
        await _loadCompanyPlan();
        await _countLeadsRecebidos();
        await _loadICP();
        await _loadLeads();
      }
    } catch (e) {
      _showToast('Erro ao carregar: $e', false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadCompanyPlan() async {
    try {
      final data = await SupaFlow.client
          .from('companies')
          .select('plan_type, plan_monthly_limit')
          .eq('id', companyId!)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          planType = data['plan_type'] ?? 'Performance';
          planMonthlyLimit = data['plan_monthly_limit'] ?? 70;
        });
      }
    } catch (e) {
      print('Erro ao carregar plano: $e');
    }
  }

  // ===== CORREÇÃO PROBLEMA 2: Contador de leads agora conta dinamicamente do banco =====
  Future<void> _countLeadsRecebidos() async {
    try {
      print('🔍 Contando leads extraídos dinamicamente do banco...');
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // CORREÇÃO: Contar DIRETAMENTE da tabela ICP_leads
      // Buscar leads criados no mês atual
      final leadsData = await SupaFlow.client
          .from('ICP_leads')
          .select('id, created_at')
          .eq('company_id', companyId!);

      // Contar quantos leads foram criados no mês atual
      int extracted = 0;
      if (leadsData != null && leadsData is List) {
        for (var lead in leadsData) {
          final createdAt = lead['created_at'];
          if (createdAt != null) {
            final dt = DateTime.tryParse(createdAt.toString());
            if (dt != null) {
              final leadMonth =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
              if (leadMonth == currentMonth) {
                extracted++;
              }
            }
          }
        }
      }

      print('📊 Leads extraídos no mês $currentMonth: $extracted');

      // Também atualizar o contador na tabela companies para manter sincronizado
      final companyData = await SupaFlow.client
          .from('companies')
          .select('plan_monthly_limit')
          .eq('id', companyId!)
          .maybeSingle();

      if (companyData != null) {
        planMonthlyLimit = companyData['plan_monthly_limit'] ?? 70;

        // Atualizar contador na tabela companies
        await SupaFlow.client.from('companies').update({
          'leads_extracted_this_month': extracted,
          'last_extraction_month': currentMonth,
        }).eq('id', companyId!);
      }

      if (mounted) {
        setState(() {
          leadsRecebidosMes = extracted;
          leadsDisponiveis = planMonthlyLimit - extracted;
          if (leadsDisponiveis < 0) leadsDisponiveis = 0;
          if (leadsPerDay > leadsDisponiveis) {
            leadsPerDay =
                leadsDisponiveis > 0 ? leadsDisponiveis.toDouble() : 1;
          }
        });
        print('✅ Contador atualizado! Disponíveis: $leadsDisponiveis / $planMonthlyLimit');
      }
    } catch (e) {
      print('❌ Erro ao contar leads: $e');
    }
  }

  Future<void> _loadICP() async {
    try {
      final res = await SupaFlow.client
          .from('icp_configuration')
          .select()
          .eq('company_id', companyId!)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          icpId = res['id'];
          // ===== CORREÇÃO PROBLEMA 1: Carregar dados como strings (não controllers) =====
          idadeMin = res['idade_min']?.toString() ?? '';
          idadeMax = res['idade_max']?.toString() ?? '';
          rendaMin = _formatBRLFromNumber(res['renda_min']);
          rendaMax = _formatBRLFromNumber(res['renda_max']);
          genero = res['genero']?.toString() ?? '';
          escolaridade = res['escolaridade']?.toString() ?? '';
          selectedEstados = List<String>.from(res['estados'] ?? []);
          selectedRegioes = List<String>.from(res['regioes'] ?? []);
          selectedSegmentos =
              List<String>.from(res['nicho'] ?? res['nichos'] ?? []);
          selectedCanais = List<String>.from(res['canais'] ?? []);
          tamanhoEmpresa = res['tamanho_empresa']?.toString() ?? '';
          tempoMercado = res['tempo_mercado']?.toString() ?? '';
          empresaFuncionarios =
              res['empresa_funcionarios']?.toString() ?? '';
          preferenciaContato =
              res['preferencia_contato']?.toString() ?? '';
          horario = res['horario']?.toString() ?? '';
          linguagem = res['linguagem']?.toString() ?? '';
          cicloCompra = res['ciclo_compra']?.toString() ?? '';
          comprouOnline = res['comprou_online'] ?? false;
          influenciador = res['influenciador'] ?? false;
          budgetMin = _formatBRLFromNumber(res['budget_min']);
          budgetMax = _formatBRLFromNumber(res['budget_max']);
          desafios = res['dores']?.toString() ?? '';
          objetivos = res['objetivos']?.toString() ?? '';
          leadsPerDay =
              (res['leads_por_dia_max'] ?? res['leads_desejados'] ?? 3)
                  .toDouble();
          usarIA = res['usar_ia'] ?? true;
          entregarFds = res['entregar_fins_semana'] ?? false;
          prioridade = res['prioridade']?.toString() ?? 'Média';
          notificarNovosLeads = res['notificar_novos_leads'] ?? true;
        });
      }
    } catch (e) {
      print('Erro ao carregar ICP: $e');
    }
  }

  Future<void> _loadLeads() async {
    try {
      var q = SupaFlow.client
          .from('ICP_leads')
          .select()
          .eq('company_id', companyId!);
      if (icpId != null) q = q.eq('icp_id', icpId!);
      final res = await q.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          leads = List<Map<String, dynamic>>.from(res ?? []);
          _applyFilters();
        });
      }
    } catch (e) {
      print('Erro ao carregar leads: $e');
    }
  }

  void _applyFilters() {
    final q = searchQuery.trim().toLowerCase();
    filteredLeads = leads.where((l) {
      final nome = (l['nome'] ?? '').toString().toLowerCase();
      final empresa =
          (l['empresa'] ?? l['company_name'] ?? '').toString().toLowerCase();
      final status = (l['status'] ?? '').toString();
      final matchQ = q.isEmpty || nome.contains(q) || empresa.contains(q);
      final matchS = statusFilter == 'Todos' || status == statusFilter;
      return matchQ && matchS;
    }).toList();
    currentPage = 1;
  }

  List<Map<String, dynamic>> get pagedLeads {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return filteredLeads.sublist(start.clamp(0, filteredLeads.length),
        end.clamp(0, filteredLeads.length));
  }

  int get totalPages => filteredLeads.isEmpty
      ? 1
      : ((filteredLeads.length + itemsPerPage - 1) ~/ itemsPerPage);

  // ===== CORREÇÃO PROBLEMA 1: Função _saveICP REMOVIDA (não é mais necessária) =====
  // Usuários não podem mais editar a configuração do ICP

  Future<void> _updateLeadStatus(
      Map<String, dynamic> lead, String newStatus) async {
    try {
      await SupaFlow.client
          .from('ICP_leads')
          .update({'status': newStatus}).eq('id', lead['id']);
      _showToast('Status atualizado', true);
      await _loadLeads();
    } catch (e) {
      _showToast('Erro ao atualizar status', false);
    }
  }

  Future<void> _showLeadDetails(Map<String, dynamic> lead) async {
    final t = FlutterFlowTheme.of(context);
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: t.secondaryBackground,
        title: Text('Detalhes do Lead', style: t.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Nome', lead['nome']),
              _detailRow('Empresa', lead['empresa'] ?? lead['company_name']),
              _detailRow('Email', lead['email']),
              _detailRow('WhatsApp', lead['whatsapp']),
              _detailRow('Cidade', lead['cidade']),
              _detailRow('Estado', lead['estado']),
              _detailRow('Segmento', lead['segmento'] ?? lead['segment']),
              _detailRow('Status', lead['status']),
              _detailRow('Prioridade', lead['prioridade'] ?? lead['priority']),
              _detailRow(
                  'Observações', lead['observacoes'] ?? 'Sem observações'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Fechar'))
        ],
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final t = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: t.labelMedium.override(
                      fontFamily: t.labelMediumFamily,
                      fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(value?.toString() ?? 'N/A', style: t.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _editLead(Map<String, dynamic> lead) async {
    final t = FlutterFlowTheme.of(context);
    final nomeCtrl = TextEditingController(text: lead['nome']);
    final empresaCtrl =
        TextEditingController(text: lead['empresa'] ?? lead['company_name']);
    final emailCtrl = TextEditingController(text: lead['email']);
    final whatsappCtrl = TextEditingController(text: lead['whatsapp']);
    String selectedStatus = lead['status'] ?? 'Lead novo';
    String selectedPriority = lead['prioridade'] ?? lead['priority'] ?? 'Média';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: t.secondaryBackground,
          title: Text('Editar Lead', style: t.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nomeCtrl,
                    decoration: InputDecoration(labelText: 'Nome'),
                    style: t.bodyMedium),
                SizedBox(height: 12),
                TextField(
                    controller: empresaCtrl,
                    decoration: InputDecoration(labelText: 'Empresa'),
                    style: t.bodyMedium),
                SizedBox(height: 12),
                TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(labelText: 'Email'),
                    style: t.bodyMedium),
                SizedBox(height: 12),
                TextField(
                    controller: whatsappCtrl,
                    decoration: InputDecoration(labelText: 'WhatsApp'),
                    style: t.bodyMedium),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(labelText: 'Status'),
                  items: [
                    'Lead novo',
                    'Em contato',
                    'Interessado',
                    'Proposta enviada',
                    'Fechado',
                    'Perdido',
                    'Remarketing'
                  ]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => selectedStatus = v!),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: InputDecoration(labelText: 'Prioridade'),
                  items: ['Alta', 'Média', 'Baixa']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => selectedPriority = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar')),
            TextButton(
              onPressed: () async {
                try {
                  await SupaFlow.client.from('ICP_leads').update({
                    'nome': nomeCtrl.text,
                    'empresa': empresaCtrl.text,
                    'email': emailCtrl.text,
                    'whatsapp': whatsappCtrl.text,
                    'status': selectedStatus,
                    'prioridade': selectedPriority,
                  }).eq('id', lead['id']);
                  Navigator.pop(ctx, true);
                } catch (e) {
                  Navigator.pop(ctx, false);
                }
              },
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      _showToast('Lead atualizado', true);
      await _loadLeads();
    }
  }

  Future<void> _showNotes(Map<String, dynamic> lead) async {
    final t = FlutterFlowTheme.of(context);
    final notesCtrl = TextEditingController(text: lead['observacoes'] ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.secondaryBackground,
        title: Text('Observações', style: t.headlineSmall),
        content: TextField(
          controller: notesCtrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Adicione observações sobre este lead...',
            border: OutlineInputBorder(),
          ),
          style: t.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                await SupaFlow.client.from('ICP_leads').update(
                    {'observacoes': notesCtrl.text}).eq('id', lead['id']);
                Navigator.pop(ctx, true);
              } catch (e) {
                Navigator.pop(ctx, false);
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showToast('Observações salvas', true);
      await _loadLeads();
    }
  }

  Future<void> _deleteLead(Map<String, dynamic> lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text(
            'Deseja realmente excluir este lead?\n\n⚠️ ATENÇÃO: Excluir não devolve a cota mensal!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child:
                  Text('Excluir', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SupaFlow.client.from('ICP_leads').delete().eq('id', lead['id']);
        _showToast('Lead excluído (cota NÃO devolvida)', true);
        await _loadLeads();
        // Atualizar contador após exclusão
        await _countLeadsRecebidos();
      } catch (e) {
        _showToast('Erro ao excluir', false);
      }
    }
  }

  void _showToast(String msg, bool success) {
    final t = FlutterFlowTheme.of(context);
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: success ? Color(0xFF064E3B) : Color(0xFF7F1D1D),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(success ? Icons.check_circle : Icons.error,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(msg,
                    style: t.bodyMedium.override(
                        fontFamily: t.bodyMediumFamily, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(Duration(seconds: 3), () => entry.remove());
  }

  Widget _metricCard(
      String title, String value, IconData icon, String subtitle) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      height: 180,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(), style: t.labelMedium),
              Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: t.primary, size: 20),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(value, style: t.titleLarge),
          Spacer(),
          Text(subtitle,
              style: t.labelSmall.override(
                  fontFamily: t.labelSmallFamily, color: t.secondaryText)),
        ],
      ),
    );
  }

  Widget _dashboard(int hoje, double kpiMatch, double conversao) {
    final t = FlutterFlowTheme.of(context);
    final percent = planMonthlyLimit > 0
        ? (leadsRecebidosMes / planMonthlyLimit * 100).clamp(0, 100)
        : 0.0;
    return Container(
      height: 700,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.alternate)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard de Performance', style: t.titleMedium),
                    SizedBox(height: 4),
                    Text('Visão geral dos seus leads',
                        style: t.labelSmall.override(
                            fontFamily: t.labelSmallFamily,
                            color: t.secondaryText)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Plano: $planType',
                    style: t.labelSmall.override(
                        fontFamily: t.labelSmallFamily,
                        color: t.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: t.primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.alternate)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Leads Mensais (Extraídos)', style: t.labelMedium),
                    // ===== CORREÇÃO PROBLEMA 2: Contador agora mostra valor correto =====
                    Text('$leadsRecebidosMes / $planMonthlyLimit',
                        style: t.titleSmall.override(
                            fontFamily: t.titleSmallFamily, color: t.primary)),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 8,
                      backgroundColor: t.alternate,
                      color: percent >= 90 ? Color(0xFFEF4444) : t.primary),
                ),
                SizedBox(height: 4),
                Text('$leadsDisponiveis leads disponíveis para extração',
                    style: t.labelSmall.override(
                        fontFamily: t.labelSmallFamily,
                        color: leadsDisponiveis > 0
                            ? Color(0xFF22C55E)
                            : Color(0xFFEF4444))),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                      child: _metricCard('Leads Hoje', hoje.toString(),
                          Icons.show_chart, 'Recebidos hoje')),
                  SizedBox(width: 16),
                  Expanded(
                      child: _metricCard('Total', leads.length.toString(),
                          Icons.call, 'Leads importados'))
                ]),
                SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _metricCard(
                          'KPI Match',
                          '${kpiMatch.toStringAsFixed(1)}%',
                          Icons.radio_button_checked,
                          'Taxa de correspondência')),
                  SizedBox(width: 16),
                  Expanded(
                      child: _metricCard(
                          'Conversão',
                          '${conversao.toStringAsFixed(1)}%',
                          Icons.insert_chart_outlined,
                          'Leads fechados'))
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoReadOnly(String label) {
    final t = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: t.primaryBackground.withOpacity(0.3),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.alternate.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.alternate.withOpacity(0.5))),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.alternate.withOpacity(0.3))),
      labelStyle: t.bodySmall.override(
          fontFamily: t.bodySmallFamily, color: t.secondaryText),
    );
  }

  // ===== CORREÇÃO PROBLEMA 1: Chips agora são READ-ONLY (apenas visualização) =====
  Widget _chipGroupReadOnly(List<String> options, List<String> selected) {
    final t = FlutterFlowTheme.of(context);
    if (selected.isEmpty) {
      return Text('Nenhum selecionado',
          style: t.bodyMedium.override(
              fontFamily: t.bodyMediumFamily, color: t.secondaryText));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selected.map((o) {
        return Chip(
          label: Text(o, style: t.labelMedium),
          backgroundColor: t.primary.withOpacity(0.15),
          labelStyle: t.labelMedium.override(
              fontFamily: t.labelMediumFamily, color: t.primary),
          side: BorderSide(color: t.primary.withOpacity(0.3)),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String text) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Color(0xFF1F3A8A), borderRadius: BorderRadius.circular(16)),
      child: Text(text.toUpperCase(),
          style: t.labelSmall.override(
              fontFamily: t.labelSmallFamily,
              color: Color(0xFF93C5FD),
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _priorityIndicator(String p) {
    final t = FlutterFlowTheme.of(context);
    Color dot;
    switch (p.toLowerCase()) {
      case 'alta':
        dot = Color(0xFFEF4444);
        break;
      case 'baixa':
        dot = Color(0xFF3B82F6);
        break;
      default:
        dot = Color(0xFF9CA3AF);
    }
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      SizedBox(width: 8),
      Text(p, style: t.bodyMedium)
    ]);
  }

  Widget _leadsTable() {
    final t = FlutterFlowTheme.of(context);
    final flex = [15, 15, 20, 15, 12, 10, 13];

    Widget hCell(String text, int f) => Expanded(
        flex: f,
        child: Text(text,
            style: t.labelMedium.override(
                fontFamily: t.labelMediumFamily, color: t.secondaryText)));
    Widget cell(String text, int f, {FontWeight? w}) => Expanded(
        flex: f,
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            style: t.bodyMedium.override(
                fontFamily: t.bodyMediumFamily,
                fontWeight: w ?? FontWeight.normal)));

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.alternate)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planilha de Leads', style: t.titleMedium),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: t.primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.alternate)),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Icon(Icons.search, color: t.secondaryText, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            onChanged: (v) => setState(() {
                                  searchQuery = v;
                                  _applyFilters();
                                }),
                            decoration: InputDecoration.collapsed(
                                hintText: 'Buscar leads...'),
                            style: t.bodyMedium))
                  ]),
                ),
              ),
              SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: Container(
                  height: 44,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: t.primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.alternate)),
                  child: DropdownButton<String>(
                      value: statusFilter,
                      items: statusOpts
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s, style: t.bodyMedium)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          setState(() {
                            statusFilter = v;
                            _applyFilters();
                          });
                      }),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: t.primaryBackground,
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              hCell('Nome', flex[0]),
              hCell('Empresa', flex[1]),
              hCell('Email', flex[2]),
              hCell('WhatsApp', flex[3]),
              hCell('Status', flex[4]),
              hCell('Prioridade', flex[5]),
              hCell('Ações', flex[6])
            ]),
          ),
          SizedBox(height: 4),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: pagedLeads.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: t.alternate),
            itemBuilder: (_, i) {
              final l = pagedLeads[i];
              final nome = (l['nome'] ?? 'Sem nome').toString();
              final empresa =
                  (l['empresa'] ?? l['company_name'] ?? 'Sem empresa')
                      .toString();
              final email = (l['email'] ?? 'Sem email').toString();
              final whatsapp = (l['whatsapp'] ?? 'N/A').toString();
              final status = (l['status'] ?? 'Lead novo').toString();
              final priority =
                  (l['prioridade'] ?? l['priority'] ?? 'Média').toString();

              return Container(
                height: 52,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color:
                        i.isEven ? t.secondaryBackground : t.primaryBackground,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    cell(nome, flex[0], w: FontWeight.w600),
                    cell(empresa, flex[1]),
                    Expanded(
                        flex: flex[2],
                        child: Tooltip(
                            message: email,
                            child: Text(email,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodyMedium))),
                    cell(whatsapp, flex[3]),
                    Expanded(
                        flex: flex[4],
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: _statusBadge(status))),
                    Expanded(
                        flex: flex[5], child: _priorityIndicator(priority)),
                    Expanded(
                      flex: flex[6],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                              icon: Icon(Icons.visibility,
                                  color: t.secondaryText, size: 18),
                              onPressed: () => _showLeadDetails(l)),
                          IconButton(
                              icon: Icon(Icons.edit,
                                  color: t.secondaryText, size: 18),
                              onPressed: () => _editLead(l)),
                          IconButton(
                              icon: Icon(Icons.note_add,
                                  color: t.secondaryText, size: 18),
                              onPressed: () => _showNotes(l)),
                          IconButton(
                              icon: Icon(Icons.delete,
                                  color: Color(0xFFEF4444), size: 18),
                              onPressed: () => _deleteLead(l)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: Text(
                      'Mostrando ${filteredLeads.isEmpty ? 0 : ((currentPage - 1) * itemsPerPage + 1)}–${((currentPage - 1) * itemsPerPage + pagedLeads.length)} de ${filteredLeads.length} leads',
                      style: t.labelSmall)),
              IconButton(
                  onPressed: currentPage > 1
                      ? () => setState(() => currentPage--)
                      : null,
                  icon: Icon(Icons.chevron_left, color: t.secondaryText)),
              Text('$currentPage', style: t.bodyMedium),
              IconButton(
                  onPressed: currentPage < totalPages
                      ? () => setState(() => currentPage++)
                      : null,
                  icon: Icon(Icons.chevron_right, color: t.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(int i) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: currentStep == i ? t.primary : t.primaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: t.alternate)),
      alignment: Alignment.center,
      child: Text('${i + 1}',
          style: t.labelMedium.override(
              fontFamily: t.labelMediumFamily,
              color: currentStep == i ? t.secondaryBackground : t.secondaryText,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _stepLine() {
    final t = FlutterFlowTheme.of(context);
    return Expanded(
        child: Container(
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: 8),
            color: t.alternate.withOpacity(0.4)));
  }

  // ===== CORREÇÃO PROBLEMA 1: Conteúdo das etapas agora é READ-ONLY =====
  Widget _stepContent() {
    final t = FlutterFlowTheme.of(context);
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: idadeMin),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Idade Mínima'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: idadeMax),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Idade Máxima'),
                      style: t.bodyMedium))
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: rendaMin),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Renda Mínima (R\$)'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: rendaMax),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Renda Máxima (R\$)'),
                      style: t.bodyMedium))
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: genero),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Gênero'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: escolaridade),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Escolaridade'),
                      style: t.bodyMedium))
            ]),
            SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estados', style: t.titleSmall),
              SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: _chipGroupReadOnly(estadosOpts, selectedEstados)),
              SizedBox(height: 18),
              Text('Regiões', style: t.titleSmall),
              SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: _chipGroupReadOnly(regioesOpts, selectedRegioes))
            ]),
          ],
        );
      case 1:
        return Column(
          children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: tamanhoEmpresa),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Tamanho da empresa'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: tempoMercado),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Tempo de mercado'),
                      style: t.bodyMedium))
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller:
                          TextEditingController(text: empresaFuncionarios),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Funcionários'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(child: Container())
            ]),
            SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Segmentos', style: t.titleSmall),
              SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: _chipGroupReadOnly(segmentosOpts, selectedSegmentos))
            ]),
          ],
        );
      case 2:
        return Column(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Canais', style: t.titleSmall),
              SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: _chipGroupReadOnly(canaisOpts, selectedCanais))
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller:
                          TextEditingController(text: preferenciaContato),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Preferência de contato'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: horario),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Horário'),
                      style: t.bodyMedium))
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: linguagem),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Linguagem'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(child: Container())
            ]),
          ],
        );
      case 3:
        return Column(
          children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: cicloCompra),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Ciclo de compra'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(child: Container())
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: SwitchListTile(
                      value: comprouOnline,
                      onChanged: null, // Desabilitado
                      title: Text('Comprou online', style: t.bodyMedium))),
              Expanded(
                  child: SwitchListTile(
                      value: influenciador,
                      onChanged: null, // Desabilitado
                      title: Text('Influenciador', style: t.bodyMedium)))
            ]),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: budgetMin),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Budget Mínimo (R\$)'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: budgetMax),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Budget Máximo (R\$)'),
                      style: t.bodyMedium))
            ]),
          ],
        );
      case 4:
        return Column(children: [
          TextField(
              controller: TextEditingController(text: desafios),
              enabled: false,
              maxLines: 3,
              decoration: _inputDecoReadOnly('Dores'),
              style: t.bodyMedium),
          SizedBox(height: 16),
          TextField(
              controller: TextEditingController(text: objetivos),
              enabled: false,
              maxLines: 3,
              decoration: _inputDecoReadOnly('Objetivos'),
              style: t.bodyMedium)
        ]);
      default:
        // Etapa 5 - Configurações de entrega
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leads por dia: ${leadsPerDay.round()}',
                            style: t.titleSmall),
                        SizedBox(height: 8),
                        Slider(
                            value: leadsPerDay,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '${leadsPerDay.round()} leads',
                            onChanged: null // Desabilitado
                            ),
                      ]),
                ),
                SizedBox(width: 16),
                Expanded(
                    child: Column(children: [
                  SwitchListTile(
                      value: usarIA,
                      onChanged: null, // Desabilitado
                      title: Text('Usar IA', style: t.bodyMedium)),
                  SwitchListTile(
                      value: entregarFds,
                      onChanged: null, // Desabilitado
                      title:
                          Text('Entregar fins de semana', style: t.bodyMedium)),
                  SwitchListTile(
                      value: notificarNovosLeads,
                      onChanged: null, // Desabilitado
                      title: Text('Notificar novos leads', style: t.bodyMedium))
                ])),
              ],
            ),
            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: TextEditingController(text: prioridade),
                      enabled: false,
                      decoration: _inputDecoReadOnly('Prioridade'),
                      style: t.bodyMedium)),
              SizedBox(width: 16),
              Expanded(child: Container())
            ]),
          ],
        );
    }
  }

  // ===== CORREÇÃO PROBLEMA 1: Painel ICP agora é READ-ONLY =====
  Widget _icpPanel() {
    final t = FlutterFlowTheme.of(context);
    return Container(
      height: 700,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.alternate)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== MENSAGEM DE AVISO: Configuração READ-ONLY =====
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF3B82F6).withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configuração Gerenciada',
                          style: t.labelMedium.override(
                              fontFamily: t.labelMediumFamily,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text(
                          'Esta configuração é gerenciada pela equipe vend.AI. Para alterações, entre em contato com o suporte.',
                          style: t.labelSmall.override(
                              fontFamily: t.labelSmallFamily,
                              color: t.secondaryText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Configuração do Cliente Ideal (ICP)', style: t.titleMedium),
              SizedBox(width: 8),
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Color(0xFF9CA3AF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Somente Leitura',
                      style: t.labelSmall.override(
                          fontFamily: t.labelSmallFamily,
                          color: t.secondaryText,
                          fontWeight: FontWeight.w600)))
            ]),
            SizedBox(height: 4),
            Text('Etapa ${currentStep + 1} de $totalSteps',
                style: t.labelSmall
                    .override(fontFamily: t.labelSmallFamily, color: t.primary))
          ]),
          SizedBox(height: 16),
          Row(children: [
            _stepCircle(0),
            _stepLine(),
            _stepCircle(1),
            _stepLine(),
            _stepCircle(2),
            _stepLine(),
            _stepCircle(3),
            _stepLine(),
            _stepCircle(4),
            _stepLine(),
            _stepCircle(5)
          ]),
          SizedBox(height: 20),
          Expanded(child: SingleChildScrollView(child: _stepContent())),
          SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                  onPressed: currentStep > 0
                      ? () => setState(() => currentStep--)
                      : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: t.secondaryBackground,
                      foregroundColor: t.primaryText,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  child: Text('Anterior')),
              Spacer(),
              if (currentStep < totalSteps - 1)
                ElevatedButton(
                    onPressed: () => setState(() => currentStep++),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: t.secondaryBackground,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    child: Text('Próximo'))
              else
                // ===== CORREÇÃO PROBLEMA 1: Botão "Exportar" removido =====
                // Usuários não podem mais exportar/modificar ICP
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: t.alternate.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          color: t.secondaryText, size: 16),
                      SizedBox(width: 8),
                      Text('Exportação Gerenciada',
                          style: t.bodyMedium.override(
                              fontFamily: t.bodyMediumFamily,
                              color: t.secondaryText)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 1024;

    int hoje = 0;
    try {
      final now = DateTime.now();
      hoje = leads.where((l) {
        final s = l['created_at'];
        if (s == null) return false;
        final dt = DateTime.tryParse(s.toString());
        if (dt == null) return false;
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      }).length;
    } catch (_) {}

    final totalLeads = leads.length;
    final leadsFechados = leads.where((l) => l['status'] == 'Fechado').length;
    final leadsQualificados = leads
        .where((l) => [
              'Em contato',
              'Interessado',
              'Proposta enviada',
              'Fechado'
            ].contains(l['status']))
        .length;

    final kpiMatch =
        totalLeads > 0 ? (leadsQualificados / totalLeads * 100) : 0.0;
    final conversao = totalLeads > 0 ? (leadsFechados / totalLeads * 100) : 0.0;

    final topContent = isWide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _dashboard(hoje, kpiMatch, conversao)),
            SizedBox(width: 16),
            Expanded(child: _icpPanel())
          ])
        : Column(children: [
            _dashboard(hoje, kpiMatch, conversao),
            SizedBox(height: 16),
            _icpPanel()
          ]);

    return Container(
      width: widget.width,
      height: widget.height,
      color: t.primaryBackground,
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [topContent, SizedBox(height: 20), _leadsTable()]),
            ),
    );
  }

  double? _parseBRL(String v) {
    if (v.isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.parse(digits) / 100.0;
  }

  String _formatBRLFromNumber(dynamic numValue) {
    if (numValue == null) return '';
    final value = (numValue is num)
        ? numValue.toDouble()
        : double.tryParse(numValue.toString()) ?? 0.0;
    final cents = (value * 100).round();
    return _formatBRL(cents.toString());
  }

  String _formatBRL(String digits) {
    if (digits.isEmpty) return '';
    while (digits.length < 3) digits = '0$digits';
    final intPart = digits.substring(0, digits.length - 2);
    final decPart = digits.substring(digits.length - 2);
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1 && i != intPart.length - 1)
        buf.write('.');
    }
    return 'R\$ ${buf.toString()},$decPart';
  }
}

// ===== MODAL DE EXPORTAÇÃO (REMOVIDO - Não é mais usado) =====
// Os usuários não podem mais exportar configurações ICP
