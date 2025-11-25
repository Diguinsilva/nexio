// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:google_fonts/google_fonts.dart';

class MeusLeadsPage extends StatefulWidget {
  const MeusLeadsPage({
    super.key,
    this.width,
    this.height,
    this.onAdicionarLead,
    this.onEditarLead,
    this.onLeadClick,
  });

  final double? width;
  final double? height;
  final Future<dynamic> Function()? onAdicionarLead;
  final Future<dynamic> Function(int leadId)? onEditarLead;
  final Future<dynamic> Function(int leadId)? onLeadClick;

  @override
  State<MeusLeadsPage> createState() => _MeusLeadsPageState();
}

class _MeusLeadsPageState extends State<MeusLeadsPage> {
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  bool _isLoading = true;
  int? _companyId;
  String? _userId;

  int _currentPage = 0;
  final int _rowsPerPage = 10;
  int get _totalPages => (_filteredLeads.length / _rowsPerPage).ceil();
  int get _totalLeads => _filteredLeads.length;
  int get _startIndex => _currentPage * _rowsPerPage + 1;
  int get _endIndex =>
      ((_currentPage + 1) * _rowsPerPage).clamp(0, _totalLeads);

  final _searchCtrl = TextEditingController();
  String _statusFilter = 'Todos';
  String _prioridadeFilter = 'Todas';

  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _toast?.remove();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user != null) {
        _userId = user.id;
        final data = await SupaFlow.client
            .from('users')
            .select('company_id')
            .eq('auth_user_id', _userId!)
            .maybeSingle();

        if (data != null) {
          _companyId = data['company_id'];
          if (_companyId != null) await _loadLeads();
        }
      }
    } catch (e) {
      debugPrint('Init error: $e');
      _showToast('Erro ao carregar dados', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeads() async {
    try {
      setState(() => _isLoading = true);

      final res = await SupaFlow.client
          .from('agropro_leads')
          .select()
          .eq('company_id', _companyId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _leads = List<Map<String, dynamic>>.from(res);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load leads error: $e');
      _showToast('Erro ao carregar leads', true);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final search = _searchCtrl.text.toLowerCase();
    List<Map<String, dynamic>> filtered = List.from(_leads);

    if (search.isNotEmpty) {
      filtered = filtered.where((lead) {
        final empresa = (lead['company'] ?? '').toString().toLowerCase();
        final segmento = (lead['segmento'] ?? '').toString().toLowerCase();
        final website = (lead['website'] ?? '').toString().toLowerCase();
        final telefone = (lead['phone'] ?? '').toString().toLowerCase();
        return empresa.contains(search) ||
            segmento.contains(search) ||
            website.contains(search) ||
            telefone.contains(search);
      }).toList();
    }

    if (_statusFilter != 'Todos') {
      filtered =
          filtered.where((lead) => lead['status'] == _statusFilter).toList();
    }

    if (_prioridadeFilter != 'Todas') {
      filtered = filtered
          .where((lead) => lead['prioridade'] == _prioridadeFilter)
          .toList();
    }

    setState(() {
      _filteredLeads = filtered;
      _currentPage = 0;
    });
  }

  void _limparFiltros() {
    setState(() {
      _searchCtrl.clear();
      _statusFilter = 'Todos';
      _prioridadeFilter = 'Todas';
      _applyFilters();
    });
  }

  List<Map<String, dynamic>> _getCurrentPageLeads() {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filteredLeads.length);
    return _filteredLeads.sublist(start, end);
  }

  Future<void> _deleteLead(int leadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.inter(
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        content: Text(
          'Deseja realmente excluir este lead?',
          style: GoogleFonts.inter(
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupaFlow.client.from('agropro_leads').delete().eq('id', leadId);
        _showToast('Lead excluído com sucesso', false);
        await _loadLeads();
      } catch (e) {
        debugPrint('Delete error: $e');
        _showToast('Erro ao excluir lead', true);
      }
    }
  }

  void _showToast(String msg, bool error) {
    _toast?.remove();
    _toast = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 80,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (_, double v, __) => Transform.translate(
              offset: Offset(50 * (1 - v), 0),
              child: Opacity(
                opacity: v,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: error
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        error
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          msg,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_toast!);
    Future.delayed(const Duration(seconds: 3), () => _toast?.remove());
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 768;

    return Container(
      width: widget.width,
      height: widget.height,
      color: theme.primaryBackground,
      child: Column(
        children: [
          _buildHeader(theme, mobile),
          _buildFiltrosAvancados(theme, mobile),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primary))
                : _filteredLeads.isEmpty
                    ? _buildEmptyState(theme)
                    : mobile
                        ? _buildMobileView(theme)
                        : _buildTableView(theme),
          ),
          if (!_isLoading && _filteredLeads.isNotEmpty)
            _buildPagination(theme, mobile),
        ],
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 20 : 40,
        vertical: mobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: theme.alternate, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_chart,
                    color: theme.primaryText,
                    size: mobile ? 20 : 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Planilha de Leads',
                    style: GoogleFonts.inter(
                      fontSize: mobile ? 18 : 22,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: mobile ? 32 : 36),
                child: Text(
                  'Gerencie todos os seus leads em um só lugar',
                  style: GoogleFonts.inter(
                    fontSize: mobile ? 12 : 14,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (widget.onAdicionarLead != null) {
                await widget.onAdicionarLead!();
                await _loadLeads();
              }
            },
            icon: Icon(Icons.add, size: mobile ? 16 : 18),
            label: Text(
              mobile ? 'Adicionar' : 'Adicionar Lead',
              style: GoogleFonts.inter(
                fontSize: mobile ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 16 : 20,
                vertical: mobile ? 10 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosAvancados(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: theme.alternate, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros Avançados',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              TextButton(
                onPressed: _limparFiltros,
                child: Text(
                  'Limpar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF9500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          mobile ? _buildFiltrosMobile(theme) : _buildFiltrosDesktop(theme),
        ],
      ),
    );
  }

  Widget _buildFiltrosDesktop(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Icon(Icons.search, color: theme.secondaryText, size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                      hintStyle: GoogleFonts.inter(
                        color: theme.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            'Status',
            _statusFilter,
            ['Todos', 'Lead novo', 'Em contato', 'Qualificado', 'Perdido'],
            (v) => setState(() {
              _statusFilter = v!;
              _applyFilters();
            }),
            theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            'Prioridade',
            _prioridadeFilter,
            ['Todas', 'Alta', 'Média', 'Baixa'],
            (v) => setState(() {
              _prioridadeFilter = v!;
              _applyFilters();
            }),
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltrosMobile(FlutterFlowTheme theme) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    Icon(Icons.search, color: theme.secondaryText, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style:
                      GoogleFonts.inter(fontSize: 14, color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: GoogleFonts.inter(color: theme.secondaryText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Status',
                _statusFilter,
                ['Todos', 'Lead novo', 'Em contato', 'Qualificado', 'Perdido'],
                (v) => setState(() {
                  _statusFilter = v!;
                  _applyFilters();
                }),
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                'Prioridade',
                _prioridadeFilter,
                ['Todas', 'Alta', 'Média', 'Baixa'],
                (v) => setState(() {
                  _prioridadeFilter = v!;
                  _applyFilters();
                }),
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    FlutterFlowTheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.alternate),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: theme.primaryText),
        style: GoogleFonts.inter(fontSize: 14, color: theme.primaryText),
        dropdownColor: theme.secondaryBackground,
        hint:
            Text(label, style: GoogleFonts.inter(color: theme.secondaryText)),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: theme.secondaryText),
          const SizedBox(height: 20),
          Text(
            'Nenhum lead encontrado',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione leads para começar',
            style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(FlutterFlowTheme theme) {
    final currentLeads = _getCurrentPageLeads();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(theme.primaryBackground),
          dataRowColor: WidgetStateProperty.all(theme.secondaryBackground),
          headingRowHeight: 48,
          dataRowHeight: 64,
          horizontalMargin: 24,
          columnSpacing: 32,
          dividerThickness: 1,
          columns: [
            DataColumn(
              label: Text(
                'NOME DA EMPRESA',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'SEGMENTO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'STATUS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'WEBSITE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'TELEFONE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'PRIORIDADE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'IMPORTAÇÃO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'OBSERVAÇÕES',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'AÇÕES',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          rows: currentLeads.map((lead) {
            return DataRow(
              cells: [
                DataCell(Text(
                  lead['company'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(
                  lead['segmento'] ?? 'Saúde/Medicina',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(_buildStatusBadge(lead['status'] ?? 'Lead novo', theme)),
                DataCell(_buildWebsiteLink(lead['website'], theme)),
                DataCell(Text(
                  lead['phone'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(_buildPrioridadeBadge(
                    lead['prioridade'] ?? 'Média', theme)),
                DataCell(Text(
                  lead['importacao'] ?? 'PEG',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(
                  lead['observacoes'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(_buildAcoes(lead['id'], theme)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView(FlutterFlowTheme theme) {
    final currentLeads = _getCurrentPageLeads();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentLeads.length,
      itemBuilder: (context, index) {
        final lead = currentLeads[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lead['company'] ?? 'Sem nome',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  _buildAcoes(lead['id'], theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Segmento: ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lead['segmento'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                  _buildStatusBadge(lead['status'] ?? 'Lead novo', theme),
                ],
              ),
              const SizedBox(height: 8),
              if (lead['website'] != null)
                Row(
                  children: [
                    Text(
                      'Website: ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.secondaryText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lead['website'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Telefone: ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lead['phone'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Prioridade: ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                  _buildPrioridadeBadge(lead['prioridade'] ?? 'Média', theme),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, FlutterFlowTheme theme) {
    Color color;
    switch (status) {
      case 'Lead novo':
        color = const Color(0xFF34C759);
        break;
      case 'Em contato':
        color = const Color(0xFF007AFF);
        break;
      case 'Qualificado':
        color = const Color(0xFFFF9500);
        break;
      case 'Perdido':
        color = const Color(0xFFFF3B30);
        break;
      default:
        color = theme.secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPrioridadeBadge(String prioridade, FlutterFlowTheme theme) {
    Color color;
    IconData icon;

    switch (prioridade) {
      case 'Alta':
        color = const Color(0xFFFF3B30);
        icon = Icons.circle;
        break;
      case 'Média':
        color = const Color(0xFFFF9500);
        icon = Icons.circle;
        break;
      case 'Baixa':
        color = const Color(0xFF34C759);
        icon = Icons.circle;
        break;
      default:
        color = theme.secondaryText;
        icon = Icons.circle_outlined;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          prioridade,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildWebsiteLink(String? website, FlutterFlowTheme theme) {
    if (website == null || website.isEmpty || website == '-') {
      return Text(
        'Não tem',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: theme.secondaryText,
        ),
      );
    }

    return Text(
      'Link',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFFF9500),
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildAcoes(int leadId, FlutterFlowTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, size: 18, color: theme.primaryText),
          onPressed: () async {
            if (widget.onEditarLead != null) {
              await widget.onEditarLead!(leadId);
              await _loadLeads();
            }
          },
          tooltip: 'Editar',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete, size: 18, color: Color(0xFFFF3B30)),
          onPressed: () => _deleteLead(leadId),
          tooltip: 'Excluir',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildPagination(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $_startIndex-$_endIndex de $_totalLeads',
            style: GoogleFonts.inter(
              fontSize: mobile ? 12 : 14,
              color: theme.secondaryText,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                child: Text(
                  'Anterior',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentPage > 0
                        ? theme.primaryText
                        : theme.secondaryText,
                  ),
                ),
              ),
              if (!mobile) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_currentPage + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                child: Text(
                  'Próximo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentPage < _totalPages - 1
                        ? theme.primaryText
                        : theme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
