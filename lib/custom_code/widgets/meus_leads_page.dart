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
import 'dart:convert';

/// Página Completa: Meus Leads
/// Inclui header, filtros, busca e tabela de leads integrados

class MeusLeadsPage extends StatefulWidget {
  const MeusLeadsPage({
    super.key,
    this.width,
    this.height,
    this.onNovoLead,
    this.onConfigICP,
    this.onLeadClick,
  });

  final double? width;
  final double? height;
  final Future<dynamic> Function()? onNovoLead;
  final Future<dynamic> Function()? onConfigICP;
  final Future<dynamic> Function(int leadId)? onLeadClick;

  @override
  State<MeusLeadsPage> createState() => _MeusLeadsPageState();
}

class _MeusLeadsPageState extends State<MeusLeadsPage> {
  // ========== State Management ==========
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  bool _isLoading = true;
  int? _companyId;
  String? _userId;

  // Paginação
  int _currentPage = 0;
  int _rowsPerPage = 10;
  int get _totalPages => (_filteredLeads.length / _rowsPerPage).ceil();

  // Ordenação
  String _sortColumn = 'created_at';
  bool _sortAscending = false;

  // Filtros
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'Todos';

  // Selection
  final Set<int> _selectedLeads = {};
  bool get _allSelected =>
      _selectedLeads.length == _getCurrentPageLeads().length &&
      _getCurrentPageLeads().isNotEmpty;

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

