# 💻 NEXIO - Código Completo para FlutterFlow

## 📋 Este arquivo contém todos os códigos prontos para copiar e colar no FlutterFlow

---

## 1️⃣ ESTRUTURA DA PÁGINA (Widget Tree)

Cole esta estrutura no FlutterFlow criando os widgets na ordem:

```
DashboardPage [Scaffold]
│
├─ AppBar
│  ├─ Container [Leading]
│  │  └─ Icon [menu] (branco)
│  ├─ Text "Overview" (título - branco, 20px, bold)
│  └─ Row [Actions]
│     └─ IconButton [theme toggle]
│        └─ Icon [light_mode/dark_mode] (condicional)
│
└─ SingleChildScrollView [Body]
   └─ Column [mainAxisAlignment: start, crossAxisAlignment: stretch]
      │
      ├─ Container [FilterBar] (padding: 20, 16, 20, 16)
      │  └─ Wrap (spacing: 8, runSpacing: 8)
      │     ├─ GestureDetector [Filtro Hoje]
      │     │  └─ Container (width: 80, height: 40, borderRadius: 8)
      │     │     └─ Text "Hoje" (center, branco, 14px)
      │     ├─ GestureDetector [Filtro Semana]
      │     │  └─ Container (width: 80, height: 40, borderRadius: 8)
      │     │     └─ Text "Semana" (center, branco, 14px)
      │     ├─ GestureDetector [Filtro Mês]
      │     │  └─ Container (width: 80, height: 40, borderRadius: 8)
      │     │     └─ Text "Mês" (center, branco, 14px)
      │     ├─ GestureDetector [Filtro Ano]
      │     │  └─ Container (width: 80, height: 40, borderRadius: 8)
      │     │     └─ Text "Ano" (center, branco, 14px)
      │     └─ IconButton [Calendário]
      │        └─ Icon [calendar_today] (branco)
      │
      ├─ Container [CardsSection] (padding: 0, 16, 20, 16)
      │  └─ Wrap (spacing: 16, runSpacing: 16, alignment: center)
      │     ├─ MetricCard [Custom Widget - Novos Leads]
      │     ├─ MetricCard [Custom Widget - Em Atendimento]
      │     ├─ MetricCard [Custom Widget - Taxa de Conversão]
      │     └─ MetricCard [Custom Widget - Faturamento]
      │
      ├─ Container [ChartsSection] (padding: 0, 16, 20, 16)
      │  └─ Condicional [Responsivo]
      │     │
      │     ├─ Row [Desktop > 768px]
      │     │  ├─ Container [Performance Chart] (flex: 6)
      │     │  │  └─ Column
      │     │  │     ├─ Text "Performance de Lead" (18px, bold)
      │     │  │     ├─ Text "Leads gerados vs convertidos" (12px, opacity)
      │     │  │     └─ PerformanceBarChart [Custom Widget]
      │     │  │
      │     │  ├─ SizedBox (width: 20)
      │     │  │
      │     │  └─ Container [Right Column] (flex: 4)
      │     │     └─ Column
      │     │        ├─ Container [Conversion Chart]
      │     │        │  └─ Column
      │     │        │     ├─ Row
      │     │        │     │  ├─ Container [Badge "real"]
      │     │        │     │  │  └─ Text "real" (10px, branco)
      │     │        │     │  └─ Spacer
      │     │        │     ├─ Text "Taxa de conversão geral" (16px, bold)
      │     │        │     ├─ Text "% de leads que viraram clientes" (12px)
      │     │        │     └─ ConversionPieChart [Custom Widget]
      │     │        │
      │     │        ├─ SizedBox (height: 20)
      │     │        │
      │     │        └─ Container [Funnel]
      │     │           └─ Column
      │     │              ├─ Row
      │     │              │  ├─ Container [Badge "real"]
      │     │              │  │  └─ Text "real" (10px, branco)
      │     │              │  └─ Spacer
      │     │              ├─ Text "Funil de Vendas" (16px, bold)
      │     │              ├─ Text "Estágios que viraram clientes" (12px)
      │     │              ├─ FunnelBar [Custom Widget - Novos]
      │     │              ├─ FunnelBar [Custom Widget - Em contato]
      │     │              ├─ FunnelBar [Custom Widget - Em negociação]
      │     │              └─ FunnelBar [Custom Widget - Fechados]
      │     │
      │     └─ Column [Mobile < 768px]
      │        ├─ Container [Performance Chart]
      │        ├─ SizedBox (height: 20)
      │        ├─ Container [Conversion Chart]
      │        ├─ SizedBox (height: 20)
      │        └─ Container [Funnel]
      │
      └─ SizedBox (height: 40)
```

