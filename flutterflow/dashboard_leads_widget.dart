// =====================================================
// NEXIO - Dashboard de Leads - COMPLETO E CORRIGIDO
// =====================================================
// Widget personalizado para FlutterFlow
// TODAS AS CORREÇÕES IMPLEMENTADAS:
// ✅ Cards dinâmicos (atualizam com filtros)
// ✅ DatePicker funcional
// ✅ Funil de vendas dinâmico
// ✅ Cores exatas do layout
// =====================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DashboardLeadsWidget extends StatefulWidget {
  const DashboardLeadsWidget({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<DashboardLeadsWidget> createState() => _DashboardLeadsWidgetState();
}

class _DashboardLeadsWidgetState extends State<DashboardLeadsWidget> {
  // ===== VARIÁVEIS DE ESTADO =====
  String filtroAtivo = 'hoje';
  int? companyId;
  bool isLoading = true;

  // Métricas dos Cards
  int novosLeads = 0;
  int emAtendimento = 0;
  double taxaConversao = 0.0;
  double faturamento = 0.0;

  // Dados dos Gráficos
  List<Map<String, dynamic>> dadosGrafico = [];
  double percentualConversao = 0.0;

  // Dados do Funil
  int funilNovos = 0;
  int funilEmContato = 0;
  int funilEmNegociacao = 0;
  int funilFechados = 0;
  int funilMaximo = 100;

  // Datas customizadas
  DateTime? dataInicioCustom;
  DateTime? dataFimCustom;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Obter company_id do usuário autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar company_id da tabela users
      final userData = await Supabase.instance.client
          .from('users')
          .select('company_id')
          .eq('id', user.id)
          .single();

      companyId = userData['company_id'] as int;

      // Carregar dados do filtro "Hoje" (padrão)
      await _carregarDadosHoje();
    } catch (e) {
      print('Erro ao inicializar dashboard: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // FUNÇÃO NOVA: CARREGAR MÉTRICAS POR PERÍODO
  // =====================================================
  Future<void> _carregarMetricasPeriodo(DateTime inicio, DateTime fim) async {
    try {
      // 1. Novos Leads
      final novosResult = await Supabase.instance.client
          .rpc('get_novos_leads', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      });

      // 2. Em Atendimento
      final atendimentoResult = await Supabase.instance.client
          .rpc('get_leads_em_atendimento', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      });

      // 3. Taxa de Conversão
      final conversaoResult = await Supabase.instance.client
          .rpc('get_taxa_conversao', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      });

      // 4. Faturamento
      final faturamentoResult = await Supabase.instance.client
          .rpc('get_faturamento', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      });

      setState(() {
        novosLeads = novosResult ?? 0;
        emAtendimento = atendimentoResult ?? 0;
        taxaConversao = (conversaoResult ?? 0.0).toDouble();
        faturamento = (faturamentoResult ?? 0.0).toDouble();
      });
    } catch (e) {
      print('Erro ao carregar métricas: $e');
    }
  }

  // =====================================================
  // FUNÇÃO NOVA: CARREGAR FUNIL POR PERÍODO
  // =====================================================
  Future<void> _carregarFunilPeriodo(DateTime inicio, DateTime fim) async {
    try {
      final funilResult = await Supabase.instance.client
          .rpc('get_funil_vendas', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      }) as List<dynamic>;

      int novos = 0;
      int emContato = 0;
      int emNegociacao = 0;
      int fechados = 0;

      for (var item in funilResult) {
        String estagio = item['estagio'] as String;
        int quantidade = item['quantidade'] as int;

        switch (estagio) {
          case 'Novos':
            novos = quantidade;
            break;
          case 'Em contato':
            emContato = quantidade;
            break;
          case 'Em negociação':
            emNegociacao = quantidade;
            break;
          case 'Fechados':
            fechados = quantidade;
            break;
        }
      }

      setState(() {
        funilNovos = novos;
        funilEmContato = emContato;
        funilEmNegociacao = emNegociacao;
        funilFechados = fechados;
        funilMaximo = [novos, emContato, emNegociacao, fechados]
            .reduce((a, b) => a > b ? a : b);
        if (funilMaximo == 0) funilMaximo = 100;
      });
    } catch (e) {
      print('Erro ao carregar funil: $e');
    }
  }

  // =====================================================
  // FUNÇÃO NOVA: ABRIR CALENDÁRIO (DatePicker)
  // =====================================================
  Future<void> _abrirCalendario() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dataInicioCustom != null && dataFimCustom != null
          ? DateTimeRange(start: dataInicioCustom!, end: dataFimCustom!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFF59E0B),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF0F0F0F),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        filtroAtivo = 'custom';
        dataInicioCustom = picked.start;
        dataFimCustom = picked.end;
      });

      // Carregar dados do período customizado
      await _carregarDadosCustom(picked.start, picked.end);
    }
  }

  // =====================================================
  // FILTRO: HOJE (8 períodos de hora - 9h até 17h)
  // =====================================================
  Future<void> _carregarDadosHoje() async {
    setState(() {
      isLoading = true;
      filtroAtivo = 'hoje';
    });

    try {
      DateTime hoje = DateTime.now();
      DateTime inicio = DateTime(hoje.year, hoje.month, hoje.day, 0, 0, 0);
      DateTime fim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

      // 1. Carregar métricas do período
      await _carregarMetricasPeriodo(inicio, fim);

      // 2. Carregar funil do período
      await _carregarFunilPeriodo(inicio, fim);

      // 3. Carregar gráfico de performance
      final performanceResult = await Supabase.instance.client
          .rpc('get_performance_lead', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
        'p_agrupamento': 'dia',
      }) as List<dynamic>;

      // 4. Carregar taxa de conversão geral
      final taxaGeralResult = await Supabase.instance.client
          .rpc('get_taxa_conversao_geral', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      }) as List<dynamic>;

      // Processar taxa de conversão
      double percentual = 0.0;
      for (var item in taxaGeralResult) {
        if (item['categoria'] == 'Convertidos') {
          percentual = (item['percentual'] as num).toDouble();
          break;
        }
      }

      setState(() {
        dadosGrafico = List<Map<String, dynamic>>.from(performanceResult);
        percentualConversao = percentual;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados de hoje: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // FILTRO: SEMANA (7 dias)
  // =====================================================
  Future<void> _carregarDadosSemana() async {
    setState(() {
      isLoading = true;
      filtroAtivo = 'semana';
    });

    try {
      DateTime hoje = DateTime.now();
      int daysToMonday = hoje.weekday - 1;
      DateTime inicio = DateTime(
        hoje.year,
        hoje.month,
        hoje.day - daysToMonday,
        0,
        0,
        0,
      );
      DateTime fim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

      // 1. Carregar métricas do período
      await _carregarMetricasPeriodo(inicio, fim);

      // 2. Carregar funil do período
      await _carregarFunilPeriodo(inicio, fim);

      // 3. Carregar gráfico de performance
      final performanceResult = await Supabase.instance.client
          .rpc('get_performance_lead', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
        'p_agrupamento': 'semana',
      }) as List<dynamic>;

      // 4. Carregar taxa de conversão geral
      final taxaGeralResult = await Supabase.instance.client
          .rpc('get_taxa_conversao_geral', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      }) as List<dynamic>;

      double percentual = 0.0;
      for (var item in taxaGeralResult) {
        if (item['categoria'] == 'Convertidos') {
          percentual = (item['percentual'] as num).toDouble();
          break;
        }
      }

      setState(() {
        dadosGrafico = List<Map<String, dynamic>>.from(performanceResult);
        percentualConversao = percentual;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados da semana: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // FILTRO: MÊS (4-5 semanas)
  // =====================================================
  Future<void> _carregarDadosMes() async {
    setState(() {
      isLoading = true;
      filtroAtivo = 'mes';
    });

    try {
      DateTime hoje = DateTime.now();
      DateTime inicio = DateTime(hoje.year, hoje.month, 1, 0, 0, 0);
      DateTime fim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

      // 1. Carregar métricas do período
      await _carregarMetricasPeriodo(inicio, fim);

      // 2. Carregar funil do período
      await _carregarFunilPeriodo(inicio, fim);

      // 3. Carregar gráfico de performance
      final performanceResult = await Supabase.instance.client
          .rpc('get_performance_lead', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
        'p_agrupamento': 'mes',
      }) as List<dynamic>;

      // 4. Carregar taxa de conversão geral
      final taxaGeralResult = await Supabase.instance.client
          .rpc('get_taxa_conversao_geral', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      }) as List<dynamic>;

      double percentual = 0.0;
      for (var item in taxaGeralResult) {
        if (item['categoria'] == 'Convertidos') {
          percentual = (item['percentual'] as num).toDouble();
          break;
        }
      }

      setState(() {
        dadosGrafico = List<Map<String, dynamic>>.from(performanceResult);
        percentualConversao = percentual;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do mês: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // FILTRO: ANO (12 meses)
  // =====================================================
  Future<void> _carregarDadosAno() async {
    setState(() {
      isLoading = true;
      filtroAtivo = 'ano';
    });

    try {
      DateTime hoje = DateTime.now();
      DateTime inicio = DateTime(hoje.year, 1, 1, 0, 0, 0);
      DateTime fim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

      // 1. Carregar métricas do período
      await _carregarMetricasPeriodo(inicio, fim);

      // 2. Carregar funil do período
      await _carregarFunilPeriodo(inicio, fim);

      // 3. Carregar gráfico de performance
      final performanceResult = await Supabase.instance.client
          .rpc('get_performance_lead', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
        'p_agrupamento': 'ano',
      }) as List<dynamic>;

      // 4. Carregar taxa de conversão geral
      final taxaGeralResult = await Supabase.instance.client
          .rpc('get_taxa_conversao_geral', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      }) as List<dynamic>;

      double percentual = 0.0;
      for (var item in taxaGeralResult) {
        if (item['categoria'] == 'Convertidos') {
          percentual = (item['percentual'] as num).toDouble();
          break;
        }
      }

      setState(() {
        dadosGrafico = List<Map<String, dynamic>>.from(performanceResult);
        percentualConversao = percentual;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do ano: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // FILTRO: CUSTOM (Período personalizado)
  // =====================================================
  Future<void> _carregarDadosCustom(DateTime inicio, DateTime fim) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Determinar tipo de agrupamento baseado na diferença de dias
      int diferencaDias = fim.difference(inicio).inDays;
      String agrupamento;

      if (diferencaDias <= 1) {
        agrupamento = 'dia';
      } else if (diferencaDias <= 7) {
        agrupamento = 'semana';
      } else if (diferencaDias <= 60) {
        agrupamento = 'mes';
      } else {
        agrupamento = 'ano';
      }

      // 1. Carregar métricas do período
      await _carregarMetricasPeriodo(inicio, fim);

      // 2. Carregar funil do período
      await _carregarFunilPeriodo(inicio, fim);

      // 3. Carregar gráfico de performance
      final performanceResult = await Supabase.instance.client
          .rpc('get_performance_lead', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
        'p_agrupamento': agrupamento,
      }) as List<dynamic>;

      // 4. Carregar taxa de conversão geral
      final taxaGeralResult = await Supabase.instance.client
          .rpc('get_taxa_conversao_geral', params: {
        'p_company_id': companyId,
        'p_data_inicio': inicio.toIso8601String(),
        'p_data_fim': fim.toIso8601String(),
      }) as List<dynamic>;

      double percentual = 0.0;
      for (var item in taxaGeralResult) {
        if (item['categoria'] == 'Convertidos') {
          percentual = (item['percentual'] as num).toDouble();
          break;
        }
      }

      setState(() {
        dadosGrafico = List<Map<String, dynamic>>.from(performanceResult);
        percentualConversao = percentual;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados customizados: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // BUILD: INTERFACE DO DASHBOARD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Color(0xFF0F0F0F),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Color(0xFF0F0F0F),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // AppBar
            _buildAppBar(),

            // Filtros
            _buildFiltros(),

            SizedBox(height: 24),

            // Conteúdo Principal
            LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 768;

                if (isMobile) {
                  return _buildMobileLayout();
                } else {
                  return _buildDesktopLayout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // COMPONENTE: AppBar
  // =====================================================
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Dashboard de Leads',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF00BFA5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'NEXIO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // COMPONENTE: Filtros
  // =====================================================
  Widget _buildFiltros() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildBotaoFiltro('Hoje', 'hoje', Icons.today),
          _buildBotaoFiltro('Semana', 'semana', Icons.date_range),
          _buildBotaoFiltro('Mês', 'mes', Icons.calendar_month),
          _buildBotaoFiltro('Ano', 'ano', Icons.calendar_today),
          _buildBotaoCalendario(),
        ],
      ),
    );
  }

  Widget _buildBotaoFiltro(String label, String valor, IconData icon) {
    bool isAtivo = filtroAtivo == valor;

    return ElevatedButton.icon(
      onPressed: () {
        switch (valor) {
          case 'hoje':
            _carregarDadosHoje();
            break;
          case 'semana':
            _carregarDadosSemana();
            break;
          case 'mes':
            _carregarDadosMes();
            break;
          case 'ano':
            _carregarDadosAno();
            break;
        }
      },
      icon: Icon(
        icon,
        color: isAtivo ? Colors.white : Color(0xFF6B7280),
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isAtivo ? Colors.white : Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: isAtivo ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAtivo ? Color(0xFFF59E0B) : Color(0xFF1A1A1A),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isAtivo ? Color(0xFFF59E0B) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoCalendario() {
    bool isAtivo = filtroAtivo == 'custom';

    return ElevatedButton.icon(
      onPressed: _abrirCalendario,
      icon: Icon(
        Icons.calendar_today,
        color: isAtivo ? Colors.white : Color(0xFF6B7280),
        size: 18,
      ),
      label: Text(
        dataInicioCustom != null && dataFimCustom != null
            ? '${DateFormat('dd/MM').format(dataInicioCustom!)} - ${DateFormat('dd/MM').format(dataFimCustom!)}'
            : 'Calendário',
        style: TextStyle(
          color: isAtivo ? Colors.white : Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: isAtivo ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAtivo ? Color(0xFFF59E0B) : Color(0xFF1A1A1A),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isAtivo ? Color(0xFFF59E0B) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // LAYOUT: Mobile
  // =====================================================
  Widget _buildMobileLayout() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 4 Cards
          _buildMetricCard(
            'NOVOS LEADS',
            novosLeads.toString(),
            'Leads criados no período',
            Icons.person_add,
          ),
          SizedBox(height: 16),
          _buildMetricCard(
            'EM ATENDIMENTO',
            emAtendimento.toString(),
            'Leads em processo',
            Icons.support_agent,
          ),
          SizedBox(height: 16),
          _buildMetricCard(
            'TAXA DE CONVERSÃO',
            '${taxaConversao.toStringAsFixed(1)}%',
            'Percentual de conversão',
            Icons.trending_up,
          ),
          SizedBox(height: 16),
          _buildMetricCard(
            'FATURAMENTO',
            _formatCurrency(faturamento),
            'Valor total fechado',
            Icons.attach_money,
          ),

          SizedBox(height: 24),

          // Gráfico de Barras
          _buildGraficoBarras(),

          SizedBox(height: 24),

          // Gráfico Circular
          _buildGraficoCircular(),

          SizedBox(height: 24),

          // Funil de Vendas
          _buildFunilVendas(),
        ],
      ),
    );
  }

  // =====================================================
  // LAYOUT: Desktop
  // =====================================================
  Widget _buildDesktopLayout() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // 4 Cards em linha
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'NOVOS LEADS',
                  novosLeads.toString(),
                  'Leads criados no período',
                  Icons.person_add,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'EM ATENDIMENTO',
                  emAtendimento.toString(),
                  'Leads em processo',
                  Icons.support_agent,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'TAXA DE CONVERSÃO',
                  '${taxaConversao.toStringAsFixed(1)}%',
                  'Percentual de conversão',
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'FATURAMENTO',
                  _formatCurrency(faturamento),
                  'Valor total fechado',
                  Icons.attach_money,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Gráficos em linha (66% + 34%)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna Esquerda: Gráfico de Barras (66%)
              Expanded(
                flex: 66,
                child: _buildGraficoBarras(),
              ),

              SizedBox(width: 24),

              // Coluna Direita: Circular + Funil (34%)
              Expanded(
                flex: 34,
                child: Column(
                  children: [
                    _buildGraficoCircular(),
                    SizedBox(height: 24),
                    _buildFunilVendas(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // COMPONENTE: Card de Métrica
  // =====================================================
  Widget _buildMetricCard(
    String titulo,
    String valor,
    String subtitulo,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            valor,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // COMPONENTE: Gráfico de Barras
  // =====================================================
  Widget _buildGraficoBarras() {
    if (dadosGrafico.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Nenhum dado disponível',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      height: 400,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance de Lead',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFF6B7280),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Leads convertidos',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(width: 20),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Leads gerados',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Color(0xFF2A2A2A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < dadosGrafico.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              dadosGrafico[index]['periodo'] as String,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < dadosGrafico.length; i++) {
      int leadsConvertidos = dadosGrafico[i]['leads_convertidos'] as int;
      int leadsGerados = dadosGrafico[i]['leads_gerados'] as int;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: leadsConvertidos.toDouble(),
              color: Color(0xFF6B7280),
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: leadsGerados.toDouble(),
              color: Color(0xFFF59E0B),
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    return groups;
  }

  double _calculateMaxY() {
    if (dadosGrafico.isEmpty) return 10;

    int maxValue = 0;
    for (var item in dadosGrafico) {
      int gerados = item['leads_gerados'] as int;
      int convertidos = item['leads_convertidos'] as int;
      if (gerados > maxValue) maxValue = gerados;
      if (convertidos > maxValue) maxValue = convertidos;
    }

    return (maxValue * 1.2).ceilToDouble();
  }

  // =====================================================
  // COMPONENTE: Gráfico Circular
  // =====================================================
  Widget _buildGraficoCircular() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Taxa de Conversão Geral',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(
                        color: Color(0xFFF59E0B),
                        value: percentualConversao,
                        title: '',
                        radius: 40,
                      ),
                      PieChartSectionData(
                        color: Color(0xFF2A2A2A),
                        value: 100 - percentualConversao,
                        title: '',
                        radius: 40,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentualConversao.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // COMPONENTE: Funil de Vendas
  // =====================================================
  Widget _buildFunilVendas() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Funil de Vendas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildBarraFunil('Novos', funilNovos, Color(0xFFF59E0B)),
          SizedBox(height: 12),
          _buildBarraFunil('Em contato', funilEmContato, Color(0xFF3B82F6)),
          SizedBox(height: 12),
          _buildBarraFunil('Em negociação', funilEmNegociacao, Color(0xFF10B981)),
          SizedBox(height: 12),
          _buildBarraFunil('Fechados', funilFechados, Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildBarraFunil(String label, int value, Color color) {
    double percentage = funilMaximo > 0 ? (value / funilMaximo) : 0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Stack(
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                height: 32,
                width: MediaQuery.of(context).size.width * 0.3 * percentage,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        SizedBox(
          width: 40,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // HELPER: Formatação de Moeda
  // =====================================================
  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
}
