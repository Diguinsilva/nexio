# Integração com Seu Agente SDR Próprio

Como conectar o Nexio.AI CRM com **seu agente SDR e fluxos existentes**.

---

## 🎯 Cenário

Você já tem:
- ✅ **Agente SDR** rodando (n8n, Make, custom, etc)
- ✅ **Fluxo Apify** para extrair leads do Google Maps
- ✅ **Minimax API** para transcrição de áudios (mais humanizado que Whisper)

Você quer:
- ✅ **CRM visual** (Kanban, Dashboard, Lead Viewer)
- ✅ **WhatsApp espelhado** no frontend
- ✅ **Banco centralizado** (Supabase)
- ✅ Seu agente **lê/escreve** nesse banco

---

## 🏗️ Arquitetura de Integração

```
┌─────────────────────────────────────────────────────┐
│              SEU AGENTE SDR (existente)              │
│         (n8n, Make, Python, Node.js, etc)            │
└───────────────┬─────────────────────────────────────┘
                │
                │ HTTP API / Webhook
                ▼
┌─────────────────────────────────────────────────────┐
│           Nexio.AI Backend (Express)                 │
│  ┌──────────────┐  ┌──────────────┐                │
│  │  Webhook API │  │ WebSocket    │                │
│  │  /api/agent  │  │ (real-time)  │                │
│  └──────────────┘  └──────────────┘                │
└───────────────┬─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────┐
│              Supabase (PostgreSQL)                   │
│  ┌─────────┐  ┌──────────┐  ┌──────────────┐      │
│  │ leads   │  │ convs    │  │ tasks        │      │
│  └─────────┘  └──────────┘  └──────────────┘      │
└───────────────┬─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────┐
│          Nexio.AI Frontend (React)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │Dashboard │  │  Kanban  │  │ WhatsApp │          │
│  └──────────┘  └──────────┘  └──────────┘          │
└─────────────────────────────────────────────────────┘
```

---

## 📡 Endpoints para Seu Agente

### 1. Criar Lead (do seu Apify)

**Quando**: Seu fluxo Apify extrai lead do Maps

```bash
POST https://api.nexio.seudominio.com/api/agent/leads
Authorization: Bearer SEU_JWT_TOKEN
Content-Type: application/json

{
  "name": "João Silva",
  "phone": "+5511999999999",
  "email": "joao@pizzaria.com",
  "company_name": "Pizzaria Bella",
  "city": "São Paulo",
  "state": "SP",
  "address": "Rua XYZ, 123",
  "source": "maps",
  "source_url": "https://maps.google.com/...",
  "tags": ["restaurante", "pizzaria"],
  "raw_data": {
    // dados brutos do Apify
    "rating": 4.5,
    "reviews": 234
  }
}
```

**Resposta**:
```json
{
  "success": true,
  "data": {
    "id": "uuid-do-lead",
    "name": "João Silva",
    "stage": "new",
    "score": 45
  }
}
```

---

### 2. Salvar Mensagem Enviada

**Quando**: Seu agente envia mensagem via Evolution API

```bash
POST https://api.nexio.seudominio.com/api/agent/conversations
Authorization: Bearer SEU_JWT_TOKEN
Content-Type: application/json

{
  "lead_id": "uuid-do-lead",
  "message": "Olá João! Vi que você tem uma pizzaria...",
  "message_type": "text",
  "direction": "out",
  "whatsapp_message_id": "msg-id-do-evolution",
  "status": "sent"
}
```

**Resposta**:
```json
{
  "success": true,
  "data": {
    "id": "uuid-da-conversa",
    "created_at": "2025-01-21T10:30:00Z"
  }
}
```

**Efeito**:
- Mensagem aparece no **WhatsApp Mirror** do frontend
- `leads.last_contact_at` é atualizado automaticamente (trigger)

---

### 3. Atualizar Stage do Lead

**Quando**: Seu agente classifica lead (ex: "respondeu com interesse")

```bash
PATCH https://api.nexio.seudominio.com/api/agent/leads/{lead_id}
Authorization: Bearer SEU_JWT_TOKEN
Content-Type: application/json

{
  "stage": "qualified",
  "score": 75,
  "notes": "Lead demonstrou interesse, agendar call"
}
```

