# 🚀 Deploy: Sistema de Múltiplos Webhooks SDR

**Data:** 23/11/2025
**Versão:** 2.0

## 📋 O que mudou?

### ✅ Correções Implementadas:
1. **Erro antigo na UI**: Mensagens de erro antigas não aparecem mais automaticamente
2. **Botão "Limpar Erro"**: Permite limpar mensagens de erro manualmente
3. **Salvamento corrigido**: Configurações agora são salvas corretamente e limpam erros antigos
4. **Validação melhor**: Edge Function agora trata erros de forma mais robusta

### 🎯 Nova Funcionalidade: Múltiplos Webhooks
- ✅ Adicionar/remover webhooks dinamicamente
- ✅ Cada webhook com nome, URL, secret e status ativo/inativo
- ✅ Ordem de execução configurável
- ✅ Webhooks executados em paralelo
- ✅ Status individual para cada webhook

---

## 📦 Arquivos Alterados/Criados

### Novos Arquivos:
- `migrations/add_multiple_webhooks.sql` - Migration para criar tabela `sdr_webhooks`
- `src/components/SDRConfigMultiple.jsx` - Novo componente React
- `DEPLOY_MULTIPLE_WEBHOOKS.md` - Este arquivo

### Arquivos Modificados:
- `src/components/SDRConfig.jsx` - Componente antigo (correções aplicadas)
- `supabase/functions/send-webhook/index.ts` - Edge Function refatorada
- `src/App.jsx` - Import atualizado para usar novo componente

---

## 🛠️ Passo a Passo de Deploy

### 1️⃣ Executar Migration no Supabase

Abra o **SQL Editor** no dashboard do Supabase e execute:

```sql
-- Copie e cole TODO o conteúdo de migrations/add_multiple_webhooks.sql
```

**O que a migration faz:**
- Cria tabela `sdr_webhooks` com suporte para múltiplos webhooks
- Migra webhook existente de `sdr_config` para `sdr_webhooks` (se houver)
- Configura RLS policies para acesso

### 2️⃣ Redesenhar Edge Function

**Opção A: Dashboard do Supabase** (Recomendado)
1. Acesse **Edge Functions** no dashboard
2. Selecione `send-webhook`
3. Clique em **Edit Function**
4. Copie e cole o conteúdo de `supabase/functions/send-webhook/index.ts`
5. Clique em **Save** e **Deploy**

**Opção B: CLI do Supabase**
```bash
# Na raiz do projeto
supabase functions deploy send-webhook
```

### 3️⃣ Deploy do Frontend

```bash
# Build da aplicação
npm run build

# Deploy para produção (ajuste conforme seu ambiente)
# Exemplo: Vercel, Netlify, etc
```

---

## 🧪 Como Testar

### 1. Verificar Migration
Acesse **Table Editor** > `sdr_webhooks` no Supabase. A tabela deve existir.

### 2. Testar Interface
1. Abra a página de **Configurações SDR** no app
2. Clique em **Adicionar** para criar um novo webhook
3. Preencha:
   - Nome: `Teste n8n`
   - URL: `https://webhook.site/unique-id` (use webhook.site para testar)
   - Secret: (opcional)
   - Ordem: `1`
4. Clique em **Adicionar Webhook**
5. O webhook deve aparecer na lista

### 3. Testar Webhook
1. Clique em **Testar** no card do webhook
2. Acesse webhook.site e veja se recebeu o payload de teste
3. Volte ao app e verifique se o status foi atualizado (verde = sucesso)

### 4. Testar Múltiplos Webhooks
1. Adicione 2-3 webhooks diferentes
2. Quando uma venda for detectada, todos webhooks ativos serão chamados em paralelo
3. Verifique os logs individuais de cada webhook

---

## 📖 Guia de Uso

### Adicionar Webhook
1. Clique em **Adicionar**
2. Preencha nome, URL, secret (opcional) e ordem
3. Clique em **Adicionar Webhook**

