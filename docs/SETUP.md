# Nexio.AI - Setup Local (Atualizado)

Guia completo para configurar o ambiente de desenvolvimento local na **sua VPS com Easypanel**.

---

## Pré-requisitos

### Ferramentas Necessárias

1. **Node.js 20+**
   ```bash
   node --version  # Deve retornar v20.x.x ou superior
   ```

2. **pnpm** (gerenciador de pacotes)
   ```bash
   npm install -g pnpm
   ```

3. **Docker** (já deve estar na VPS com Easypanel)
   ```bash
   docker --version
   ```

4. **Git**
   ```bash
   git --version
   ```

### Contas Externas Necessárias

1. ✅ **Supabase**: https://supabase.com (plano Free)
2. ✅ **OpenAI**: https://platform.openai.com/api-keys (para o agente de IA)
3. ✅ **Apify**: https://apify.com (scraping Google Maps - plano Free)
4. ✅ **Evolution API ou Uaevolution** (WhatsApp) - **ESCOLHA UM**:
   - **Evolution API**: https://evolution.me (R$ 50-100/mês, muito estável)
   - **Uaevolution**: https://uaevolution.cloud (R$ 70-150/mês, recursos extras)
   - ❌ ~~Evolution API~~ (caro demais)
   - ❌ ~~Evolution API~~ (instável)

---

## Passo 1: Clonar Repositório

```bash
# Na sua VPS
cd /var/www  # ou onde preferir
git clone https://github.com/seu-usuario/nexio-ai.git
cd nexio-ai
```

---

## Passo 2: Configurar Supabase

### 2.1. Criar Projeto Supabase

1. Acesse https://app.supabase.com
2. Clique em "New Project"
3. Preencha:
   - **Name**: Nexio AI
   - **Database Password**: (senha forte)
   - **Region**: South America (São Paulo)
4. Aguarde ~2 min

### 2.2. Obter Credenciais

No dashboard → **Settings → API**:
- **Project URL**: `https://xxxxxxxxxxx.supabase.co`
- **anon key**: `eyJhbGc...` (frontend)
- **service_role key**: `eyJhbGc...` (backend - **SEGREDO!**)

### 2.3. Rodar Migrations

**Opção 1** (via SQL Editor - mais fácil):
1. Vá em **SQL Editor** no Supabase
2. Copie e execute cada arquivo em ordem:
   - `supabase/migrations/20250101000001_initial_schema.sql`
   - `supabase/migrations/20250101000002_rls_policies.sql`
   - `supabase/migrations/20250101000003_functions.sql`
   - `supabase/migrations/20250101000004_triggers.sql`

**Opção 2** (via CLI):
```bash
npm install -g supabase
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

---

## Passo 3: Configurar OpenAI (para Agente de IA)

### O que a IA faz no sistema:
- 🤖 Gera mensagens personalizadas para cada lead
- 🎙️ Transcreve áudios do WhatsApp
- 🧠 Classifica intenção de respostas (interesse/objeção)
- 📝 Sugere próximas ações

### Como configurar:
1. Acesse https://platform.openai.com/api-keys
2. Crie nova chave: "Create new secret key"
3. Copie a chave: `sk-proj-...`
4. **Adicione cartão** no billing (necessário mesmo no free tier)

**Custo estimado**: ~R$ 100-200/mês para 1.000-2.000 leads

---

## Passo 4: Configurar Apify (Scraping Google Maps)

1. Crie conta em https://apify.com
2. Vá em **Settings → Integrations**
3. Copie **API Token**: `apify_api_...`

**Actor usado**: Google Maps Scraper
- Extrai dados: nome, telefone, endereço, rating, etc
- Free tier: 5 USD crédito (suficiente para ~500 leads)

---

## Passo 5: Configurar WhatsApp (Evolution API ou Uaevolution)

### ⭐ Opção Recomendada: Evolution API

**Por que Evolution API?**
- ✅ Estável (uptime 99%+)
- ✅ API simples (REST)
- ✅ Webhook confiável
- ✅ Suporte brasileiro
- ✅ R$ 50-100/mês

**Setup Evolution API**:

1. **Criar conta**: https://evolution.me
2. **Criar instância**: Painel → Nova Instância
3. **Conectar WhatsApp**:
   - Escanear QR Code com seu WhatsApp Business
   - Aguardar confirmação

4. **Copiar credenciais**:
   ```bash
   EVOLUTION_INSTANCE_ID=sua-instancia
   EVOLUTION_TOKEN=seu-token
   EVOLUTION_WEBHOOK_URL=https://seu-dominio.com/api/whatsapp/webhook
   ```

5. **Configurar Webhook**:
   - Painel Evolution API → Configurações → Webhook
   - URL: `https://seu-dominio.com/api/whatsapp/webhook`
   - Eventos: `message.received`, `message.sent`, `message.status`

