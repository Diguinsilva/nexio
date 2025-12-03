// =====================================================
// NEXIO - Custom Actions para FlutterFlow
// =====================================================
// Adicione estas Custom Actions no FlutterFlow
// =====================================================

import 'package:intl/intl.dart';

// =====================================================
// 1. CUSTOM ACTION: Calcular Período de Filtro
// =====================================================
// Nome: calculateFilterPeriod
// Parâmetros:
//   - filterType: String (hoje, semana, mes, ano, custom)
//   - customStartDate: DateTime? (opcional)
//   - customEndDate: DateTime? (opcional)
// Retorno: JSON
// =====================================================

Future<dynamic> calculateFilterPeriod(
  String filterType,
  DateTime? customStartDate,
  DateTime? customEndDate,
) async {
  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (filterType.toLowerCase()) {
    case 'hoje':
      startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      break;

    case 'semana':
      // Começa na segunda-feira da semana atual
      int daysToMonday = now.weekday - 1;
      startDate = DateTime(now.year, now.month, now.day - daysToMonday, 0, 0, 0);
      break;

    case 'mes':
      startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
      break;

    case 'ano':
      startDate = DateTime(now.year, 1, 1, 0, 0, 0);
      break;

    case 'custom':
      if (customStartDate != null && customEndDate != null) {
        startDate = DateTime(
          customStartDate.year,
          customStartDate.month,
          customStartDate.day,
          0, 0, 0
        );
        endDate = DateTime(
          customEndDate.year,
          customEndDate.month,
          customEndDate.day,
          23, 59, 59
        );
      } else {
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      }
      break;

    default:
      startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
  }

  return {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'filterType': filterType,
  };
}

// =====================================================
// 2. CUSTOM ACTION: Formatar Valor Monetário (BRL)
// =====================================================
// Nome: formatCurrency
// Parâmetros:
//   - value: double
// Retorno: String
// =====================================================

String formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

// =====================================================
// 3. CUSTOM ACTION: Calcular Taxa de Conversão
// =====================================================
// Nome: calculateConversionRate
// Parâmetros:
//   - leadsConvertidos: int
//   - totalLeads: int
// Retorno: double
// =====================================================

double calculateConversionRate(int leadsConvertidos, int totalLeads) {
  if (totalLeads == 0) return 0.0;
  return (leadsConvertidos / totalLeads) * 100;
}

// =====================================================
// 4. CUSTOM ACTION: Processar Dados do Gráfico de Barras
// =====================================================
// Nome: processBarChartData
// Parâmetros:
//   - performanceData: List<dynamic> (dados da query)
//   - filterType: String
// Retorno: JSON
// =====================================================

Future<dynamic> processBarChartData(
  List<dynamic> performanceData,
  String filterType,
) async {
  if (performanceData.isEmpty) {
    return {
      'labels': [],
      'leadsGerados': [],
      'leadsConvertidos': [],
      'maxValue': 0,
    };
  }

  List<String> labels = [];
  List<int> leadsGerados = [];
  List<int> leadsConvertidos = [];

  // Ordenar dados por período_numero
  performanceData.sort((a, b) =>
    (a['periodo_numero'] as int).compareTo(b['periodo_numero'] as int)
  );

  // Processar cada período
  for (var item in performanceData) {
    labels.add(item['periodo'] as String);
    leadsGerados.add(item['leads_gerados'] as int);
    leadsConvertidos.add(item['leads_convertidos'] as int);
  }

  // Calcular valor máximo para escala do gráfico
  int maxGerados = leadsGerados.isEmpty ? 0 : leadsGerados.reduce((a, b) => a > b ? a : b);
  int maxConvertidos = leadsConvertidos.isEmpty ? 0 : leadsConvertidos.reduce((a, b) => a > b ? a : b);
  int maxValue = maxGerados > maxConvertidos ? maxGerados : maxConvertidos;

  return {
    'labels': labels,
    'leadsGerados': leadsGerados,
    'leadsConvertidos': leadsConvertidos,
    'maxValue': maxValue + (maxValue * 0.2).round(), // +20% para espaço superior
  };
}

// =====================================================
// 5. CUSTOM ACTION: Processar Dados do Gráfico Circular
// =====================================================
// Nome: processCircularChartData
// Parâmetros:
//   - taxaConversaoData: dynamic (dados da query)
// Retorno: JSON
// =====================================================

Future<dynamic> processCircularChartData(dynamic taxaConversaoData) async {
  if (taxaConversaoData == null) {
    return {
      'percentualConvertidos': 0.0,
      'percentualNaoConvertidos': 100.0,
      'leadsConvertidos': 0,
      'totalLeads': 0,
    };
  }

  List<dynamic> data = taxaConversaoData is List
    ? taxaConversaoData
    : [taxaConversaoData];

  double percentualConvertidos = 0.0;
  double percentualNaoConvertidos = 0.0;
  int convertidos = 0;
  int naoConvertidos = 0;

  for (var item in data) {
    if (item['categoria'] == 'Convertidos') {
      percentualConvertidos = (item['percentual'] as num).toDouble();
      convertidos = item['quantidade'] as int;
    } else if (item['categoria'] == 'Não Convertidos') {
      percentualNaoConvertidos = (item['percentual'] as num).toDouble();
      naoConvertidos = item['quantidade'] as int;
    }
  }

  return {
    'percentualConvertidos': percentualConvertidos,
    'percentualNaoConvertidos': percentualNaoConvertidos,
    'leadsConvertidos': convertidos,
    'totalLeads': convertidos + naoConvertidos,
  };
}

