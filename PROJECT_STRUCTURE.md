# Nexio.AI - Estrutura de Pastas

```
nexio-ai/
├── frontend/                          # Aplicação React
│   ├── public/
│   │   ├── favicon.ico
│   │   ├── logo-purple.svg
│   │   └── logo-white.svg
│   ├── src/
│   │   ├── assets/
│   │   │   ├── fonts/
│   │   │   └── images/
│   │   ├── components/
│   │   │   ├── ui/                    # Componentes base reutilizáveis
│   │   │   │   ├── Orb/
│   │   │   │   │   ├── Orb.tsx
│   │   │   │   │   └── Orb.css
│   │   │   │   ├── MagicBento/
│   │   │   │   │   ├── MagicBento.tsx
│   │   │   │   │   └── MagicBento.css
│   │   │   │   ├── Loader/
│   │   │   │   │   └── Loader.tsx
│   │   │   │   ├── AILoadingState/
│   │   │   │   │   └── AILoadingState.tsx
│   │   │   │   ├── ProfileDropdown/
│   │   │   │   │   └── ProfileDropdown.tsx
│   │   │   │   ├── Button/
│   │   │   │   │   └── Button.tsx
│   │   │   │   ├── Modal/
│   │   │   │   │   └── Modal.tsx
│   │   │   │   ├── Toast/
│   │   │   │   │   └── Toast.tsx
│   │   │   │   └── Skeleton/
│   │   │   │       └── Skeleton.tsx
│   │   │   ├── layout/
│   │   │   │   ├── Navbar.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   └── Layout.tsx
│   │   │   ├── leads/
│   │   │   │   ├── LeadCard.tsx
│   │   │   │   ├── LeadList.tsx
│   │   │   │   ├── LeadViewer.tsx
│   │   │   │   ├── KanbanBoard.tsx
│   │   │   │   ├── KanbanColumn.tsx
│   │   │   │   └── BulkActions.tsx
│   │   │   ├── whatsapp/
│   │   │   │   ├── ChatContainer.tsx
│   │   │   │   ├── MessageBubble.tsx
│   │   │   │   ├── AudioPlayer.tsx
│   │   │   │   ├── AudioRecorder.tsx
│   │   │   │   └── ConversationList.tsx
│   │   │   ├── mining/
│   │   │   │   ├── MiningDashboard.tsx
│   │   │   │   ├── ExtractModal.tsx
│   │   │   │   ├── ProgressTracker.tsx
│   │   │   │   └── LeadPreview.tsx
│   │   │   └── dashboard/
│   │   │       ├── MetricsCard.tsx
│   │   │       ├── FilterBar.tsx
│   │   │       └── QuickActions.tsx
│   │   ├── pages/
│   │   │   ├── Login.tsx
│   │   │   ├── Register.tsx
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Mining.tsx
│   │   │   ├── Kanban.tsx
│   │   │   ├── LeadDetails.tsx
│   │   │   ├── WhatsApp.tsx
│   │   │   ├── Settings.tsx
│   │   │   ├── Profile.tsx
│   │   │   └── Reports.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useWebSocket.ts
│   │   │   ├── useLeads.ts
│   │   │   ├── useConversations.ts
│   │   │   ├── useTheme.ts
│   │   │   └── useToast.ts
│   │   ├── stores/
│   │   │   ├── authStore.ts
│   │   │   ├── leadsStore.ts
│   │   │   ├── conversationsStore.ts
│   │   │   └── uiStore.ts
│   │   ├── services/
│   │   │   ├── api.ts              # Axios instance
│   │   │   ├── leadService.ts
│   │   │   ├── conversationService.ts
│   │   │   ├── authService.ts
│   │   │   └── wsService.ts
│   │   ├── types/
│   │   │   ├── lead.ts
│   │   │   ├── conversation.ts
│   │   │   ├── user.ts
│   │   │   └── index.ts
│   │   ├── utils/
│   │   │   ├── formatters.ts
│   │   │   ├── validators.ts
│   │   │   ├── constants.ts
│   │   │   └── helpers.ts
│   │   ├── styles/
│   │   │   ├── globals.css
│   │   │   ├── variables.css       # Design tokens
│   │   │   └── themes.css          # Dark/Light themes
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   └── vite-env.d.ts
│   ├── .env.example
│   ├── .eslintrc.json
│   ├── .prettierrc
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   └── vite.config.ts
│
├── backend/                           # API Node.js + TypeScript
│   ├── src/
│   │   ├── routes/
│   │   │   ├── auth.routes.ts
│   │   │   ├── leads.routes.ts
│   │   │   ├── conversations.routes.ts
│   │   │   ├── n8n.routes.ts
│   │   │   ├── users.routes.ts
│   │   │   └── index.ts
│   │   ├── controllers/
│   │   │   ├── auth.controller.ts
│   │   │   ├── leads.controller.ts
│   │   │   ├── conversations.controller.ts
│   │   │   └── n8n.controller.ts
│   │   ├── services/
│   │   │   ├── apify.service.ts
│   │   │   ├── whatsapp.service.ts
│   │   │   ├── supabase.service.ts
│   │   │   ├── openai.service.ts
│   │   │   ├── enrichment.service.ts
│   │   │   └── n8n.service.ts
│   │   ├── jobs/
│   │   │   ├── extractLeads.job.ts
│   │   │   ├── enrichLead.job.ts
│   │   │   ├── sendWhatsApp.job.ts
│   │   │   └── queue.ts            # BullMQ setup
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts
│   │   │   ├── tenant.middleware.ts
│   │   │   ├── errorHandler.middleware.ts
│   │   │   ├── rateLimit.middleware.ts
│   │   │   └── validate.middleware.ts
│   │   ├── websocket/
│   │   │   ├── server.ts
│   │   │   ├── handlers.ts
│   │   │   └── rooms.ts
│   │   ├── models/
│   │   │   ├── lead.model.ts
│   │   │   ├── conversation.model.ts
│   │   │   └── user.model.ts
│   │   ├── types/
│   │   │   ├── express.d.ts
│   │   │   └── index.ts
│   │   ├── utils/
│   │   │   ├── logger.ts
│   │   │   ├── validators.ts
│   │   │   └── helpers.ts
│   │   ├── config/
│   │   │   ├── database.ts
│   │   │   ├── redis.ts
│   │   │   └── env.ts
│   │   └── app.ts
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── e2e/
│   ├── .env.example
│   ├── .eslintrc.json
│   ├── .prettierrc
│   ├── Dockerfile
│   ├── package.json
│   ├── tsconfig.json
│   └── nodemon.json
│
├── supabase/                          # Migrations e funções
│   ├── migrations/
│   │   ├── 20250101000001_initial_schema.sql
│   │   ├── 20250101000002_rls_policies.sql
│   │   ├── 20250101000003_functions.sql
│   │   └── 20250101000004_triggers.sql
│   ├── functions/                     # Edge functions (opcional)
│   │   └── webhook-handler/
│   ├── seed.sql
│   └── config.toml
│
├── n8n/                               # Workflows exportados
│   ├── workflows/
│   │   ├── lead-intake.json
│   │   ├── sdr-agent.json
│   │   ├── audio-processor.json
│   │   ├── enrichment.json
│   │   └── follow-up-scheduler.json
│   ├── credentials/
│   │   └── credentials-template.json
│   └── README.md
│
├── docs/                              # Documentação adicional
│   ├── API.md                         # Documentação de endpoints
│   ├── PROMPTS.md                     # Prompts de IA
│   ├── SETUP.md                       # Setup local
│   ├── DEPLOY.md                      # Deploy production
│   └── TESTING.md                     # Guia de testes
│
├── scripts/                           # Scripts utilitários
│   ├── generate-jwt.js
│   ├── seed-database.js
│   ├── migrate.sh
│   └── deploy.sh
│
├── .github/
│   ├── workflows/
│   │   ├── frontend-ci.yml
│   │   ├── backend-ci.yml
│   │   └── deploy.yml
│   └── PULL_REQUEST_TEMPLATE.md
│
├── docker-compose.yml                 # Desenvolvimento local
├── docker-compose.prod.yml            # Produção
├── .gitignore
├── .env.example
├── README.md
├── ARCHITECTURE.md
├── PROJECT_STRUCTURE.md
├── LICENSE
└── CHANGELOG.md
```

