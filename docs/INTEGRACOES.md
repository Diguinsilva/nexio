# Sistema de Integrações Modular - Nexio.AI

## 🎯 Visão Geral

O Nexio.AI possui um **sistema de integrações plugável e escalável** que permite você escolher e configurar os serviços que deseja usar, diretamente pela interface.

**Não é hardcoded!** Você decide:
- Qual API de WhatsApp usar (Evolution, Zapi, Uazapi, Twilio)
- Qual serviço de transcrição (Minimax, Whisper, AssemblyAI)
- Qual LLM usar (GPT-4, Claude, Groq)
- E muito mais...

---

## 🏗️ Arquitetura

```
┌──────────────────────────────────────┐
│     Frontend (React)                  │
│  Página de Integrações               │
│  - Lista integrações configuradas    │
│  - Adiciona novas integrações        │
│  - Testa credenciais                 │
└───────────────┬──────────────────────┘
                │ REST API
                ▼
┌──────────────────────────────────────┐
│     Backend (Node.js)                 │
│  IntegrationsService                 │
│  - Busca config do tenant            │
│  - Inicializa providers              │
│  - Cache de 5 minutos                │
└───────────────┬──────────────────────┘
                │
        ┌───────┼───────┐
        ▼       ▼       ▼
    ┌─────┐ ┌─────┐ ┌─────┐
    │Evo  │ │Zapi │ │Mini.│  Adapters
    │API  │ │     │ │max  │
    └─────┘ └─────┘ └─────┘
                │
                ▼
┌──────────────────────────────────────┐
│     Supabase (PostgreSQL)             │
│  Tabelas:                            │
│  - integration_types                 │
│  - integration_providers             │
│  - tenant_integrations               │
│  - integration_usage_logs            │
└──────────────────────────────────────┘
```

---

## 📊 Banco de Dados

### Tabelas Principais

**1. `integration_types`** - Tipos de integrações
```sql
- whatsapp (Mensageria)
- transcription (IA - Transcrição)
- llm (IA - Modelos de Linguagem)
- scraping (Extração de dados)
- crm (CRMs externos)
- email (E-mail marketing)
```

**2. `integration_providers`** - Provedores disponíveis
```sql
WhatsApp:
  - evolution_api (Evolution API - self-hosted)
  - zapi (Zapi - R$ 50-100/mês)
  - uazapi (Uazapi - R$ 70-150/mês)
  - twilio (Twilio - oficial)

Transcrição:
  - minimax (Minimax - humanizado PT-BR)
  - openai_whisper (OpenAI Whisper)
  - assemblyai (AssemblyAI - sentiment analysis)

LLM:
  - openai_gpt4 (GPT-4o)
  - anthropic_claude (Claude 3.5)

Scraping:
  - apify (Apify Google Maps)
```

**3. `tenant_integrations`** - Integrações configuradas por tenant
```sql
- tenant_id (qual empresa)
- provider_id (qual provedor)
- credentials (JSON criptografado)
- is_active (ativo/inativo)
- is_default (se é o padrão para aquele tipo)
```

---

## 🔌 Como Funciona na Prática

### 1. Usuário Configura no Frontend

1. Acessa **Configurações → Integrações**
2. Clica em **"+ Adicionar Integração"**
3. Escolhe provedor (ex: Evolution API)
4. Preenche credenciais:
   ```json
   {
     "api_url": "https://evolution.seudominio.com",
     "api_key": "sua-chave",
     "instance": "nome-instancia"
   }
   ```
5. Clica em **"Testar Conexão"** (valida antes de salvar)
6. Salva ✅

### 2. Backend Busca Integração Ativa

Quando o sistema precisa enviar uma mensagem:

```typescript
// No controller/job
const tenantId = '123-456-789';

// IntegrationsService busca no banco qual provedor está ativo
const whatsappProvider = await integrationsService.getWhatsAppProvider(tenantId);

// Usa o provedor configurado (pode ser Evolution, Zapi, etc)
await whatsappProvider.sendText('+5511999999999', 'Olá!');
```

