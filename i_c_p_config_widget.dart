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

import 'package:flutter/services.dart';
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
  bool isSaving = false;

  // Controle de planos
  String planType = 'Performance';
  int planMonthlyLimit = 70;
  int leadsRecebidosMes = 0;
  int leadsDisponiveis = 70;

  int currentStep = 0;
  final int totalSteps = 6;

  final idadeMinCtrl = TextEditingController();
  final idadeMaxCtrl = TextEditingController();
  final rendaMinCtrl = TextEditingController();
  final rendaMaxCtrl = TextEditingController();

  final generoCtrl = TextEditingController();
  final escolaridadeCtrl = TextEditingController();

  List<String> selectedEstados = [];
  List<String> selectedRegioes = [];
  List<String> selectedSegmentos = [];
  List<String> selectedCanais = [];

  final tamanhoEmpresaCtrl = TextEditingController();
  final tempoMercadoCtrl = TextEditingController();
  final empresaFuncionariosCtrl = TextEditingController();

  final preferenciaContatoCtrl = TextEditingController();
  final horarioCtrl = TextEditingController();
  final linguagemCtrl = TextEditingController();

  final cicloCompraCtrl = TextEditingController();
  bool comprouOnline = false;
  bool influenciador = false;
  final budgetMinCtrl = TextEditingController();
  final budgetMaxCtrl = TextEditingController();

  final desafiosCtrl = TextEditingController();
  final objetivosCtrl = TextEditingController();

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

  final estadosOpts = ['SP','MG','RJ','ES','PR','SC','RS','BA','PE','CE'];
  final regioesOpts = ['Norte','Nordeste','Centro-Oeste','Sudeste','Sul'];
  final segmentosOpts = ['Agricultura','Pecuária','Agroindústria','Tecnologia para Agro','Insumos Agrícolas','Máquinas e Equipamentos','Consultoria Agro'];
  final canaisOpts = ['Instagram','Facebook','LinkedIn','WhatsApp','YouTube','E-mail'];
  final statusOpts = ['Todos','Novo','Em Contato','Qualificado','MQL','SQL'];

  final Color cardBg = const Color(0xFF0C0C0C);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    idadeMinCtrl.dispose();
    idadeMaxCtrl.dispose();
    rendaMinCtrl.dispose();
    rendaMaxCtrl.dispose();
    generoCtrl.dispose();
    escolaridadeCtrl.dispose();
    tamanhoEmpresaCtrl.dispose();
    tempoMercadoCtrl.dispose();
    empresaFuncionariosCtrl.dispose();
    preferenciaContatoCtrl.dispose();
    horarioCtrl.dispose();
    linguagemCtrl.dispose();
    cicloCompraCtrl.dispose();
    budgetMinCtrl.dispose();
    budgetMaxCtrl.dispose();
    desafiosCtrl.dispose();
    objetivosCtrl.dispose();
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
      _showToastTopRight('Erro ao carregar: $e', false);
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
      // Se der erro, mantém valores padrão
    }
  }

  Future<void> _countLeadsRecebidos() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

      final response = await SupaFlow.client
          .from('ICP_leads')
          .select('id')
          .eq('company_id', companyId!)
          .gte('created_at', firstDayOfMonth);

      if (mounted) {
        setState(() {
          leadsRecebidosMes = (response as List).length;
          leadsDisponiveis = planMonthlyLimit - leadsRecebidosMes;
          if (leadsDisponiveis < 0) leadsDisponiveis = 0;

          // Ajusta o slider se exceder o disponível
          if (leadsPerDay > leadsDisponiveis) {
            leadsPerDay = leadsDisponiveis.toDouble();
            if (leadsPerDay < 1 && leadsDisponiveis > 0) leadsPerDay = 1;
          }
        });
      }
    } catch (e) {
      // Se der erro, mantém valores padrão
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
          idadeMinCtrl.text = res['idade_min']?.toString() ?? '';
          idadeMaxCtrl.text = res['idade_max']?.toString() ?? '';
          rendaMinCtrl.text = _formatBRLFromNumber(res['renda_min']);
          rendaMaxCtrl.text = _formatBRLFromNumber(res['renda_max']);
          generoCtrl.text = res['genero']?.toString() ?? '';
          escolaridadeCtrl.text = res['escolaridade']?.toString() ?? '';
          selectedEstados = List<String>.from(res['estados'] ?? []);
          selectedRegioes = List<String>.from(res['regioes'] ?? []);
          selectedSegmentos = List<String>.from(res['nicho'] ?? res['nichos'] ?? []);
          selectedCanais = List<String>.from(res['canais'] ?? []);
          tamanhoEmpresaCtrl.text = res['tamanho_empresa']?.toString() ?? '';
          tempoMercadoCtrl.text = res['tempo_mercado']?.toString() ?? '';
          empresaFuncionariosCtrl.text = res['empresa_funcionarios']?.toString() ?? '';
          preferenciaContatoCtrl.text = res['preferencia_contato']?.toString() ?? '';
          horarioCtrl.text = res['horario']?.toString() ?? '';
          linguagemCtrl.text = res['linguagem']?.toString() ?? '';
          cicloCompraCtrl.text = res['ciclo_compra']?.toString() ?? '';
          comprouOnline = res['comprou_online'] ?? false;
          influenciador = res['influenciador'] ?? false;
          budgetMinCtrl.text = _formatBRLFromNumber(res['budget_min']);
          budgetMaxCtrl.text = _formatBRLFromNumber(res['budget_max']);
          desafiosCtrl.text = res['dores']?.toString() ?? '';
          objetivosCtrl.text = res['objetivos']?.toString() ?? '';
          leadsPerDay = (res['leads_por_dia_max'] ?? res['leads_desejados'] ?? 3).toDouble();
          usarIA = res['usar_ia'] ?? true;
          entregarFds = res['entregar_fins_semana'] ?? false;
          prioridade = res['prioridade']?.toString() ?? 'Média';
          notificarNovosLeads = res['notificar_novos_leads'] ?? true;
        });
      }
    } catch (e) {
      _showToastTopRight('Erro ao carregar ICP: $e', false);
    }
  }

  Future<void> _loadLeads() async {
    try {
      var q = SupaFlow.client
          .from('ICP_leads')
          .select()
          .eq('company_id', companyId!);
      if (icpId != null) {
        q = q.eq('icp_id', icpId!);
      }
      final res = await q.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          leads = List<Map<String, dynamic>>.from(res ?? []);
          _applyFilters();
        });
      }
    } catch (e) {
      _showToastTopRight('Erro ao carregar leads: $e', false);
    }
  }

  void _applyFilters() {
    final q = searchQuery.trim().toLowerCase();
    final f = statusFilter;
    filteredLeads = leads.where((lead) {
      final nome = (lead['nome'] ?? '').toString().toLowerCase();
      final empresa = (lead['empresa'] ?? lead['company_name'] ?? '').toString().toLowerCase();
      final status = (lead['status'] ?? '').toString();
      final matchQuery = q.isEmpty || nome.contains(q) || empresa.contains(q);
      final matchStatus = f == 'Todos' || status == f;
      return matchQuery && matchStatus;
    }).toList();
    currentPage = 1;
  }

  void _setSearchQuery(String v) {
    setState(() {
      searchQuery = v;
      _applyFilters();
    });
  }

  void _setStatusFilter(String v) {
    setState(() {
      statusFilter = v;
      _applyFilters();
    });
  }

  List<Map<String, dynamic>> get pagedLeads {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return filteredLeads.sublist(
      start.clamp(0, filteredLeads.length),
      end.clamp(0, filteredLeads.length),
    );
  }

  int get totalPages {
    if (filteredLeads.isEmpty) return 1;
    return ((filteredLeads.length + itemsPerPage - 1) ~/ itemsPerPage);
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  Future<void> _saveICP() async {
    if (companyId == null) return;
    setState(() => isSaving = true);
    try {
      final data = {
        'company_id': companyId!,
        'idade_min': idadeMinCtrl.text.isNotEmpty ? int.parse(idadeMinCtrl.text) : null,
        'idade_max': idadeMaxCtrl.text.isNotEmpty ? int.parse(idadeMaxCtrl.text) : null,
        'renda_min': _parseBRL(rendaMinCtrl.text),
        'renda_max': _parseBRL(rendaMaxCtrl.text),
        'genero': generoCtrl.text,
        'escolaridade': escolaridadeCtrl.text,
        'estados': selectedEstados,
        'regioes': selectedRegioes,
        'nicho': selectedSegmentos,
        'canais': selectedCanais,
        'tamanho_empresa': tamanhoEmpresaCtrl.text,
        'tempo_mercado': tempoMercadoCtrl.text,
        'empresa_funcionarios': empresaFuncionariosCtrl.text.isNotEmpty ? int.tryParse(empresaFuncionariosCtrl.text) : null,
        'preferencia_contato': preferenciaContatoCtrl.text,
        'horario': horarioCtrl.text,
        'linguagem': linguagemCtrl.text,
        'ciclo_compra': cicloCompraCtrl.text,
        'comprou_online': comprouOnline,
        'influenciador': influenciador,
        'budget_min': _parseBRL(budgetMinCtrl.text),
        'budget_max': _parseBRL(budgetMaxCtrl.text),
        'dores': desafiosCtrl.text,
        'objetivos': objetivosCtrl.text,
        'leads_por_dia_max': leadsPerDay.toInt(),
        'usar_ia': usarIA,
        'entregar_fins_semana': entregarFds,
        'prioridade': prioridade,
        'notificar_novos_leads': notificarNovosLeads,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (icpId == null) {
        data['created_at'] = DateTime.now().toIso8601String();
        final res = await SupaFlow.client
            .from('icp_configuration')
            .insert(data)
            .select()
            .single();
        icpId = res['id'];
      } else {
        await SupaFlow.client
            .from('icp_configuration')
            .update(data)
            .eq('id', icpId!);
      }
      _showToastTopRight('Configuração salva', true);
      await _loadLeads();
    } catch (e) {
      _showToastTopRight('Erro ao salvar: $e', false);
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _exportICP() async {
    // Verifica se há leads disponíveis
    if (leadsDisponiveis <= 0) {
      _showToastTopRight('Limite mensal de leads atingido. Aguarde o próximo ciclo.', false);
      return;
    }

    // Monta o payload com todos os dados do ICP + informações de plano
    final icpData = {
      'company_id': companyId,
      'icp_id': icpId,
      'user_id': userId,

      // DADOS DO PLANO
      'plan_type': planType,
      'plan_monthly_limit': planMonthlyLimit,
      'leads_recebidos_mes': leadsRecebidosMes,
      'leads_disponiveis': leadsDisponiveis,
      'leads_solicitados': leadsPerDay.toInt(),

      // DEMOGRÁFICO
      'idade_min': idadeMinCtrl.text.isNotEmpty ? int.tryParse(idadeMinCtrl.text) : null,
      'idade_max': idadeMaxCtrl.text.isNotEmpty ? int.tryParse(idadeMaxCtrl.text) : null,
      'renda_min': _parseBRL(rendaMinCtrl.text),
      'renda_max': _parseBRL(rendaMaxCtrl.text),
      'genero': generoCtrl.text,
      'escolaridade': escolaridadeCtrl.text,
      'estados': selectedEstados,
      'regioes': selectedRegioes,

      // FIRMOGRÁFICO
      'tamanho_empresa': tamanhoEmpresaCtrl.text,
      'tempo_mercado': tempoMercadoCtrl.text,
      'empresa_funcionarios': empresaFuncionariosCtrl.text.isNotEmpty ? int.tryParse(empresaFuncionariosCtrl.text) : null,
      'segmentos': selectedSegmentos,

      // CANAIS
      'canais': selectedCanais,
      'preferencia_contato': preferenciaContatoCtrl.text,
      'horario': horarioCtrl.text,
      'linguagem': linguagemCtrl.text,

      // COMPORTAMENTO
      'ciclo_compra': cicloCompraCtrl.text,
      'comprou_online': comprouOnline,
      'influenciador': influenciador,
      'budget_min': _parseBRL(budgetMinCtrl.text),
      'budget_max': _parseBRL(budgetMaxCtrl.text),

      // DORES E OBJETIVOS
      'dores': desafiosCtrl.text,
      'objetivos': objetivosCtrl.text,

      // PREFERÊNCIAS
      'leads_por_dia_max': leadsPerDay.toInt(),
      'usar_ia': usarIA,
      'entregar_fins_semana': entregarFds,
      'prioridade': prioridade,
      'notificar_novos_leads': notificarNovosLeads,
    };

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExportICPModal(icpData: icpData, onSuccess: _countLeadsRecebidos),
    );
  }

  void _exportCSV() {
    if (filteredLeads.isEmpty) {
      _showToastTopRight('Nenhum lead para exportar', false);
      return;
    }
    final csv = StringBuffer();
    csv.writeln('Nome,Empresa,Email,Telefone,Status,Segmento,Prioridade,Cidade,Estado');
    for (final lead in filteredLeads) {
      csv.write('"${lead['nome'] ?? ''}"');
      csv.write(',"${lead['empresa'] ?? lead['company_name'] ?? ''}"');
      csv.write(',"${lead['email'] ?? ''}"');
      csv.write(',"${lead['telefone'] ?? lead['whatsapp'] ?? ''}"');
      csv.write(',"${lead['status'] ?? 'Novo'}"');
      csv.write(',"${lead['segmento'] ?? lead['segment'] ?? ''}"');
      csv.write(',"${lead['priority'] ?? 'Média'}"');
      csv.write(',"${lead['cidade'] ?? ''}"');
      csv.write(',"${lead['estado'] ?? ''}"');
      csv.writeln();
    }
    _showToastTopRight('CSV gerado: ${filteredLeads.length} leads', true);
  }

  void _showToastTopRight(String msg, bool success) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final t = FlutterFlowTheme.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 20,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 250),
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: success ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(success ? Icons.check_circle : Icons.error, color: t.secondaryBackground),
                    const SizedBox(width: 8),
                    Text(msg, style: t.bodyMedium.override(fontFamily: t.bodyMediumFamily, color: t.secondaryBackground)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  final Color _iconTileBg = const Color(0x22000000);

  Widget _metricCardBox(String title, String value, IconData icon, String subtitle) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(), style: t.labelMedium),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconTileBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: t.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: t.titleLarge),
          const Spacer(),
          Text(subtitle, style: t.labelSmall.override(fontFamily: t.labelSmallFamily, color: t.secondaryText)),
        ],
      ),
    );
  }

  Widget _dashboardSection(int leadsHoje) {
    final t = FlutterFlowTheme.of(context);
    final percentUsed = planMonthlyLimit > 0 ? (leadsRecebidosMes / planMonthlyLimit * 100).clamp(0, 100) : 0.0;

    return Container(
      height: 440,
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard de Performance', style: t.titleMedium),
                    const SizedBox(height: 4),
                    Text('Visão geral dos seus leads e métricas de conversão', style: t.labelSmall.override(fontFamily: t.labelSmallFamily, color: t.secondaryText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Plano: $planType',
                  style: t.labelSmall.override(
                    fontFamily: t.labelSmallFamily,
                    color: t.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Indicador de progresso do plano
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.alternate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Leads Mensais', style: t.labelMedium),
                    Text('$leadsRecebidosMes / $planMonthlyLimit', style: t.titleSmall.override(fontFamily: t.titleSmallFamily, color: t.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentUsed / 100,
                    minHeight: 8,
                    backgroundColor: t.alternate,
                    color: percentUsed >= 90 ? const Color(0xFFEF4444) : t.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$leadsDisponiveis leads disponíveis',
                  style: t.labelSmall.override(
                    fontFamily: t.labelSmallFamily,
                    color: leadsDisponiveis > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _metricCardBox('Leads Hoje', leadsHoje.toString(), Icons.show_chart, 'Recebidos hoje')),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCardBox('Total de Contatos', leads.length.toString(), Icons.call, 'Leads importados')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricCardBox('KPI Match', '0.0%', Icons.radio_button_checked, 'Taxa de correspondência')),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCardBox('Conversão', '0%', Icons.insert_chart_outlined, 'Sem dados ainda')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, String hint) {
    final t = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: t.primaryBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.alternate),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.alternate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.primary),
      ),
      labelStyle: t.bodySmall,
      hintStyle: t.labelMedium,
    );
  }

  Widget _chipGroup(List<String> options, List<String> selected) {
    final t = FlutterFlowTheme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSel = selected.contains(opt);
        return ChoiceChip(
          selected: isSel,
          label: Text(opt, style: t.labelMedium),
          selectedColor: t.primary,
          backgroundColor: t.secondaryBackground,
          labelStyle: t.labelMedium.override(
            fontFamily: t.labelMediumFamily,
            color: isSel ? t.secondaryBackground : t.primaryText,
          ),
          onSelected: (v) {
            setState(() {
              if (v) {
                selected.add(opt);
              } else {
                selected.remove(opt);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String text) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1F3A8A), borderRadius: BorderRadius.circular(16)),
      child: Text(text.toUpperCase(), style: t.labelSmall.override(fontFamily: t.labelSmallFamily, color: const Color(0xFF93C5FD), fontWeight: FontWeight.w700)),
    );
  }

  Widget _priorityIndicator(String p) {
    final t = FlutterFlowTheme.of(context);
    Color dot;
    switch (p.toLowerCase()) {
      case 'alta':
        dot = t.primary;
        break;
      case 'baixa':
        dot = const Color(0xFF3B82F6);
        break;
      default:
        dot = const Color(0xFF9CA3AF);
    }
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(p, style: t.bodyMedium),
      ],
    );
  }

  Widget _searchFilterRow() {
    final t = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: t.primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.alternate),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, color: t.secondaryText, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: _setSearchQuery,
                    decoration: const InputDecoration.collapsed(hintText: 'Buscar leads...'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: t.primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.alternate),
            ),
            child: DropdownButton<String>(
              value: statusFilter,
              items: statusOpts.map((s) => DropdownMenuItem(value: s, child: Text(s, style: t.bodyMedium))).toList(),
              onChanged: (v) {
                if (v != null) _setStatusFilter(v);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _exportCSV,
          style: ElevatedButton.styleFrom(
            backgroundColor: t.primary,
            foregroundColor: t.secondaryBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Exportar CSV'),
        ),
      ],
    );
  }

  Widget _leadsTableSection() {
    final t = FlutterFlowTheme.of(context);
    final flex = const [28, 18, 14, 14, 12, 14];

    Widget headerCell(String text, int f) {
      return Expanded(
        flex: f,
        child: Text(text, style: t.labelMedium.override(fontFamily: t.labelMediumFamily, color: t.secondaryText)),
      );
    }

    Widget cellText(String text, int f, {FontWeight? weight}) {
      return Expanded(
        flex: f,
        child: Text(text, overflow: TextOverflow.ellipsis, style: t.bodyMedium.override(fontFamily: t.bodyMediumFamily, fontWeight: weight ?? FontWeight.normal)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planilha de Leads', style: t.titleMedium),
          const SizedBox(height: 12),
          _searchFilterRow(),
          const SizedBox(height: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: t.primaryBackground, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                headerCell('Empresa', flex[0]),
                headerCell('Segmento', flex[1]),
                headerCell('Status', flex[2]),
                headerCell('Telefone', flex[3]),
                headerCell('Prioridade', flex[4]),
                headerCell('Ações', flex[5]),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pagedLeads.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: t.alternate),
            itemBuilder: (_, i) {
              final l = pagedLeads[i];
              final empresa = (l['empresa'] ?? l['company_name'] ?? '').toString();
              final segmento = (l['segmento'] ?? l['segment'] ?? '').toString();
              final status = (l['status'] ?? 'LEAD NOVO').toString();
              final telefone = (l['telefone'] ?? l['whatsapp'] ?? '').toString();
              final p = (l['priority'] ?? 'Média').toString();

              return Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: i.isEven ? t.secondaryBackground : t.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    cellText(empresa, flex[0], weight: FontWeight.w600),
                    cellText(segmento, flex[1]),
                    Expanded(flex: flex[2], child: Align(alignment: Alignment.centerLeft, child: _statusBadge(status))),
                    cellText(telefone, flex[3]),
                    Expanded(flex: flex[4], child: _priorityIndicator(p)),
                    Expanded(
                      flex: flex[5],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(icon: Icon(Icons.visibility, color: t.secondaryText, size: 18), onPressed: () {}),
                          IconButton(icon: Icon(Icons.edit, color: t.secondaryText, size: 18), onPressed: () {}),
                          IconButton(icon: Icon(Icons.delete, color: t.secondaryText, size: 18), onPressed: () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mostrando ${(filteredLeads.isEmpty) ? 0 : ((currentPage - 1) * itemsPerPage + 1)}–'
                  '${((currentPage - 1) * itemsPerPage + pagedLeads.length)} de ${filteredLeads.length} leads',
                  style: t.labelSmall,
                ),
              ),
              IconButton(onPressed: previousPage, icon: Icon(Icons.chevron_left, color: t.secondaryText)),
              Text('$currentPage', style: t.bodyMedium),
              IconButton(onPressed: nextPage, icon: Icon(Icons.chevron_right, color: t.secondaryText)),
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
        border: Border.all(color: t.alternate),
      ),
      alignment: Alignment.center,
      child: Text(
        '${i + 1}',
        style: t.labelMedium.override(
          fontFamily: t.labelMediumFamily,
          color: currentStep == i ? t.secondaryBackground : t.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _stepLine() {
    final t = FlutterFlowTheme.of(context);
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: t.alternate.withOpacity(0.4),
      ),
    );
  }

  void _maskBRL(TextEditingController ctrl, String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    var d = digits.isEmpty ? '0' : digits;
    while (d.length < 3) {
      d = '0$d';
    }
    final intPart = d.substring(0, d.length - 2);
    final decPart = d.substring(d.length - 2);
    final sb = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      sb.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1 && i != intPart.length - 1) {
        sb.write('.');
      }
    }
    final formatted = 'R\$ ${sb.toString()},$decPart';
    ctrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }

  Widget stepContent() {
    final t = FlutterFlowTheme.of(context);
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: idadeMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Idade Mínima', 'Ex: 25'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: idadeMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Idade Máxima', 'Ex: 65'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rendaMinCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _maskBRL(rendaMinCtrl, v),
                    decoration: _inputDeco('Renda Mínima (R\$)', 'Ex: 5000'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: rendaMaxCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _maskBRL(rendaMaxCtrl, v),
                    decoration: _inputDeco('Renda Máxima (R\$)', 'Ex: 50000'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: generoCtrl,
                    decoration: _inputDeco('Gênero', 'Ex: Indiferente'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: escolaridadeCtrl,
                    decoration: _inputDeco('Escolaridade', 'Ex: Superior completo'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estados', style: t.titleSmall),
              const SizedBox(height: 8),
              _chipGroup(estadosOpts, selectedEstados),
              const SizedBox(height: 16),
              Text('Regiões', style: t.titleSmall),
              const SizedBox(height: 8),
              _chipGroup(regioesOpts, selectedRegioes),
            ]),
          ],
        );
      case 1:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tamanhoEmpresaCtrl,
                    decoration: _inputDeco('Tamanho da empresa', 'Ex: Média'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: tempoMercadoCtrl,
                    decoration: _inputDeco('Tempo de mercado', 'Ex: 5 anos'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: empresaFuncionariosCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Funcionários', 'Ex: 50'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()),
              ],
            ),
            const SizedBox(height: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Segmentos', style: t.titleSmall),
              const SizedBox(height: 8),
              _chipGroup(segmentosOpts, selectedSegmentos),
            ]),
          ],
        );
      case 2:
        return Column(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Canais', style: t.titleSmall),
              const SizedBox(height: 8),
              _chipGroup(canaisOpts, selectedCanais),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: preferenciaContatoCtrl,
                    decoration: _inputDeco('Preferência de contato', 'Ex: WhatsApp'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: horarioCtrl,
                    decoration: _inputDeco('Horário', 'Ex: 9h–18h'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: linguagemCtrl,
                    decoration: _inputDeco('Linguagem', 'Ex: Formal'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cicloCompraCtrl,
                    decoration: _inputDeco('Ciclo de compra', 'Ex: 30 dias'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    value: comprouOnline,
                    onChanged: (v) => setState(() => comprouOnline = v),
                    title: Text('Comprou online', style: t.bodyMedium),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    value: influenciador,
                    onChanged: (v) => setState(() => influenciador = v),
                    title: Text('Influenciador', style: t.bodyMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: budgetMinCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _maskBRL(budgetMinCtrl, v),
                    decoration: _inputDeco('Budget Mínimo (R\$)', 'Ex: 5000'),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: budgetMaxCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _maskBRL(budgetMaxCtrl, v),
                    decoration: _inputDeco('Budget Máximo (R\$)', 'Ex: 50000'),
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            TextField(
              controller: desafiosCtrl,
              maxLines: 3,
              decoration: _inputDeco('Dores', 'Principais desafios'),
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: objetivosCtrl,
              maxLines: 3,
              decoration: _inputDeco('Objetivos', 'Objetivos'),
              style: t.bodyMedium,
            ),
          ],
        );
      default:
        final maxLeadsSlider = leadsDisponiveis > 0 ? leadsDisponiveis.toDouble() : 1.0;
        final divisionsSlider = leadsDisponiveis > 1 ? leadsDisponiveis - 1 : 0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Leads por dia (Disponíveis: $leadsDisponiveis)', style: t.titleSmall),
                      Slider(
                        value: leadsPerDay.clamp(1, maxLeadsSlider),
                        min: 1,
                        max: maxLeadsSlider,
                        divisions: divisionsSlider,
                        label: '${leadsPerDay.round()} leads',
                        onChanged: leadsDisponiveis > 0 ? (v) => setState(() => leadsPerDay = v) : null,
                      ),
                      if (leadsDisponiveis <= 0)
                        Text(
                          'Limite mensal atingido',
                          style: t.labelSmall.override(
                            fontFamily: t.labelSmallFamily,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: usarIA,
                        onChanged: (v) => setState(() => usarIA = v),
                        title: Text('Usar IA', style: t.bodyMedium),
                      ),
                      SwitchListTile(
                        value: entregarFds,
                        onChanged: (v) => setState(() => entregarFds = v),
                        title: Text('Entregar fins de semana', style: t.bodyMedium),
                      ),
                      SwitchListTile(
                        value: notificarNovosLeads,
                        onChanged: (v) => setState(() => notificarNovosLeads = v),
                        title: Text('Notificar novos leads', style: t.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.alternate),
                      ),
                      child: DropdownButton<String>(
                        value: prioridade,
                        items: ['Alta','Média','Baixa'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: t.bodyMedium))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => prioridade = v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()),
              ],
            ),
          ],
        );
    }
  }

  Widget _icpHeader() {
    final t = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Configuração do Cliente Ideal (ICP)', style: t.titleMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('Ativo', style: t.labelSmall.override(fontFamily: t.labelSmallFamily, color: const Color(0xFF22C55E))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Etapa ${currentStep + 1} de $totalSteps: Demográfico', style: t.labelSmall.override(fontFamily: t.labelSmallFamily, color: t.primary)),
      ],
    );
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final width = widget.width ?? double.infinity;
    final isWide = MediaQuery.of(context).size.width >= 1024;

    int leadsHoje = 0;
    try {
      final now = DateTime.now();
      leadsHoje = leads.where((l) {
        final s = l['created_at'];
        if (s == null) return false;
        final dt = DateTime.tryParse(s.toString());
        if (dt == null) return false;
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      }).length;
    } catch (_) {}

    Widget icpPanel = Container(
      height: 440,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icpHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              _stepCircle(0), _stepLine(),
              _stepCircle(1), _stepLine(),
              _stepCircle(2), _stepLine(),
              _stepCircle(3), _stepLine(),
              _stepCircle(4), _stepLine(),
              _stepCircle(5),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: stepContent(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _prevStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.secondaryBackground,
                  foregroundColor: t.primaryText,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Anterior'),
              ),
              const Spacer(),
              if (currentStep < totalSteps - 1)
                ElevatedButton(
                  onPressed: () => setState(() => currentStep++),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.secondaryBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Próximo'),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    await _saveICP();
                    await _exportICP();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.secondaryBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Exportar'),
                ),
            ],
          ),
        ],
      ),
    );

    final topContent = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _dashboardSection(leadsHoje)),
              const SizedBox(width: 16),
              Expanded(child: icpPanel),
            ],
          )
        : Column(
            children: [
              _dashboardSection(leadsHoje),
              const SizedBox(height: 16),
              icpPanel,
            ],
          );

    return Container(
      width: width,
      height: widget.height,
      color: t.primaryBackground,
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  topContent,
                  const SizedBox(height: 20),
                  _leadsTableSection(),
                ],
              ),
            ),
    );
  }

  double? _parseBRL(String v) {
    if (v.isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final cents = double.parse(digits) / 100.0;
    return cents;
  }

  String _formatBRLFromNumber(dynamic numValue) {
    if (numValue == null) return '';
    final value = (numValue is num) ? numValue.toDouble() : double.tryParse(numValue.toString()) ?? 0.0;
    final cents = (value * 100).round();
    return _formatBRL(cents.toString());
  }

  String _formatBRL(String digits) {
    if (digits.isEmpty) return '';
    while (digits.length < 3) {
      digits = '0$digits';
    }
    final intPart = digits.substring(0, digits.length - 2);
    final decPart = digits.substring(digits.length - 2);
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1 && i != intPart.length - 1) {
        buf.write('.');
      }
    }
    return 'R\$ ${buf.toString()},$decPart';
  }
}

