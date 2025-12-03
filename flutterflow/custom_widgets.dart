// =====================================================
// NEXIO - Custom Widgets para FlutterFlow
// =====================================================
// Widgets personalizados para gráficos do dashboard
// =====================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

// =====================================================
// 1. CUSTOM WIDGET: Gráfico de Barras - Performance de Lead
// =====================================================
// Nome: PerformanceBarChart
// Parâmetros:
//   - labels: List<String>
//   - leadsGerados: List<int>
//   - leadsConvertidos: List<int>
//   - width: double
//   - height: double
//   - isDarkMode: bool
// =====================================================

class PerformanceBarChart extends StatefulWidget {
  const PerformanceBarChart({
    Key? key,
    required this.labels,
    required this.leadsGerados,
    required this.leadsConvertidos,
    this.width = 800,
    this.height = 300,
    this.isDarkMode = true,
  }) : super(key: key);

  final List<String> labels;
  final List<int> leadsGerados;
  final List<int> leadsConvertidos;
  final double width;
  final double height;
  final bool isDarkMode;

  @override
  State<PerformanceBarChart> createState() => _PerformanceBarChartState();
}

class _PerformanceBarChartState extends State<PerformanceBarChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.labels.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Nenhum dado disponível',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFF666666),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Leads convertidos',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 20),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Leads gerados',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                ),
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
                    tooltipBgColor: widget.isDarkMode
                        ? Color(0xFF2A2A2A)
                        : Colors.grey[800],
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
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
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
                        if (index >= 0 && index < widget.labels.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              widget.labels[index],
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white54
                                    : Colors.black54,
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
                            color: widget.isDarkMode
                                ? Colors.white54
                                : Colors.black54,
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
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
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

    for (int i = 0; i < widget.labels.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: widget.leadsConvertidos[i].toDouble(),
              color: Color(0xFF666666),
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: widget.leadsGerados[i].toDouble(),
              color: Color(0xFFFF9800),
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
    if (widget.leadsGerados.isEmpty && widget.leadsConvertidos.isEmpty) {
      return 10;
    }

    int maxGerados = widget.leadsGerados.isEmpty
        ? 0
        : widget.leadsGerados.reduce(math.max);
    int maxConvertidos = widget.leadsConvertidos.isEmpty
        ? 0
        : widget.leadsConvertidos.reduce(math.max);

    int maxValue = math.max(maxGerados, maxConvertidos);
    return (maxValue * 1.2).ceilToDouble(); // +20% para espaço superior
  }
}

// =====================================================
// 2. CUSTOM WIDGET: Gráfico Circular - Taxa de Conversão
// =====================================================
// Nome: ConversionPieChart
// Parâmetros:
//   - percentualConvertidos: double
//   - width: double
//   - height: double
//   - isDarkMode: bool
// =====================================================

class ConversionPieChart extends StatefulWidget {
  const ConversionPieChart({
    Key? key,
    required this.percentualConvertidos,
    this.width = 300,
    this.height = 300,
    this.isDarkMode = true,
  }) : super(key: key);

  final double percentualConvertidos;
  final double width;
  final double height;
  final bool isDarkMode;

  @override
  State<ConversionPieChart> createState() => _ConversionPieChartState();
}

class _ConversionPieChartState extends State<ConversionPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 80,
              sections: _buildSections(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.percentualConvertidos.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    double percentualNaoConvertidos = 100 - widget.percentualConvertidos;

    return [
      PieChartSectionData(
        color: Color(0xFFFF9800),
        value: widget.percentualConvertidos,
        title: '',
        radius: touchedIndex == 0 ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: widget.isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFE0E0E0),
        value: percentualNaoConvertidos,
        title: '',
        radius: touchedIndex == 1 ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}

// =====================================================
// 3. CUSTOM WIDGET: Barra do Funil de Vendas
// =====================================================
// Nome: FunnelBar
// Parâmetros:
//   - label: String
//   - value: int
//   - maxValue: int
//   - color: Color
//   - width: double
//   - isDarkMode: bool
// =====================================================

class FunnelBar extends StatelessWidget {
  const FunnelBar({
    Key? key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.width = 400,
    this.isDarkMode = true,
  }) : super(key: key);

  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final double width;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    double percentage = maxValue > 0 ? (value / maxValue) : 0;
    double barWidth = width * percentage;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
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
                    color: isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  height: 32,
                  width: barWidth,
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
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// 4. CUSTOM WIDGET: Card de Métrica
// =====================================================
// Nome: MetricCard
// Parâmetros:
//   - title: String
//   - value: String
//   - subtitle: String
//   - icon: IconData
//   - width: double
//   - height: double
//   - isDarkMode: bool
// =====================================================

class MetricCard extends StatelessWidget {
  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.width = 280,
    this.height = 140,
    this.isDarkMode = true,
  }) : super(key: key);

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final double width;
  final double height;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5),
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
                  title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DEPENDÊNCIAS NECESSÁRIAS NO pubspec.yaml:
// =====================================================
// dependencies:
//   fl_chart: ^0.65.0
// =====================================================
