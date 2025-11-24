# Nexio.AI 🚀

<div align="center">
  <img src="frontend/public/logo-purple.svg" alt="Nexio.AI Logo" width="200" />

  <p><strong>Plataforma B2B SaaS de Automação e CRM com Agentes de IA SDR</strong></p>

  <p>
    <img src="https://img.shields.io/badge/React-18+-blue?logo=react" alt="React" />
    <img src="https://img.shields.io/badge/TypeScript-5+-blue?logo=typescript" alt="TypeScript" />
    <img src="https://img.shields.io/badge/Node.js-20+-green?logo=node.js" alt="Node.js" />
    <img src="https://img.shields.io/badge/Supabase-PostgreSQL-green?logo=supabase" alt="Supabase" />
    <img src="https://img.shields.io/badge/n8n-Workflows-orange?logo=n8n" alt="n8n" />
  </p>
</div>

---

## 📋 Sobre o Projeto

**Nexio.AI** é uma plataforma completa de automação de vendas e CRM B2B que utiliza Inteligência Artificial para:

- 🎯 **Minerar leads** automaticamente via Google Maps (Apify)
- 💬 **Qualificar e nutrir** leads via WhatsApp com agente SDR autônomo
- 📊 **Gerenciar pipeline** com Kanban visual e métricas em tempo real
- 🤖 **Automatizar follow-ups** com n8n e OpenAI
- 🎙️ **Processar áudios** com STT (Whisper) e TTS

### Público-Alvo
PMEs, agências de marketing e empresas que querem escalar prospecção B2B sem aumentar equipe.

---

## ✨ Funcionalidades Principais

### 🔍 Mineração Inteligente de Leads
- Extração via URL do Google Maps (ex: "restaurantes em São Paulo")
- Processamento assíncrono com BullMQ
- Deduplicação automática
- Score de ICP (Ideal Customer Profile) calculado por IA

### 📱 WhatsApp Espelhado (Mirroring)
- Integração com WhatsApp Business API (Evolution API)
- Espelhamento de conversas em tempo real
- Suporte a mensagens de texto, áudio, imagem e vídeo
- Transcrição automática de áudios (Whisper STT)
- Player nativo de áudio com controles

### 🤖 Agente SDR Autônomo
- Mensagens iniciais personalizadas geradas por IA
- Follow-ups automáticos programados
- Classificação de intenção de respostas
- Criação de tarefas quando lead demonstra interesse
- Movimentação automática no funil

### 📊 Dashboard & Kanban
- Interface Magic Bento (ReactBits) com métricas em tempo real
- Kanban drag & drop (new → contacted → qualified → proposal → closed)
- Filtros avançados (ICP, cidade, score, tags)
- Exportação CSV
- Bulk actions (mover, deletar, tagear)

### 📈 Relatórios & Auditoria
- Métricas de conversão por stage
- Taxa de resposta WhatsApp
- ROI estimado
- Logs de auditoria completos
- Timeline de interações

---

## 🛠️ Stack Tecnológica

### Frontend
- **React 18** + **TypeScript**
- **Vite** (build tool)
- **Tailwind CSS** (estilização)
- **Zustand** (state management)
- **React Query** (data fetching)
- **React Router v6** (navegação)
- **GSAP** + **Framer Motion** (animações)
- **Socket.IO Client** (real-time)

**Componentes UI**:
- **ReactBits**: Magic Bento, Orb (background login)
- **Kokomut UI**: Loader, AI State Loading, Profile Dropdown

### Backend
- **Node.js 20** + **TypeScript**
- **Express.js** (API REST)
- **BullMQ** + **Redis** (job queue)
- **Socket.IO** (WebSocket real-time)
- **Zod** (validação de schemas)

### Banco de Dados
- **Supabase** (PostgreSQL + Auth + Storage)
- **Redis** (cache e jobs)

### Orquestração & IA
- **n8n** (workflows de automação)
- **OpenAI GPT-4o** (geração de mensagens, classificação)
- **Whisper** (Speech-to-Text)
- **ElevenLabs / Amazon Polly** (Text-to-Speech)

### Integrações
- **Apify** (scraping Google Maps)
- **Evolution API / 360dialog** (WhatsApp Business API)
- **Clearbit / CNPJ Receita / SerpAPI** (enriquecimento de dados)

### DevOps
- **Docker** + **Docker Compose**
- **GitHub Actions** (CI/CD)
- **Vercel** (frontend)
- **Railway / Render** (backend)
- **Sentry** (error tracking)

---

## 🚀 Quick Start

### Pré-requisitos
- **Node.js** 20+
- **pnpm** (ou npm/yarn)
- **Docker** e **Docker Compose**
- **Conta Supabase** (grátis)
- **Conta OpenAI** (API key)
- **Conta Apify** (scraping)

### Instalação Local

```bash
# 1. Clonar repositório
git clone https://github.com/seu-usuario/nexio-ai.git
cd nexio-ai

# 2. Instalar dependências
pnpm install

# 3. Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas credenciais

# 4. Subir serviços (Redis, n8n, PostgreSQL local opcional)
docker-compose up -d

# 5. Rodar migrations Supabase
cd supabase
supabase migration up

# 6. Iniciar backend
cd ../backend
pnpm dev

# 7. Iniciar frontend (outro terminal)
cd ../frontend
pnpm dev
```

Acesse:
- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:3000
- **n8n**: http://localhost:5678

Ver [docs/SETUP.md](docs/SETUP.md) para instruções detalhadas.