---

## 2️⃣ PAGE STATE VARIABLES

Vá em **Page State** e adicione estas variáveis:

```dart
// Nome: selectedFilter
// Tipo: String
// Valor inicial: 'mes'

// Nome: filterStartDate
// Tipo: DateTime
// Valor inicial: [deixe vazio, será definido no OnPageLoad]

// Nome: filterEndDate
// Tipo: DateTime
// Valor inicial: [deixe vazio, será definido no OnPageLoad]

// Nome: companyId
// Tipo: String
// Valor inicial: ''

// Nome: groupingType
// Tipo: String
// Valor inicial: 'mes'
```

---

## 3️⃣ BACKEND CALLS (Supabase Queries)

### Query 1: Get Company ID
**Nome:** getCompanyId
**Tipo:** Query Single Row
**Table:** users

**Query:**
```sql
SELECT company_id
FROM users
WHERE auth_user_id = :userId
LIMIT 1
```

**Parâmetros:**
- userId: `Authenticated User > User ID`

---

### Query 2: Get Novos Leads
**Nome:** getNovosLeads
**Tipo:** Postgres Function (RPC)

**Function Name:** get_novos_leads

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate
}
```

---

### Query 3: Get Leads Em Atendimento
**Nome:** getLeadsEmAtendimento
**Tipo:** Postgres Function (RPC)

**Function Name:** get_leads_em_atendimento

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate
}
```

---

### Query 4: Get Taxa de Conversão
**Nome:** getTaxaConversao
**Tipo:** Postgres Function (RPC)

**Function Name:** get_taxa_conversao

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate
}
```

---

### Query 5: Get Faturamento
**Nome:** getFaturamento
**Tipo:** Postgres Function (RPC)

**Function Name:** get_faturamento

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate
}
```

---

### Query 6: Get Performance Lead
**Nome:** getPerformanceLead
**Tipo:** Postgres Function (RPC)

**Function Name:** get_performance_lead

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate,
  "p_tipo_agrupamento": groupingType
}
```

---

### Query 7: Get Taxa Conversão Geral
**Nome:** getTaxaConversaoGeral
**Tipo:** Postgres Function (RPC)

**Function Name:** get_taxa_conversao_geral

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate
}
```

---

### Query 8: Get Funil Vendas
**Nome:** getFunilVendas
**Tipo:** Postgres Function (RPC)

**Function Name:** get_funil_vendas

**Parâmetros:**
```dart
{
  "p_company_id": companyId,
  "p_data_inicio": filterStartDate,
  "p_data_fim": filterEndDate
}
```

---

## 4️⃣ ACTIONS

### Action: OnPageLoad

Sequência de ações ao carregar a página:

```
1. Backend Call: getCompanyId
   ↓ Success
   └─ Update Page State
      - companyId = getCompanyIdResult.companyId

2. Custom Action: calculateFilterPeriod
   Parâmetros:
   - filterType: 'mes'
   - customStartDate: null
   - customEndDate: null
   ↓ Retorno salvo em: filterPeriodResult
   └─ Update Page State
      - filterStartDate = filterPeriodResult.startDate
      - filterEndDate = filterPeriodResult.endDate

3. Custom Action: determineGroupingType
   Parâmetros:
   - filterType: 'mes'
   ↓ Retorno salvo em: groupingResult
   └─ Update Page State
      - groupingType = groupingResult

4. Update Page
```

---

### Action: OnTap Filtro "Hoje"

