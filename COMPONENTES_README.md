# 📋 Documentação dos Componentes Custom do Nexio

## 🎯 Visão Geral

Este projeto contém dois componentes custom widgets desenvolvidos para Flutter/FlutterFlow:

1. **ICPConfigWidget** - Formulário de configuração de ICP (Ideal Customer Profile)
2. **LeadsTableWidget** - Tabela profissional de gerenciamento de leads

---

## 📱 1. ICP Configuration Widget

### Descrição
Widget completo para configuração do perfil de cliente ideal com 5 etapas intuitivas.

### Arquivo
`lib/custom_code/widgets/icp_config_widget.dart`

### Características

#### ✨ Funcionalidades Principais
- **5 Etapas Completas:**
  1. **Demográfico**: Idade, renda, gênero, escolaridade, estados
  2. **Profissional**: Cargos, segmentos, tamanho da empresa, tempo de mercado
  3. **Comportamento**: Canais digitais, dores, objetivos, ciclo de compra
  4. **Preferências**: Formas de contato, budget, canais de comunicação
  5. **Cadência**: Leads por dia, prioridade, IA, notificações

#### 🎨 UI/UX
- ✅ Indicador de progresso visual entre etapas
- ✅ Validações inline com feedback imediato
- ✅ Tooltips explicativos em campos importantes
- ✅ Toasts animados no canto superior direito
- ✅ Animação de loading durante salvamento
- ✅ Animação de sucesso ao concluir
- ✅ Animação de erro com mensagens claras
- ✅ Design totalmente responsivo (mobile/tablet/desktop)
- ✅ Suporte automático a dark/light mode via FlutterFlowTheme
- ✅ Transições suaves entre etapas com animações
- ✅ Botão de voltar ao dashboard no header

#### 🔧 Integrações
- Supabase para persistência de dados
- Webhook N8N para processamento assíncrono
- FlutterFlow Theme System

### Uso no FlutterFlow

```dart
ICPConfigWidget(
  width: double.infinity,
  height: double.infinity,
  onComplete: () async {
    // Ação após salvar com sucesso
    Navigator.pop(context);
  },
)
```

### Campos Obrigatórios por Etapa

**Etapa 1 - Demográfico:**
- Idade Mínima *
- Idade Máxima *
- Estados * (pelo menos 1)

**Etapa 2 - Profissional:**
- Cargos * (pelo menos 1)
- Segmentos * (pelo menos 1)

**Etapa 3 - Comportamento:**
- Canais * (pelo menos 1)
- Dores * (pelo menos 1)

**Etapa 4 - Preferências:**
- Preferência de Contato * (pelo menos 1)

**Etapa 5 - Cadência:**
- Leads por dia (slider 0-20)

### Estrutura do Banco (Supabase)

Tabela: `icp_configuration`