class _ExportICPModal extends StatefulWidget {
  final Map<String, dynamic> icpData;
  final Function? onSuccess;

  const _ExportICPModal({required this.icpData, this.onSuccess});

  @override
  State<_ExportICPModal> createState() => _ExportICPModalState();
}

class _ExportICPModalState extends State<_ExportICPModal> {
  String state = 'loading'; // loading, success, error
  int leadsCount = 0;
  String errorMessage = '';
  List<dynamic> leads = [];

  // URL do webhook N8N
  static const String webhookUrl = 'https://vendai-n8n.aw5nou.easypanel.host/webhook/eaeeb03b-7336-4e40-ac00-6d644100c6b1';

  @override
  void initState() {
    super.initState();
    _processExport();
  }

  Future<void> _processExport() async {
    try {
      // Faz POST para o webhook N8N
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(widget.icpData),
      );

      if (response.statusCode == 200) {
        // Parse da resposta
        final responseData = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            // Verifica se foi sucesso
            if (responseData['success'] == true) {
              state = 'success';
              leadsCount = responseData['leads_count'] ?? responseData['leadsCount'] ?? 0;
              leads = responseData['leads'] ?? [];

              // Chama o callback de sucesso para atualizar contadores
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              }
            } else {
              state = 'error';
              errorMessage = responseData['message'] ?? 'Erro ao processar leads. Tente novamente.';
            }
          });
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          state = 'error';
          errorMessage = 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == 'loading') ..._buildLoadingState(t),
            if (state == 'success') ..._buildSuccessState(t),
            if (state == 'error') ..._buildErrorState(t),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoadingState(FlutterFlowTheme t) {
    return [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: t.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: t.primary,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Extraindo Leads...',
        style: t.titleLarge.override(
          fontFamily: t.titleLargeFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Nossa IA está analisando o mercado para encontrar os melhores contatos para o seu ICP.',
        textAlign: TextAlign.center,
        style: t.bodyMedium.override(
          fontFamily: t.bodyMediumFamily,
          color: t.secondaryText,
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: t.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Processando dados em tempo real',
              style: t.labelSmall.override(
                fontFamily: t.labelSmallFamily,
                color: t.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancelar',
          style: t.bodyMedium.override(
            fontFamily: t.bodyMediumFamily,
            color: t.secondaryText,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSuccessState(FlutterFlowTheme t) {
    return [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Color(0xFF22C55E),
          size: 50,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Leads Extraídos com Sucesso!',
        style: t.titleLarge.override(
          fontFamily: t.titleLargeFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Encontramos $leadsCount leads qualificados que correspondem ao seu perfil de cliente ideal.',
        textAlign: TextAlign.center,
        style: t.bodyMedium.override(
          fontFamily: t.bodyMediumFamily,
          color: t.secondaryText,
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.alternate),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Fechar',
                style: t.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: t.secondaryBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ver Leads'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildErrorState(FlutterFlowTheme t) {
    return [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline,
          color: Color(0xFFEF4444),
          size: 50,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Erro ao Extrair Leads',
        style: t.titleLarge.override(
          fontFamily: t.titleLargeFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        errorMessage,
        textAlign: TextAlign.center,
        style: t.bodyMedium.override(
          fontFamily: t.bodyMediumFamily,
          color: t.secondaryText,
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.alternate),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Fechar',
                style: t.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  state = 'loading';
                  _processExport();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: t.secondaryBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ),
        ],
      ),
    ];
  }
}

class BrlCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var d = digits.isEmpty ? '0' : digits;
    while (d.length < 3) {
      d = '0$d';
    }
    final intPart = d.substring(0, d.length - 2);
    final decPart = d.substring(d.length - 2);
    final sb = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      sb.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1 && i != intPart.length - 1) {
        sb.write('.');
      }
    }
    final formatted = 'R\$ ${sb.toString()},$decPart';
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
