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
import 'package:http/http.dart' as http;
import 'dart:convert';

class ICPConfigWidget extends StatefulWidget {
  const ICPConfigWidget({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  State<ICPConfigWidget> createState() => _ICPConfigWidgetState();
}

class _ICPConfigWidgetState extends State<ICPConfigWidget> {
  // State
  int? _companyId;
  String? _userId;
  int? _icpId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isProcessing = false;
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Controllers
  final _idadeMinCtrl = TextEditingController();
  final _idadeMaxCtrl = TextEditingController();
  final _rendaMinCtrl = TextEditingController();
  final _rendaMaxCtrl = TextEditingController();

  // Data
  List<String> _estados = [];
  List<String> _segmentos = [];
  List<String> _canais = [];
  String _horario = 'Manhã';
  String _linguagem = 'Informal';
  bool _comprouOnline = false;
  int _leadsMax = 3;
  bool _usarIA = true;
  bool _entregarFds = false;

  final _estadosOpts = ['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];
  final _segmentosOpts = ['Agricultura','Pecuária','Agroindústria','Tecnologia Agro','Insumos','Máquinas','Consultoria','Cooperativas','Distribuidores','Exportação'];
  final _canaisOpts = ['Instagram','Facebook','YouTube','WhatsApp','TikTok','LinkedIn','Site','E-mail'];

  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _toast?.remove();
    _idadeMinCtrl.dispose();
    _idadeMaxCtrl.dispose();
    _rendaMinCtrl.dispose();
    _rendaMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user != null) {
        _userId = user.id;
        final data = await SupaFlow.client.from('users').select('company_id').eq('auth_user_id', _userId!).maybeSingle();
        if (data != null) {
          _companyId = data['company_id'];
          if (_companyId != null) await _loadICP();
        }
      }
    } catch (e) {
      debugPrint('❌ Init error: $e');
      _showToast('Erro ao carregar', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadICP() async {
    try {
      final res = await SupaFlow.client.from('icp_configuration').select().eq('company_id', _companyId!).maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _icpId = res['id'];
          _idadeMinCtrl.text = res['idade_min']?.toString() ?? '';
          _idadeMaxCtrl.text = res['idade_max']?.toString() ?? '';
          _rendaMinCtrl.text = res['renda_min']?.toString() ?? '';
          _rendaMaxCtrl.text = res['renda_max']?.toString() ?? '';
          _estados = List<String>.from(res['estados'] ?? []);
          _segmentos = List<String>.from(res['nichos'] ?? []);
          _leadsMax = res['leads_por_dia_max'] ?? 3;
          _usarIA = res['usar_ia'] ?? true;
          _entregarFds = res['entregar_fins_semana'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load error: $e');
    }
  }

  Future<void> _save() async {
    if (_companyId == null) return;
    setState(() => _isSaving = true);

    try {
      final data = {
        'company_id': _companyId!,
        'idade_min': _idadeMinCtrl.text.isNotEmpty ? int.parse(_idadeMinCtrl.text) : null,
        'idade_max': _idadeMaxCtrl.text.isNotEmpty ? int.parse(_idadeMaxCtrl.text) : null,
        'renda_min': _rendaMinCtrl.text.isNotEmpty ? double.parse(_rendaMinCtrl.text) : null,
        'renda_max': _rendaMaxCtrl.text.isNotEmpty ? double.parse(_rendaMaxCtrl.text) : null,
        'estados': _estados,
        'nichos': _segmentos,
        'leads_por_dia_max': _leadsMax,
        'usar_ia': _usarIA,
        'entregar_fins_semana': _entregarFds,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_icpId == null) {
        data['created_at'] = DateTime.now().toIso8601String();
        final res = await SupaFlow.client.from('icp_configuration').insert(data).select().single();
        _icpId = res['id'];
      } else {
        await SupaFlow.client.from('icp_configuration').update(data).eq('id', _icpId!);
      }

      setState(() {
        _isSaving = false;
        _isProcessing = true;
      });

      await _webhook();
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showToast('Erro ao salvar', true);
      setState(() => _isSaving = false);
    }
  }

  Future<void> _webhook() async {
    try {
      const url = 'https://seu-n8n.com/webhook/processar-icp';

      final payload = {
        'user_id': _userId,
        'company_id': _companyId,
        'icp': {
          'idade_min': _idadeMinCtrl.text,
          'idade_max': _idadeMaxCtrl.text,
          'renda_min': _rendaMinCtrl.text,
          'renda_max': _rendaMaxCtrl.text,
          'estados': _estados,
          'segmentos': _segmentos,
          'canais': _canais,
          'horario': _horario,
          'linguagem': _linguagem,
          'comprou_online': _comprouOnline,
          'leads_max': _leadsMax,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-API-Key': 'SUA_KEY'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        setState(() => _isProcessing = false);
        _showSuccess();
        await Future.delayed(const Duration(seconds: 2));
        _showToast('ICP ativo! Processando leads...', false);
      } else {
        throw Exception('Webhook error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Webhook error: $e');
      setState(() => _isProcessing = false);
      _showToast('ICP salvo, mas erro no processamento', true);
    }
  }

  void _showToast(String msg, bool error) {
    _toast?.remove();
    _toast = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 80, right: 20,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: error ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (_, double v, __) => Transform.scale(
            scale: v,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF34C759).withOpacity(0.4), blurRadius: 30, spreadRadius: 10)],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () => Navigator.pop(context));
  }

  bool _validate() {
    switch (_currentStep) {
      case 0:
        if (_idadeMinCtrl.text.isEmpty || _idadeMaxCtrl.text.isEmpty) {
          _showToast('Idade obrigatória', true);
          return false;
        }
        if (int.parse(_idadeMinCtrl.text) >= int.parse(_idadeMaxCtrl.text)) {
          _showToast('Idade min < max', true);
          return false;
        }
        return true;
      case 1:
        if (_estados.isEmpty) {
          _showToast('Selecione estados', true);
          return false;
        }
        return true;
      case 2:
        if (_segmentos.isEmpty) {
          _showToast('Selecione segmentos', true);
          return false;
        }
        return true;
      case 3:
        if (_canais.isEmpty) {
          _showToast('Selecione canais', true);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (_validate()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
      } else {
        _save();
      }
    }
  }

  void _prev() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 768;

    if (_isLoading) {
      return Container(
        width: widget.width, height: widget.height, color: theme.primaryBackground,
        child: Center(child: CircularProgressIndicator(color: theme.primary)),
      );
    }

    return Container(
      width: widget.width, height: widget.height, color: theme.primaryBackground,
      child: Stack(
        children: [
          Column(
            children: [
              _header(theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(mobile ? 16 : 32),
                  child: Column(
                    children: [
                      _progress(theme, mobile),
                      const SizedBox(height: 32),
                      _stepContent(theme, mobile),
                      const SizedBox(height: 32),
                      _buttons(theme, mobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isSaving || _isProcessing) _loading(theme),
        ],
      ),
    );
  }

  Widget _header(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.secondaryBackground, border: Border(bottom: BorderSide(color: theme.alternate))),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.arrow_back, color: theme.primaryText), onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configuração de ICP', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: theme.primaryText)),
              Text('Defina seu perfil ideal', style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progress(FlutterFlowTheme theme, bool mobile) {
    final steps = ['Demográfico', 'Localização', 'Segmento', 'Comportamento', 'Cadência'];

    if (mobile) {
      return Column(
        children: [
          LinearProgressIndicator(value: (_currentStep + 1) / _totalSteps, backgroundColor: theme.alternate, valueColor: AlwaysStoppedAnimation(theme.primary)),
          const SizedBox(height: 12),
          Text('Passo ${_currentStep + 1} de $_totalSteps: ${steps[_currentStep]}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
        ],
      );
    }

    return Row(
      children: List.generate(_totalSteps, (i) {
        final active = i == _currentStep;
        final done = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active ? theme.primary.withOpacity(0.1) : done ? const Color(0xFF34C759).withOpacity(0.1) : theme.secondaryBackground,
                    border: Border.all(color: active ? theme.primary : done ? const Color(0xFF34C759) : theme.alternate, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: active ? theme.primary : done ? const Color(0xFF34C759) : theme.alternate, shape: BoxShape.circle),
                        child: Center(child: done ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${i + 1}', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(height: 8),
                      Text(steps[i], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? theme.primary : done ? const Color(0xFF34C759) : theme.secondaryText), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              if (i < _totalSteps - 1) Container(width: 20, height: 2, color: done ? const Color(0xFF34C759) : theme.alternate),
            ],
          ),
        );
      }),
    );
  }

  Widget _stepContent(FlutterFlowTheme theme, bool mobile) {
    switch (_currentStep) {
      case 0: return _stepDemo(theme);
      case 1: return _stepLoc(theme);
      case 2: return _stepSeg(theme);
      case 3: return _stepComp(theme);
      case 4: return _stepCad(theme);
      default: return Container();
    }
  }

  Widget _stepDemo(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.alternate)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informações Demográficas', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: theme.primaryText)),
          const SizedBox(height: 8),
          Text('Faixa etária e renda', style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _field('Idade Mín *', _idadeMinCtrl, theme, hint: '18', num: true)),
              const SizedBox(width: 16),
              Expanded(child: _field('Idade Máx *', _idadeMaxCtrl, theme, hint: '65', num: true)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field('Renda Mín (R\$)', _rendaMinCtrl, theme, hint: '5000', num: true)),
              const SizedBox(width: 16),
              Expanded(child: _field('Renda Máx (R\$)', _rendaMaxCtrl, theme, hint: '50000', num: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepLoc(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.alternate)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Localização', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: theme.primaryText)),
          const SizedBox(height: 8),
          Text('Estados de atuação', style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _estadosOpts.map((e) {
              final sel = _estados.contains(e);
              return InkWell(
                onTap: () => setState(() => sel ? _estados.remove(e) : _estados.add(e)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? theme.primary.withOpacity(0.1) : theme.primaryBackground,
                    border: Border.all(color: sel ? theme.primary : theme.alternate, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel) ...[Icon(Icons.check, size: 16, color: theme.primary), const SizedBox(width: 6)],
                      Text(e, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? theme.primary : theme.primaryText)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('${_estados.length} selecionados', style: GoogleFonts.inter(fontSize: 12, color: theme.secondaryText)),
        ],
      ),
    );
  }

  Widget _stepSeg(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.alternate)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Segmento', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: theme.primaryText)),
          const SizedBox(height: 8),
          Text('Áreas do agronegócio', style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _segmentosOpts.map((s) {
              final sel = _segmentos.contains(s);
              return InkWell(
                onTap: () => setState(() => sel ? _segmentos.remove(s) : _segmentos.add(s)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? theme.primary.withOpacity(0.1) : theme.primaryBackground,
                    border: Border.all(color: sel ? theme.primary : theme.alternate, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel) ...[Icon(Icons.check, size: 16, color: theme.primary), const SizedBox(width: 6)],
                      Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? theme.primary : theme.primaryText)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _stepComp(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comportamento', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: theme.primaryText)),
          const SizedBox(height: 8),
          Text('Como seu cliente consome conteúdo', style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText)),
          const SizedBox(height: 24),
          Text('Canais de Conteúdo *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _canaisOpts.map((c) {
              final sel = _canais.contains(c);
              return InkWell(
                onTap: () => setState(() => sel ? _canais.remove(c) : _canais.add(c)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? theme.primary.withOpacity(0.1) : theme.primaryBackground,
                    border: Border.all(color: sel ? theme.primary : theme.alternate, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel) ...[Icon(Icons.check, size: 14, color: theme.primary), const SizedBox(width: 4)],
                      Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? theme.primary : theme.primaryText)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Horário Mais Ativo', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Manhã', 'Tarde', 'Noite', 'Madrugada'].map((h) {
              final sel = _horario == h;
              return InkWell(
                onTap: () => setState(() => _horario = h),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? theme.primary : theme.primaryBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? theme.primary : theme.alternate),
                  ),
                  child: Text(h, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.primaryText)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Tom de Linguagem', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Formal', 'Informal', 'Técnica'].map((l) {
              final sel = _linguagem == l;
              return InkWell(
                onTap: () => setState(() => _linguagem = l),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? theme.primary : theme.primaryBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? theme.primary : theme.alternate),
                  ),
                  child: Text(l, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : theme.primaryText)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text('Já comprou produtos online', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: theme.primaryText)),
            value: _comprouOnline,
            activeColor: theme.primary,
            onChanged: (v) => setState(() => _comprouOnline = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _stepCad(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cadência de Entrega', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: theme.primaryText)),
          const SizedBox(height: 8),
          Text('Configure como receber os leads', style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Leads por dia', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(8)),
                child: Text('$_leadsMax', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          Slider(
            value: _leadsMax.toDouble(),
            min: 0, max: 20, divisions: 20,
            activeColor: theme.primary,
            inactiveColor: theme.alternate,
            onChanged: (v) => setState(() => _leadsMax = v.toInt()),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _usarIA ? theme.primary.withOpacity(0.1) : theme.alternate.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, color: _usarIA ? theme.primary : theme.secondaryText, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usar IA para qualificação', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
                      Text('Filtra automaticamente leads de maior qualidade', style: GoogleFonts.inter(fontSize: 12, color: theme.secondaryText)),
                    ],
                  ),
                ),
                Switch(value: _usarIA, activeColor: theme.primary, onChanged: (v) => setState(() => _usarIA = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _entregarFds ? theme.primary.withOpacity(0.1) : theme.alternate.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.today, color: _entregarFds ? theme.primary : theme.secondaryText, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entregar em fins de semana', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText)),
                      Text('Receber leads aos sábados e domingos', style: GoogleFonts.inter(fontSize: 12, color: theme.secondaryText)),
                    ],
                  ),
                ),
                Switch(value: _entregarFds, activeColor: theme.primary, onChanged: (v) => setState(() => _entregarFds = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primary.withOpacity(0.1), theme.primary.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Resumo da Configuração', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: theme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                _resumoItem('Estados', '${_estados.length} selecionados', theme),
                _resumoItem('Segmentos', '${_segmentos.length} selecionados', theme),
                _resumoItem('Canais', '${_canais.length} selecionados', theme),
                _resumoItem('Leads/dia', '$_leadsMax leads', theme),
                _resumoItem('IA', _usarIA ? 'Ativada' : 'Desativada', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoItem(String label, String value, FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryText)),
        ],
      ),
    );
  }

  Widget _buttons(FlutterFlowTheme theme, bool mobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _prev,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text('Voltar', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryText,
              side: BorderSide(color: theme.alternate),
              padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else
          const SizedBox(),
        ElevatedButton.icon(
          onPressed: _next,
          icon: Icon(_currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward, size: 18),
          label: Text(_currentStep == _totalSteps - 1 ? 'Salvar e Ativar' : 'Próximo', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _loading(FlutterFlowTheme theme) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                duration: const Duration(seconds: 2),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (_, double v, __) => CircularProgressIndicator(
                  value: _isSaving ? null : v,
                  color: theme.primary,
                  strokeWidth: 3,
                ),
                onEnd: () {
                  if (_isProcessing && mounted) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                _isSaving ? 'Salvando configuração...' : 'Processando leads...',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: theme.primaryText),
              ),
              const SizedBox(height: 8),
              Text(
                _isSaving ? 'Aguarde um momento' : 'Filtrando base de dados',
                style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, FlutterFlowTheme theme, {String? hint, bool num = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: theme.primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.secondaryText),
        hintText: hint,
        filled: true,
        fillColor: theme.primaryBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.primary, width: 2)),
      ),
    );
  }
}
