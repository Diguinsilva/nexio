# 🔧 Solução: Erro 400 - Webhook não configurado ou desativado

## 🐛 Problema Identificado

O sistema está tentando chamar webhooks usando a tabela `sdr_webhooks`, mas esta tabela **não existe no banco de dados**. Por isso você está vendo o erro:

```
❌ Erro ao testar "Teste_zoi". Webhook não configurado ou desativado
HTTP 400 (Bad Request)
```

## 🔍 Causa Raiz

1. O código foi atualizado para usar múltiplos webhooks (`sdr_webhooks`)
2. A migration que cria esta tabela foi criada mas **não foi executada no Supabase**
3. A Edge Function `send-webhook` tenta buscar dados de uma tabela que não existe
4. Resultado: erro 400

## ✅ Solução (3 Passos Simples)

### Passo 1: Executar o Script SQL

1. Abra o **Supabase Dashboard**
2. Vá em **SQL Editor** (menu lateral esquerdo)
3. Clique em **New Query**
4. Copie e cole **TODO** o conteúdo do arquivo `FIX_SDR_WEBHOOKS.sql`
5. Clique em **Run** (ou pressione Ctrl+Enter)

O script irá:
- ✅ Criar a tabela `sdr_webhooks`
- ✅ Configurar permissões (RLS)
- ✅ Migrar webhook antigo (se existir em `sdr_config`)
- ✅ Mostrar mensagens de confirmação

### Passo 2: Verificar se Funcionou

No SQL Editor, execute:

```sql
SELECT * FROM sdr_webhooks;
```

Se a tabela existir e mostrar resultado (mesmo vazio), está OK!

### Passo 3: Configurar Webhook na Interface

1. Volte para a página **SDR Config** no seu app
2. Clique em **Adicionar**
3. Preencha:
   - **Nome:** `Teste_zoi` (ou outro nome)
   - **URL:** Cole a URL do seu webhook n8n
   - **Secret:** (opcional) Token de segurança
   - **Ordem:** `1`
4. Clique em **Adicionar Webhook**
5. Clique em **Testar** no card do webhook criado

Agora deve funcionar! ✅

## 🎯 Como Testar sem n8n

Se você ainda não tem webhook n8n configurado:

1. Acesse [webhook.site](https://webhook.site)
2. Copie a URL única gerada (ex: `https://webhook.site/abc-123-def`)
3. Use essa URL no campo **URL do Webhook**
4. Clique em **Testar**
5. Volte no webhook.site e veja o payload recebido!

## 📊 Estrutura da Nova Tabela

| Campo | Descrição |
|-------|-----------|
| `id` | ID único do webhook |
| `name` | Nome (ex: "n8n Principal", "Backup") |
| `webhook_url` | URL completa do webhook |
| `webhook_secret` | Token secreto (opcional) |
| `enabled` | Ativo (true) ou Inativo (false) |
| `execution_order` | Ordem de execução (menor = primeiro) |
| `last_call` | Data/hora da última chamada |
| `last_status` | Status: `success` ou `error` |
| `last_error` | Mensagem de erro (se houver) |

## 🚀 Vantagens do Novo Sistema

### Antes (Sistema Antigo)
- ❌ Apenas 1 webhook configurado
- ❌ Se o webhook cair, você perde eventos
- ❌ Não dá para ter backup ou analytics separados

### Depois (Sistema Novo)
- ✅ **Múltiplos webhooks** configurados ao mesmo tempo
- ✅ **Backup automático**: configure 2+ webhooks para redundância
- ✅ **Analytics separado**: envie para n8n principal + Google Analytics
- ✅ **Ordem de execução**: controle quem executa primeiro
- ✅ **Ativar/Desativar**: pause webhooks sem deletar
- ✅ **Status individual**: veja qual webhook está funcionando

## 🔄 Execução em Paralelo vs Sequencial

### Paralelo (Mesma Ordem)
```
Ordem 1: Webhook A + Webhook B → executam ao mesmo tempo
```

### Sequencial (Ordens Diferentes)
```
Ordem 1: Webhook A → executa primeiro
Ordem 2: Webhook B → executa depois que A terminar
```

## 🛡️ Segurança com Secrets

Sempre configure um **webhook_secret** forte:

```
Exemplo de token: 3k9mP2vN8xQ5jL7rT4wY1zB6cF0hS9aD
```

No n8n, valide assim:

```javascript
// Nó IF do n8n
{{ $headers['x-webhook-secret'] === 'seu-token-aqui' }}
```

Se o token não bater, rejeite a requisição.

## 📱 Payload Enviado

```json
{
  "event_type": "sale_confirmed",
  "test": false,
  "timestamp": "2025-11-23T02:14:00Z",
  "data": {
    "product_id": 42,
    "product_name": "Kenner Slide Preto",
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

## 🆘 Troubleshooting

### Erro persiste após executar script
**Solução:** Verifique se a tabela foi criada:
```sql
SELECT table_name FROM information_schema.tables WHERE table_name = 'sdr_webhooks';
```

Se não retornar nada, a tabela não foi criada. Execute o script novamente.

### Webhook não recebe chamada
**Checklist:**
- [ ] Webhook está **ativo** (toggle verde)?
- [ ] URL está correta (sem espaços extras)?
- [ ] Edge Function `send-webhook` está deployada?
- [ ] Firewall/CORS do webhook permite requisições POST?

### Erro "relation sdr_webhooks does not exist"
Significa que a tabela não existe. Execute `FIX_SDR_WEBHOOKS.sql`.

### Webhook retorna 403/404/500
- **403**: Token/secret incorreto ou bloqueado
- **404**: URL do webhook está errada
- **500**: Erro interno no n8n (verifique logs do n8n)

## 📞 Suporte

Em caso de dúvidas:
1. Verifique logs da Edge Function no Supabase Dashboard
2. Abra o Console do navegador (F12) e veja erros
3. Teste com webhook.site para isolar problema do n8n

---

**Criado por:** Claude Code
**Data:** 23/11/2025
**Versão:** 1.0