**Resposta**:
```json
{
  "success": true,
  "data": {
    "id": "uuid-do-lead",
    "stage": "qualified",
    "score": 75
  }
}
```

**Efeito**:
- Lead **move automaticamente** no Kanban (drag & drop visual)
- Frontend recebe via **WebSocket** (sem refresh)

---

### 4. Criar Tarefa

**Quando**: Seu agente decide que precisa follow-up

```bash
POST https://api.nexio.seudominio.com/api/agent/tasks
Authorization: Bearer SEU_JWT_TOKEN
Content-Type: application/json

{
  "lead_id": "uuid-do-lead",
  "title": "Follow-up: João - Pizzaria Bella",
  "description": "Lead pediu proposta. Enviar pricing e agendar demo.",
  "type": "follow_up",
  "priority": "high",
  "due_date": "2025-01-24T14:00:00Z"
}
```

**Resposta**:
```json
{
  "success": true,
  "data": {
    "id": "uuid-da-task",
    "status": "pending"
  }
}
```

**Efeito**: Tarefa aparece no **Lead Viewer** do frontend

---

## 🎙️ Minimax Integration (Transcrição)

### Backend Service

Crie `backend/src/services/minimax.service.ts`:

```typescript
import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';

export class MinimaxService {
  private apiKey: string;
  private baseUrl = 'https://api.minimax.chat/v1';

  constructor() {
    this.apiKey = process.env.MINIMAX_API_KEY!;
  }

  /**
   * Transcrever áudio com Minimax (mais humanizado)
   */
  async transcribeAudio(audioBuffer: Buffer, language = 'pt'): Promise<string> {
    try {
      const formData = new FormData();
      formData.append('file', audioBuffer, {
        filename: 'audio.ogg',
        contentType: 'audio/ogg'
      });
      formData.append('model', 'speech-01');
      formData.append('language', language);

      const response = await axios.post(
        `${this.baseUrl}/audio/transcriptions`,
        formData,
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            ...formData.getHeaders()
          }
        }
      );

      return response.data.text;
    } catch (error: any) {
      console.error('Minimax transcription error:', error);
      throw new Error(`Erro ao transcrever áudio: ${error.message}`);
    }
  }

  /**
   * Gerar áudio (TTS) - se você usar
   */
  async textToSpeech(text: string, voice = 'pt-BR-1'): Promise<Buffer> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/audio/speech`,
        {
          model: 'speech-01',
          input: text,
          voice,
          response_format: 'mp3'
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json'
          },
          responseType: 'arraybuffer'
        }
      );

      return Buffer.from(response.data);
    } catch (error: any) {
      console.error('Minimax TTS error:', error);
      throw new Error(`Erro ao gerar áudio: ${error.message}`);
    }
  }
}

export const minimaxService = new MinimaxService();
```

### Webhook Handler (quando áudio chega do Evolution API)

```typescript
// backend/src/routes/whatsapp.routes.ts

import { minimaxService } from '../services/minimax.service';

router.post('/webhook', async (req, res) => {
  const { phone, audio, messageId } = req.body;

  if (audio) {
    // 1. Baixar áudio do Evolution API
    const audioBuffer = await evolutionService.downloadMedia(audio);

    // 2. Transcrever com Minimax (mais humanizado!)
    const transcription = await minimaxService.transcribeAudio(audioBuffer, 'pt');

    // 3. Salvar no banco
    await supabase.from('conversations').insert({
      lead_id: lead.id,
      message: transcription,
      message_type: 'audio',
      direction: 'in',
      media_url: audio,
      transcript: transcription
    });

    // 4. Notificar frontend
    req.io.emit('new_message', { lead_id: lead.id, transcript: transcription });

    // 5. OPCIONAL: Notificar seu agente
    await axios.post('https://seu-agente.com/webhook/audio', {
      lead_id: lead.id,
      transcript: transcription,
      confidence: 0.95
    });
  }

  res.status(200).json({ ok: true });
});
```

---

## 🔐 Autenticação do Seu Agente

### Opção 1: JWT Token (Recomendado)

**Gerar token**:
```bash
# No backend
node scripts/generate-agent-token.js