```
1. Update Page State
   - selectedFilter = 'hoje'

2. Custom Action: calculateFilterPeriod
   Parâmetros:
   - filterType: 'hoje'
   - customStartDate: null
   - customEndDate: null
   ↓ Retorno salvo em: filterPeriodResult
   └─ Update Page State
      - filterStartDate = filterPeriodResult.startDate
      - filterEndDate = filterPeriodResult.endDate

3. Custom Action: determineGroupingType
   Parâmetros:
   - filterType: 'hoje'
   ↓ Retorno salvo em: groupingResult
   └─ Update Page State
      - groupingType = groupingResult

4. Update Page
```

---

### Action: OnTap Filtro "Semana"

```
1. Update Page State
   - selectedFilter = 'semana'

2. Custom Action: calculateFilterPeriod
   Parâmetros:
   - filterType: 'semana'
   - customStartDate: null
   - customEndDate: null
   ↓ Retorno salvo em: filterPeriodResult
   └─ Update Page State
      - filterStartDate = filterPeriodResult.startDate
      - filterEndDate = filterPeriodResult.endDate

3. Custom Action: determineGroupingType
   Parâmetros:
   - filterType: 'semana'
   ↓ Retorno salvo em: groupingResult
   └─ Update Page State
      - groupingType = groupingResult

4. Update Page
```

---

### Action: OnTap Filtro "Mês"

```
1. Update Page State
   - selectedFilter = 'mes'

2. Custom Action: calculateFilterPeriod
   Parâmetros:
   - filterType: 'mes'
   - customStartDate: null
   - customEndDate: null
   ↓ Retorno salvo em: filterPeriodResult
   └─ Update Page State
      - filterStartDate = filterPeriodResult.startDate
      - filterEndDate = filterPeriodResult.endDate

3. Custom Action: determineGroupingType
   Parâmetros:
   - filterType: 'mes'
   ↓ Retorno salvo em: groupingResult
   └─ Update Page State
      - groupingType = groupingResult

4. Update Page
```

---

### Action: OnTap Filtro "Ano"

```
1. Update Page State
   - selectedFilter = 'ano'

2. Custom Action: calculateFilterPeriod
   Parâmetros:
   - filterType: 'ano'
   - customStartDate: null
   - customEndDate: null
   ↓ Retorno salvo em: filterPeriodResult
   └─ Update Page State
      - filterStartDate = filterPeriodResult.startDate
      - filterEndDate = filterPeriodResult.endDate

3. Custom Action: determineGroupingType
   Parâmetros:
   - filterType: 'ano'
   ↓ Retorno salvo em: groupingResult
   └─ Update Page State
      - groupingType = groupingResult

4. Update Page
```

---

### Action: OnTap Calendário (Date Range Picker)

```
1. Date Picker (Start Date)
   ↓ Retorno salvo em: startDatePicked

2. Date Picker (End Date)
   ↓ Retorno salvo em: endDatePicked

3. Update Page State
   - selectedFilter = 'custom'
   - filterStartDate = startDatePicked
   - filterEndDate = endDatePicked

4. Custom Action: determineGroupingType
   Parâmetros:
   - filterType: 'custom'
   ↓ Retorno salvo em: groupingResult
   └─ Update Page State
      - groupingType = groupingResult

5. Update Page
```

---

### Action: OnTap Theme Toggle

```
1. Condicional
   If: Theme.of(context).brightness == Brightness.dark
   Then:
     - Set App Theme Mode: ThemeMode.light
   Else:
     - Set App Theme Mode: ThemeMode.dark

2. Update Page
```

---

## 5️⃣ PROPRIEDADES DOS WIDGETS

### AppBar
```dart
backgroundColor: Color(0xFF000000)
elevation: 0
title: Text(
  'Overview',
  style: TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
)
```

---

### Filtro Button (Container + GestureDetector)

**Container:**
```dart
width: 80
height: 40
padding: EdgeInsets.all(8)
decoration: BoxDecoration(
  color: selectedFilter == 'hoje'
    ? Color(0xFFFF9800)
    : Color(0xFF2A2A2A),
  borderRadius: BorderRadius.circular(8),
)
```

