# vend.AI - Sistema de Gestão de Leads com IA

Sistema de gestão de leads inteligente para empresas, desenvolvido com FlutterFlow e Supabase.

## 🚀 Projeto

**vend.AI** é uma plataforma que ajuda empresas a gerenciar leads qualificados através de inteligência artificial, com configuração de ICP (Ideal Customer Profile) e limites de plano mensais.

## 📋 Stack Tecnológica

- **Frontend:** FlutterFlow (Flutter)
- **Backend:** Supabase (PostgreSQL)
- **Autenticação:** Supabase Auth
- **Database:** PostgreSQL com Row Level Security (RLS)

## 🔧 Correções Recentes

### ✅ Bugs Críticos Corrigidos (17/12/2023)

Dois problemas críticos foram identificados e corrigidos:

#### 1. **ICP Configuration agora é READ-ONLY**
- ✅ Usuários não podem mais editar configurações do ICP
- ✅ Todos os campos transformados em visualização apenas
- ✅ Segurança RLS implementada no Supabase
- ✅ Banner informativo adicionado
- ✅ Apenas administradores podem modificar via painel admin

#### 2. **Contador de Leads Corrigido**
- ✅ Agora conta dinamicamente do banco de dados
- ✅ Sempre mostra valor preciso (ex: 9/70 em vez de 0/70)
- ✅ Atualização automática via triggers
- ✅ Reset mensal implementado

📖 **Documentação completa:** [docs/FIXES_VENDAI_CRITICAL_BUGS.md](docs/FIXES_VENDAI_CRITICAL_BUGS.md)

## 📁 Estrutura do Projeto

```
nexio/
├── lib/
│   └── custom_code/
│       └── widgets/
│           ├── icp_config_widget.dart           # Widget corrigido (READ-ONLY)
│           └── icp_config_widget_original.dart  # Backup do código original
├── supabase/
│   └── migrations/
│       └── 20231217_fix_vendai_critical_bugs.sql  # Migration com correções
├── docs/
│   └── FIXES_VENDAI_CRITICAL_BUGS.md  # Documentação detalhada
└── README.md  # Este arquivo
```

## 🚀 Como Aplicar as Correções

### 1. Aplicar Migration no Supabase

```bash
# Via Supabase CLI
supabase db push

# Ou via Dashboard Supabase SQL Editor
# Execute: supabase/migrations/20231217_fix_vendai_critical_bugs.sql
```

### 2. Atualizar Widget no FlutterFlow

1. Acesse FlutterFlow Dashboard
2. Navegue: **Custom Code** → **Widgets** → **ICPConfigWidget**
3. Substitua pelo código: `lib/custom_code/widgets/icp_config_widget.dart`
4. Salve e publique

### 3. Verificar Correções

- ✓ Campos ICP estão todos desabilitados (cinza)
- ✓ Banner "Gerenciado pela equipe vend.AI" aparece
- ✓ Contador de leads mostra valor correto
- ✓ Disponíveis = Limite - Extraídos

## 🔒 Segurança

### Row Level Security (RLS)

- **icp_configuration:** Apenas SELECT permitido para usuários
- **companies:** SELECT e UPDATE apenas da própria empresa
- **ICP_leads:** SELECT, UPDATE, DELETE apenas da própria empresa
- **Administradores:** Controle total via backend

## 📊 Estrutura de Dados

### Tabelas Principais

#### `companies`
- Informações da empresa
- Plano contratado (Performance, Enterprise, etc.)
- Limite mensal de leads
- Contador de leads extraídos (atualizado automaticamente)

#### `icp_configuration`
- Configuração do ICP (Ideal Customer Profile)
- READ-ONLY para usuários
- Editável apenas por administradores

#### `ICP_leads`
- Leads gerados baseados no ICP
- Status, prioridade, observações
- Gestão completa pelo usuário

## 📝 Funcionalidades

- ✅ Dashboard com métricas em tempo real
- ✅ Visualização de configuração ICP
- ✅ Gestão de leads (editar, visualizar, adicionar notas)
- ✅ Contador preciso de leads mensais
- ✅ Filtros e busca de leads
- ✅ Paginação de resultados
- ✅ Segurança com RLS

## 🧪 Testes

### Teste ICP READ-ONLY
```bash
1. Acessar página de Configuração ICP
2. Verificar que todos campos estão desabilitados
3. Verificar banner de aviso
4. Tentar editar → deve estar bloqueado
```

### Teste Contador de Leads
```bash
1. Verificar contador no dashboard
2. Comparar com tabela de leads
3. Extrair novo lead → contador deve aumentar
4. Verificar precisão: Extraídos + Disponíveis = Limite
```

## 📞 Suporte

Para alterações na configuração do ICP, entre em contato com:
- **Email:** suporte@vendai.com.br
- **Equipe:** vend.AI Support

## 🎯 Próximos Passos

- [ ] Dashboard administrativo para gestão de ICP
- [ ] Notificações quando limite de leads próximo
- [ ] Logs de auditoria para extrações
- [ ] Relatórios mensais de consumo
- [ ] API para integração externa

## 📄 Licença

Propriedade de vend.AI - Todos os direitos reservados.

---

**Versão:** 1.0.0
**Última atualização:** 17 de Dezembro de 2023