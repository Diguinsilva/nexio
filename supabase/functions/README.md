# Supabase Edge Functions

## 📦 send-webhook

Edge Function para enviar webhooks ao n8n sem problemas de CORS.

### Por que preciso disso?

Quando você tenta chamar o webhook do n8n direto do navegador, ocorre erro de **CORS** porque são domínios diferentes. Esta Edge Function resolve isso fazendo a chamada pelo backend do Supabase.

### Como fazer deploy

#### Opção 1: Via Supabase CLI (Recomendado)

```bash
# 1. Instalar Supabase CLI
npm install -g supabase

# 2. Login no Supabase
supabase login

# 3. Link com seu projeto
supabase link --project-ref SEU_PROJECT_REF

# 4. Deploy da function
supabase functions deploy send-webhook
```

#### Opção 2: Via Dashboard do Supabase

1. Acesse: https://supabase.com/dashboard
2. Vá em **Edge Functions**
3. Clique em **Create Function**
4. Nome: `send-webhook`
5. Cole o código de `supabase/functions/send-webhook/index.ts`
6. Clique em **Deploy**

### Como testar

Depois do deploy, a função estará disponível em:
```
https://SEU_PROJECT_REF.supabase.co/functions/v1/send-webhook
```

No SDR Config, quando você clicar em **Testar Webhook**, ele vai usar essa Edge Function automaticamente!

### Logs

Para ver os logs da Edge Function:

```bash
# Via CLI
supabase functions logs send-webhook

# Ou via Dashboard
Dashboard > Edge Functions > send-webhook > Logs
```

### Estrutura do Payload

A Edge Function espera receber:

```json
{
  "payload": {
    "event_type": "test",
    "test": true,
    "data": {
      "product_id": 1,
      "customer": {
        "phone": "+5511999999999",
        "name": "Cliente Teste"
      }
    }
  }
}
```

E retorna:

```json
{
  "success": true,
  "status": 200,
  "data": {
    "message": "Webhook recebido"
  }
}
```

### Troubleshooting

**Erro: "Webhook não configurado ou desativado"**
- Verifique se a URL do webhook está salva em `sdr_config`
- Verifique se `webhook_enabled` está `true`

**Erro: "Failed to fetch"**
- A Edge Function não foi deployada ou o nome está errado
- Verifique o nome exato: `send-webhook`

**Erro: "Unauthorized"**
- O usuário não está autenticado
- Faça login no sistema primeiro
