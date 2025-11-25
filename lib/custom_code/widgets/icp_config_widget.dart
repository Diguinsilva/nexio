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

/// Widget de Configuração de ICP (Ideal Customer Profile)
/// Componente completo com 5 etapas, validações, tooltips e responsividade

class ICPConfigWidget extends StatefulWidget {
  const ICPConfigWidget({
    super.key,
    this.width,
    this.height,
    this.onComplete,
  });

  final double? width;
  final double? height;
  final Future<dynamic> Function()? onComplete;

  @override
  State<ICPConfigWidget> createState() => _ICPConfigWidgetState();
}

class _ICPConfigWidgetState extends State<ICPConfigWidget>
    with SingleTickerProviderStateMixin {
  // ========== State Management ==========
  int? _companyId;
  String? _userId;
  int? _icpId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isProcessing = false;
  int _currentStep = 0;
  final int _totalSteps = 5;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // ========== Controllers ==========
  final _idadeMinCtrl = TextEditingController();
  final _idadeMaxCtrl = TextEditingController();
  final _rendaMinCtrl = TextEditingController();
  final _rendaMaxCtrl = TextEditingController();
  final _empresaFuncionariosMinCtrl = TextEditingController();
  final _empresaFuncionariosMaxCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  // ========== Form Data ==========
  // Step 1: Demográfico
  List<String> _estados = [];
  List<String> _cidades = [];
  String _genero = 'Todos';
  String _escolaridade = 'Qualquer';

  // Step 2: Profissional
  List<String> _cargos = [];
  List<String> _segmentos = [];
  List<String> _tamanhoEmpresas = [];
  String _tempoMercado = 'Qualquer';

  // Step 3: Comportamento
  List<String> _canais = [];
  List<String> _dores = [];
  List<String> _objetivos = [];
  String _horario = 'Manhã';
  String _linguagem = 'Informal';
  String _cicloCompra = 'Curto (até 30 dias)';
  bool _comprouOnline = false;
  bool _influenciador = false;

  // Step 4: Preferências
  List<String> _preferenciaContato = [];
  List<String> _diasSemana = [];
  bool _aceitaWhatsApp = true;
  bool _aceitaEmail = true;
  bool _aceitaTelefone = false;

  // Step 5: Cadência
  int _leadsMax = 5;
  bool _usarIA = true;
  bool _entregarFds = false;
  String _prioridade = 'Qualidade';
  bool _notificarNovosLeads = true;

  // ========== Options ==========
  final _estadosOpts = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  final _segmentosOpts = [
    'Agricultura',
    'Pecuária',
    'Agroindústria',
    'Tecnologia Agro',
    'Insumos Agrícolas',
    'Máquinas e Equipamentos',
    'Consultoria Rural',
    'Cooperativas',
    'Distribuidores',
    'Exportação',
    'Varejo Agro',
    'Serviços Financeiros',
  ];

  final _cargosOpts = [
    'Proprietário Rural',
    'Gestor de Fazenda',
    'Agrônomo',
    'Técnico Agrícola',
    'Veterinário',
    'Zootecnista',
    'Gerente Comercial',
    'Comprador',
    'Diretor',
    'Consultor',
  ];

  final _canaisOpts = [
    'Instagram',
    'Facebook',
    'YouTube',
    'WhatsApp',
    'TikTok',
    'LinkedIn',
    'Site/Blog',
    'E-mail',
    'Podcast',
    'Eventos',
  ];

  final _doresOpts = [
    'Baixa produtividade',
    'Custos elevados',
    'Gestão ineficiente',
    'Falta de tecnologia',
    'Dificuldade de crédito',
    'Clima adverso',
    'Pragas e doenças',
    'Preços voláteis',
    'Logística',
    'Falta de mão de obra',
  ];

  final _objetivosOpts = [
    'Aumentar produção',
    'Reduzir custos',
    'Melhorar gestão',
    'Adotar tecnologia',
    'Expandir negócio',
    'Diversificar',
    'Sustentabilidade',
    'Certificações',
    'Exportar',
    'Automatizar',
  ];

  final _tamanhoEmpresaOpts = [
    'MEI',
    'Microempresa (até 19 funcionários)',
    'Pequena (20-99 funcionários)',
    'Média (100-499 funcionários)',
    'Grande (500+ funcionários)',
  ];

  OverlayEntry? _toast;
  final Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _init();
  }

  @override
  void dispose() {
    _toast?.remove();
    _animController.dispose();
    _idadeMinCtrl.dispose();
    _idadeMaxCtrl.dispose();
    _rendaMinCtrl.dispose();
    _rendaMaxCtrl.dispose();
    _empresaFuncionariosMinCtrl.dispose();
    _empresaFuncionariosMaxCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
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
          if (_companyId != null) await _loadICP();
        }
      }
    } catch (e) {
      debugPrint('❌ Init error: $e');
      _showToast('Erro ao carregar dados', true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  Future<void> _loadICP() async {
    try {
      final res = await SupaFlow.client
          .from('icp_configuration')
          .select()
          .eq('company_id', _companyId!)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _icpId = res['id'];
          _idadeMinCtrl.text = res['idade_min']?.toString() ?? '';
          _idadeMaxCtrl.text = res['idade_max']?.toString() ?? '';
          _rendaMinCtrl.text = res['renda_min']?.toString() ?? '';
          _rendaMaxCtrl.text = res['renda_max']?.toString() ?? '';
          _empresaFuncionariosMinCtrl.text =
              res['empresa_funcionarios_min']?.toString() ?? '';
          _empresaFuncionariosMaxCtrl.text =
              res['empresa_funcionarios_max']?.toString() ?? '';
          _budgetMinCtrl.text = res['budget_min']?.toString() ?? '';
          _budgetMaxCtrl.text = res['budget_max']?.toString() ?? '';

          _estados = List<String>.from(res['estados'] ?? []);
          _segmentos = List<String>.from(res['nichos'] ?? []);
          _cargos = List<String>.from(res['cargos'] ?? []);
          _canais = List<String>.from(res['canais'] ?? []);
          _dores = List<String>.from(res['dores'] ?? []);
          _objetivos = List<String>.from(res['objetivos'] ?? []);
          _tamanhoEmpresas = List<String>.from(res['tamanho_empresas'] ?? []);
          _preferenciaContato =
              List<String>.from(res['preferencia_contato'] ?? []);

          _genero = res['genero'] ?? 'Todos';
          _escolaridade = res['escolaridade'] ?? 'Qualquer';
          _horario = res['horario'] ?? 'Manhã';
          _linguagem = res['linguagem'] ?? 'Informal';
          _cicloCompra = res['ciclo_compra'] ?? 'Curto (até 30 dias)';
          _tempoMercado = res['tempo_mercado'] ?? 'Qualquer';
          _prioridade = res['prioridade'] ?? 'Qualidade';

          _comprouOnline = res['comprou_online'] ?? false;
          _influenciador = res['influenciador'] ?? false;
          _aceitaWhatsApp = res['aceita_whatsapp'] ?? true;
          _aceitaEmail = res['aceita_email'] ?? true;
          _aceitaTelefone = res['aceita_telefone'] ?? false;
          _usarIA = res['usar_ia'] ?? true;
          _entregarFds = res['entregar_fins_semana'] ?? false;
          _notificarNovosLeads = res['notificar_novos_leads'] ?? true;

          _leadsMax = res['leads_por_dia_max'] ?? 5;
        });
      }
    } catch (e) {
      debugPrint('❌ Load error: $e');
    }
  }

  // ========== Save & Webhook ==========
  Future<void> _save() async {
    if (_companyId == null) return;
    setState(() => _isSaving = true);

    try {
      final data = {
        'company_id': _companyId!,
        'idade_min': _idadeMinCtrl.text.isNotEmpty
            ? int.parse(_idadeMinCtrl.text)
            : null,
        'idade_max': _idadeMaxCtrl.text.isNotEmpty
            ? int.parse(_idadeMaxCtrl.text)
            : null,
        'renda_min': _rendaMinCtrl.text.isNotEmpty
            ? double.parse(_rendaMinCtrl.text)
            : null,
        'renda_max': _rendaMaxCtrl.text.isNotEmpty
            ? double.parse(_rendaMaxCtrl.text)
            : null,
        'empresa_funcionarios_min': _empresaFuncionariosMinCtrl.text.isNotEmpty
            ? int.parse(_empresaFuncionariosMinCtrl.text)
            : null,
        'empresa_funcionarios_max': _empresaFuncionariosMaxCtrl.text.isNotEmpty
            ? int.parse(_empresaFuncionariosMaxCtrl.text)
            : null,
        'budget_min': _budgetMinCtrl.text.isNotEmpty
            ? double.parse(_budgetMinCtrl.text)
            : null,
        'budget_max': _budgetMaxCtrl.text.isNotEmpty
            ? double.parse(_budgetMaxCtrl.text)
            : null,
        'estados': _estados,
        'nichos': _segmentos,
        'cargos': _cargos,
        'canais': _canais,
        'dores': _dores,
        'objetivos': _objetivos,
        'tamanho_empresas': _tamanhoEmpresas,
        'preferencia_contato': _preferenciaContato,
        'genero': _genero,
        'escolaridade': _escolaridade,
        'horario': _horario,
        'linguagem': _linguagem,
        'ciclo_compra': _cicloCompra,
        'tempo_mercado': _tempoMercado,
        'prioridade': _prioridade,
        'comprou_online': _comprouOnline,
        'influenciador': _influenciador,
        'aceita_whatsapp': _aceitaWhatsApp,
        'aceita_email': _aceitaEmail,
        'aceita_telefone': _aceitaTelefone,
        'leads_por_dia_max': _leadsMax,
        'usar_ia': _usarIA,
        'entregar_fins_semana': _entregarFds,
        'notificar_novos_leads': _notificarNovosLeads,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_icpId == null) {
        data['created_at'] = DateTime.now().toIso8601String();
        final res = await SupaFlow.client
            .from('icp_configuration')
            .insert(data)
            .select()
            .single();
        _icpId = res['id'];
      } else {
        await SupaFlow.client
            .from('icp_configuration')
            .update(data)
            .eq('id', _icpId!);
      }

      setState(() {
        _isSaving = false;
        _isProcessing = true;
      });

      await _webhook();
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showToast('Erro ao salvar configuração', true);
      setState(() => _isSaving = false);
    }
  }

  Future<void> _webhook() async {
    try {
      const url = 'https://seu-n8n.com/webhook/processar-icp';

      final payload = {
        'user_id': _userId,
        'company_id': _companyId,
        'icp_id': _icpId,
        'icp': {
          'demografico': {
            'idade_min': _idadeMinCtrl.text,
            'idade_max': _idadeMaxCtrl.text,
            'renda_min': _rendaMinCtrl.text,
            'renda_max': _rendaMaxCtrl.text,
            'genero': _genero,
            'escolaridade': _escolaridade,
            'estados': _estados,
          },
          'profissional': {
            'cargos': _cargos,
            'segmentos': _segmentos,
            'tamanho_empresas': _tamanhoEmpresas,
            'tempo_mercado': _tempoMercado,
            'funcionarios_min': _empresaFuncionariosMinCtrl.text,
            'funcionarios_max': _empresaFuncionariosMaxCtrl.text,
          },
          'comportamento': {
            'canais': _canais,
            'dores': _dores,
            'objetivos': _objetivos,
            'horario': _horario,
            'linguagem': _linguagem,
            'ciclo_compra': _cicloCompra,
            'comprou_online': _comprouOnline,
            'influenciador': _influenciador,
          },
          'preferencias': {
            'contato': _preferenciaContato,
            'whatsapp': _aceitaWhatsApp,
            'email': _aceitaEmail,
            'telefone': _aceitaTelefone,
          },
          'cadencia': {
            'leads_max': _leadsMax,
            'usar_ia': _usarIA,
            'entregar_fds': _entregarFds,
            'prioridade': _prioridade,
            'notificar': _notificarNovosLeads,
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final res = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': 'SUA_KEY_AQUI',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        setState(() => _isProcessing = false);
        _showSuccess();
        await Future.delayed(const Duration(seconds: 2));
        _showToast('ICP ativo! Processando leads...', false);
        if (widget.onComplete != null) {
          await widget.onComplete!();
        }
      } else {
        throw Exception('Webhook error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Webhook error: $e');
      setState(() => _isProcessing = false);
      _showToast('ICP salvo, mas erro no processamento', true);
    }
  }

  // ========== Validation ==========
  bool _validate() {
    _fieldErrors.clear();

    switch (_currentStep) {
      case 0: // Demográfico
        if (_idadeMinCtrl.text.isEmpty) {
          _fieldErrors['idade_min'] = 'Idade mínima é obrigatória';
        }
        if (_idadeMaxCtrl.text.isEmpty) {
          _fieldErrors['idade_max'] = 'Idade máxima é obrigatória';
        }
        if (_idadeMinCtrl.text.isNotEmpty && _idadeMaxCtrl.text.isNotEmpty) {
          final min = int.tryParse(_idadeMinCtrl.text);
          final max = int.tryParse(_idadeMaxCtrl.text);
          if (min != null && max != null && min >= max) {
            _fieldErrors['idade'] = 'Idade mínima deve ser menor que máxima';
            _showToast('Idade mínima deve ser menor que máxima', true);
            setState(() {});
            return false;
          }
        }
        if (_estados.isEmpty) {
          _fieldErrors['estados'] = 'Selecione pelo menos um estado';
          _showToast('Selecione pelo menos um estado', true);
          setState(() {});
          return false;
        }
        break;

      case 1: // Profissional
        if (_cargos.isEmpty) {
          _fieldErrors['cargos'] = 'Selecione pelo menos um cargo';
          _showToast('Selecione pelo menos um cargo', true);
          setState(() {});
          return false;
        }
        if (_segmentos.isEmpty) {
          _fieldErrors['segmentos'] = 'Selecione pelo menos um segmento';
          _showToast('Selecione pelo menos um segmento', true);
          setState(() {});
          return false;
        }
        break;

      case 2: // Comportamento
        if (_canais.isEmpty) {
          _fieldErrors['canais'] = 'Selecione pelo menos um canal';
          _showToast('Selecione pelo menos um canal', true);
          setState(() {});
          return false;
        }
        if (_dores.isEmpty) {
          _fieldErrors['dores'] = 'Selecione pelo menos uma dor/problema';
          _showToast('Selecione pelo menos uma dor/problema', true);
          setState(() {});
          return false;
        }
        break;

      case 3: // Preferências
        if (_preferenciaContato.isEmpty) {
          _fieldErrors['preferencia'] =
              'Selecione pelo menos uma forma de contato';
          _showToast('Selecione pelo menos uma forma de contato', true);
          setState(() {});
          return false;
        }
        break;

      case 4: // Cadência
        if (_leadsMax <= 0) {
          _showToast('Configure o número de leads por dia', true);
          return false;
        }
        break;
    }

    if (_fieldErrors.isNotEmpty) {
      setState(() {});
      return false;
    }

    return true;
  }

  // ========== Navigation ==========
  void _next() {
    if (_validate()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
          _animController.reset();
          _animController.forward();
        });
      } else {
        _save();
      }
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _fieldErrors.clear();
        _animController.reset();
        _animController.forward();
      });
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: error
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF34C759),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34C759).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
      ),
    );
    Future.delayed(
      const Duration(milliseconds: 1500),
      () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  // ========== Build Methods ==========
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 768;
    final tablet = size.width >= 768 && size.width < 1024;

    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: theme.primaryBackground,
        child: Center(
          child: CircularProgressIndicator(color: theme.primary),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: theme.primaryBackground,
      child: Stack(
        children: [
          Column(
            children: [
              _header(theme, mobile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(mobile ? 16 : tablet ? 24 : 32),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
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
              ),
            ],
          ),
          if (_isSaving || _isProcessing) _loading(theme),
        ],
      ),
    );
  }

  Widget _header(FlutterFlowTheme theme, bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(
          bottom: BorderSide(color: theme.alternate),
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuração de ICP',
                  style: GoogleFonts.inter(
                    fontSize: mobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  'Defina seu perfil de cliente ideal',
                  style: GoogleFonts.inter(
                    fontSize: mobile ? 12 : 13,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Ajuda',
            child: IconButton(
              icon: Icon(Icons.help_outline, color: theme.secondaryText),
              onPressed: () => _showToast(
                'Configure cada etapa para definir seu perfil ideal de cliente',
                false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(FlutterFlowTheme theme, bool mobile) {
    final steps = [
      'Demográfico',
      'Profissional',
      'Comportamento',
      'Preferências',
      'Cadência'
    ];

    if (mobile) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme.alternate,
            valueColor: AlwaysStoppedAnimation(theme.primary),
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          Text(
            'Passo ${_currentStep + 1} de $_totalSteps: ${steps[_currentStep]}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.primary.withOpacity(0.1)
                        : done
                            ? const Color(0xFF34C759).withOpacity(0.1)
                            : theme.secondaryBackground,
                    border: Border.all(
                      color: active
                          ? theme.primary
                          : done
                              ? const Color(0xFF34C759)
                              : theme.alternate,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: active
                              ? theme.primary
                              : done
                                  ? const Color(0xFF34C759)
                                  : theme.alternate,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[i],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? theme.primary
                              : done
                                  ? const Color(0xFF34C759)
                                  : theme.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < _totalSteps - 1)
                Container(
                  width: 20,
                  height: 2,
                  color: done ? const Color(0xFF34C759) : theme.alternate,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _stepContent(FlutterFlowTheme theme, bool mobile) {
    switch (_currentStep) {
      case 0:
        return _stepDemografico(theme, mobile);
      case 1:
        return _stepProfissional(theme, mobile);
      case 2:
        return _stepComportamento(theme, mobile);
      case 3:
        return _stepPreferencias(theme, mobile);
      case 4:
        return _stepCadencia(theme, mobile);
      default:
        return Container();
    }
  }

  // Continue no próximo arquivo devido ao tamanho...
  // Os métodos _stepDemografico, _stepProfissional, etc. virão a seguir

  Widget _stepDemografico(FlutterFlowTheme theme, bool mobile) {
    return _stepContainer(
      theme,
      title: 'Informações Demográficas',
      subtitle: 'Defina idade, localização e perfil básico',
      children: [
        // Faixa Etária
        Row(
          children: [
            Expanded(
              child: _field(
                'Idade Mínima *',
                _idadeMinCtrl,
                theme,
                hint: '18',
                num: true,
                error: _fieldErrors['idade_min'] ?? _fieldErrors['idade'],
                tooltip: 'Idade mínima do seu cliente ideal',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                'Idade Máxima *',
                _idadeMaxCtrl,
                theme,
                hint: '65',
                num: true,
                error: _fieldErrors['idade_max'] ?? _fieldErrors['idade'],
                tooltip: 'Idade máxima do seu cliente ideal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Faixa de Renda
        Row(
          children: [
            Expanded(
              child: _field(
                'Renda Mínima (R\$)',
                _rendaMinCtrl,
                theme,
                hint: '5000',
                num: true,
                tooltip: 'Renda mensal mínima',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                'Renda Máxima (R\$)',
                _rendaMaxCtrl,
                theme,
                hint: '50000',
                num: true,
                tooltip: 'Renda mensal máxima',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Gênero
        _sectionTitle('Gênero', theme),
        const SizedBox(height: 12),
        _radioGroup(
          ['Todos', 'Masculino', 'Feminino', 'Outro'],
          _genero,
          (v) => setState(() => _genero = v),
          theme,
        ),
        const SizedBox(height: 24),

        // Escolaridade
        _sectionTitle('Escolaridade', theme),
        const SizedBox(height: 12),
        _radioGroup(
          [
            'Qualquer',
            'Fundamental',
            'Médio',
            'Superior',
            'Pós-graduação',
          ],
          _escolaridade,
          (v) => setState(() => _escolaridade = v),
          theme,
        ),
        const SizedBox(height: 24),

        // Estados
        _sectionTitle(
          'Estados de Atuação *',
          theme,
          error: _fieldErrors['estados'],
        ),
        const SizedBox(height: 12),
        _multiSelect(
          _estadosOpts,
          _estados,
          (e) => setState(() =>
              _estados.contains(e) ? _estados.remove(e) : _estados.add(e)),
          theme,
          mobile,
        ),
        const SizedBox(height: 8),
        Text(
          '${_estados.length} estado(s) selecionado(s)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _stepProfissional(FlutterFlowTheme theme, bool mobile) {
    return _stepContainer(
      theme,
      title: 'Perfil Profissional',
      subtitle: 'Cargo, segmento e características da empresa',
      children: [
        // Cargos
        _sectionTitle('Cargos/Funções *', theme, error: _fieldErrors['cargos']),
        const SizedBox(height: 12),
        _multiSelect(
          _cargosOpts,
          _cargos,
          (c) => setState(() =>
              _cargos.contains(c) ? _cargos.remove(c) : _cargos.add(c)),
          theme,
          mobile,
        ),
        const SizedBox(height: 8),
        Text(
          '${_cargos.length} cargo(s) selecionado(s)',
          style: GoogleFonts.inter(fontSize: 12, color: theme.secondaryText),
        ),
        const SizedBox(height: 24),

        // Segmentos
        _sectionTitle('Segmentos de Atuação *', theme,
            error: _fieldErrors['segmentos']),
        const SizedBox(height: 12),
        _multiSelect(
          _segmentosOpts,
          _segmentos,
          (s) => setState(() => _segmentos.contains(s)
              ? _segmentos.remove(s)
              : _segmentos.add(s)),
          theme,
          mobile,
        ),
        const SizedBox(height: 8),
        Text(
          '${_segmentos.length} segmento(s) selecionado(s)',
          style: GoogleFonts.inter(fontSize: 12, color: theme.secondaryText),
        ),
        const SizedBox(height: 24),

        // Tamanho da Empresa
        _sectionTitle('Tamanho da Empresa', theme),
        const SizedBox(height: 12),
        _multiSelect(
          _tamanhoEmpresaOpts,
          _tamanhoEmpresas,
          (t) => setState(() => _tamanhoEmpresas.contains(t)
              ? _tamanhoEmpresas.remove(t)
              : _tamanhoEmpresas.add(t)),
          theme,
          mobile,
        ),
        const SizedBox(height: 24),

        // Número de Funcionários
        _sectionTitle('Número de Funcionários (Opcional)', theme),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                'Mínimo',
                _empresaFuncionariosMinCtrl,
                theme,
                hint: '10',
                num: true,
                tooltip: 'Número mínimo de funcionários',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                'Máximo',
                _empresaFuncionariosMaxCtrl,
                theme,
                hint: '500',
                num: true,
                tooltip: 'Número máximo de funcionários',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tempo no Mercado
        _sectionTitle('Tempo no Mercado', theme),
        const SizedBox(height: 12),
        _radioGroup(
          [
            'Qualquer',
            'Até 2 anos',
            '2-5 anos',
            '5-10 anos',
            'Mais de 10 anos',
          ],
          _tempoMercado,
          (v) => setState(() => _tempoMercado = v),
          theme,
        ),
      ],
    );
  }

  Widget _stepComportamento(FlutterFlowTheme theme, bool mobile) {
    return _stepContainer(
      theme,
      title: 'Comportamento Digital',
      subtitle: 'Como seu cliente consome conteúdo e interage',
      children: [
        // Canais de Conteúdo
        _sectionTitle('Canais de Conteúdo *', theme,
            error: _fieldErrors['canais']),
        const SizedBox(height: 12),
        _multiSelect(
          _canaisOpts,
          _canais,
          (c) => setState(() =>
              _canais.contains(c) ? _canais.remove(c) : _canais.add(c)),
          theme,
          mobile,
        ),
        const SizedBox(height: 24),

        // Horário Mais Ativo
        _sectionTitle('Horário Mais Ativo', theme),
        const SizedBox(height: 12),
        _radioGroup(
          ['Manhã', 'Tarde', 'Noite', 'Madrugada'],
          _horario,
          (h) => setState(() => _horario = h),
          theme,
        ),
        const SizedBox(height: 24),

        // Tom de Linguagem
        _sectionTitle('Tom de Linguagem Preferido', theme),
        const SizedBox(height: 12),
        _radioGroup(
          ['Formal', 'Informal', 'Técnica'],
          _linguagem,
          (l) => setState(() => _linguagem = l),
          theme,
        ),
        const SizedBox(height: 24),

        // Ciclo de Compra
        _sectionTitle('Ciclo de Compra Esperado', theme),
        const SizedBox(height: 12),
        _radioGroup(
          [
            'Curto (até 30 dias)',
            'Médio (30-90 dias)',
            'Longo (mais de 90 dias)',
          ],
          _cicloCompra,
          (c) => setState(() => _cicloCompra = c),
          theme,
        ),
        const SizedBox(height: 24),

        // Dores/Problemas
        _sectionTitle('Principais Dores/Problemas *', theme,
            error: _fieldErrors['dores']),
        const SizedBox(height: 12),
        _multiSelect(
          _doresOpts,
          _dores,
          (d) =>
              setState(() => _dores.contains(d) ? _dores.remove(d) : _dores.add(d)),
          theme,
          mobile,
        ),
        const SizedBox(height: 24),

        // Objetivos
        _sectionTitle('Objetivos Principais', theme),
        const SizedBox(height: 12),
        _multiSelect(
          _objetivosOpts,
          _objetivos,
          (o) => setState(() => _objetivos.contains(o)
              ? _objetivos.remove(o)
              : _objetivos.add(o)),
          theme,
          mobile,
        ),
        const SizedBox(height: 24),

        // Switches
        _switchTile(
          'Já comprou produtos online',
          _comprouOnline,
          (v) => setState(() => _comprouOnline = v),
          theme,
        ),
        const SizedBox(height: 12),
        _switchTile(
          'É influenciador ou formador de opinião',
          _influenciador,
          (v) => setState(() => _influenciador = v),
          theme,
        ),
      ],
    );
  }

  Widget _stepPreferencias(FlutterFlowTheme theme, bool mobile) {
    return _stepContainer(
      theme,
      title: 'Preferências de Contato',
      subtitle: 'Como e quando entrar em contato',
      children: [
        // Formas de Contato Preferidas
        _sectionTitle('Formas de Contato Preferidas *', theme,
            error: _fieldErrors['preferencia']),
        const SizedBox(height: 12),
        _multiSelect(
          ['WhatsApp', 'E-mail', 'Telefone', 'SMS', 'Redes Sociais'],
          _preferenciaContato,
          (p) => setState(() => _preferenciaContato.contains(p)
              ? _preferenciaContato.remove(p)
              : _preferenciaContato.add(p)),
          theme,
          mobile,
        ),
        const SizedBox(height: 24),

        // Canais Aceitos
        _sectionTitle('Canais de Comunicação', theme),
        const SizedBox(height: 12),
        _featureTile(
          Icons.whatsapp,
          'WhatsApp',
          'Permitir contato via WhatsApp',
          _aceitaWhatsApp,
          (v) => setState(() => _aceitaWhatsApp = v),
          theme,
        ),
        const SizedBox(height: 12),
        _featureTile(
          Icons.email,
          'E-mail',
          'Permitir contato via e-mail',
          _aceitaEmail,
          (v) => setState(() => _aceitaEmail = v),
          theme,
        ),
        const SizedBox(height: 12),
        _featureTile(
          Icons.phone,
          'Telefone',
          'Permitir contato via telefone',
          _aceitaTelefone,
          (v) => setState(() => _aceitaTelefone = v),
          theme,
        ),
        const SizedBox(height: 24),

        // Budget
        _sectionTitle('Orçamento Médio (Opcional)', theme),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                'Budget Mínimo (R\$)',
                _budgetMinCtrl,
                theme,
                hint: '1000',
                num: true,
                tooltip: 'Valor mínimo de investimento esperado',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                'Budget Máximo (R\$)',
                _budgetMaxCtrl,
                theme,
                hint: '100000',
                num: true,
                tooltip: 'Valor máximo de investimento esperado',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepCadencia(FlutterFlowTheme theme, bool mobile) {
    return _stepContainer(
      theme,
      title: 'Cadência de Entrega',
      subtitle: 'Configure como e quando receber os leads',
      children: [
        // Leads por dia
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leads por dia',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  'Quantidade máxima diária',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_leadsMax',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _leadsMax.toDouble(),
          min: 0,
          max: 20,
          divisions: 20,
          activeColor: theme.primary,
          inactiveColor: theme.alternate,
          label: '$_leadsMax leads/dia',
          onChanged: (v) => setState(() => _leadsMax = v.toInt()),
        ),
        const SizedBox(height: 24),

        // Prioridade
        _sectionTitle('Prioridade de Entrega', theme),
        const SizedBox(height: 12),
        _radioGroup(
          ['Qualidade', 'Quantidade', 'Balanceado'],
          _prioridade,
          (p) => setState(() => _prioridade = p),
          theme,
        ),
        const SizedBox(height: 24),

        // Features
        _featureTile(
          Icons.auto_awesome,
          'Usar IA para qualificação',
          'Filtra automaticamente leads de maior qualidade usando inteligência artificial',
          _usarIA,
          (v) => setState(() => _usarIA = v),
          theme,
        ),
        const SizedBox(height: 12),
        _featureTile(
          Icons.today,
          'Entregar em fins de semana',
          'Receber leads aos sábados e domingos',
          _entregarFds,
          (v) => setState(() => _entregarFds = v),
          theme,
        ),
        const SizedBox(height: 12),
        _featureTile(
          Icons.notifications_active,
          'Notificar novos leads',
          'Receber notificações quando novos leads forem encontrados',
          _notificarNovosLeads,
          (v) => setState(() => _notificarNovosLeads = v),
          theme,
        ),
        const SizedBox(height: 24),

        // Resumo
        _resumo(theme),
      ],
    );
  }

  // ========== Reusable Widgets ==========

  Widget _stepContainer(
    FlutterFlowTheme theme, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, FlutterFlowTheme theme, {String? error}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: error != null ? const Color(0xFFFF3B30) : theme.primaryText,
          ),
        ),
        if (error != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    FlutterFlowTheme theme, {
    String? hint,
    bool num = false,
    String? error,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.primaryText,
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: num ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: theme.secondaryText,
            ),
            filled: true,
            fillColor: theme.primaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error != null
                    ? const Color(0xFFFF3B30)
                    : theme.alternate,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error != null
                    ? const Color(0xFFFF3B30)
                    : theme.alternate,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error != null
                    ? const Color(0xFFFF3B30)
                    : theme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            errorText: error,
            errorStyle: GoogleFonts.inter(fontSize: 11),
          ),
          onChanged: (_) {
            if (error != null) {
              setState(() => _fieldErrors.remove(label.toLowerCase()));
            }
          },
        ),
      ],
    );
  }

  Widget _multiSelect(
    List<String> options,
    List<String> selected,
    Function(String) onTap,
    FlutterFlowTheme theme,
    bool mobile,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final sel = selected.contains(item);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(item),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 12 : 14,
                vertical: mobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: sel
                    ? theme.primary.withOpacity(0.1)
                    : theme.primaryBackground,
                border: Border.all(
                  color: sel ? theme.primary : theme.alternate,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sel) ...[
                    Icon(
                      Icons.check,
                      size: mobile ? 14 : 16,
                      color: theme.primary,
                    ),
                    SizedBox(width: mobile ? 4 : 6),
                  ],
                  Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: mobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? theme.primary : theme.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _radioGroup(
    List<String> options,
    String selected,
    Function(String) onChanged,
    FlutterFlowTheme theme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final sel = selected == opt;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(opt),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? theme.primary : theme.primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? theme.primary : theme.alternate,
                ),
              ),
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : theme.primaryText,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _switchTile(
    String title,
    bool value,
    Function(bool) onChanged,
    FlutterFlowTheme theme,
  ) {
    return Material(
      color: theme.primaryBackground,
      borderRadius: BorderRadius.circular(8),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.primaryText,
          ),
        ),
        value: value,
        activeColor: theme.primary,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.alternate),
        ),
      ),
    );
  }

  Widget _featureTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    FlutterFlowTheme theme,
  ) {
    return Container(
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
              color: value
                  ? theme.primary.withOpacity(0.1)
                  : theme.alternate.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? theme.primary : theme.secondaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: theme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _resumo(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withOpacity(0.1),
            theme.primary.withOpacity(0.05),
          ],
        ),
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
              Text(
                'Resumo da Configuração',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resumoItem('Estados', '${_estados.length}', theme),
          _resumoItem('Cargos', '${_cargos.length}', theme),
          _resumoItem('Segmentos', '${_segmentos.length}', theme),
          _resumoItem('Canais', '${_canais.length}', theme),
          _resumoItem('Dores', '${_dores.length}', theme),
          _resumoItem('Leads/dia', '$_leadsMax', theme),
          _resumoItem('IA', _usarIA ? 'Ativada' : 'Desativada', theme),
          _resumoItem('Prioridade', _prioridade, theme),
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
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
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
            label: Text(
              'Voltar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryText,
              side: BorderSide(color: theme.alternate, width: 2),
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 16 : 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          const SizedBox(),
        ElevatedButton.icon(
          onPressed: _next,
          icon: Icon(
            _currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward,
            size: 18,
          ),
          label: Text(
            _currentStep == _totalSteps - 1 ? 'Salvar e Ativar' : 'Próximo',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 20 : 32,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                builder: (_, double v, __) => SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _isSaving ? null : v,
                    color: theme.primary,
                    strokeWidth: 4,
                  ),
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSaving ? 'Aguarde um momento' : 'Analisando base de dados',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