**Text:**
```dart
text: 'Hoje'
style: TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontWeight: selectedFilter == 'hoje'
    ? FontWeight.bold
    : FontWeight.normal,
)
textAlign: TextAlign.center
```

**Repetir para "Semana", "Mês", "Ano" mudando a condição:**
- Semana: `selectedFilter == 'semana'`
- Mês: `selectedFilter == 'mes'`
- Ano: `selectedFilter == 'ano'`

---

### MetricCard: Novos Leads

```dart
// Backend Call: getNovosLeads
// Query já configurada acima

MetricCard(
  title: 'Novos leads',
  value: getNovosLeadsResult?.total_novos_leads?.toString() ?? '0',
  subtitle: 'Novos leads criados',
  icon: Icons.person,
  width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40),
  height: 140,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### MetricCard: Em Atendimento

```dart
// Backend Call: getLeadsEmAtendimento

MetricCard(
  title: 'Em atendimento',
  value: getLeadsEmAtendimentoResult?.total_em_atendimento?.toString() ?? '0',
  subtitle: 'Leads em atendimento',
  icon: Icons.chat,
  width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40),
  height: 140,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### MetricCard: Taxa de Conversão

```dart
// Backend Call: getTaxaConversao

MetricCard(
  title: 'Taxa de conversão',
  value: getTaxaConversaoResult?.taxa_conversao?.toStringAsFixed(1) ?? '0.0',
  subtitle: 'Leads convertidos',
  icon: Icons.trending_up,
  width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40),
  height: 140,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### MetricCard: Faturamento

```dart
// Backend Call: getFaturamento
// Antes de exibir, processar com Custom Action

// Custom Action inline:
String faturamentoFormatado = formatCurrency(
  getFaturamentoResult?.faturamento_total?.toDouble() ?? 0.0
);

MetricCard(
  title: 'Faturamento',
  value: faturamentoFormatado,
  subtitle: 'Faturamento em projetos',
  icon: Icons.attach_money,
  width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40),
  height: 140,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### PerformanceBarChart

```dart
// Backend Call: getPerformanceLead
// Retorno: List de objetos com periodo, periodo_numero, leads_gerados, leads_convertidos

// Custom Action para processar:
dynamic chartData = await processBarChartData(
  getPerformanceLeadResult ?? [],
  selectedFilter,
);

PerformanceBarChart(
  labels: (chartData['labels'] as List).cast<String>(),
  leadsGerados: (chartData['leadsGerados'] as List).cast<int>(),
  leadsConvertidos: (chartData['leadsConvertidos'] as List).cast<int>(),
  width: MediaQuery.of(context).size.width > 768
    ? (MediaQuery.of(context).size.width * 0.6 - 80)
    : (MediaQuery.of(context).size.width - 80),
  height: 300,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### ConversionPieChart

```dart
// Backend Call: getTaxaConversaoGeral
// Retorno: List com categoria, quantidade, percentual

// Custom Action para processar:
dynamic chartData = await processCircularChartData(
  getTaxaConversaoGeralResult ?? [],
);

