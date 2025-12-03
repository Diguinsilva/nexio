# 📊 NEXIO - Dashboard de Leads - Guia de Implementação FlutterFlow

## 📋 Índice
1. [Configuração do Supabase](#1-configuração-do-supabase)
2. [Configuração do FlutterFlow](#2-configuração-do-flutterflow)
3. [Criação da Página Dashboard](#3-criação-da-página-dashboard)
4. [Implementação dos Filtros](#4-implementação-dos-filtros)
5. [Implementação dos Cards](#5-implementação-dos-cards)
6. [Implementação dos Gráficos](#6-implementação-dos-gráficos)
7. [Modo Dark/Light](#7-modo-darklight)
8. [Responsividade](#8-responsividade)

---

## 1. Configuração do Supabase

### 1.1 Executar Schema SQL
1. Acesse o **Supabase Dashboard**
2. Vá em **SQL Editor**
3. Cole o conteúdo do arquivo `database/schema.sql`
4. Execute o script
5. Verifique se todas as tabelas foram criadas: `companies`, `users`, `leads`

### 1.2 Executar Queries/Funções
1. No **SQL Editor**, cole o conteúdo do arquivo `database/queries.sql`
2. Execute o script
3. Verifique se todas as funções foram criadas

### 1.3 Configurar RLS (Row Level Security)
- O RLS já está configurado no schema.sql
- Verifique se as políticas estão ativas em **Authentication > Policies**

---

## 2. Configuração do FlutterFlow

### 2.1 Conectar Supabase
1. Vá em **Settings > Integrations > Supabase**
2. Adicione:
   - **Supabase URL**: Sua URL do Supabase
   - **Supabase Anon Key**: Sua chave pública
3. Clique em **Connect**

### 2.2 Configurar Autenticação
1. Vá em **App Settings > Authentication**
2. Ative **Supabase Auth**
3. Configure:
   - **Enable Email/Password**: ON
   - **Initial Page**: LoginPage
   - **Logged In Page**: DashboardPage

### 2.3 Adicionar Dependências
1. Vá em **Settings > Dependencies**
2. Adicione as seguintes dependências:
```yaml
fl_chart: ^0.65.0
intl: ^0.18.0
```

### 2.4 Adicionar Custom Actions
1. Vá em **Custom Code > Actions**
2. Para cada Custom Action do arquivo `flutterflow/custom_actions.dart`:
   - Clique em **+ Add Action**
   - Cole o código da função
   - Configure os parâmetros conforme especificado no código

**Lista de Custom Actions a adicionar:**
- `calculateFilterPeriod`
- `formatCurrency`
- `calculateConversionRate`
- `processBarChartData`
- `processCircularChartData`
- `processFunnelData`
- `getMonthNamePt`
- `getWeekDayNamePt`
- `formatDatePt`
- `determineGroupingType`
- `validateCompanyId`
- `calculateBarWidth`

### 2.5 Adicionar Custom Widgets
1. Vá em **Custom Code > Widgets**
2. Para cada Custom Widget do arquivo `flutterflow/custom_widgets.dart`:
   - Clique em **+ Add Widget**
   - Cole o código da classe
   - Configure os parâmetros conforme especificado no código

**Lista de Custom Widgets a adicionar:**
- `PerformanceBarChart`
- `ConversionPieChart`
- `FunnelBar`
- `MetricCard`

---

## 3. Criação da Página Dashboard

### 3.1 Criar Nova Página
1. Vá em **Pages**
2. Clique em **+ Add Page**
3. Nome: `DashboardPage`
4. Configure:
   - **Authentication Required**: ON
   - **Scaffold**: ON
   - **AppBar**: ON

### 3.2 Estrutura da Página
```
DashboardPage (Column)
├── AppBar
│   ├── Title: "Overview"
│   └── Actions
│       └── ThemeToggleButton (IconButton)
├── FilterBar (Row - Responsivo)
│   ├── FilterButton: "Hoje"
│   ├── FilterButton: "Semana"
│   ├── FilterButton: "Mês"
│   ├── FilterButton: "Ano"
│   └── CalendarButton (DatePicker)
└── ScrollView (SingleChildScrollView)
    ├── CardsSection (Row/Wrap - Responsivo)
    │   ├── MetricCard: Novos Leads
    │   ├── MetricCard: Em Atendimento
    │   ├── MetricCard: Taxa de Conversão
    │   └── MetricCard: Faturamento
    ├── ChartsSection (Row/Column - Responsivo)
    │   ├── PerformanceSection (Container)
    │   │   ├── Title: "Performance de Lead"
    │   │   └── PerformanceBarChart (Custom Widget)
    │   └── RightColumn (Column)
    │       ├── ConversionSection (Container)
    │       │   ├── Title: "Taxa de conversão geral"
    │       │   └── ConversionPieChart (Custom Widget)
    │       └── FunnelSection (Container)
    │           ├── Badge: "real"
    │           ├── Title: "Funil de Vendas"
    │           └── FunnelBars (Column)
    │               ├── FunnelBar: Novos
    │               ├── FunnelBar: Em contato
    │               ├── FunnelBar: Em negociação
    │               └── FunnelBar: Fechados
```

---

## 4. Implementação dos Filtros

### 4.1 Criar Page State Variables
1. Na página Dashboard, vá em **Page State**
2. Adicione as seguintes variáveis:

```dart
// Filtro selecionado
String selectedFilter = 'mes'; // hoje, semana, mes, ano, custom

// Datas de filtro
DateTime filterStartDate = DateTime.now();
DateTime filterEndDate = DateTime.now();

// Company ID do usuário logado
String companyId = '';

// Tipo de agrupamento para gráficos
String groupingType = 'mes'; // dia, semana, mes, ano
```

### 4.2 Criar Action: OnPageLoad
1. Vá em **Actions** da página
2. Adicione ação **On Page Load**
3. Sequência de ações:

```
1. Backend Call - Supabase Query
   - Table: users
   - Filter: auth_user_id = Authenticated User > User ID
   - Single Result: ON
   - Resultado: Salvar em Page State > companyId

2. Custom Action: calculateFilterPeriod
   - filterType: 'mes'
   - Resultado: Salvar em Page State > filterStartDate e filterEndDate

3. Custom Action: determineGroupingType
   - filterType: 'mes'
   - Resultado: Salvar em Page State > groupingType

4. Update Page (Refresh)
```

### 4.3 Criar Botões de Filtro
Para cada botão (Hoje, Semana, Mês, Ano):

**Propriedades do Container:**
```dart
Width: 80
Height: 40
Padding: 8px
Background Color: selectedFilter == 'hoje' ? Color(0xFFFF9800) : Color(0xFF2A2A2A)
Border Radius: 8
```

**Propriedades do Text:**
```dart
Text: "Hoje" (ou Semana, Mês, Ano)
Color: Colors.white
Font Size: 14
Font Weight: selectedFilter == 'hoje' ? Bold : Normal
```

**Actions On Tap:**
```
1. Update Page State
   - selectedFilter = 'hoje'

2. Custom Action: calculateFilterPeriod
   - filterType: 'hoje'
   - Resultado: Atualizar filterStartDate e filterEndDate

3. Custom Action: determineGroupingType
   - filterType: 'hoje'
   - Resultado: Atualizar groupingType

4. Update Page (Refresh)
```

### 4.4 Criar Calendário Personalizado
**Widget: IconButton**
```dart
Icon: Icons.calendar_today
Color: Colors.white
```

**Actions On Tap:**
```
1. Show Date Picker
   - Initial Date: filterStartDate
   - Resultado: Salvar em variável local startDatePicked

2. Show Date Picker
   - Initial Date: filterEndDate
   - Resultado: Salvar em variável local endDatePicked

3. Update Page State
   - selectedFilter = 'custom'
   - filterStartDate = startDatePicked
   - filterEndDate = endDatePicked

4. Custom Action: determineGroupingType
   - filterType: 'custom'
   - Resultado: Atualizar groupingType

5. Update Page (Refresh)
```

---

## 5. Implementação dos Cards

### 5.1 Card: Novos Leads

**Backend Call (Query Row):**
```sql
SELECT * FROM get_novos_leads(
  :companyId,
  :filterStartDate,
  :filterEndDate
)
```

**Parâmetros:**
- `companyId`: Page State > companyId
- `filterStartDate`: Page State > filterStartDate
- `filterEndDate`: Page State > filterEndDate

**Widget: MetricCard (Custom Widget)**
```dart
title: "Novos leads"
value: queryResult.totalNovosLeads.toString()
subtitle: "Novos leads criados"
icon: Icons.person
width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40)
height: 140
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

### 5.2 Card: Em Atendimento

**Backend Call (Query Row):**
```sql
SELECT * FROM get_leads_em_atendimento(
  :companyId,
  :filterStartDate,
  :filterEndDate
)
```

**Widget: MetricCard**
```dart
title: "Em atendimento"
value: queryResult.totalEmAtendimento.toString()
subtitle: "Leads em atendimento"
icon: Icons.message (use WhatsApp icon se disponível)
width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40)
height: 140
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

### 5.3 Card: Taxa de Conversão

**Backend Call (Query Row):**
```sql
SELECT * FROM get_taxa_conversao(
  :companyId,
  :filterStartDate,
  :filterEndDate
)
```

**Widget: MetricCard**
```dart
title: "Taxa de conversão"
value: queryResult.taxaConversao.toString()
subtitle: "Leads convertidos"
icon: Icons.trending_up
width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40)
height: 140
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

### 5.4 Card: Faturamento

**Backend Call (Query Row):**
```sql
SELECT * FROM get_faturamento(
  :companyId,
  :filterStartDate,
  :filterEndDate
)
```

**Custom Action antes de exibir:**
```dart
String faturamentoFormatado = formatCurrency(queryResult.faturamentoTotal);
```

**Widget: MetricCard**
```dart
title: "Faturamento"
value: faturamentoFormatado
subtitle: "Faturamento em projetos"
icon: Icons.attach_money
width: MediaQuery.of(context).size.width > 768 ? 280 : (MediaQuery.of(context).size.width - 40)
height: 140
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

---

## 6. Implementação dos Gráficos

### 6.1 Gráfico: Performance de Lead

**Container Principal:**
```dart
Width: MediaQuery.of(context).size.width > 768
  ? (MediaQuery.of(context).size.width * 0.6 - 40)
  : (MediaQuery.of(context).size.width - 40)
Padding: 20
Background Color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white
Border Radius: 12
```

**Título:**
```dart
Text: "Performance de Lead"
Font Size: 18
Font Weight: Bold
Color: isDarkMode ? Colors.white : Colors.black
Margin Bottom: 8
```

**Subtítulo:**
```dart
Text: "Leads gerados vs convertidos"
Font Size: 12
Color: isDarkMode ? Colors.white54 : Colors.black54
Margin Bottom: 20
```

**Backend Call (Query Rows):**
```sql
SELECT * FROM get_performance_lead(
  :companyId,
  :filterStartDate,
  :filterEndDate,
  :groupingType
)
```

**Parâmetros:**
- `companyId`: Page State > companyId
- `filterStartDate`: Page State > filterStartDate
- `filterEndDate`: Page State > filterEndDate
- `groupingType`: Page State > groupingType

**Processar Dados (Custom Action):**
```dart
dynamic chartData = await processBarChartData(
  queryResult, // Lista de resultados
  selectedFilter // Page State
);
```

**Widget: PerformanceBarChart (Custom Widget)**
```dart
labels: chartData['labels']
leadsGerados: chartData['leadsGerados']
leadsConvertidos: chartData['leadsConvertidos']
width: MediaQuery.of(context).size.width > 768
  ? (MediaQuery.of(context).size.width * 0.6 - 80)
  : (MediaQuery.of(context).size.width - 80)
height: 300
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

### 6.2 Gráfico: Taxa de Conversão Geral

**Container Principal:**
```dart
Width: MediaQuery.of(context).size.width > 768
  ? (MediaQuery.of(context).size.width * 0.4 - 40)
  : (MediaQuery.of(context).size.width - 40)
Padding: 20
Background Color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white
Border Radius: 12
Margin Bottom: 20
```

**Badge "real":**
```dart
Container:
  Width: 40
  Height: 20
  Background: Color(0xFF00BFA5)
  Border Radius: 4
  Padding: 4

  Text:
    Text: "real"
    Color: Colors.white
    Font Size: 10
```

**Título:**
```dart
Text: "Taxa de conversão geral"
Font Size: 16
Font Weight: Bold
Color: isDarkMode ? Colors.white : Colors.black
Margin Bottom: 8
```

**Subtítulo:**
```dart
Text: "% de leads que viraram clientes"
Font Size: 12
Color: isDarkMode ? Colors.white54 : Colors.black54
Margin Bottom: 20
```

**Backend Call (Query Rows):**
```sql
SELECT * FROM get_taxa_conversao_geral(
  :companyId,
  :filterStartDate,
  :filterEndDate
)
```

**Processar Dados (Custom Action):**
```dart
dynamic chartData = await processCircularChartData(queryResult);
```

**Widget: ConversionPieChart (Custom Widget)**
```dart
percentualConvertidos: chartData['percentualConvertidos']
width: 300
height: 300
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

### 6.3 Funil de Vendas

**Container Principal:**
```dart
Width: MediaQuery.of(context).size.width > 768
  ? (MediaQuery.of(context).size.width * 0.4 - 40)
  : (MediaQuery.of(context).size.width - 40)
Padding: 20
Background Color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white
Border Radius: 12
```

**Badge "real":**
```dart
Container:
  Width: 40
  Height: 20
  Background: Color(0xFF00BFA5)
  Border Radius: 4
  Padding: 4

  Text:
    Text: "real"
    Color: Colors.white
    Font Size: 10
```

**Título:**
```dart
Text: "Funil de Vendas"
Font Size: 16
Font Weight: Bold
Color: isDarkMode ? Colors.white : Colors.black
Margin Bottom: 8
```

**Subtítulo:**
```dart
Text: "Estágios que viraram clientes"
Font Size: 12
Color: isDarkMode ? Colors.white54 : Colors.black54
Margin Bottom: 20
```

**Backend Call (Query Rows):**
```sql
SELECT * FROM get_funil_vendas(
  :companyId,
  :filterStartDate,
  :filterEndDate
)
```

**Processar Dados (Custom Action):**
```dart
dynamic funnelData = await processFunnelData(queryResult);
```

**Widgets: FunnelBar (Custom Widget) - 4 instâncias**

**1. Novos:**
```dart
label: "Novos"
value: funnelData['novos']
maxValue: funnelData['total']
color: Color(0xFFFF9800)
width: (largura do container - 40)
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

**2. Em contato:**
```dart
label: "Em contato"
value: funnelData['emContato']
maxValue: funnelData['total']
color: Color(0xFFFF9800)
width: (largura do container - 40)
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

**3. Em negociação:**
```dart
label: "Em negociação"
value: funnelData['emNegociacao']
maxValue: funnelData['total']
color: Color(0xFFFF9800)
width: (largura do container - 40)
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

**4. Fechados:**
```dart
label: "Fechados"
value: funnelData['fechados']
maxValue: funnelData['total']
color: Color(0xFFFF9800)
width: (largura do container - 40)
isDarkMode: Theme.of(context).brightness == Brightness.dark
```

---

## 7. Modo Dark/Light

### 7.1 Configurar Tema no FlutterFlow
1. Vá em **App Settings > Theme**
2. Configure **Light Theme**:
```dart
Primary Color: #FF9800
Secondary Color: #2A2A2A
Background Color: #FFFFFF
Surface Color: #F5F5F5
Error Color: #D32F2F
```

3. Configure **Dark Theme**:
```dart
Primary Color: #FF9800
Secondary Color: #666666
Background Color: #000000
Surface Color: #1A1A1A
Error Color: #CF6679
```

### 7.2 Criar Theme Toggle Button
**Widget: IconButton (no AppBar)**
```dart
Icon: Theme.of(context).brightness == Brightness.dark
  ? Icons.light_mode
  : Icons.dark_mode
Color: Colors.white
Size: 24
```

**Actions On Tap:**
```
1. Set App Theme Mode
   - Mode: Theme.of(context).brightness == Brightness.dark
     ? ThemeMode.light
     : ThemeMode.dark

2. Update Page (Refresh)
```

### 7.3 Usar Tema Dinâmico nos Widgets
Em todos os widgets personalizados e containers, use:

```dart
isDarkMode: Theme.of(context).brightness == Brightness.dark

// Para cores de fundo:
backgroundColor: isDarkMode ? Color(0xFF1A1A1A) : Colors.white

// Para cores de texto:
textColor: isDarkMode ? Colors.white : Colors.black87
```

---

## 8. Responsividade

### 8.1 Configurar Breakpoints
1. Vá em **App Settings > Responsive**
2. Configure breakpoints:
   - Mobile: < 768px
   - Tablet: 768px - 1024px
   - Desktop: > 1024px

### 8.2 Layout Responsivo - Cards Section

**Widget: Wrap (para Mobile) ou Row (para Desktop)**

**Condição:**
```dart
MediaQuery.of(context).size.width > 768
  ? Row(...)
  : Wrap(...)
```

**Para Row (Desktop):**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    MetricCard(width: 280, ...),
    MetricCard(width: 280, ...),
    MetricCard(width: 280, ...),
    MetricCard(width: 280, ...),
  ],
)
```

**Para Wrap (Mobile):**
```dart
Wrap(
  spacing: 16,
  runSpacing: 16,
  children: [
    MetricCard(width: MediaQuery.of(context).size.width - 40, ...),
    MetricCard(width: MediaQuery.of(context).size.width - 40, ...),
    MetricCard(width: MediaQuery.of(context).size.width - 40, ...),
    MetricCard(width: MediaQuery.of(context).size.width - 40, ...),
  ],
)
```

### 8.3 Layout Responsivo - Charts Section

**Para Desktop (> 768px):**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Performance Chart (60% da largura)
    Container(
      width: MediaQuery.of(context).size.width * 0.6 - 40,
      child: PerformanceBarChart(...),
    ),
    SizedBox(width: 20),
    // Right Column (40% da largura)
    Container(
      width: MediaQuery.of(context).size.width * 0.4 - 40,
      child: Column(
        children: [
          ConversionPieChart(...),
          SizedBox(height: 20),
          FunnelSection(...),
        ],
      ),
    ),
  ],
)
```

**Para Mobile (< 768px):**
```dart
Column(
  children: [
    PerformanceBarChart(
      width: MediaQuery.of(context).size.width - 40,
      ...
    ),
    SizedBox(height: 20),
    ConversionPieChart(
      width: MediaQuery.of(context).size.width - 40,
      ...
    ),
    SizedBox(height: 20),
    FunnelSection(
      width: MediaQuery.of(context).size.width - 40,
      ...
    ),
  ],
)
```

### 8.4 Filtros Responsivos

**Para Desktop:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    FilterButton("Hoje"),
    SizedBox(width: 8),
    FilterButton("Semana"),
    SizedBox(width: 8),
    FilterButton("Mês"),
    SizedBox(width: 8),
    FilterButton("Ano"),
    SizedBox(width: 8),
    CalendarButton(),
  ],
)
```

**Para Mobile:**
```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    FilterButton("Hoje"),
    FilterButton("Semana"),
    FilterButton("Mês"),
    FilterButton("Ano"),
    CalendarButton(),
  ],
)
```

---

## 🎨 Cores e Estilos (Exatamente como no layout)

### Cores Principais:
```dart
// Laranja (Primário)
Color(0xFFFF9800)

// Cinza Escuro (Cards no Dark Mode)
Color(0xFF1A1A1A)

// Cinza Médio (Elementos secundários)
Color(0xFF2A2A2A)

// Cinza para Leads Convertidos
Color(0xFF666666)

// Verde para Badge "real"
Color(0xFF00BFA5)

// Texto Branco
Colors.white

// Texto Branco com Opacidade
Colors.white54
Colors.white70

// Fundo Preto
Color(0xFF000000)
```

### Tipografia:
```dart
// Títulos Principais
fontSize: 18
fontWeight: FontWeight.bold

// Valores dos Cards
fontSize: 32
fontWeight: FontWeight.bold

// Subtítulos
fontSize: 12
fontWeight: FontWeight.normal
opacity: 0.54

// Labels dos Filtros
fontSize: 14
fontWeight: FontWeight.w500

// Percentual do Gráfico Circular
fontSize: 48
fontWeight: FontWeight.bold
```

### Espaçamentos:
```dart
// Padding dos Cards
padding: 20

// Espaçamento entre Cards
spacing: 16

// Border Radius
borderRadius: 8 (botões)
borderRadius: 12 (cards e gráficos)
borderRadius: 4 (barras do funil)

// Altura dos Cards
height: 140

// Altura das Barras do Funil
height: 32
```

---

## ⚠️ Checklist Final

### Supabase:
- [ ] Schema SQL executado com sucesso
- [ ] Queries/Funções criadas
- [ ] RLS configurado e ativo
- [ ] Dados de teste inseridos (opcional)

### FlutterFlow:
- [ ] Supabase conectado
- [ ] Autenticação configurada
- [ ] Dependências adicionadas (fl_chart, intl)
- [ ] Todas as Custom Actions adicionadas (12)
- [ ] Todos os Custom Widgets adicionados (4)
- [ ] Page State Variables criadas
- [ ] Backend Calls configurados em todos os componentes

### Página Dashboard:
- [ ] AppBar com título e botão de tema
- [ ] Barra de filtros funcionando (Hoje, Semana, Mês, Ano, Calendário)
- [ ] 4 Cards principais exibindo dados corretos
- [ ] Gráfico Performance de Lead funcionando
- [ ] Gráfico Taxa de Conversão Geral funcionando
- [ ] Funil de Vendas funcionando
- [ ] Modo Dark/Light funcionando
- [ ] Responsividade funcionando (Mobile e Desktop)

### Testes:
- [ ] Testar filtro "Hoje"
- [ ] Testar filtro "Semana"
- [ ] Testar filtro "Mês"
- [ ] Testar filtro "Ano"
- [ ] Testar filtro customizado (calendário)
- [ ] Testar alternância entre Dark/Light mode
- [ ] Testar em dispositivo mobile
- [ ] Testar em dispositivo desktop
- [ ] Testar com dados reais
- [ ] Testar autenticação e RLS

---

## 🚀 Dicas de Performance

1. **Cache de Queries**: Use o cache do Supabase para queries que não mudam frequentemente
2. **Índices**: Certifique-se de que os índices estão criados (já incluídos no schema.sql)
3. **Pagination**: Se houver muitos leads, considere adicionar paginação
4. **Loading States**: Adicione estados de loading em todos os Backend Calls
5. **Error Handling**: Adicione tratamento de erros para queries que falham

---

## 📞 Suporte

Se encontrar algum problema durante a implementação:

1. Verifique o console de erros do FlutterFlow
2. Verifique os logs do Supabase
3. Confirme que todas as funções SQL foram criadas corretamente
4. Verifique se o company_id está sendo passado corretamente
5. Confirme que as datas de filtro estão no formato correto (ISO 8601)

---

**Desenvolvido para NEXIO** 🚀