```sql
CREATE TABLE icp_configuration (
  id SERIAL PRIMARY KEY,
  company_id INTEGER NOT NULL REFERENCES companies(id),

  -- Demográfico
  idade_min INTEGER,
  idade_max INTEGER,
  renda_min DECIMAL,
  renda_max DECIMAL,
  genero VARCHAR(50),
  escolaridade VARCHAR(100),
  estados TEXT[],

  -- Profissional
  cargos TEXT[],
  nichos TEXT[],
  tamanho_empresas TEXT[],
  tempo_mercado VARCHAR(100),
  empresa_funcionarios_min INTEGER,
  empresa_funcionarios_max INTEGER,

  -- Comportamento
  canais TEXT[],
  dores TEXT[],
  objetivos TEXT[],
  horario VARCHAR(50),
  linguagem VARCHAR(50),
  ciclo_compra VARCHAR(100),
  comprou_online BOOLEAN DEFAULT FALSE,
  influenciador BOOLEAN DEFAULT FALSE,

  -- Preferências
  preferencia_contato TEXT[],
  aceita_whatsapp BOOLEAN DEFAULT TRUE,
  aceita_email BOOLEAN DEFAULT TRUE,
  aceita_telefone BOOLEAN DEFAULT FALSE,
  budget_min DECIMAL,
  budget_max DECIMAL,

  -- Cadência
  leads_por_dia_max INTEGER DEFAULT 5,
  usar_ia BOOLEAN DEFAULT TRUE,
  entregar_fins_semana BOOLEAN DEFAULT FALSE,
  prioridade VARCHAR(50) DEFAULT 'Qualidade',
  notificar_novos_leads BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Webhook N8N

**Endpoint:** Configure em `lib/custom_code/widgets/icp_config_widget.dart` linha 246

```dart
const url = 'https://seu-n8n.com/webhook/processar-icp';
```

**Headers:**
```json
{
  "Content-Type": "application/json",
  "X-API-Key": "SUA_KEY_AQUI"
}
```

**Payload:**
```json
{
  "user_id": "uuid",
  "company_id": 123,
  "icp_id": 456,
  "icp": {
    "demografico": {...},
    "profissional": {...},
    "comportamento": {...},
    "preferencias": {...},
    "cadencia": {...}
  },
  "timestamp": "2025-11-25T10:30:00Z"
}
```

---

## 📊 2. Leads Table Widget

### Descrição
Tabela profissional e completa para gerenciamento de leads com todas as funcionalidades necessárias.

### Arquivo
`lib/custom_code/widgets/leads_table_widget.dart`

### Características

#### ✨ Funcionalidades Principais
- **Visualização Dual:**
  - Desktop/Tablet: DataTable completa
  - Mobile: Cards adaptados

- **Filtros e Busca:**
  - Busca por nome, email, telefone, empresa
  - Filtro por status (Novo, Contatado, Qualificado, etc.)
  - Filtro por período (Hoje, Semana, Mês)

- **Ordenação:**
  - Clique nas colunas para ordenar
  - Indicador visual de coluna ordenada
  - Ordem ascendente/descendente

- **Seleção e Bulk Actions:**
  - Checkbox para seleção múltipla
  - Seleção individual ou "Selecionar Todos"
  - Excluir múltiplos leads de uma vez
  - Contador de selecionados

- **Paginação:**
  - 10 leads por página (configurável)
  - Navegação entre páginas
  - Indicador de página atual

- **Ações Individuais:**
  - Visualizar detalhes
  - Alterar status
  - Excluir lead

- **Exportação:**
  - Exportar para CSV
  - Exportar selecionados ou todos filtrados

#### 🎨 UI/UX
- ✅ Design profissional e moderno
- ✅ Badges coloridos por status
- ✅ Score visual com estrela
- ✅ Responsividade total
- ✅ Dark/light mode automático
- ✅ Toasts no canto superior direito
- ✅ Confirmações para ações destrutivas
- ✅ Loading states
- ✅ Empty states (quando aplicável)

### Uso no FlutterFlow

```dart
LeadsTableWidget(
  width: double.infinity,
  height: double.infinity,
  onLeadClick: (leadId) async {
    // Navegar para detalhes do lead
    context.pushNamed('LeadDetails', extra: {'id': leadId});
  },
)
```

### Status de Leads

| Status | Cor | Significado |
|--------|-----|-------------|
| Novo | Azul (#007AFF) | Lead recém-chegado |
| Contatado | Roxo (#5856D6) | Primeiro contato feito |
| Qualificado | Laranja (#FF9500) | Lead qualificado |
| Proposta | Amarelo (#FFCC00) | Proposta enviada |
| Ganho | Verde (#34C759) | Lead convertido |
| Perdido | Vermelho (#FF3B30) | Lead perdido |

### Score de Qualidade

- 🟢 **80-100**: Alta qualidade
- 🟠 **50-79**: Média qualidade
- 🔴 **0-49**: Baixa qualidade

### Estrutura do Banco (Supabase)

Tabela: `leads`

```sql
CREATE TABLE leads (
  id SERIAL PRIMARY KEY,
  company_id INTEGER NOT NULL REFERENCES companies(id),

  -- Dados do Lead
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company VARCHAR(255),

  -- Status e Score
  status VARCHAR(50) DEFAULT 'Novo',
  score INTEGER DEFAULT 0,

  -- Metadados
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Índices
  INDEX idx_company_status (company_id, status),
  INDEX idx_created_at (created_at),
  INDEX idx_score (score)
);
```

---

## 🚀 Como Usar no FlutterFlow

### 1. Importar os Widgets

1. Abra seu projeto no FlutterFlow
2. Vá em **Custom Code** → **Widgets**
3. Clique em **Add Widget**
4. Cole o código de cada widget
5. Configure as dependências:
   - `google_fonts: ^6.1.0`
   - `http: ^1.1.0`

### 2. Configurar Supabase

1. Crie as tabelas no Supabase (scripts SQL acima)
2. Configure Row Level Security (RLS)
3. Teste as permissões

### 3. Configurar Webhook N8N

1. Crie um workflow no N8N
2. Configure o webhook endpoint
3. Atualize a URL no código (icp_config_widget.dart, linha 246)
4. Adicione a API Key

### 4. Adicionar à Página

**Para ICP Config:**
```
1. Crie uma nova página "ConfigurarICP"
2. Adicione um Custom Widget
3. Selecione "ICPConfigWidget"
4. Configure width/height como desejado
```

**Para Tabela de Leads:**
```
1. Crie uma página "MeusLeads"
2. Adicione um Custom Widget
3. Selecione "LeadsTableWidget"
4. Configure width/height como desejado
5. Configure o callback onLeadClick se necessário
```

---

## 🎨 Temas e Responsividade

### Dark/Light Mode

Ambos os componentes detectam automaticamente o tema do FlutterFlow:

```dart
final theme = FlutterFlowTheme.of(context);
// Usa automaticamente:
// - theme.primary
// - theme.secondary
// - theme.primaryBackground
// - theme.secondaryBackground
// - theme.primaryText
// - theme.secondaryText
// - theme.alternate
```

### Breakpoints

- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

Os componentes se adaptam automaticamente.

---

## ⚙️ Configurações Importantes

### URLs a Configurar

1. **Webhook N8N** (`icp_config_widget.dart`, linha 246):
```dart
const url = 'https://SEU-N8N.com/webhook/processar-icp';
```

2. **API Key** (`icp_config_widget.dart`, linha 252):
```dart
'X-API-Key': 'SUA_KEY_AQUI',
```

### Ajustes Opcionais

**Leads por página** (`leads_table_widget.dart`, linha 49):
```dart
int _rowsPerPage = 10; // Altere para 15, 20, etc.
```

**Timeout do webhook** (`icp_config_widget.dart`, linha 255):
```dart
.timeout(const Duration(seconds: 30)); // Aumente se necessário
```

---

## 🐛 Troubleshooting

### Problema: "Erro ao carregar dados"
- ✅ Verifique a conexão com Supabase
- ✅ Confirme que as tabelas existem
- ✅ Verifique as RLS policies

### Problema: "Erro ao salvar configuração"
- ✅ Verifique os campos obrigatórios
- ✅ Confirme o company_id
- ✅ Veja os logs no console

### Problema: "ICP salvo, mas erro no processamento"
- ✅ Verifique a URL do webhook
- ✅ Confirme que a API Key está correta
- ✅ Teste o endpoint manualmente

### Problema: Tema não muda
- ✅ Certifique-se de usar FlutterFlowTheme.of(context)
- ✅ Reinicie o app após mudar o tema
- ✅ Verifique se o tema está configurado no FlutterFlow

---

## 📝 Checklist de Implementação

### Setup Inicial
- [ ] Criar tabelas no Supabase
- [ ] Configurar RLS policies
- [ ] Criar workflow no N8N
- [ ] Adicionar widgets no FlutterFlow
- [ ] Instalar dependências

### Configuração
- [ ] Atualizar URL do webhook
- [ ] Adicionar API Key
- [ ] Testar conexão com Supabase
- [ ] Testar webhook

### Deploy
- [ ] Criar páginas no FlutterFlow
- [ ] Adicionar navigation
- [ ] Testar em mobile
- [ ] Testar em desktop
- [ ] Testar dark/light mode
- [ ] Testar com dados reais

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs do console (debugPrint)
2. Teste as queries do Supabase diretamente
3. Valide o payload do webhook
4. Revise este README

---

## 🎉 Próximos Passos

Depois de implementar estes componentes, você pode:

1. **Adicionar mais filtros** na tabela de leads
2. **Criar dashboard** com métricas de leads
3. **Implementar notificações** push quando novos leads chegarem
4. **Adicionar histórico** de alterações de status
5. **Criar relatórios** de conversão
6. **Integrar com CRM** externo

---

**Versão:** 1.0
**Data:** 25/11/2025
**Desenvolvido para:** Nexio - Sistema de Gerenciamento de Leads
**Stack:** Flutter + FlutterFlow + Supabase + N8N