// =====================================================
// 6. CUSTOM ACTION: Processar Dados do Funil de Vendas
// =====================================================
// Nome: processFunnelData
// Parâmetros:
//   - funnelData: List<dynamic> (dados da query)
// Retorno: JSON
// =====================================================

Future<dynamic> processFunnelData(List<dynamic> funnelData) async {
  if (funnelData.isEmpty) {
    return {
      'novos': 0,
      'emContato': 0,
      'emNegociacao': 0,
      'fechados': 0,
      'total': 0,
    };
  }

  int novos = 0;
  int emContato = 0;
  int emNegociacao = 0;
  int fechados = 0;

  for (var item in funnelData) {
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

  int total = novos + emContato + emNegociacao + fechados;

  return {
    'novos': novos,
    'emContato': emContato,
    'emNegociacao': emNegociacao,
    'fechados': fechados,
    'total': total,
    'percentualNovos': total > 0 ? (novos / total * 100).toStringAsFixed(1) : '0.0',
    'percentualEmContato': total > 0 ? (emContato / total * 100).toStringAsFixed(1) : '0.0',
    'percentualEmNegociacao': total > 0 ? (emNegociacao / total * 100).toStringAsFixed(1) : '0.0',
    'percentualFechados': total > 0 ? (fechados / total * 100).toStringAsFixed(1) : '0.0',
  };
}

// =====================================================
// 7. CUSTOM ACTION: Obter Nome do Mês em Português
// =====================================================
// Nome: getMonthNamePt
// Parâmetros:
//   - date: DateTime
// Retorno: String
// =====================================================

String getMonthNamePt(DateTime date) {
  const months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  return months[date.month - 1];
}

// =====================================================
// 8. CUSTOM ACTION: Obter Nome do Dia da Semana em Português
// =====================================================
// Nome: getWeekDayNamePt
// Parâmetros:
//   - date: DateTime
// Retorno: String
// =====================================================

String getWeekDayNamePt(DateTime date) {
  const weekDays = [
    'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
    'Sexta-feira', 'Sábado', 'Domingo'
  ];
  return weekDays[date.weekday - 1];
}

// =====================================================
// 9. CUSTOM ACTION: Formatar Data em Português
// =====================================================
// Nome: formatDatePt
// Parâmetros:
//   - date: DateTime
//   - format: String (short, medium, long)
// Retorno: String
// =====================================================

String formatDatePt(DateTime date, String format) {
  switch (format.toLowerCase()) {
    case 'short':
      // 03/12/2025
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
    case 'medium':
      // 03 de dez. de 2025
      return DateFormat('dd \'de\' MMM \'de\' yyyy', 'pt_BR').format(date);
    case 'long':
      // 03 de dezembro de 2025
      return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
    default:
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }
}

// =====================================================
// 10. CUSTOM ACTION: Determinar Tipo de Agrupamento
// =====================================================
// Nome: determineGroupingType
// Parâmetros:
//   - filterType: String
// Retorno: String (dia, semana, mes, ano)
// =====================================================

String determineGroupingType(String filterType) {
  switch (filterType.toLowerCase()) {
    case 'hoje':
      return 'dia'; // Agrupar por hora
    case 'semana':
      return 'semana'; // Agrupar por dia
    case 'mes':
      return 'mes'; // Agrupar por semana
    case 'ano':
      return 'ano'; // Agrupar por mês
    default:
      return 'mes';
  }
}

// =====================================================
// 11. CUSTOM ACTION: Validar Company ID
// =====================================================
// Nome: validateCompanyId
// Parâmetros:
//   - companyId: String
// Retorno: bool
// =====================================================

bool validateCompanyId(String companyId) {
  if (companyId.isEmpty) return false;

  // Validar formato UUID
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  return uuidRegex.hasMatch(companyId);
}

// =====================================================
// 12. CUSTOM ACTION: Calcular Largura de Barra do Gráfico
// =====================================================
// Nome: calculateBarWidth
// Parâmetros:
//   - screenWidth: double
//   - numberOfBars: int
// Retorno: double
// =====================================================

double calculateBarWidth(double screenWidth, int numberOfBars) {
  if (numberOfBars == 0) return 40.0;

  // Calcular largura considerando padding e espaçamento
  double availableWidth = screenWidth - 80; // Margem lateral
  double barSpacing = 20.0; // Espaço entre grupos de barras
  double totalSpacing = barSpacing * (numberOfBars - 1);

  double barWidth = (availableWidth - totalSpacing) / (numberOfBars * 2);

  // Limitar largura mínima e máxima
  if (barWidth < 20) return 20.0;
  if (barWidth > 60) return 60.0;

  return barWidth;
}

// =====================================================
// DEPENDÊNCIAS NECESSÁRIAS NO pubspec.yaml:
// =====================================================
// dependencies:
//   intl: ^0.18.0
// =====================================================