### 🔄 Alternativa: Uaevolution

Processo similar ao Evolution API:
1. Conta em https://uaevolution.cloud
2. Criar instância + conectar WhatsApp
3. Configurar webhook

**Diferenças Uaevolution**:
- Mais recursos (grupos, listas de transmissão)
- Mais caro (R$ 70-150/mês)
- API levemente diferente

---

## Passo 6: Deploy na VPS com Easypanel

### 6.1. Acessar Easypanel

```bash
# Se ainda não instalou Easypanel na VPS
curl -sSL https://get.easypanel.io | sh
```

Acesse: `https://seu-ip:3000` ou `https://painel.seudominio.com`

### 6.2. Criar Projeto no Easypanel

1. **New Project** → Nome: `nexio-ai`
2. **Add Service** → Docker Compose
3. Cole o `docker-compose.yml` (ajustado abaixo)

### 6.3. Docker Compose para Easypanel

Crie `/var/www/nexio-ai/docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - nexio

  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=${DOMAIN}
      - WEBHOOK_URL=https://${DOMAIN}/n8n/
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped
    networks:
      - nexio

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - REDIS_URL=redis://redis:6379
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - APIFY_API_KEY=${APIFY_API_KEY}

      # EVOLUTION (escolha Evolution API ou Uaevolution)
      - WHATSAPP_PROVIDER=evolution
      - EVOLUTION_INSTANCE_ID=${EVOLUTION_INSTANCE_ID}
      - EVOLUTION_TOKEN=${EVOLUTION_TOKEN}

      # Ou UAEVOLUTION
      # - WHATSAPP_PROVIDER=uaevolution
      # - UAEVOLUTION_INSTANCE_ID=${UAEVOLUTION_INSTANCE_ID}
      # - UAEVOLUTION_TOKEN=${UAEVOLUTION_TOKEN}

      - N8N_WEBHOOK_URL=http://n8n:5678/webhook
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - redis
      - n8n
    restart: unless-stopped
    networks:
      - nexio

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    environment:
      - VITE_API_URL=https://api.${DOMAIN}
      - VITE_WS_URL=wss://api.${DOMAIN}
      - VITE_SUPABASE_URL=${SUPABASE_URL}
      - VITE_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - nexio

volumes:
  redis_data:
  n8n_data:

networks:
  nexio:
    driver: bridge
```

### 6.4. Variáveis de Ambiente no Easypanel

No Easypanel, adicione estas variáveis:

```bash
# Domínio
DOMAIN=nexio.seudominio.com

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
SUPABASE_ANON_KEY=eyJhbGc...

# OpenAI
OPENAI_API_KEY=sk-proj-...

# Apify
APIFY_API_KEY=apify_api_...

# WhatsApp (Evolution API)
EVOLUTION_INSTANCE_ID=sua-instancia
EVOLUTION_TOKEN=seu-token

# n8n
N8N_PASSWORD=senha-segura-admin

# JWT
JWT_SECRET=$(openssl rand -hex 32)
```

### 6.5. Configurar Domínios

No Easypanel:
1. **Domains** → Add Domain
2. Configure:
   - `nexio.seudominio.com` → Frontend (porta 80)
   - `api.nexio.seudominio.com` → Backend (porta 3000)
   - `n8n.nexio.seudominio.com` → n8n (porta 5678)

3. **SSL**: Easypanel configura Let's Encrypt automaticamente

---

## Passo 7: Ajustar Código para Evolution API

### Backend - WhatsApp Service

Crie `backend/src/services/evolution.service.ts`:

```typescript
import axios from 'axios';

const EVOLUTION_BASE_URL = 'https://api.z-api.io/instances';

export class Evolution APIService {
  private instanceId: string;
  private token: string;
  private baseUrl: string;

  constructor() {
    this.instanceId = process.env.EVOLUTION_INSTANCE_ID!;
    this.token = process.env.EVOLUTION_TOKEN!;
    this.baseUrl = `${EVOLUTION_BASE_URL}/${this.instanceId}/token/${this.token}`;
  }

  // Enviar mensagem de texto
  async sendText(phone: string, message: string) {
    const url = `${this.baseUrl}/send-text`;
    const response = await axios.post(url, {
      phone: this.cleanPhone(phone),
      message
    });
    return response.data;
  }

  // Enviar áudio
  async sendAudio(phone: string, audioUrl: string) {
    const url = `${this.baseUrl}/send-audio`;
    const response = await axios.post(url, {
      phone: this.cleanPhone(phone),
      audio: audioUrl
    });
    return response.data;
  }

  // Baixar mídia (áudio, imagem)
  async downloadMedia(mediaId: string) {
    const url = `${this.baseUrl}/download-media/${mediaId}`;
    const response = await axios.get(url, { responseType: 'arraybuffer' });
    return response.data;
  }

  // Limpar telefone (remover +, espaços)
  private cleanPhone(phone: string): string {
    return phone.replace(/\D/g, '');
  }
}

export const evolutionService = new Evolution APIService();
```

