# Nexio.AI - Brief Executivo

<div align="center">

![Nexio.AI](https://via.placeholder.com/800x200/5415AC/FFFFFF?text=Nexio.AI)

**Plataforma B2B SaaS de Automação de Vendas com Agentes de IA**

*Mineração Inteligente de Leads + CRM Visual + WhatsApp Automation*

---

[![Stack](https://img.shields.io/badge/Stack-React%20%7C%20Node.js%20%7C%20Supabase-5415AC)](.)
[![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-orange)](.)
[![License](https://img.shields.io/badge/License-MIT-green)](.)

</div>

---

## 🎯 O Problema

**PMEs brasileiras perdem 60-70% dos leads** por falta de:
- ❌ Follow-up consistente
- ❌ Resposta rápida (< 5 min)
- ❌ Qualificação eficiente
- ❌ Visibilidade do pipeline

**Soluções atuais**:
- CRMs genéricos (Pipedrive, HubSpot): Caros, complexos, sem IA
- WhatsApp manual: Desorganizado, sem histórico, 1 device
- Agências: R$ 5-15k/mês, black box

---

## 💡 A Solução: Nexio.AI

**Plataforma All-in-One** que:

1. 🎯 **Minera leads** automaticamente (Google Maps)
2. 🤖 **Qualifica com IA** (score de fit, intent detection)
3. 💬 **Automatiza WhatsApp** (agente SDR autônomo)
4. 📊 **Visualiza pipeline** (Kanban em tempo real)
5. 🎙️ **Transcreve áudios** (Minimax API)

**Resultado**: PME converte 2-3x mais leads com 70% menos esforço manual.

---

## ✨ Diferenciais

| Nexio.AI | Concorrentes |
|----------|--------------|
| ✅ Mineração automática (Maps) | ❌ Importação manual |
| ✅ Agente SDR com IA | ❌ Automação básica (evolutioner) |
| ✅ WhatsApp espelhado + transcrição | ❌ Integração limitada |
| ✅ Kanban visual em tempo real | ⚠️ Listas estáticas |
| ✅ Multi-tenant (white-label ready) | ❌ Single-tenant |
| ✅ R$ 297-697/mês | ❌ R$ 1.500-5.000/mês |

**Vantagem competitiva**: Stack brasileiro (Evolution API, Minimax) + preço acessível + IA embutida.

---

## 🏗️ Arquitetura Técnica

```
┌─────────────────────────────────────────────────┐
│           Frontend (React + TypeScript)          │
│  Dashboard | Kanban | WhatsApp Mirror | Reports │
└────────────────────┬────────────────────────────┘
                     │ HTTPS/WSS
                     ▼
┌─────────────────────────────────────────────────┐
│        Backend (Node.js + Express + BullMQ)      │
│  REST API | WebSocket | Jobs Queue | Webhooks   │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
┌─────────────┐ ┌─────────┐ ┌──────────┐
│  Supabase   │ │  Redis  │ │   n8n    │
│ (Postgres)  │ │ (Cache) │ │(Workflow)│
└─────────────┘ └─────────┘ └──────────┘
        │
        └──> Integrações:
             • Evolution API (WhatsApp)
             • Apify (Scraping Maps)
             • Minimax (STT)
             • OpenAI (opcional - IA)
```

**Stack**:
- **Frontend**: React 18, TypeScript, Tailwind, Zustand, Socket.IO
- **Backend**: Node.js 20, Express, BullMQ, Zod
- **Banco**: Supabase (Postgres + Auth + Storage)
- **Deploy**: VPS + Easypanel (Docker)
- **Integrações**: Evolution API, Apify, Minimax, n8n

---

## 💰 Modelo de Negócio

### Planos SaaS (B2B):

| Plano | Preço/mês | Leads | Usuários | Features |
|-------|-----------|-------|----------|----------|
| **Starter** | R$ 297 | 500 | 1 | Extração manual, CRM básico |
| **Pro** | R$ 697 | 2.000 | 3 | Agente SDR, WhatsApp, IA |
| **Enterprise** | Sob consulta | Ilimitado | Ilimitado | White-label, SLA, suporte |

### Custos Operacionais (por cliente):

| Item | Custo/mês |
|------|-----------|
| VPS 4GB | R$ 40-80 |
| Supabase Pro | R$ 130 |
| Evolution API (WhatsApp) | R$ 50-100 |
| Minimax (STT) | R$ 50-100 |
| Apify (scraping) | R$ 0-50 |
| **Total** | **R$ 270-460** |

**Margem**: 40-60% (plano Pro)

### Projeção (12 meses):

| Mês | Clientes | MRR | Custo | Lucro |
|-----|----------|-----|-------|-------|
| 1-3 | 5 | R$ 3.485 | R$ 2.300 | R$ 1.185 |
| 4-6 | 15 | R$ 10.455 | R$ 6.900 | R$ 3.555 |
| 7-9 | 30 | R$ 20.910 | R$ 13.800 | R$ 7.110 |
| 10-12 | 50 | R$ 34.850 | R$ 23.000 | R$ 11.850 |

**Meta ano 1**: 50 clientes, R$ 35k MRR, R$ 12k lucro/mês

---

## 🎨 Design & UX

### Paleta de Cores:
- **Roxo primário**: `#5415AC` (dominante)
- **Laranja**: `#ED4F22`
- **Rosa magenta**: `#FD0685`
- **Gradiente**: `linear-gradient(90deg, #5415AC, #ED4F22, #FD0685)`

### Componentes Visuais:
- ✅ **Orb** (background login - ReactBits)
- ✅ **Magic Bento** (dashboard - ReactBits)
- ✅ **Kokomut UI Loader** (carregamentos elegantes)
- ✅ **AI State Loading** (progresso mineração)
- ✅ **Dark/Light Mode** (toggle automático)

### Responsividade:
- ✅ Mobile-first (375px+)
- ✅ Tablet (768px+)
- ✅ Desktop (1024px+)

**Referências de UI**:
- Linear.app (clean, minimalista)
- Notion (kanban fluido)
- Intercom (chat elegante)

---

## 📊 Funcionalidades Principais

### 1. Dashboard Inteligente
- Métricas em tempo real (leads hoje, conversão, score médio)
- Cards Magic Bento animados
- Filtros avançados (ICP, cidade, score, stage)
- Botão rápido "Extrair Leads"

### 2. Mineração Automática
- Input: URL do Google Maps
- Processo: Apify extrai até 500 leads/vez
- Output: Leads no Kanban em < 5 min
- Deduplicação automática (telefone/email)

### 3. Kanban Visual
- Drag & drop entre stages (new → contacted → qualified → proposal → won)
- Cards com: nome, score, cidade, tags, última interação
- Bulk actions (mover, deletar, exportar)
- WebSocket real-time (sem refresh)

### 4. WhatsApp Espelhado
- Lista de conversas (igual WhatsApp Web)
- Mensagens texto + áudio + imagem
- Transcrição automática (Minimax)
- Player nativo de áudio
- Status de entrega (✓, ✓✓, lido)
- Resposta manual ou automática (agente SDR)

### 5. Lead Viewer
- Dados completos (nome, telefone, empresa, cidade, score)
- Histórico de interações (timeline)
- ICP Match Score (0-100) com justificativa
- Botões: Copiar, WhatsApp (deep link), Editar
- Notas internas + tags

### 6. Agente SDR (Integração)
- Mensagens personalizadas (IA do usuário)
- Follow-up automático (D+3, D+7)
- Classificação de intenção (interesse/objeção)
- Criação de tarefas quando necessário

### 7. Relatórios
- Conversão por stage (funil)
- Taxa de resposta WhatsApp
- Leads por fonte (Maps, CSV, API)
- Export CSV/Excel

---

## 🚀 Roadmap de Produto

### MVP (3 meses):
- [x] Auth + Multi-tenant
- [x] Dashboard + Kanban básico
- [x] Extração Maps (Apify)
- [x] WhatsApp Mirror (texto)
- [x] Lead Viewer
- [x] Banco Supabase completo

### V1.0 (6 meses):
- [ ] WhatsApp áudio + transcrição (Minimax)
- [ ] Agente SDR baseline (integração API)
- [ ] Import CSV avançado
- [ ] Relatórios analytics
- [ ] Dark mode polido

### V2.0 (12 meses):
- [ ] Billing (Stripe)
- [ ] Integrações CRM (Pipedrive, HubSpot)
- [ ] Multi-canal (Email, Instagram)
- [ ] Mobile app (React Native)
- [ ] White-label

---

## 👥 Público-Alvo

### ICP (Ideal Customer Profile):

**Empresa**:
- Porte: PME (5-50 funcionários)
- Setor: Serviços, varejo, clínicas, escolas
- Receita: R$ 50k-500k/mês
- Localização: Brasil (SP, RJ, MG, PR, RS)

**Persona (Decisor)**:
- Cargo: Dono, Gestor comercial, CMO
- Dor: "Perco 70% dos leads por falta de follow-up"
- Meta: Aumentar vendas 2-3x sem contratar
- Orçamento: R$ 300-1.000/mês para automação

**Setores prioritários**:
1. 🏥 Clínicas e consultórios
2. 🏫 Escolas e cursos
3. 🍕 Restaurantes e delivery
4. 🏗️ Construtoras e imobiliárias
5. 💇 Salões e estética

---

## 📈 Go-to-Market

### Canais de Aquisição:

1. **Orgânico** (Custo: R$ 0)
   - SEO (blog: "como vender mais via WhatsApp")
   - YouTube (tutoriais de automação)
   - LinkedIn (posts do fundador)

2. **Pago** (Budget: R$ 3k/mês)
   - Google Ads (CPC R$ 2-5) - "CRM WhatsApp"
   - Meta Ads (CPL R$ 15-30) - Lookalike PMEs
   - TikTok Ads (vídeos "antes/depois")

3. **Parcerias** (Rev Share 20%)
   - Agências de marketing digital
   - Consultorias de vendas
   - Comunidades de empreendedores

4. **Indicação** (Desconto 30%)
   - Cliente indica → ganha 1 mês grátis
   - Indicado fecha → 30% off primeiro mês

### Funil de Conversão:

```
100 visitantes
  ↓ 20% (landing page)
20 leads
  ↓ 50% (trial 7 dias grátis)
10 trials
  ↓ 40% (ativação + onboarding)
4 pagantes

CAC: R$ 300-500
LTV: R$ 8.364 (12 meses × R$ 697)
LTV/CAC: 16x
```

---

## 🔐 Segurança & Compliance

### Implementado:
- ✅ HTTPS obrigatório (Let's Encrypt)
- ✅ JWT autenticação (Supabase Auth)
- ✅ Row-Level Security (RLS) - multi-tenant isolado
- ✅ Rate limiting (100 req/min)
- ✅ Webhook signature validation (HMAC)
- ✅ Logs de auditoria (quem/quando/o quê)

### LGPD:
- ✅ Consentimento explícito (checkbox opt-in)
- ✅ Direito ao esquecimento (soft delete)
- ✅ Portabilidade (export CSV/JSON)
- ✅ Minimização de dados (só o necessário)
- ✅ Termos de Uso + Política de Privacidade

### Backup:
- ✅ Supabase: backup diário automático (7 dias retention)
- ✅ Redis: snapshot a cada 6h
- ✅ Arquivos: Supabase Storage (replicado 3x)

---

## 💻 Stack Técnica Detalhada

### Frontend:
```json
{
  "framework": "React 18 + TypeScript",
  "build": "Vite",
  "styling": "Tailwind CSS + CSS Modules",
  "state": "Zustand + React Query",
  "routing": "React Router v6",
  "animations": "GSAP + Framer Motion",
  "charts": "Recharts",
  "ui-libs": ["ReactBits", "Kokomut UI"],
  "websocket": "Socket.IO Client"
}
```

### Backend:
```json
{
  "runtime": "Node.js 20 + TypeScript",
  "framework": "Express.js",
  "validation": "Zod",
  "jobs": "BullMQ + Redis",
  "websocket": "Socket.IO",
  "orm": "Prisma (opcional) ou SQL direto"
}
```

### Infraestrutura:
```yaml
Database: Supabase (Postgres 15 + Auth + Storage)
Cache: Redis 7 (Upstash ou self-hosted)
Queue: BullMQ
Workflows: n8n (self-hosted)
Deploy: Docker + Easypanel (VPS)
CDN: Cloudflare
Monitoring: Sentry + Uptime Robot
```

### Integrações:
- **WhatsApp**: Evolution API ou Uaevolution (APIs brasileiras)
- **Scraping**: Apify (Google Maps Scraper)
- **STT**: Minimax API (transcrição PT-BR)
- **IA**: OpenAI GPT-4o (opcional) ou agente custom do cliente

---

## 📞 Contato & Links

**Website**: nexio.ai (em construção)
**Demo**: app.nexio.ai (em breve)
**Docs**: docs.nexio.ai
**GitHub**: github.com/seu-usuario/nexio-ai
**Email**: contato@nexio.ai
**WhatsApp**: +55 11 9xxxx-xxxx

---

## 📄 Anexos

- [Arquitetura Completa](ARCHITECTURE.md)
- [Setup Local](docs/SETUP.md)
- [Integração com Agente Próprio](docs/INTEGRACAO_AGENTE_PROPRIO.md)
- [Prompts de IA](docs/PROMPTS.md)
- [Testes & QA](docs/TESTING.md)

---

<div align="center">

**Nexio.AI** - Automatize vendas, multiplique resultados.

*Made with 💜 in Brazil*

[![Deploy](https://img.shields.io/badge/Deploy-Ready-success)]()
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)]()
[![TypeScript](https://img.shields.io/badge/TypeScript-100%25-blue)]()

</div>