### 3. Adapter Pattern

Cada provedor implementa a mesma interface:

```typescript
interface IWhatsAppProvider {
  sendText(to: string, message: string): Promise<WhatsAppSendResult>;
  sendAudio(to: string, audioUrl: string): Promise<WhatsAppSendResult>;
  downloadMedia(mediaUrl: string): Promise<Buffer>;
  getStatus(): Promise<WhatsAppInstanceStatus>;
}
```

**Vantagens**:
- ✅ Código do sistema não muda ao trocar provedor
- ✅ Você adiciona novos provedores sem quebrar nada
- ✅ Testa múltiplos provedores sem reescrever código

---

## 💻 Uso no Código

### Exemplo 1: Enviar Mensagem WhatsApp

```typescript
import { integrationsService } from '@/services/integrations.service';

async function enviarMensagem(tenantId: string, telefone: string, texto: string) {
  // Busca provedor WhatsApp ativo do tenant
  const whatsapp = await integrationsService.getWhatsAppProvider(tenantId);

  // Envia (funciona com Evolution, Zapi, Uazapi, Twilio...)
  const result = await whatsapp.sendText(telefone, texto);

  if (result.status === 'sent') {
    console.log('Mensagem enviada!', result.messageId);
  }
}
```

### Exemplo 2: Transcrever Áudio

```typescript
import { integrationsService } from '@/services/integrations.service';

async function transcreverAudio(tenantId: string, audioBuffer: Buffer) {
  // Busca provedor de transcrição ativo (pode ser Minimax ou Whisper)
  const transcription = await integrationsService.getTranscriptionProvider(tenantId);

  // Transcreve
  const result = await transcription.transcribe(audioBuffer, 'pt');

  console.log('Texto:', result.text);
  return result.text;
}
```

### Exemplo 3: Webhook do WhatsApp

```typescript
router.post('/api/whatsapp/webhook', async (req, res) => {
  const { phone, audio } = req.body;

  // 1. Buscar lead
  const lead = await getLeadByPhone(phone);

  if (audio) {
    // 2. Baixar áudio usando o provedor configurado
    const whatsapp = await integrationsService.getWhatsAppProvider(lead.tenant_id);
    const audioBuffer = await whatsapp.downloadMedia(audio);

    // 3. Transcrever usando o provedor de transcrição configurado
    const transcriptionProvider = await integrationsService.getTranscriptionProvider(lead.tenant_id);
    const transcription = await transcriptionProvider.transcribe(audioBuffer);

    // 4. Salvar no banco
    await saveConversation({
      lead_id: lead.id,
      message: transcription.text,
      type: 'audio',
    });
  }

  res.json({ ok: true });
});
```

---

## 🛠️ Adicionar Novo Provedor

### Passo 1: Criar o Adapter

```typescript
// backend/src/integrations/whatsapp/UazapiProvider.ts

import { IWhatsAppProvider, WhatsAppSendResult } from './IWhatsAppProvider';

export class UazapiProvider implements IWhatsAppProvider {
  readonly providerName = 'uazapi';

  async initialize(credentials: Record<string, any>): Promise<void> {
    this.instanceId = credentials.instance_id;
    this.token = credentials.token;
  }

  async sendText(to: string, message: string): Promise<WhatsAppSendResult> {
    // Implementar chamada API Uazapi
    const response = await axios.post(`https://api.uazapi.com/send`, {
      instance: this.instanceId,
      phone: to,
      text: message,
    }, {
      headers: { 'Authorization': `Bearer ${this.token}` }
    });

    return {
      messageId: response.data.id,
      status: 'sent',
    };
  }

  // Implementar outros métodos...
}
```

### Passo 2: Registrar no Factory

```typescript
// backend/src/integrations/whatsapp/WhatsAppFactory.ts

import { UazapiProvider } from './UazapiProvider';