# Retorna:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Usar nas requisições**:
```bash
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Opção 2: API Key (Mais simples)

**Criar API key** (no banco):
```sql
INSERT INTO api_keys (tenant_id, key, name, permissions)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'nexio_api_' || gen_random_uuid(),
  'Agente SDR',
  ARRAY['leads:write', 'conversations:write', 'tasks:write']
);
```

**Usar**:
```bash
X-API-Key: nexio_api_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## 📊 Seu Agente Lê Dados do Banco

Se seu agente precisa **ler** leads do banco:

### Opção 1: Polling (simples)

Seu agente faz request a cada X minutos:

```bash
GET https://api.nexio.seudominio.com/api/agent/leads?stage=new&limit=50
Authorization: Bearer SEU_JWT_TOKEN
```

### Opção 2: Webhook (real-time)

Configure **trigger no Supabase** que chama seu agente:

```sql
-- supabase/migrations/notify_agent_new_lead.sql

CREATE OR REPLACE FUNCTION notify_agent_new_lead()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('new_lead', json_build_object(
    'lead_id', NEW.id,
    'name', NEW.name,
    'phone', NEW.phone,
    'source', NEW.source
  )::text);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_agent_new_lead
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION notify_agent_new_lead();
```

Seu agente escuta `pg_notify` ou você cria um worker no backend que repassa para webhook do seu agente.

---

## 🧪 Testar Integração

### 1. Simular Lead do Apify

```bash
curl -X POST https://api.nexio.seudominio.com/api/agent/leads \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Teste João",
    "phone": "+5511999999999",
    "company_name": "Pizzaria Teste",
    "city": "São Paulo"
  }'
```

### 2. Verificar no Frontend

1. Acesse `https://nexio.seudominio.com`
2. Vá em **Kanban**
3. Lead deve aparecer na coluna **"New"**

### 3. Mover Lead (simular resposta)

```bash
curl -X PATCH https://api.nexio.seudominio.com/api/agent/leads/UUID \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "stage": "qualified",
    "score": 80
  }'
```

Lead deve mover automaticamente no Kanban (via WebSocket).

---

## 📋 Checklist de Integração

- [ ] Backend rodando na VPS (Easypanel)
- [ ] Supabase migrations rodadas
- [ ] Gerar JWT token ou API key para seu agente
- [ ] Testar POST `/api/agent/leads` (criar lead)
- [ ] Testar POST `/api/agent/conversations` (salvar mensagem)
- [ ] Testar PATCH `/api/agent/leads/:id` (mover stage)
- [ ] Configurar webhook Evolution API → Backend `/api/whatsapp/webhook`
- [ ] Implementar Minimax service (transcrição)
- [ ] Seu agente chama API do Nexio quando necessário
- [ ] Frontend exibe tudo em tempo real

---

## 💡 Vantagens Dessa Abordagem

✅ **Desacoplamento**: Seu agente não precisa mudar nada crítico
✅ **Flexibilidade**: Você troca de agente sem mudar o CRM
✅ **Visibilidade**: Time vê tudo no frontend (Kanban, chat)
✅ **Escalabilidade**: Backend gerencia WebSocket/cache
✅ **Auditoria**: Tudo registrado no Supabase (compliance)

---

## 🤔 Exemplo de Fluxo Completo

1. **Apify extrai lead** → Seu script Python/Node.js
2. **Seu script chama** `POST /api/agent/leads` → Lead criado
3. **Frontend atualiza** Kanban (WebSocket) → Vendedor vê novo lead
4. **Seu agente SDR dispara** mensagem via Evolution API
5. **Seu agente chama** `POST /api/agent/conversations` → Mensagem salva
6. **Lead responde áudio** → Evolution API webhook → Backend
7. **Backend chama Minimax** → Transcrição salva
8. **Seu agente recebe** webhook com transcrição
9. **Seu agente classifica** interesse → Chama `PATCH /api/agent/leads/:id` stage=qualified
10. **Frontend move** lead no Kanban automaticamente

Tudo conectado! 🚀

---

## 📞 Dúvidas?

Se precisar de:
- Exemplo de código do seu agente chamando a API
- Webhook específico para seu fluxo
- Ajuste nos endpoints

É só falar!