---

## Descrição dos Principais Diretórios

### `/frontend`
Aplicação React com TypeScript, Tailwind CSS e componentes ReactBits/Kokomut UI.

**Principais módulos**:
- `components/ui`: Componentes base reutilizáveis (Orb, MagicBento, Loader, etc)
- `components/leads`: Componentes específicos para gestão de leads
- `components/whatsapp`: Interface de chat espelhado do WhatsApp
- `components/mining`: Interface de extração em tempo real
- `pages`: Páginas principais da aplicação
- `stores`: Zustand stores para gerenciamento de estado global
- `hooks`: Custom hooks para lógica reutilizável
- `services`: Camada de comunicação com API

### `/backend`
API RESTful em Node.js + TypeScript com Express.

**Principais módulos**:
- `routes`: Definição de rotas HTTP
- `controllers`: Lógica de negócio para cada endpoint
- `services`: Integrações com serviços externos (Apify, WhatsApp, OpenAI)
- `jobs`: BullMQ jobs para processamento assíncrono
- `websocket`: Servidor Socket.IO para comunicação real-time
- `middleware`: Auth, validação, rate limiting, etc

### `/supabase`
Migrations SQL e funções do banco de dados.

**Tabelas principais**:
- `tenants`: Multi-tenancy
- `users`: Usuários por tenant
- `leads`: Leads minerados e importados
- `conversations`: Histórico de mensagens WhatsApp
- `n8n_jobs`: Controle de workflows
- `audit_logs`: Auditoria de ações

