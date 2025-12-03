# 📊 NEXIO - Dashboard de Leads para FlutterFlow

## 🎯 Sobre o Projeto

Dashboard completo de gerenciamento de leads desenvolvido para **FlutterFlow** com integração ao **Supabase**.

Este dashboard oferece:
- ✅ **Autenticação** por empresa (company_id)
- ✅ **Filtros dinâmicos** (Hoje, Semana, Mês, Ano, Calendário customizado)
- ✅ **4 Cards principais** com métricas em tempo real
- ✅ **Gráfico de barras** comparativo (Leads gerados vs convertidos)
- ✅ **Gráfico circular** de taxa de conversão
- ✅ **Funil de vendas** com 4 estágios
- ✅ **Modo Dark/Light** dinâmico
- ✅ **100% Responsivo** (Mobile e Desktop)
- ✅ **Layout EXATO** conforme especificado

---

## 📁 Estrutura do Projeto

```
nexio/
├── README.md                          # Este arquivo
├── GUIA_IMPLEMENTACAO.md              # Guia completo passo a passo
├── CODIGO_COMPLETO_FLUTTERFLOW.md     # Códigos prontos para copiar
├── database/
│   ├── schema.sql                     # Schema do banco de dados
│   └── queries.sql                    # Queries e funções SQL
└── flutterflow/
    ├── custom_actions.dart            # 12 Custom Actions
    └── custom_widgets.dart            # 4 Custom Widgets
```

---

## 🚀 Início Rápido (3 Passos)

### 1️⃣ Configurar Supabase
```bash
1. Acesse seu Supabase Dashboard
2. Vá em SQL Editor
3. Execute o arquivo: database/schema.sql
4. Execute o arquivo: database/queries.sql
5. Verifique se as tabelas e funções foram criadas
```

### 2️⃣ Configurar FlutterFlow
```bash
1. Conecte ao Supabase (Settings > Integrations)
2. Adicione dependências: fl_chart: ^0.65.0 e intl: ^0.18.0
3. Adicione os 12 Custom Actions de: flutterflow/custom_actions.dart
4. Adicione os 4 Custom Widgets de: flutterflow/custom_widgets.dart
```

### 3️⃣ Implementar Dashboard
```bash
1. Abra o arquivo: CODIGO_COMPLETO_FLUTTERFLOW.md
2. Siga a estrutura da Widget Tree
3. Cole os códigos nos locais indicados
4. Configure as Actions conforme especificado
5. Teste em modo Dark e Light
```

---

## 📊 Funcionalidades do Dashboard

### 🎴 Cards de Métricas
1. **Novos Leads** - Quantidade de leads criados no período
2. **Em Atendimento** - Leads em processo de negociação
3. **Taxa de Conversão** - Percentual de conversão calculado dinamicamente
4. **Faturamento** - Valor total de projetos fechados (R$)

### 📈 Gráficos

#### Performance de Lead (Barras Comparativas)
Compara leads gerados vs convertidos com agrupamento dinâmico:
- **Dia**: 24 colunas (uma por hora)
- **Semana**: 7 colunas (uma por dia)
- **Mês**: 4 colunas (uma por semana)
- **Ano**: 12 colunas (uma por mês)

#### Taxa de Conversão Geral (Circular)
Mostra o percentual total de leads que viraram clientes no período.

#### Funil de Vendas
Exibe 4 estágios com barras horizontais:
1. Novos
2. Em contato
3. Em negociação
4. Fechados

### 🎯 Filtros
- **Hoje**: Dados do dia atual
- **Semana**: Dados da semana atual (Segunda a Domingo)
- **Mês**: Dados do mês atual
- **Ano**: Dados do ano atual
- **Calendário**: Período customizado com data início e fim

---

## 🎨 Design System

### Cores Principais
```dart
Laranja (Primário):      #FF9800
Cinza Escuro:            #1A1A1A
Cinza Médio:             #2A2A2A
Cinza Claro:             #666666
Verde (Badge):           #00BFA5
Preto:                   #000000
Branco:                  #FFFFFF
```

### Tipografia
```dart
Título Principal:        18px, Bold
Valores dos Cards:       32px, Bold
Subtítulos:              12px, Regular
Percentual Grande:       48px, Bold
```

### Espaçamentos
```dart
Padding Cards:           20px
Espaçamento Cards:       16px
Border Radius Cards:     12px
Border Radius Buttons:   8px
```

---

## 🗄️ Banco de Dados

### Tabelas Principais
- **companies** - Empresas cadastradas
- **users** - Usuários com vinculação à empresa
- **leads** - Leads com todos os dados

### Enums Disponíveis
```sql
Segmento:          E-commerce, Saúde/Medicina, Educação, ...
Prioridade:        Alta, Média, Baixa
Fonte:             PEG, LinkedIn, Meta Ads, Google Ads, ...
Estágio:           Lead novo, Em contato, Fechado, ...
Cargo:             Proprietário/Dono, Gerente Comercial, ...
Status:            Quente 🔥, Morno 🌡️, Frio ❄️
```