---

## 📁 Estrutura do Projeto

```
nexio-ai/
├── frontend/          # React + TypeScript
│   ├── src/
│   │   ├── components/   # Componentes reutilizáveis
│   │   ├── pages/        # Páginas
│   │   ├── hooks/        # Custom hooks
│   │   ├── stores/       # Zustand stores
│   │   ├── services/     # API clients
│   │   └── styles/       # CSS global e tokens
│   └── package.json
│
├── backend/           # Node.js + Express
│   ├── src/
│   │   ├── routes/       # Rotas da API
│   │   ├── controllers/  # Lógica de negócio
│   │   ├── services/     # Integrações externas
│   │   ├── jobs/         # BullMQ jobs
│   │   └── middleware/   # Auth, validação, etc
│   └── package.json
│
├── supabase/          # Migrations e funções SQL
│   └── migrations/
│
├── n8n/               # Workflows exportados
│   └── workflows/
│
├── docs/              # Documentação
│   ├── API.md
│   ├── PROMPTS.md
│   ├── SETUP.md
│   └── DEPLOY.md
│
└── docker-compose.yml
```

Ver [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) completo.

---

## 🎨 Design System

### Paleta de Cores

```css
--color-primary: #5415AC;       /* Roxo (prevalece) */
--color-accent-orange: #ED4F22; /* Laranja */
--color-accent-pink: #FD0685;   /* Rosa magenta */

/* Gradiente principal */
--gradient-primary: linear-gradient(90deg, #5415AC 0%, #ED4F22 50%, #FD0685 100%);
```

### Temas
- **Light Mode**: Background claro, texto escuro
- **Dark Mode**: Background #0A0A0F, texto claro, roxo dominante

Ver [frontend/src/styles/variables.css](frontend/src/styles/variables.css).

---

## 🔐 Variáveis de Ambiente

### Frontend (.env)
```bash
VITE_API_URL=http://localhost:3000
VITE_WS_URL=ws://localhost:3000
VITE_SUPABASE_URL=https://seu-projeto.supabase.co
VITE_SUPABASE_ANON_KEY=sua-anon-key
```

### Backend (.env)
```bash
# API
PORT=3000
NODE_ENV=development

# Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sua-service-role-key

# Redis
REDIS_URL=redis://localhost:6379

# OpenAI
OPENAI_API_KEY=sk-...

# Apify
APIFY_API_KEY=apify_api_...

# WhatsApp (Evolution API)
EVOLUTION_ACCOUNT_SID=AC...
EVOLUTION_AUTH_TOKEN=...
EVOLUTION_WHATSAPP_NUMBER=+14155238886

# n8n
N8N_WEBHOOK_URL=http://localhost:5678/webhook
```

Ver [.env.example](.env.example) completo.

---

## 📚 Documentação Completa

- [**ARCHITECTURE.md**](ARCHITECTURE.md) - Arquitetura do sistema e fluxos
- [**PROJECT_STRUCTURE.md**](PROJECT_STRUCTURE.md) - Estrutura de pastas detalhada
- [**docs/SETUP.md**](docs/SETUP.md) - Setup local passo a passo
- [**docs/DEPLOY.md**](docs/DEPLOY.md) - Deploy em produção
- [**docs/API.md**](docs/API.md) - Documentação de endpoints
- [**docs/PROMPTS.md**](docs/PROMPTS.md) - Prompts de IA utilizados
- [**docs/TESTING.md**](docs/TESTING.md) - Guia de testes

---

## 🧪 Testes

```bash
# Backend
cd backend
pnpm test              # Unit tests
pnpm test:integration  # Integration tests
pnpm test:e2e          # E2E tests

# Frontend
cd frontend
pnpm test              # Jest + React Testing Library
pnpm test:e2e          # Playwright
```

---

## 🚢 Deploy

### Frontend (Vercel)
```bash
cd frontend
vercel --prod
```

### Backend (Railway/Render)
```bash
cd backend
railway up
# ou
render deploy
```

Ver [docs/DEPLOY.md](docs/DEPLOY.md) para instruções completas.

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Add: nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Ver [LICENSE](LICENSE).

---

## 👥 Time

Desenvolvido por **[Seu Nome/Empresa]** com ❤️

---

## 📞 Suporte

- 📧 Email: suporte@nexio.ai
- 💬 Discord: [discord.gg/nexioai](https://discord.gg/nexioai)
- 📖 Docs: [docs.nexio.ai](https://docs.nexio.ai)

---

## 🎯 Roadmap

### MVP (Sprint 0-3) ✅
- [x] Autenticação multi-tenant
- [x] Dashboard com Magic Bento
- [x] Extração de leads via Google Maps
- [x] Kanban básico
- [x] WhatsApp text mirroring
- [x] n8n baseline workflow

### v1.0 (Sprint 4-5)
- [ ] WhatsApp audio com STT/TTS
- [ ] Agente SDR autônomo completo
- [ ] Importação CSV avançada
- [ ] Relatórios e analytics
- [ ] Billing com Stripe

### v2.0 (Futuro)
- [ ] Integração com CRMs (HubSpot, Pipedrive)
- [ ] Multi-canal (Email, Instagram)
- [ ] IA fine-tuned por tenant
- [ ] Mobile app (React Native)
- [ ] White-label

---

<div align="center">
  <p>Feito com 💜 usando React, Node.js, Supabase e n8n</p>
  <p>⭐ Se este projeto te ajudou, deixe uma estrela!</p>
</div>