### Backend - Webhook Handler

Ajuste `backend/src/routes/whatsapp.routes.ts`:

```typescript
import { Router } from 'express';
import { evolutionService } from '../services/evolution.service';
import { openaiService } from '../services/openai.service';
import { supabaseService } from '../services/supabase.service';

const router = Router();

// Webhook Evolution API
router.post('/webhook', async (req, res) => {
  const { phone, message, audio, messageId, timestamp } = req.body;

  try {
    // 1. Buscar lead por telefone
    const supabase = supabaseService.getClient();
    const { data: lead } = await supabase
      .from('leads')
      .select('*')
      .eq('phone', `+${phone}`)
      .single();

    if (!lead) {
      return res.status(200).json({ ok: true, message: 'Lead não encontrado' });
    }

    let finalMessage = message;
    let transcription = null;

    // 2. Se for áudio, transcrever com Whisper
    if (audio) {
      const audioBuffer = await evolutionService.downloadMedia(audio);
      transcription = await openaiService.transcribeAudio(audioBuffer);
      finalMessage = transcription;
    }

    // 3. Salvar conversa no banco
    await supabase.from('conversations').insert({
      tenant_id: lead.tenant_id,
      lead_id: lead.id,
      message: finalMessage,
      message_type: audio ? 'audio' : 'text',
      direction: 'in',
      media_url: audio || null,
      transcript: transcription,
      whatsapp_message_id: messageId,
      status: 'delivered',
      created_at: new Date(timestamp * 1000).toISOString()
    });

    // 4. Notificar frontend via WebSocket
    req.io.to(`tenant:${lead.tenant_id}`).emit('new_message', {
      lead_id: lead.id,
      message: finalMessage,
      type: audio ? 'audio' : 'text'
    });

    // 5. Disparar n8n se necessário (resposta automática)
    // ...

    res.status(200).json({ ok: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: 'Internal error' });
  }
});

export default router;
```

---

## Passo 8: Testar Localmente Antes de Deploy

```bash
# 1. Configurar .env local
cp .env.example .env
# Editar com suas credenciais

# 2. Subir serviços
docker-compose up -d

# 3. Backend
cd backend
pnpm install
pnpm dev

# 4. Frontend (outro terminal)
cd frontend
pnpm install
pnpm dev
```

Teste:
1. Login em http://localhost:5173
2. Extrair 5 leads de teste do Maps
3. Enviar mensagem de teste no Evolution API
4. Verificar se aparece no UI

---

## Passo 9: Deploy Produção

```bash
# Na VPS
cd /var/www/nexio-ai

# Build e suba com Easypanel
docker-compose -f docker-compose.prod.yml up -d --build
```

Acesse:
- Frontend: https://nexio.seudominio.com
- Backend: https://api.nexio.seudominio.com/health
- n8n: https://n8n.nexio.seudominio.com

---

## Resumo das Mudanças

| Antes (doc original) | Agora (ajustado) |
|---------------------|------------------|
| Evolution API WhatsApp | ✅ Evolution API / Uaevolution |
| Evolution API | ❌ Removido |
| Vercel + Railway | ✅ VPS + Easypanel |
| Deploy manual | ✅ Docker Compose |

---

## Custos Reais (por mês)

- VPS (4GB RAM): R$ 40-80
- Supabase Pro: R$ 130 (~$25)
- OpenAI (IA): R$ 100-200 (1-2k leads)
- Evolution API: R$ 50-100
- Apify: R$ 0 (free tier)

**Total**: R$ 320-510/mês (~$60-100 USD)

---

## Troubleshooting

### Evolution API não recebe mensagens
- Verifique webhook configurado: Painel Evolution API → Configurações
- Teste endpoint: `curl -X POST https://api.nexio.seudominio.com/api/whatsapp/webhook`

### OpenAI retorna erro 401
- Verifique `OPENAI_API_KEY` no `.env`
- Confirme que adicionou cartão no billing

### Frontend não conecta ao backend
- Verifique `VITE_API_URL` no frontend
- Teste: `curl https://api.nexio.seudominio.com/health`

---

**Próximo**: Leia `IMPLEMENTATION_SUMMARY.md` para entender o que implementar nas Sprints 1-3.