  // ========== Initialization ==========
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
      debugPrint('❌ Init error: $e');
      _showToast('Erro ao carregar dados', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeads() async {
    try {
      setState(() => _isLoading = true);

      final res = await SupaFlow.client
          .from('leads')
          .select()
          .eq('company_id', _companyId!)
          .order(_sortColumn, ascending: _sortAscending);

      if (mounted) {
        setState(() {
          _leads = List<Map<String, dynamic>>.from(res);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load leads error: $e');
      _showToast('Erro ao carregar leads', true);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== Filtros e Ordenação ==========
  void _applyFilters() {
    final search = _searchCtrl.text.toLowerCase();
    List<Map<String, dynamic>> filtered = List.from(_leads);

    // Search filter
    if (search.isNotEmpty) {
      filtered = filtered.where((lead) {
        final name = (lead['name'] ?? '').toString().toLowerCase();
        final email = (lead['email'] ?? '').toString().toLowerCase();
        final phone = (lead['phone'] ?? '').toString().toLowerCase();
        final company = (lead['company'] ?? '').toString().toLowerCase();
        return name.contains(search) ||
            email.contains(search) ||
            phone.contains(search) ||
            company.contains(search);
      }).toList();
    }

    // Status filter
    if (_statusFilter != 'Todos') {
      filtered = filtered.where((lead) => lead['status'] == _statusFilter).toList();
    }

    setState(() {
      _filteredLeads = filtered;
      _currentPage = 0;
      _selectedLeads.clear();
    });
  }

  void _sort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }

      _filteredLeads.sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];

        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return _sortAscending ? -1 : 1;
        if (bVal == null) return _sortAscending ? 1 : -1;

        final comparison = aVal.toString().compareTo(bVal.toString());
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  List<Map<String, dynamic>> _getCurrentPageLeads() {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filteredLeads.length);
    return _filteredLeads.sublist(start, end);
  }

  // ========== Actions ==========
  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedLeads.clear();
      } else {
        for (var lead in _getCurrentPageLeads()) {
          _selectedLeads.add(lead['id']);
        }
      }
    });
  }

  void _toggleSelect(int leadId) {
    setState(() {
      if (_selectedLeads.contains(leadId)) {
        _selectedLeads.remove(leadId);
      } else {
        _selectedLeads.add(leadId);
      }
    });
  }

  Future<void> _exportToCSV() async {
    try {
      final leadsToExport = _selectedLeads.isEmpty
          ? _filteredLeads
          : _filteredLeads.where((l) => _selectedLeads.contains(l['id'])).toList();

      final csv = StringBuffer();
      csv.writeln('Nome,Email,Telefone,Empresa,Status,Score,Data');

      for (var lead in leadsToExport) {
        csv.writeln(
          '${lead['name'] ?? ''},'
          '${lead['email'] ?? ''},'
          '${lead['phone'] ?? ''},'
          '${lead['company'] ?? ''},'
          '${lead['status'] ?? ''},'
          '${lead['score'] ?? ''},'
          '${lead['created_at'] ?? ''}',
        );
      }

      _showToast('${leadsToExport.length} leads exportados!', false);
    } catch (e) {
      debugPrint('❌ Export error: $e');
      _showToast('Erro ao exportar', true);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedLeads.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.inter(color: FlutterFlowTheme.of(context).primaryText),
        ),
        content: Text(
          'Deseja realmente excluir ${_selectedLeads.length} lead(s)?',
          style: GoogleFonts.inter(color: FlutterFlowTheme.of(context).secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupaFlow.client
            .from('leads')
            .delete()
            .in_('id', _selectedLeads.toList());

        _showToast('${_selectedLeads.length} lead(s) excluído(s)', false);
        _selectedLeads.clear();
        await _loadLeads();
      } catch (e) {
        debugPrint('❌ Delete error: $e');
        _showToast('Erro ao excluir leads', true);
      }
    }
  }

  Future<void> _updateStatus(int leadId, String newStatus) async {
    try {
      await SupaFlow.client
          .from('leads')
          .update({'status': newStatus})
          .eq('id', leadId);

      _showToast('Status atualizado', false);
      await _loadLeads();
    } catch (e) {
      debugPrint('❌ Update status error: $e');
      _showToast('Erro ao atualizar status', true);
    }
  }

  // ========== UI Feedback ==========
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: error ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        error ? Icons.error_outline : Icons.check_circle_outline,
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

  // ========== Build Methods ==========
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 768;
    final tablet = size.width >= 768 && size.width < 1024;

    return Container(
      width: widget.width,
      height: widget.height,
      color: theme.primaryBackground,
      child: Column(
        children: [
          _header(theme, mobile),
          _searchAndFilters(theme, mobile),
          if (_selectedLeads.isNotEmpty) _bulkActions(theme, mobile),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : _filteredLeads.isEmpty
                    ? _emptyState(theme)
                    : mobile
                        ? _mobileView(theme)
                        : _tableView(theme, tablet),
          ),
          if (!_isLoading && _filteredLeads.isNotEmpty)
            _pagination(theme, mobile),
        ],
      ),
    );
  }

  Widget _header(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: theme.alternate)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão voltar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.primaryText,
                  size: mobile ? 20 : 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meus Leads',
                  style: GoogleFonts.inter(
                    fontSize: mobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  'Gerencie seus leads',
                  style: GoogleFonts.inter(
                    fontSize: mobile ? 12 : 13,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Botões de ação
          if (!mobile) ...[
            _headerButton(
              Icons.download,
              'Exportar',
              _exportToCSV,
              theme,
              outlined: true,
            ),
            const SizedBox(width: 8),
          ],
          _headerButton(
            Icons.add,
            mobile ? '' : 'Novo Lead',
            () async {
              if (widget.onNovoLead != null) {
                await widget.onNovoLead!();
                await _loadLeads();
              }
            },
            theme,
            primary: true,
          ),
        ],
      ),
    );
  }

  Widget _headerButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    FlutterFlowTheme theme, {
    bool primary = false,
    bool outlined = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: label.isNotEmpty ? Text(label) : const SizedBox(),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary
            ? theme.primary
            : outlined
                ? Colors.transparent
                : theme.primaryBackground,
        foregroundColor: primary
            ? Colors.white
            : outlined
                ? theme.primaryText
                : theme.primaryText,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 12 : 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: outlined
              ? BorderSide(color: theme.alternate, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _searchAndFilters(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 12 : 20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: theme.alternate)),
      ),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: theme.primaryText),
            decoration: InputDecoration(
              hintText: 'Buscar por nome, email ou cidade...',
              hintStyle: GoogleFonts.inter(color: theme.secondaryText),
              prefixIcon: Icon(Icons.search, color: theme.secondaryText),
              filled: true,
              fillColor: theme.primaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filtros de status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Todos',
                'Novo',
                'Em Contato',
                'Conversando',
                'Qualificado'
              ].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
                        _statusFilter = status;
                        _applyFilters();
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primary
                              : theme.primaryBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? theme.primary : theme.alternate,
                            width: isSelected ? 0 : 1,
                          ),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : theme.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Contador de leads
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: theme.secondaryText),
              const SizedBox(width: 6),
              Text(
                '${_filteredLeads.length} lead(s) encontrado(s)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulkActions(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: theme.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_selectedLeads.length} selecionado(s)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete, size: 18),
            label: Text(mobile ? '' : 'Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => setState(() => _selectedLeads.clear()),
            icon: const Icon(Icons.clear, size: 18),
            label: Text(mobile ? '' : 'Limpar'),
            style: TextButton.styleFrom(
              foregroundColor: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: theme.secondaryText,
          ),
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
            'Configure seu ICP para começar a receber leads',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              if (widget.onConfigICP != null) {
                await widget.onConfigICP!();
              }
            },
            icon: const Icon(Icons.settings, size: 18),
            label: Text('Configurar ICP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableView(FlutterFlowTheme theme, bool tablet) {
    final currentLeads = _getCurrentPageLeads();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(theme.primaryBackground),
          dataRowColor: MaterialStateProperty.all(theme.secondaryBackground),
          headingRowHeight: 48,
          dataRowHeight: 60,
          horizontalMargin: 20,
          columnSpacing: tablet ? 20 : 40,
          dividerThickness: 1,
          columns: [
            DataColumn(
              label: Checkbox(
                value: _allSelected,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: theme.primary,
              ),
            ),
            _dataColumn('Nome', 'name', theme),
            _dataColumn('Email', 'email', theme),
            _dataColumn('Telefone', 'phone', theme),
            _dataColumn('Empresa', 'company', theme),
            _dataColumn('Status', 'status', theme),
            _dataColumn('Score', 'score', theme),
            _dataColumn('Data', 'created_at', theme),
            DataColumn(
              label: Text(
                'Ações',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ),
          ],
          rows: currentLeads.map((lead) {
            final leadId = lead['id'] as int;
            final isSelected = _selectedLeads.contains(leadId);

            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelect(leadId),
                    activeColor: theme.primary,
                  ),
                ),
                DataCell(_cellText(lead['name'] ?? '-', theme)),
                DataCell(_cellText(lead['email'] ?? '-', theme)),
                DataCell(_cellText(lead['phone'] ?? '-', theme)),
                DataCell(_cellText(lead['company'] ?? '-', theme)),
                DataCell(_statusBadge(lead['status'] ?? 'Novo', theme)),
                DataCell(_scoreBadge(lead['score'] ?? 0, theme)),
                DataCell(_cellText(_formatDate(lead['created_at']), theme)),
                DataCell(_actions(leadId, lead['status'] ?? 'Novo', theme)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _mobileView(FlutterFlowTheme theme) {
    final currentLeads = _getCurrentPageLeads();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentLeads.length,
      itemBuilder: (context, index) {
        final lead = currentLeads[index];
        final leadId = lead['id'] as int;
        final isSelected = _selectedLeads.contains(leadId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primary : theme.alternate,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.onLeadClick != null) {
                  widget.onLeadClick!(leadId);
                }
              },
              onLongPress: () => _toggleSelect(leadId),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelect(leadId),
                          activeColor: theme.primary,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead['name'] ?? 'Sem nome',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                              if (lead['company'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  lead['company'],
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _statusBadge(lead['status'] ?? 'Novo', theme),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (lead['email'] != null)
                      _mobileRow(Icons.email, lead['email'], theme),
                    if (lead['phone'] != null) ...[
                      const SizedBox(height: 8),
                      _mobileRow(Icons.phone, lead['phone'], theme),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _mobileRow(
                          Icons.calendar_today,
                          _formatDate(lead['created_at']),
                          theme,
                        ),
                        _scoreBadge(lead['score'] ?? 0, theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dataColumn(String label, String column, FlutterFlowTheme theme) {
    final isSorted = _sortColumn == column;

    return DataColumn(
      label: InkWell(
        onTap: () => _sort(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isSorted ? theme.primary : theme.primaryText,
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: theme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cellText(String text, FlutterFlowTheme theme) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, color: theme.primaryText),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _statusBadge(String status, FlutterFlowTheme theme) {
    final colors = {
      'Novo': const Color(0xFF007AFF),
      'Em Contato': const Color(0xFF5856D6),
      'Conversando': const Color(0xFFFF9500),
      'Qualificado': const Color(0xFF34C759),
    };

    final color = colors[status] ?? theme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
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

  Widget _scoreBadge(int score, FlutterFlowTheme theme) {
    Color color;
    if (score >= 80) {
      color = const Color(0xFF34C759);
    } else if (score >= 50) {
      color = const Color(0xFFFF9500);
    } else {
      color = const Color(0xFFFF3B30);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(int leadId, String currentStatus, FlutterFlowTheme theme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: theme.primaryText),
      color: theme.secondaryBackground,
      onSelected: (value) async {
        switch (value) {
          case 'view':
            if (widget.onLeadClick != null) {
              await widget.onLeadClick!(leadId);
            }
            break;
          case 'status':
            _showStatusDialog(leadId, currentStatus, theme);
            break;
          case 'delete':
            _selectedLeads.clear();
            _selectedLeads.add(leadId);
            await _deleteSelected();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18, color: theme.primaryText),
              const SizedBox(width: 12),
              Text('Visualizar', style: GoogleFonts.inter()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: theme.primaryText),
              const SizedBox(width: 12),
              Text('Alterar Status', style: GoogleFonts.inter()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18, color: Color(0xFFFF3B30)),
              const SizedBox(width: 12),
              Text(
                'Excluir',
                style: GoogleFonts.inter(color: const Color(0xFFFF3B30)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStatusDialog(
    int leadId,
    String currentStatus,
    FlutterFlowTheme theme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        String selectedStatus = currentStatus;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.secondaryBackground,
              title: Text(
                'Alterar Status',
                style: GoogleFonts.inter(color: theme.primaryText),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Novo', 'Em Contato', 'Conversando', 'Qualificado']
                    .map((status) {
                  return RadioListTile<String>(
                    title: Text(
                      status,
                      style: GoogleFonts.inter(color: theme.primaryText),
                    ),
                    value: status,
                    groupValue: selectedStatus,
                    activeColor: theme.primary,
                    onChanged: (v) {
                      setDialogState(() => selectedStatus = v!);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _updateStatus(leadId, selectedStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                  ),
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _mobileRow(IconData icon, String text, FlutterFlowTheme theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.secondaryText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _pagination(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${_currentPage + 1} de ${_totalPages == 0 ? 1 : _totalPages}',
            style: GoogleFonts.inter(
              fontSize: mobile ? 12 : 14,
              color: theme.secondaryText,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: theme.primaryText),
                onPressed:
                    _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              ),
              if (!mobile) ..._buildPageNumbers(theme),
              IconButton(
                icon: Icon(Icons.chevron_right, color: theme.primaryText),
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(FlutterFlowTheme theme) {
    List<Widget> pages = [];
    final start = (_currentPage - 2).clamp(0, _totalPages - 1);
    final end = (_currentPage + 2).clamp(0, _totalPages - 1);

    for (int i = start; i <= end && i < _totalPages; i++) {
      pages.add(
        InkWell(
          onTap: () => setState(() => _currentPage = i),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == _currentPage ? theme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: i == _currentPage ? Colors.white : theme.primaryText,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return pages;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return '-';
    }
  }
}
