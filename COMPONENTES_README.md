# 📋 Documentação dos Componentes Custom do Nexio

## 🎯 Visão Geral

Este projeto contém dois componentes custom widgets desenvolvidos para Flutter/FlutterFlow:

1. **ICPConfigWidget** - Formulário de configuração de ICP (Ideal Customer Profile)
2. **MeusLeadsPage** - Página completa de gerenciamento de leads

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

## 📊 2. Meus Leads Page

### Descrição
Página completa e integrada para gerenciamento de leads. Não é um widget separado - representa toda a interface da página "Meus Leads".

### Arquivo
`lib/custom_code/widgets/meus_leads_page.dart`

### Características

#### ✨ Layout Integrado
A página inclui tudo em um único componente:

**Header:**
- Botão voltar (canto superior esquerdo)
- Título "Meus Leads"
- Botão "Exportar" (outline)
- Botão "Novo Lead" (primário, laranja)

**Busca e Filtros:**
- Barra de busca por nome, email ou cidade
- Filtros horizontais em pills:
  - Todos (selecionado por padrão)
  - Novo
  - Em Contato
  - Conversando
  - Qualificado
- Contador de leads encontrados com ícone

**Tabela/Lista:**
- Desktop/Tablet: DataTable completa com scroll horizontal
- Mobile: Cards estilizados

#### ✨ Funcionalidades

- **Busca em Tempo Real:**
  - Busca por nome, email, telefone, empresa
  - Atualização automática ao digitar

- **Filtros de Status:**
  - Pills clicáveis com destaque visual
  - Filtro "Todos" mostra todos os leads
  - Filtros específicos por status

- **Ordenação:**
  - Clique nas colunas para ordenar
  - Indicador visual de coluna ordenada
  - Alterna entre ascendente/descendente

- **Seleção Múltipla:**
  - Checkbox em cada lead
  - "Selecionar Todos" no header da tabela
  - Barra de bulk actions aparece quando há seleção

- **Bulk Actions:**
  - Excluir múltiplos leads
  - Limpar seleção
  - Contador de selecionados

- **Ações Individuais:**
  - Visualizar detalhes (via callback)
  - Alterar status (modal)
  - Excluir lead (confirmação)

- **Paginação:**
  - 10 leads por página
  - Navegação entre páginas
  - Indicador de página atual
  - Números de página clicáveis (desktop)

- **Exportação:**
  - Exportar selecionados ou todos
  - Formato CSV
  - Toast de confirmação

- **Empty State:**
  - Ícone e mensagem quando não há leads
  - Botão "Configurar ICP"
  - Chamada para ação clara

#### 🎨 UI/UX
- ✅ Design consistente com o layout do sistema
- ✅ Badges coloridos por status
- ✅ Score visual com estrela e cores
- ✅ Responsividade total (mobile, tablet, desktop)
- ✅ Dark/light mode automático
- ✅ Toasts no canto superior direito
- ✅ Confirmações para ações destrutivas
- ✅ Loading states
- ✅ Feedback visual em todas interações
- ✅ Transições suaves

### Uso no FlutterFlow

**No FlutterFlow, crie uma página e adicione este widget ocupando toda a área:**

```dart
MeusLeadsPage(
  width: double.infinity,
  height: double.infinity,

  // Callback ao clicar em "Novo Lead"
  onNovoLead: () async {
    // Navegar para formulário de novo lead ou abrir modal
    context.pushNamed('NovoLead');
  },

  // Callback ao clicar em "Configurar ICP" (no empty state)
  onConfigICP: () async {
    // Navegar para configuração de ICP
    context.pushNamed('ConfigurarICP');
  },

  // Callback ao clicar em um lead
  onLeadClick: (leadId) async {
    // Navegar para detalhes do lead
    context.pushNamed(
      'LeadDetails',
      extra: {'id': leadId},
    );
  },
)
```

### Status de Leads

| Status | Cor | Hex |
|--------|-----|-----|
| Novo | Azul | #007AFF |
| Em Contato | Roxo | #5856D6 |
| Conversando | Laranja | #FF9500 |
| Qualificado | Verde | #34C759 |

### Score de Qualidade

