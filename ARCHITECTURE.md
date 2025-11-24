# Nexio.AI - Arquitetura do Sistema

## Visão Geral

**Nexio.AI** é uma plataforma B2B SaaS de automação e CRM com foco em agentes de IA SDR (Sales Development Representative) para mineração, qualificação e entrega de leads com automação via WhatsApp.

---

## Stack Tecnológica

### Frontend
- **Framework**: React 18+ com TypeScript
- **Estilização**: Tailwind CSS + CSS Modules
- **Animações**: GSAP (Magic Bento), Framer Motion (Loaders)
- **Componentes UI**:
  - ReactBits (Magic Bento, Orb)
  - Kokomut UI (Loader, AI State Loading, Profile Dropdown)
- **Gerenciamento de estado**: Zustand ou React Query
- **Roteamento**: React Router v6
- **Build**: Vite

### Backend
- **Runtime**: Node.js 20+ com TypeScript
- **Framework**: Express.js
- **Autenticação**: Supabase Auth (OAuth2/JWT)
- **Validação**: Zod
- **Jobs/Queue**: BullMQ + Redis
- **WebSocket**: Socket.IO (para WhatsApp real-time)

### Banco de Dados
- **Primário**: Supabase (PostgreSQL)
- **Cache**: Redis
- **Storage**: Supabase Storage (áudios, anexos)

### Orquestração e IA
- **Workflows**: n8n (auto-hospedado)
- **LLM**: OpenAI GPT-4o / Anthropic Claude
- **STT**: OpenAI Whisper
- **TTS**: ElevenLabs ou Amazon Polly

### Integrações
- **WhatsApp**: Twilio / 360dialog / Meta Business API
- **Lead Mining**: Apify (Google Maps scraper)
- **Enriquecimento**: Clearbit, CNPJ Receita, SerpAPI

### DevOps
- **Containerização**: Docker + Docker Compose
- **Orquestração**: Kubernetes (EKS/GKE) ou Railway/Render
- **CI/CD**: GitHub Actions
- **Monitoramento**: Sentry, LogTail, Uptime Robot

---

## Arquitetura de Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND (React)                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐ │
│  │ Dashboard  │  │  Kanban    │  │   Mining   │  │ WhatsApp  │ │
│  │ (Bento)    │  │  (DnD)     │  │ (Real-time)│  │  Mirror   │ │
│  └────────────┘  └────────────┘  └────────────┘  └───────────┘ │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS/WSS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY (Express)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Auth Routes  │  │ Lead Routes  │  │ WhatsApp API │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└───────┬─────────────────┬─────────────────┬─────────────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐  ┌──────────────┐  ┌─────────────────┐
│   Supabase    │  │   BullMQ     │  │   Socket.IO     │
│  (Postgres)   │  │  (Jobs)      │  │ (Real-time WS)  │
│               │  │              │  │                 │
│ • tenants     │  │ • Extract    │  │ • Chat events   │
│ • users       │  │ • Enrich     │  │ • Lead updates  │
│ • leads       │  │ • Send MSG   │  │ • Notifications │
│ • conversations│ └──────────────┘  └─────────────────┘
│ • n8n_jobs    │
└───────┬───────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                         n8n WORKFLOWS                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Lead Intake  │  │ Enrichment   │  │ SDR Agent    │          │
│  │ (Webhook)    │→ │ (APIs)       │→ │ (OpenAI)     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                 │
│         ▼                  ▼                  ▼                 │
│    [Supabase]      [External APIs]     [WhatsApp Send]         │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVIÇOS EXTERNOS                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Apify      │  │  WhatsApp    │  │   OpenAI     │          │
│  │ (Scraping)   │  │   (Twilio)   │  │  (STT/LLM)   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Fluxo de Dados Principal

### 1. Extração de Leads (Google Maps)
```
[Usuário] → [Dashboard: Inserir URL Maps]
          ↓
[POST /api/leads/extract] → [BullMQ Job: apify-scrape]
          ↓
[Apify Actor] → [Retorna JSON com leads]
          ↓
[Job Handler] → [INSERT em Supabase leads table]
          ↓
[WebSocket] → [Frontend atualiza em real-time]
          ↓
[n8n Trigger: new_lead] → [Workflow Enrichment + SDR]
```

### 2. Agente SDR (Automação de Follow-up)
```
[Lead criado] → [n8n: Webhook Trigger]
              ↓
[Enriquecimento: CNPJ, social, score]
              ↓
[OpenAI: Gerar mensagem personalizada]
              ↓
[Decisão: Enviar agora? ou agendar?]
              ↓
[WhatsApp API: Enviar mensagem]
              ↓
[Salvar em conversations table]
              ↓
[Aguardar resposta (48h)]
              ↓
[Se sem resposta] → [Follow-up #2 (delay 3 dias)]
[Se resposta]     → [Classificar intent com IA]
                     ↓
                  [Atualizar stage no Kanban]
```

### 3. WhatsApp Espelhado (Mirroring)
```
[WhatsApp Webhook: incoming message]
              ↓
[POST /api/conversations/webhook]
              ↓
[Validar assinatura Twilio/360dialog]
              ↓
[Se áudio] → [Download media] → [Whisper STT] → [Salvar transcript]
              ↓
[INSERT em conversations table]
              ↓
[Socket.IO emit: new_message]
              ↓
[Frontend Chat UI atualiza]
              ↓
[n8n: Trigger resposta automática?]
```