export class WhatsAppFactory {
  private static providers: Map<string, new () => IWhatsAppProvider> = new Map([
    ['evolution_api', EvolutionProvider],
    ['zapi', ZapiProvider],
    ['uazapi', UazapiProvider], // ✅ Adicionar aqui
  ]);
}
```

### Passo 3: Adicionar no Banco

```sql
-- Adicionar provedor na migration ou via SQL direto
INSERT INTO integration_providers (
  integration_type_id,
  slug,
  name,
  description,
  config_schema,
  pricing_info
) VALUES (
  (SELECT id FROM integration_types WHERE slug = 'whatsapp'),
  'uazapi',
  'Uazapi',
  'API WhatsApp com recursos avançados',
  '{
    "type": "object",
    "required": ["instance_id", "token"],
    "properties": {
      "instance_id": {"type": "string", "title": "Instance ID"},
      "token": {"type": "string", "title": "Token", "secret": true}
    }
  }',
  '{"monthly_cost": "R$ 70-150"}'
);
```

### Passo 4: Pronto! 🚀

Agora Uazapi aparece automaticamente na interface para o usuário configurar.

---

## 🔒 Segurança

### Credenciais Criptografadas

As credenciais são armazenadas como JSONB no Supabase. **Recomendações**:

1. **Em produção**: Criptografar campo `credentials` com `pgcrypto`
   ```sql
   -- Exemplo de criptografia no Postgres
   UPDATE tenant_integrations
   SET credentials = pgp_sym_encrypt(credentials::text, 'sua-chave-secreta');
   ```

2. **Usar Vault**: Para credenciais ultra-sensíveis, usar HashiCorp Vault ou AWS Secrets Manager

3. **RLS Policies**: Já implementado - cada tenant só vê suas próprias integrações

---

## 📈 Billing & Usage Logs

### Registrar Uso

```typescript
// Após usar uma integração
await integrationsService.logUsage(
  integrationId,
  'send_message', // operação
  'success',
  { phone: '+5511999999999', messageId: 'abc123' }
);
```

### Query de Uso (para cobrar cliente)

```sql
-- Total de mensagens enviadas no mês
SELECT
  ti.name AS integration_name,
  COUNT(*) AS total_operations,
  SUM(credits_used) AS total_credits
FROM integration_usage_logs iul
JOIN tenant_integrations ti ON iul.tenant_integration_id = ti.id
WHERE ti.tenant_id = '123-456'
  AND iul.created_at >= date_trunc('month', CURRENT_DATE)
GROUP BY ti.name;
```

---

## 🎨 Frontend - Tela de Integrações

### Componentes Criados

1. **`IntegrationsPage.tsx`** - Página principal
   - Lista integrações configuradas
   - Mostra provedores disponíveis
   - Botão "Adicionar Integração"

2. **`IntegrationCard`** - Card de integração ativa
   - Status (ativo/inativo)
   - Badge "Padrão"
   - Botões: Ativar/Desativar, Editar

3. **`ProviderCard`** - Card de provedor disponível
   - Logo, nome, descrição
   - Preço estimado
   - Botão "Configurar"

### Próximos Componentes (TODO)

- **`AddIntegrationModal`** - Modal para adicionar integração
  - Form dinâmico baseado em `config_schema`
  - Botão "Testar Conexão"
  - Validação de credenciais

- **`EditIntegrationModal`** - Editar integração existente

---

## 🚀 Roadmap

### V1 (Implementado)
- ✅ Sistema de integrações plugável no banco
- ✅ Adapters WhatsApp (Evolution, Zapi)
- ✅ Adapters Transcrição (Minimax, Whisper)
- ✅ IntegrationsService com cache
- ✅ API REST completa
- ✅ Frontend básico (lista integrações)

### V2 (Próximos Passos)
- [ ] Modal de adicionar integração com form dinâmico
- [ ] Criptografia de credenciais (pgcrypto)
- [ ] Adapters adicionais: Uazapi, Twilio, AssemblyAI
- [ ] Sistema de créditos e billing
- [ ] Webhook management (configurar webhooks via UI)

### V3 (Futuro)
- [ ] Marketplace de integrações (3rd-party plugins)
- [ ] Analytics de uso por integração
- [ ] Auto-failover (se provedor A cair, usar provedor B)
- [ ] Integrações com CRMs (HubSpot, Pipedrive)
- [ ] Integrações com Email (SendGrid, Mailgun)

---

## 📞 Exemplos de Uso Real

### Cenário 1: Cliente usa Evolution API

```typescript
// Cliente configura Evolution API na UI
// Quando o sistema precisar enviar mensagem:

const whatsapp = await integrationsService.getWhatsAppProvider(tenantId);
// → Retorna EvolutionProvider configurado

await whatsapp.sendText('+5511999999999', 'Olá!');
// → Chama Evolution API
```

### Cenário 2: Cliente migra para Zapi

Cliente decide trocar Evolution por Zapi (mais estável):

1. Acessa **Integrações**
2. Clica em **"+ Adicionar Integração"**
3. Escolhe **Zapi**
4. Preenche credenciais Zapi
5. Marca como **"Integração Padrão"** ✅
6. Desativa Evolution API

**Resultado**: Sistema agora usa Zapi automaticamente, sem mudar 1 linha de código!

### Cenário 3: Cliente quer testar 2 provedores

Cliente pode:
- Configurar **Evolution API** E **Zapi**
- Setar Evolution como padrão para testes
- Se der problema, marcar Zapi como padrão

---

## 🎓 Boas Práticas

1. **Sempre usar Factory**: Nunca instanciar providers diretamente
   ```typescript
   // ❌ Errado
   const provider = new EvolutionProvider();

   // ✅ Certo
   const provider = await integrationsService.getWhatsAppProvider(tenantId);
   ```

2. **Cachear providers**: IntegrationsService já faz isso (5 min)

3. **Testar antes de salvar**: Usar endpoint `/api/integrations/test`

4. **Registrar uso**: Sempre chamar `logUsage()` após operações

5. **Tratar erros**: Providers podem falhar, sempre usar try/catch

---

## 📚 Documentação das APIs

### REST Endpoints

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/api/integrations` | Lista integrações do tenant |
| `GET` | `/api/integrations/providers` | Lista provedores disponíveis |
| `POST` | `/api/integrations` | Cria nova integração |
| `PATCH` | `/api/integrations/:id` | Atualiza integração |
| `DELETE` | `/api/integrations/:id` | Deleta integração |
| `POST` | `/api/integrations/test` | Testa credenciais |

### Exemplo de Request

```bash
# Criar integração Evolution API
curl -X POST https://api.nexio.com/api/integrations \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: 123-456" \
  -d '{
    "provider_slug": "evolution_api",
    "name": "WhatsApp Principal",
    "credentials": {
      "api_url": "https://evolution.seudominio.com",
      "api_key": "SUA_CHAVE",
      "instance": "main"
    },
    "set_as_default": true
  }'
```

---

## ❓ FAQ

### 1. Posso usar múltiplos provedores do mesmo tipo?
Sim! Você pode ter Evolution API E Zapi configurados. Apenas um será "padrão".

### 2. Como trocar de provedor sem downtime?
1. Configure novo provedor
2. Teste no ambiente de staging
3. Marque como padrão
4. Antigo provedor fica como fallback

### 3. Credenciais são seguras?
Sim, armazenadas em JSONB no Supabase. Recomendamos criptografar em produção.

### 4. Posso criar meu próprio adapter?
Sim! Basta implementar a interface e registrar no Factory.

### 5. Sistema funciona sem integrações configuradas?
Não. Você precisa configurar pelo menos 1 provedor WhatsApp para o CRM funcionar.

---

**Documentação atualizada**: 2025-01-23
**Versão**: 1.0