### Funções SQL (8 funções)
1. `get_novos_leads()` - Retorna contagem de novos leads
2. `get_leads_em_atendimento()` - Retorna leads em atendimento
3. `get_taxa_conversao()` - Calcula taxa de conversão
4. `get_faturamento()` - Soma faturamento de leads fechados
5. `get_performance_lead()` - Dados para gráfico de barras
6. `get_taxa_conversao_geral()` - Dados para gráfico circular
7. `get_funil_vendas()` - Dados para funil de vendas
8. `get_dashboard_completo()` - Retorna todos os dados em JSON

---

## 🔐 Segurança (RLS)

Row Level Security (RLS) configurado automaticamente:
- ✅ Usuários só veem dados da própria empresa
- ✅ Filtragem automática por `company_id`
- ✅ Políticas de SELECT, INSERT, UPDATE e DELETE
- ✅ Vinculação com `auth.users` do Supabase

---

## 📱 Responsividade

### Mobile (< 768px)
- Cards empilhados verticalmente
- Gráficos em largura total
- Filtros em Wrap (quebram linha)

### Desktop (> 768px)
- Cards em linha (4 cards lado a lado)
- Gráfico de barras: 60% da largura
- Gráfico circular + Funil: 40% da largura
- Filtros em Row (linha única)

---

## 🎯 Custom Actions (12 funções)

1. **calculateFilterPeriod** - Calcula período de filtro
2. **formatCurrency** - Formata valores em R$
3. **calculateConversionRate** - Calcula taxa de conversão
4. **processBarChartData** - Processa dados do gráfico de barras
5. **processCircularChartData** - Processa dados do gráfico circular
6. **processFunnelData** - Processa dados do funil
7. **getMonthNamePt** - Retorna nome do mês em português
8. **getWeekDayNamePt** - Retorna dia da semana em português
9. **formatDatePt** - Formata data em português
10. **determineGroupingType** - Define tipo de agrupamento
11. **validateCompanyId** - Valida UUID do company_id
12. **calculateBarWidth** - Calcula largura das barras

---

## 🎨 Custom Widgets (4 widgets)

1. **MetricCard** - Card de métrica com ícone e valor
2. **PerformanceBarChart** - Gráfico de barras comparativo
3. **ConversionPieChart** - Gráfico circular de conversão
4. **FunnelBar** - Barra horizontal do funil de vendas

---

## 📚 Documentação

### Documentos Disponíveis

1. **GUIA_IMPLEMENTACAO.md**
   - Guia completo passo a passo
   - 8 seções detalhadas
   - Configuração do Supabase
   - Configuração do FlutterFlow
   - Implementação de cada componente
   - Checklist completo

2. **CODIGO_COMPLETO_FLUTTERFLOW.md**
   - Códigos prontos para copiar
   - Widget Tree completa
   - Propriedades de todos os widgets
   - Backend Calls configurados
   - Actions detalhadas

3. **database/schema.sql**
   - Schema completo do banco
   - Tabelas com índices
   - RLS configurado
   - Triggers automáticos
   - Dados de exemplo

4. **database/queries.sql**
   - 8 funções SQL otimizadas
   - Exemplos de uso
   - Comentários explicativos

5. **flutterflow/custom_actions.dart**
   - 12 Custom Actions completas
   - Tipagem correta
   - Documentação inline

6. **flutterflow/custom_widgets.dart**
   - 4 Custom Widgets completos
   - Responsivos
   - Suporte a Dark/Light mode

---

## ✅ Checklist de Implementação

### Supabase
- [ ] Schema SQL executado
- [ ] Funções SQL criadas
- [ ] RLS verificado
- [ ] Dados de teste inseridos (opcional)

### FlutterFlow
- [ ] Supabase conectado
- [ ] Dependências adicionadas
- [ ] 12 Custom Actions criadas
- [ ] 4 Custom Widgets criados
- [ ] Backend Calls configurados

### Dashboard
- [ ] AppBar implementado
- [ ] Filtros funcionando
- [ ] 4 Cards exibindo dados
- [ ] Gráfico de barras funcionando
- [ ] Gráfico circular funcionando
- [ ] Funil de vendas funcionando
- [ ] Dark/Light mode funcionando
- [ ] Responsividade funcionando

### Testes
- [ ] Autenticação testada
- [ ] Filtros testados (todos)
- [ ] Dados carregando corretamente
- [ ] Gráficos renderizando
- [ ] Tema alternando corretamente
- [ ] Mobile testado
- [ ] Desktop testado

---

## 🎓 Como Usar

### 1. Clone ou baixe este repositório

### 2. Leia a documentação na ordem:
1. Este README (você está aqui)
2. GUIA_IMPLEMENTACAO.md (guia passo a passo)
3. CODIGO_COMPLETO_FLUTTERFLOW.md (códigos prontos)