### Editar Webhook
1. Clique no ícone de lápis (✏️) no card do webhook
2. Modifique os campos desejados
3. Clique em **Salvar**

### Ativar/Desativar Webhook
- Use o toggle no canto superior direito do card
- Webhooks desativados não recebem eventos

### Deletar Webhook
1. Clique em **Deletar** no card
2. Confirme a ação

### Ordem de Execução
- Webhooks com **mesma ordem** são executados em **paralelo**
- Webhooks com **ordens diferentes** são executados em **sequência**
- Exemplo:
  - Ordem 1: Webhook A e B (executam juntos)
  - Ordem 2: Webhook C (executa depois de A e B)

---

## 🔍 Troubleshooting

### Migration Falha
**Erro:** `relation "sdr_webhooks" already exists`
**Solução:** A tabela já existe. Verifique se foi criada corretamente com `SELECT * FROM sdr_webhooks LIMIT 1`

### Edge Function Retorna 500
**Possíveis causas:**
1. Variáveis de ambiente não configuradas (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
2. Webhook URL inválida
3. Timeout na chamada ao webhook

**Solução:** Verifique logs da Edge Function no dashboard do Supabase

### Webhook Não Recebe Evento
**Checklist:**
- [ ] Webhook está ativo (toggle verde)?
- [ ] URL está correta?
- [ ] Edge Function está deployada?
- [ ] Verifique logs da Edge Function

### UI Mostra Erro Antigo
**Solução:** Clique em **Limpar** no card de erro vermelho

---

## 🔐 Segurança

### Tokens/Secrets
- Sempre use tokens fortes (min 32 caracteres)
- Tokens são enviados no header `X-Webhook-Secret`
- Valide tokens no n8n:
  ```javascript
  {{ $headers['x-webhook-secret'] === 'seu-token-aqui' }}
  ```

### RLS (Row Level Security)
- Políticas permissivas: todos podem ler/escrever `sdr_webhooks`
- **Ajuste conforme necessário para produção**
- Recomendado: Restringir para usuários admin apenas

---

## 📊 Estrutura da Tabela `sdr_webhooks`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id` | UUID | ID único do webhook |
| `name` | TEXT | Nome identificador (ex: "n8n Principal") |
| `webhook_url` | TEXT | URL do webhook |
| `webhook_secret` | TEXT | Token de segurança (opcional) |
| `enabled` | BOOLEAN | Ativo/Inativo |
| `execution_order` | INTEGER | Ordem de execução (menor = primeiro) |
| `last_call` | TIMESTAMP | Última tentativa de chamada |
| `last_status` | TEXT | Status: `success` ou `error` |
| `last_error` | TEXT | Mensagem de erro (se houver) |
| `created_at` | TIMESTAMP | Data de criação |
| `updated_at` | TIMESTAMP | Data de atualização |

---

## 🎯 Payload Enviado

```json
{
  "event_type": "sale_confirmed",
  "test": false,
  "timestamp": "2025-11-23T10:30:00Z",
  "data": {
    "product_id": 42,
    "product_name": "Produto Exemplo",
    "quantity": 2,
    "total_value": 400.00,
    "customer": {
      "phone": "+5511987654321",
      "name": "João Silva"
    },
    "payment_method": "pix",
    "source": "whatsapp"
  }
}
```

---

## 🆘 Suporte

Em caso de problemas:
1. Verifique logs da Edge Function no Supabase
2. Verifique console do navegador (F12)
3. Teste webhooks individuais usando webhook.site
4. Verifique se migration foi executada corretamente

---

## ✅ Checklist de Deploy

- [ ] Migration executada no Supabase
- [ ] Edge Function redesenhada
- [ ] Frontend deployado
- [ ] Teste de criar webhook
- [ ] Teste de editar webhook
- [ ] Teste de deletar webhook
- [ ] Teste de testar webhook
- [ ] Teste com webhook real do n8n
- [ ] Verificar logs individuais

---

**Deploy realizado por:** Claude Code
**Data:** 23/11/2025
**Versão:** 2.0