### `/n8n`
Workflows exportados em JSON para importar no n8n.

**Workflows principais**:
- `lead-intake.json`: Recebe lead → enriquece → cria mensagem
- `sdr-agent.json`: Agente autônomo de follow-up
- `audio-processor.json`: Processa áudios do WhatsApp (STT)
- `enrichment.json`: Enriquece dados via APIs externas

### `/docs`
Documentação técnica detalhada:
- `API.md`: Documentação de todos os endpoints
- `PROMPTS.md`: Prompts de IA utilizados
- `SETUP.md`: Como rodar localmente
- `DEPLOY.md`: Como fazer deploy em produção
- `TESTING.md`: Guia de testes e QA

---

## Convenções de Código

### Nomenclatura
- **Arquivos**: PascalCase para componentes React (`LeadCard.tsx`), camelCase para utilitários (`formatters.ts`)
- **Componentes**: PascalCase (`LeadViewer`)
- **Funções**: camelCase (`extractLeads()`)
- **Constantes**: UPPER_SNAKE_CASE (`API_BASE_URL`)
- **Interfaces/Types**: PascalCase com prefixo `I` opcional (`ILead` ou `Lead`)

### Estrutura de Componentes React
```tsx
// 1. Imports
import { useState } from 'react';
import { LeadCard } from '@/components/leads';

// 2. Types
interface Props {
  leadId: string;
}

// 3. Component
export default function LeadViewer({ leadId }: Props) {
  // Hooks
  const [loading, setLoading] = useState(false);

  // Handlers
  const handleAction = () => {};

  // Render
  return <div>...</div>;
}
```

### Estrutura de Services
```ts
// leadService.ts
import api from './api';
import type { Lead } from '@/types';

export const leadService = {
  getAll: async (): Promise<Lead[]> => {
    const { data } = await api.get('/leads');
    return data;
  },

  extract: async (url: string, limit: number) => {
    const { data } = await api.post('/leads/extract', { url, limit });
    return data;
  }
};
```

---

## Próximos Passos

1. Clonar estrutura: `mkdir -p frontend backend supabase n8n docs scripts`
2. Inicializar projetos: `npm create vite@latest frontend -- --template react-ts`
3. Setup Supabase: `supabase init`
4. Configurar n8n: `docker run -p 5678:5678 n8nio/n8n`

Ver `docs/SETUP.md` para instruções detalhadas.