### 3. Execute os scripts SQL:
```sql
-- Execute na ordem:
1. database/schema.sql
2. database/queries.sql
```

### 4. Adicione o código no FlutterFlow:
```dart
// Adicione na ordem:
1. Custom Actions (flutterflow/custom_actions.dart)
2. Custom Widgets (flutterflow/custom_widgets.dart)
3. Implemente a página seguindo CODIGO_COMPLETO_FLUTTERFLOW.md
```

### 5. Teste e ajuste conforme necessário

---

## 🔧 Requisitos

### FlutterFlow
- Plano Pro ou superior (para Custom Widgets)
- FlutterFlow versão 4.0+

### Supabase
- Projeto Supabase ativo
- Plano gratuito ou superior

### Dependências
```yaml
fl_chart: ^0.65.0
intl: ^0.18.0
```

---

## 📞 Suporte

### Problemas Comuns

**1. Funções SQL não encontradas**
- Verifique se executou `database/queries.sql`
- Confirme que as funções foram criadas no schema `public`

**2. Dados não carregam**
- Verifique o `company_id` do usuário logado
- Confirme que o RLS está ativo
- Verifique se há leads no período selecionado

**3. Gráficos não aparecem**
- Verifique se adicionou a dependência `fl_chart`
- Confirme que os Custom Widgets foram adicionados corretamente
- Verifique se os dados estão sendo processados pelas Custom Actions

**4. Tema não alterna**
- Verifique se configurou os temas no App Settings
- Confirme que a action `Set App Theme Mode` está correta

---

## 🎯 Características Técnicas

### Performance
- ✅ Queries otimizadas com índices
- ✅ RLS implementado corretamente
- ✅ Lazy loading dos componentes
- ✅ Cache de queries quando possível

### Segurança
- ✅ Row Level Security (RLS)
- ✅ Autenticação obrigatória
- ✅ Filtragem por empresa
- ✅ Validação de company_id

### UX/UI
- ✅ Layout EXATO conforme especificado
- ✅ Animações suaves
- ✅ Feedback visual em filtros
- ✅ Loading states
- ✅ Error handling

### Código
- ✅ Código limpo e documentado
- ✅ Tipagem correta
- ✅ Reutilização de componentes
- ✅ Padrões do FlutterFlow

---

## 🎉 Resultado Final

Após implementar todos os componentes, você terá:

✅ **Dashboard profissional** com design moderno
✅ **Filtros funcionais** com múltiplas opções
✅ **Métricas em tempo real** atualizadas por período
✅ **Gráficos interativos** com animações
✅ **Funil de vendas** visual e intuitivo
✅ **Dark/Light mode** com alternância suave
✅ **Responsivo** para mobile e desktop
✅ **Seguro** com RLS do Supabase

---

## 📝 Notas Importantes

1. **NÃO publique no GitHub** - Conforme solicitado, todo código está disponível aqui no chat
2. **Layout EXATO** - O design segue EXATAMENTE o layout fornecido
3. **Cores específicas** - Use as cores exatas especificadas (#FF9800, #1A1A1A, etc.)
4. **Ícones brancos** - Todos os ícones devem ser brancos
5. **Filtros em português** - Todos os textos em português brasileiro
6. **Company_id obrigatório** - Todos os dados são filtrados por empresa

---

## 🏆 Funcionalidades Implementadas

### ✅ Requisitos Obrigatórios
- [x] Layout EXATAMENTE como especificado
- [x] Responsivo (Mobile + Desktop)
- [x] Funcional e dinâmico
- [x] Filtros com maestria
- [x] Autenticação obrigatória
- [x] Separação por company_id
- [x] Filtros: Dia, Semana, Mês, Ano
- [x] Calendário dinâmico em português
- [x] Dark/Light mode dinâmico
- [x] Gráfico de barras comparativo
- [x] Lógica de agrupamento correta
- [x] 4 Cards com métricas
- [x] Ícones brancos (mesmos do layout)
- [x] Gráfico circular de conversão
- [x] Funil de vendas com 4 estágios
- [x] Dados da tabela leads do Supabase

### ✅ Extras Implementados
- [x] Animações suaves
- [x] Código documentado
- [x] Guia completo de implementação
- [x] Códigos prontos para copiar
- [x] Custom Actions otimizadas
- [x] Custom Widgets reutilizáveis
- [x] RLS configurado
- [x] Índices de performance
- [x] Validações
- [x] Error handling

---

## 🚀 Vamos Começar!

**Próximos passos:**

1. Abra **GUIA_IMPLEMENTACAO.md** para o passo a passo completo
2. Abra **CODIGO_COMPLETO_FLUTTERFLOW.md** para códigos prontos
3. Execute os scripts SQL em **database/**
4. Adicione os códigos Dart em **flutterflow/**
5. Implemente a página no FlutterFlow
6. Teste e publique!

---

**Desenvolvido com ❤️ para NEXIO**

Dashboard de Leads | FlutterFlow + Supabase | 100% Funcional | 100% Responsivo | Layout Exato