- 🟢 **80-100**: Alta qualidade (Verde #34C759)
- 🟠 **50-79**: Média qualidade (Laranja #FF9500)
- 🔴 **0-49**: Baixa qualidade (Vermelho #FF3B30)

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

### Status Aceitos
- 'Novo'
- 'Em Contato'
- 'Conversando'
- 'Qualificado'

---

## 🚀 Como Usar no FlutterFlow

### 1. Importar os Widgets

1. Abra seu projeto no FlutterFlow
2. Vá em **Custom Code** → **Widgets**
3. Clique em **Add Widget**
4. Cole o código de cada widget:
   - `icp_config_widget.dart`
   - `meus_leads_page.dart`
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

### 4. Criar Páginas no FlutterFlow

#### Página: Configurar ICP
```
1. Crie uma nova página "ConfigurarICP"
2. Adicione um Custom Widget
3. Selecione "ICPConfigWidget"
4. Configure:
   - width: infinityWidth
   - height: infinityHeight
   - onComplete: Navegar de volta ou mostrar sucesso
```

#### Página: Meus Leads
```
1. Crie uma nova página "MeusLeads"
2. Adicione um Custom Widget
3. Selecione "MeusLeadsPage"
4. Configure:
   - width: infinityWidth
   - height: infinityHeight
   - onNovoLead: Navegar para formulário de novo lead
   - onConfigICP: Navegar para configuração ICP
   - onLeadClick: Navegar para detalhes do lead
```

---

## 🎨 Temas e Responsividade

### Dark/Light Mode

Ambos os componentes detectam automaticamente o tema do FlutterFlow:

```dart
final theme = FlutterFlowTheme.of(context);
// Usa automaticamente:
// - theme.primary (cor primária do app)
// - theme.secondary
// - theme.primaryBackground
// - theme.secondaryBackground
// - theme.primaryText
// - theme.secondaryText
// - theme.alternate (bordas)
```

### Breakpoints

- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

Os componentes se adaptam automaticamente:
- Mobile: Interface compacta, cards, navegação simplificada
- Tablet: Interface intermediária
- Desktop: Interface completa com todos os recursos

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

**Leads por página** (`meus_leads_page.dart`, linha 49):
```dart
int _rowsPerPage = 10; // Altere para 15, 20, etc.
```

**Timeout do webhook** (`icp_config_widget.dart`, linha 255):
```dart
.timeout(const Duration(seconds: 30)); // Aumente se necessário
```

---

## 🎨 Design System

### Cores Padrão do Sistema

**Status:**
- Novo: #007AFF (Azul iOS)
- Em Contato: #5856D6 (Roxo iOS)
- Conversando: #FF9500 (Laranja iOS)
- Qualificado: #34C759 (Verde iOS)

**Feedback:**
- Sucesso: #34C759 (Verde)
- Erro: #FF3B30 (Vermelho)
- Aviso: #FF9500 (Laranja)
- Info: #007AFF (Azul)

**Scores:**
- Alto (80-100): #34C759 (Verde)
- Médio (50-79): #FF9500 (Laranja)
- Baixo (0-49): #FF3B30 (Vermelho)

### Tipografia

Usa Google Fonts - Inter:
- Títulos: Inter 18-22px, Weight 700
- Subtítulos: Inter 14-16px, Weight 600
- Corpo: Inter 13-14px, Weight 400-500
- Caption: Inter 12-13px, Weight 400

### Espaçamentos

- Padding pequeno: 8-12px
- Padding médio: 16-20px
- Padding grande: 24-32px
- Border radius: 8-12px (cards), 20px (pills)

---

## 🐛 Troubleshooting

### Problema: "Erro ao carregar dados"
- ✅ Verifique a conexão com Supabase
- ✅ Confirme que as tabelas existem
- ✅ Verifique as RLS policies
- ✅ Verifique se o usuário está autenticado

### Problema: "Erro ao salvar configuração"
- ✅ Verifique os campos obrigatórios
- ✅ Confirme o company_id
- ✅ Veja os logs no console (debugPrint)
- ✅ Verifique permissões de insert no Supabase

### Problema: "ICP salvo, mas erro no processamento"
- ✅ Verifique a URL do webhook
- ✅ Confirme que a API Key está correta
- ✅ Teste o endpoint manualmente (Postman/Insomnia)
- ✅ Verifique os logs do N8N

### Problema: Tema não muda
- ✅ Certifique-se de usar FlutterFlowTheme.of(context)
- ✅ Reinicie o app após mudar o tema
- ✅ Verifique se o tema está configurado no FlutterFlow
- ✅ Teste em hot restart, não hot reload

### Problema: Layout quebrado no mobile
- ✅ Verifique se width e height estão como infinity
- ✅ Teste em diferentes tamanhos de tela
- ✅ Verifique o console para erros de overflow
- ✅ Use o device preview do FlutterFlow

### Problema: Filtros não funcionam
- ✅ Verifique se os status no banco correspondem aos filtros
- ✅ Status são case-sensitive: "Novo", não "novo"
- ✅ Veja os logs no console
- ✅ Teste a query diretamente no Supabase

---

## 📝 Checklist de Implementação

### Setup Inicial
- [ ] Criar tabelas no Supabase
- [ ] Configurar RLS policies
- [ ] Criar workflow no N8N
- [ ] Adicionar widgets no FlutterFlow
- [ ] Instalar dependências (google_fonts, http)

### Configuração
- [ ] Atualizar URL do webhook
- [ ] Adicionar API Key
- [ ] Testar conexão com Supabase
- [ ] Testar webhook com dados de exemplo
- [ ] Configurar theme no FlutterFlow

### Páginas
- [ ] Criar página "ConfigurarICP"
- [ ] Criar página "MeusLeads"
- [ ] Adicionar navegação entre páginas
- [ ] Configurar callbacks
- [ ] Adicionar à navegação principal

### Testes
- [ ] Testar ICP em mobile
- [ ] Testar ICP em desktop
- [ ] Testar leads em mobile
- [ ] Testar leads em desktop
- [ ] Testar dark mode
- [ ] Testar light mode
- [ ] Testar com dados reais
- [ ] Testar todos os filtros
- [ ] Testar ordenação
- [ ] Testar paginação
- [ ] Testar exportação
- [ ] Testar exclusão

### Deploy
- [ ] Revisar todas as URLs
- [ ] Revisar API Keys
- [ ] Testar em produção
- [ ] Monitorar erros
- [ ] Coletar feedback dos usuários

---

## 🎯 Fluxo de Uso Recomendado

1. **Primeiro Acesso:**
   - Usuário vai para "Meus Leads"
   - Vê empty state
   - Clica em "Configurar ICP"
   - Preenche as 5 etapas
   - ICP é ativado

2. **Recebendo Leads:**
   - N8N processa o ICP
   - Leads são encontrados e inseridos no banco
   - Usuário vê notificação (se ativado)
   - Leads aparecem na página "Meus Leads"

3. **Gerenciando Leads:**
   - Usuário busca leads
   - Filtra por status
   - Clica para ver detalhes
   - Altera status conforme progresso
   - Exporta quando necessário

4. **Manutenção:**
   - Usuário pode voltar e editar o ICP
   - Configuração é atualizada
   - N8N processa novos critérios
   - Novos leads chegam conforme novo ICP

---

## 🎉 Próximos Passos

Depois de implementar estes componentes, você pode:

1. **Adicionar Dashboard** com métricas e gráficos
2. **Criar página de detalhes** do lead completa
3. **Implementar notificações push** quando novos leads chegarem
4. **Adicionar timeline** de interações com cada lead
5. **Criar relatórios** de conversão e ROI
6. **Integrar com CRM** externo (RD Station, HubSpot, etc)
7. **Adicionar tags** personalizadas nos leads
8. **Implementar funil visual** de vendas
9. **Criar automações** de follow-up
10. **Adicionar chat/mensagens** integrados

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs do console (`debugPrint`)
2. Teste as queries do Supabase diretamente no SQL Editor
3. Valide o payload do webhook no N8N
4. Revise este README
5. Verifique os commits no GitHub para ver o código completo

---

## 📦 Estrutura de Arquivos

```
nexio/
├── lib/
│   └── custom_code/
│       └── widgets/
│           ├── index.dart              # Exporta todos os widgets
│           ├── icp_config_widget.dart  # Widget de configuração ICP
│           └── meus_leads_page.dart    # Página completa de leads
├── COMPONENTES_README.md               # Esta documentação
└── README.md                           # README do projeto
```

---

**Versão:** 2.0
**Data:** 25/11/2025
**Desenvolvido para:** Nexio - Sistema de Gerenciamento de Leads
**Stack:** Flutter + FlutterFlow + Supabase + N8N
**Autor:** Claude Code Assistant

---

## 🔄 Changelog

### v2.0 - 25/11/2025
- ✅ Refatorado: Integrada tabela na página principal
- ✅ Removido: Widget separado de tabela
- ✅ Adicionado: MeusLeadsPage como componente único
- ✅ Melhorado: Layout consistente com o design do sistema
- ✅ Adicionado: Callbacks para ações customizadas

### v1.0 - 25/11/2025
- ✅ Release inicial
- ✅ ICPConfigWidget completo
- ✅ LeadsTableWidget separado (descontinuado)