ConversionPieChart(
  percentualConvertidos: chartData['percentualConvertidos']?.toDouble() ?? 0.0,
  width: 300,
  height: 300,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### FunnelBar: Novos

```dart
// Backend Call: getFunilVendas
// Retorno: List com estagio, quantidade, ordem

// Custom Action para processar:
dynamic funnelData = await processFunnelData(
  getFunilVendasResult ?? [],
);

FunnelBar(
  label: 'Novos',
  value: funnelData['novos'] ?? 0,
  maxValue: funnelData['total'] ?? 1,
  color: Color(0xFFFF9800),
  width: MediaQuery.of(context).size.width > 768
    ? (MediaQuery.of(context).size.width * 0.4 - 80)
    : (MediaQuery.of(context).size.width - 80),
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### FunnelBar: Em contato

```dart
FunnelBar(
  label: 'Em contato',
  value: funnelData['emContato'] ?? 0,
  maxValue: funnelData['total'] ?? 1,
  color: Color(0xFFFF9800),
  width: MediaQuery.of(context).size.width > 768
    ? (MediaQuery.of(context).size.width * 0.4 - 80)
    : (MediaQuery.of(context).size.width - 80),
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### FunnelBar: Em negociação

```dart
FunnelBar(
  label: 'Em negociação',
  value: funnelData['emNegociacao'] ?? 0,
  maxValue: funnelData['total'] ?? 1,
  color: Color(0xFFFF9800),
  width: MediaQuery.of(context).size.width > 768
    ? (MediaQuery.of(context).size.width * 0.4 - 80)
    : (MediaQuery.of(context).size.width - 80),
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### FunnelBar: Fechados

```dart
FunnelBar(
  label: 'Fechados',
  value: funnelData['fechados'] ?? 0,
  maxValue: funnelData['total'] ?? 1,
  color: Color(0xFFFF9800),
  width: MediaQuery.of(context).size.width > 768
    ? (MediaQuery.of(context).size.width * 0.4 - 80)
    : (MediaQuery.of(context).size.width - 80),
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

---

### Container: Badge "real"

```dart
Container(
  width: 40,
  height: 20,
  decoration: BoxDecoration(
    color: Color(0xFF00BFA5),
    borderRadius: BorderRadius.circular(4),
  ),
  alignment: Alignment.center,
  child: Text(
    'real',
    style: TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

---

## 6️⃣ CÓDIGO DE RESPONSIVIDADE

### Layout Condicional para Charts Section

```dart
// No FlutterFlow, use o widget "Conditional Builder"

// Condição:
MediaQuery.of(context).size.width > 768

// If True (Desktop):
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      flex: 6,
      child: Container(
        // Performance Chart
      ),
    ),
    SizedBox(width: 20),
    Expanded(
      flex: 4,
      child: Column(
        children: [
          Container(
            // Conversion Chart
          ),
          SizedBox(height: 20),
          Container(
            // Funnel
          ),
        ],
      ),
    ),
  ],
)

// If False (Mobile):
Column(
  children: [
    Container(
      // Performance Chart
    ),
    SizedBox(height: 20),
    Container(
      // Conversion Chart
    ),
    SizedBox(height: 20),
    Container(
      // Funnel
    ),
  ],
)
```

---

## 7️⃣ CONFIGURAÇÃO DE CORES NO THEME

### Light Theme
```dart
Primary Color: #FF9800
Secondary Color: #2A2A2A
Background Color: #FFFFFF
Surface Color: #F5F5F5
On Primary: #FFFFFF
On Secondary: #FFFFFF
On Background: #000000
On Surface: #000000
```

### Dark Theme
```dart
Primary Color: #FF9800
Secondary Color: #666666
Background Color: #000000
Surface Color: #1A1A1A
On Primary: #FFFFFF
On Secondary: #FFFFFF
On Background: #FFFFFF
On Surface: #FFFFFF
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Antes de começar:
- [ ] Supabase configurado e conectado
- [ ] Schema SQL executado
- [ ] Funções SQL criadas
- [ ] Dados de teste inseridos (opcional)

### Código:
- [ ] 12 Custom Actions adicionadas
- [ ] 4 Custom Widgets adicionados
- [ ] 5 Page State Variables criadas
- [ ] 8 Backend Calls configurados

### Layout:
- [ ] AppBar criado
- [ ] Barra de filtros criada (5 botões)
- [ ] 4 MetricCards adicionados
- [ ] PerformanceBarChart adicionado
- [ ] ConversionPieChart adicionado
- [ ] 4 FunnelBars adicionados
- [ ] Responsividade configurada
- [ ] Tema Dark/Light configurado

### Actions:
- [ ] OnPageLoad configurado
- [ ] OnTap para cada filtro (5)
- [ ] OnTap para theme toggle

### Testes:
- [ ] Testar autenticação
- [ ] Testar filtros (todos)
- [ ] Testar tema dark/light
- [ ] Testar responsividade (mobile + desktop)
- [ ] Testar com dados reais

---

**TUDO PRONTO! 🎉**

Agora você tem todos os códigos e configurações necessários para implementar o dashboard completo no FlutterFlow.

Siga o guia passo a passo e cole os códigos nos locais indicados.