---

## Módulos e Responsabilidades

### Frontend (`/frontend`)
| Módulo | Responsabilidade |
|--------|------------------|
| `pages/Dashboard` | Exibir Magic Bento com cards de métricas + botão extração |
| `pages/Mining` | Animação AI State Loading durante extração, contador em tempo real |
| `pages/Kanban` | Drag & drop de leads entre estágios (new → qualified → proposal → closed) |
| `pages/LeadViewer` | Visualização completa do lead com histórico e ações |
| `pages/WhatsApp` | Chat espelhado com player de áudio + transcrição |
| `components/Orb` | Background animado da página de login |
| `components/Loader` | Kokomut UI Loader para estados de carregamento |
| `components/AILoadingState` | Exibir progresso de extração/mineração |
| `hooks/useWebSocket` | Gerenciar conexão Socket.IO para updates em tempo real |
| `stores/authStore` | Zustand store para autenticação |
| `stores/leadsStore` | Zustand store para leads e filtros |

### Backend (`/backend`)
| Módulo | Responsabilidade |
|--------|------------------|
| `routes/auth.ts` | Login, registro, refresh token via Supabase Auth |
| `routes/leads.ts` | CRUD de leads, import CSV, extract Maps URL |
| `routes/conversations.ts` | Enviar/receber mensagens WhatsApp, webhook handler |
| `routes/n8n.ts` | Trigger workflows, receber callbacks |
| `jobs/extractLeads.ts` | BullMQ job para chamar Apify e processar resultados |
| `jobs/enrichLead.ts` | BullMQ job para enriquecer lead (CNPJ, social) |
| `jobs/sendWhatsApp.ts` | BullMQ job para enviar mensagem via Twilio |
| `services/apify.ts` | Cliente Apify para scraping Maps |
| `services/whatsapp.ts` | Cliente Twilio/360dialog para send/receive |
| `services/supabase.ts` | Cliente Supabase autenticado |
| `services/openai.ts` | Cliente OpenAI para STT/LLM |
| `middleware/auth.ts` | Validar JWT e anexar user context |
| `websocket/server.ts` | Socket.IO server para eventos em tempo real |

### n8n Workflows (`/n8n`)
| Workflow | Trigger | Ação |
|----------|---------|------|
| `lead-intake.json` | HTTP POST ou Supabase new row | Recebe lead → enriquece → gera mensagem → agenda envio |
| `sdr-agent.json` | Cron diário ou evento | Verifica leads sem resposta → follow-up automático |
| `audio-processor.json` | Webhook WhatsApp audio | Download → STT → classificar intent → responder |
| `enrichment.json` | Manual ou automático | Call APIs externas (CNPJ, Clearbit) → atualizar lead |

---

## Multi-tenancy

### Estratégia: Row-Level Security (RLS) no Supabase

Todas as tabelas possuem coluna `tenant_id`:
```sql
CREATE POLICY "Users can only see their tenant data"
ON leads FOR SELECT
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

### Subdomínios (Opcional para MVP)
- `acme.nexio.ai` → tenant_id = `acme`
- `demo.nexio.ai` → tenant_id = `demo`

Middleware detecta subdomínio e injeta `tenant_id` no request context.

---

## Segurança

1. **Autenticação**: JWT via Supabase Auth com refresh tokens
2. **Autorização**: RLS no Supabase + middleware RBAC no backend
3. **Webhooks**: Validar assinatura HMAC do Twilio/360dialog
4. **Rate Limiting**: Express Rate Limit (100 req/min por IP)
5. **CORS**: Permitir apenas domínios autorizados
6. **Secrets**: Variáveis de ambiente (`.env`) nunca commitadas
7. **Logs de Auditoria**: Tabela `audit_logs` para todas ações sensíveis

---

## Performance e Escalabilidade

1. **Cache Redis**:
   - Leads por filtro (TTL 5 min)
   - Métricas do dashboard (TTL 10 min)
2. **CDN**: Cloudflare para assets estáticos
3. **Lazy Loading**: Componentes React com `React.lazy()`
4. **Pagination**: Cursor-based para listas longas
5. **WebSocket**: Emitir apenas para salas específicas (room = tenant_id)
6. **Job Queue**: BullMQ processa em background, evita timeout HTTP

---

## Roadmap de Deploy

### MVP (Sprint 0-3)
- Frontend em **Vercel** (deploy automático via GitHub)
- Backend em **Railway** ou **Render** (container Docker)
- Supabase **Cloud** (plano Pro)
- n8n **self-hosted** em VPS (Hetzner/DigitalOcean)
- Redis **Upstash** (serverless)

### Produção (Sprint 4+)
- Frontend CDN + Vercel
- Backend em **Kubernetes** (EKS/GKE) com auto-scaling
- Supabase self-hosted ou Cloud Enterprise
- n8n em cluster (3+ nodes)
- Redis Cluster (HA)
- Monitoring: Sentry + Datadog

---

## Critérios de Sucesso (KPIs)

1. **Time to First Lead**: < 3 min da URL Maps até aparecer no Kanban
2. **WhatsApp Latency**: Mensagem entrante aparece no UI em < 5s
3. **Audio Transcription**: < 10s para áudio de 1 min
4. **Uptime**: 99.9% (target)
5. **Response Time API**: p95 < 500ms

---

## Próximos Passos

Ver `README.md` para setup local e `DEPLOY.md` para instruções de produção.
