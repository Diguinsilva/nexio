# Nexio.AI - Testes e Critérios de Aceite

Checklist completo de testes e critérios de aceitação para o MVP.

---

## 🎯 Critérios de Aceite Gerais (MVP)

### Funcionalidade Mínima Viável

- [ ] Usuário consegue fazer login e acessar dashboard
- [ ] Dashboard exibe métricas básicas (leads hoje, total, conversão)
- [ ] Extração de leads via URL do Maps funciona e exibe progresso em tempo real
- [ ] Leads aparecem no Kanban após extração
- [ ] Usuário consegue mover leads entre stages (drag & drop)
- [ ] Lead Viewer exibe dados completos e permite copiar informações
- [ ] Mensagens do WhatsApp aparecem no UI em até 5 segundos
- [ ] Sistema é responsivo (mobile, tablet, desktop)
- [ ] Dark/Light mode funciona corretamente

---

## 🧪 Testes Unitários (Backend)

### Services

#### `apifyService.ts`
```bash
✓ Deve iniciar extração do Google Maps
✓ Deve retornar erro se URL inválida
✓ Deve fazer polling do status do run
✓ Deve retornar dados transformados corretamente
```

**Comando**:
```bash
cd backend
pnpm test src/services/apify.service.test.ts
```

#### `supabaseService.ts`
```bash
✓ Deve conectar ao Supabase com credenciais válidas
✓ Deve retornar erro com credenciais inválidas
✓ Deve executar queries com RLS corretamente
```

#### `openaiService.ts`
```bash
✓ Deve gerar mensagem personalizada
✓ Deve calcular ICP score
✓ Deve retornar JSON válido
✓ Deve fazer retry em caso de rate limit
```

### Controllers

#### `leadsController.ts`
```bash
✓ GET /api/leads - Deve retornar leads do tenant correto
✓ GET /api/leads - Deve aplicar filtros (stage, source, score)
✓ POST /api/leads - Deve criar lead com dados válidos
✓ POST /api/leads/extract - Deve iniciar job de extração
✓ GET /api/leads/extract/:jobId - Deve retornar status do job
✓ PATCH /api/leads/:id - Deve atualizar lead
✓ DELETE /api/leads/:id - Deve fazer soft delete
```

**Comando**:
```bash
pnpm test src/controllers/leads.controller.test.ts
```

### Middleware

#### `authMiddleware.ts`
```bash
✓ Deve bloquear request sem token
✓ Deve aceitar token JWT válido
✓ Deve injetar user e tenantId no request
✓ Deve rejeitar token expirado
```

---

## 🔗 Testes de Integração

### Fluxo: Extração de Leads

**Cenário**: Usuário insere URL do Maps e extrai 10 leads

1. **Dado** que o usuário está autenticado
2. **Quando** ele faz POST para `/api/leads/extract` com:
   ```json
   {
     "url": "https://www.google.com/maps/search/restaurantes+sp",
     "limit": 10
   }
   ```
3. **Então**:
   - Deve retornar status `202 Accepted`
   - Deve retornar um `jobId`
   - Job deve ser criado na tabela `import_jobs` com status `pending`

4. **Quando** o job é processado:
   - Status muda para `processing`
   - Apify é chamado com parâmetros corretos
   - Leads são inseridos na tabela `leads`
   - Status muda para `completed`

5. **Então**:
   - `import_jobs.success_rows` deve ser 10
   - Tabela `leads` deve ter 10 novos registros
   - Frontend deve receber evento via WebSocket

**Comando**:
```bash
pnpm test:integration tests/flows/lead-extraction.test.ts
```

### Fluxo: WhatsApp Incoming Message

**Cenário**: Lead envia mensagem de texto via WhatsApp

1. **Dado** que lead existe no sistema com `phone = +5511999999999`
2. **Quando** Evolution API envia webhook POST para `/api/conversations/webhook`:
   ```json
   {
     "From": "whatsapp:+5511999999999",
     "Body": "Olá, tenho interesse!",
     "MessageSid": "SMxxxxxxxxx"
   }
   ```
3. **Então**:
   - Mensagem é inserida em `conversations` com `direction = 'in'`
   - `leads.last_contact_at` é atualizado
   - Evento WebSocket é emitido para sala do tenant
   - n8n workflow é acionado (se configurado)

**Comando**:
```bash
pnpm test:integration tests/flows/whatsapp-incoming.test.ts
```

---

## 🖥️ Testes E2E (Frontend)

### Login Flow

```typescript
test('Deve fazer login com credenciais válidas', async ({ page }) => {
  await page.goto('http://localhost:5173');
  await page.fill('[name="email"]', 'admin@demo.com');
  await page.fill('[name="password"]', 'senha123456');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL(/.*dashboard/);
});
```

### Lead Extraction Flow

```typescript
test('Deve extrair leads do Google Maps', async ({ page }) => {
  await page.goto('http://localhost:5173/dashboard');
  await page.click('text=Extrair Leads');
  await page.fill('[name="url"]', 'https://www.google.com/maps/search/restaurantes+sp');
  await page.fill('[name="limit"]', '5');
  await page.click('text=Extrair');

  // Aguardar modal de progresso
  await expect(page.locator('text=Extraindo leads')).toBeVisible();

  // Aguardar conclusão (até 2 min)
  await expect(page.locator('text=5 leads extraídos')).toBeVisible({ timeout: 120000 });
});
```

### Kanban Drag & Drop

```typescript
test('Deve mover lead entre stages', async ({ page }) => {
  await page.goto('http://localhost:5173/kanban');

  const leadCard = page.locator('.lead-card').first();
  const qualifiedColumn = page.locator('[data-stage="qualified"]');

  await leadCard.dragTo(qualifiedColumn);

  // Verificar se lead aparece na coluna correta
  await expect(qualifiedColumn.locator('.lead-card').first()).toContainText(await leadCard.textContent());
});
```

**Comando**:
```bash
cd frontend
pnpm test:e2e
```

---

## ✅ Checklist de Testes Manuais

### 1. Autenticação

- [ ] Login com credenciais válidas funciona
- [ ] Login com credenciais inválidas mostra erro
- [ ] Logout funciona e redireciona para login
- [ ] Token JWT expira após 24h e força re-login
- [ ] Refresh token funciona automaticamente

### 2. Dashboard

- [ ] Métricas são exibidas corretamente
- [ ] Filtro de período (hoje, semana, mês) funciona
- [ ] Cards de Magic Bento são clicáveis
- [ ] Gráficos renderizam sem erro
- [ ] Dark/Light mode alterna corretamente

### 3. Extração de Leads

- [ ] Modal abre ao clicar em "Extrair Leads"
- [ ] Validação de URL do Maps funciona
- [ ] Limite aceita apenas números de 1 a 500
- [ ] Botão "Extrair" fica desabilitado durante processamento
- [ ] Progresso é atualizado em tempo real (0% → 100%)
- [ ] Contador de leads minerados atualiza
- [ ] AI State Loading animation aparece
- [ ] Ao concluir, exibe toast de sucesso
- [ ] Leads aparecem no Kanban automaticamente
- [ ] Duplicados por telefone são bloqueados

### 4. Kanban

- [ ] Colunas são exibidas: New, Contacted, Qualified, Proposal, Closed
- [ ] Drag & drop funciona (desktop)
- [ ] Em mobile, botão "Mover para..." aparece
- [ ] Filtro por cidade funciona
- [ ] Filtro por score funciona
- [ ] Filtro por tags funciona
- [ ] Bulk selection (checkbox) funciona
- [ ] Bulk actions (mover, deletar) funcionam
- [ ] LeadCard exibe: nome, telefone, cidade, score, tags
- [ ] Badge de source é exibido corretamente

### 5. Lead Viewer

- [ ] Modal abre ao clicar em lead
- [ ] Todos os dados são exibidos (nome, telefone, email, etc)
- [ ] Botão "Copiar telefone" copia para clipboard
- [ ] Botão "Copiar mensagem formatada" gera mensagem e copia
- [ ] Botão "Abrir WhatsApp" abre deep link (web.whatsapp.com)
- [ ] Timeline de interações é exibida
- [ ] ICP Match Score é exibido com barra de progresso
- [ ] Notas podem ser editadas e salvas
- [ ] Tags podem ser adicionadas/removidas
- [ ] Dropdown de status funciona

### 6. WhatsApp Espelhado

- [ ] Lista de conversas é exibida
- [ ] Mensagens de texto aparecem corretamente
- [ ] Mensagens enviadas (out) ficam à direita
- [ ] Mensagens recebidas (in) ficam à esquerda
- [ ] Timestamp é exibido
- [ ] Badge "Bot" aparece em mensagens automáticas
- [ ] Mensagens de áudio exibem player
- [ ] Player de áudio funciona (play/pause)
- [ ] Transcrição de áudio aparece abaixo do player
- [ ] Input de texto funciona para enviar mensagem manual
- [ ] Botão de envio envia mensagem
- [ ] Scroll vai para última mensagem ao abrir
- [ ] Novas mensagens aparecem em menos de 5s

### 7. Importação CSV

- [ ] Modal de import abre
- [ ] Upload de arquivo funciona
- [ ] Preview das primeiras 10 linhas aparece
- [ ] Mapeamento de colunas é intuitivo
- [ ] Deduplicação por telefone/email funciona
- [ ] Progresso de importação é exibido
- [ ] Erros por linha são exibidos
- [ ] Ao concluir, leads aparecem no Kanban

### 8. Relatórios

- [ ] Gráfico de conversão por stage é exibido
- [ ] Métricas de taxa de resposta WhatsApp
- [ ] Filtro de período funciona
- [ ] Exportação CSV funciona
- [ ] CSV contém todas as colunas esperadas

### 9. Configurações

- [ ] Página de perfil exibe dados do usuário
- [ ] Upload de foto de perfil funciona
- [ ] Edição de nome/bio funciona
- [ ] Configurações de cadência SDR podem ser editadas
- [ ] Configuração de ICP (cidades, score mínimo) funciona
- [ ] Integração WhatsApp pode ser testada (botão "Testar")

### 10. Responsividade

- [ ] Mobile (375px): Layout adapta-se corretamente
- [ ] Tablet (768px): Layout adapta-se corretamente
- [ ] Desktop (1920px): Layout não quebra
- [ ] Hamburger menu funciona em mobile
- [ ] Kanban em mobile usa scroll horizontal
- [ ] Modais ocupam 90% da tela em mobile

---

## 🚀 Critérios de Performance

### Tempo de Carregamento

- [ ] **Dashboard inicial**: < 2s (First Contentful Paint)
- [ ] **Time to Interactive**: < 3s
- [ ] **Lead Extraction (50 leads)**: < 5 min
- [ ] **WhatsApp message latency**: < 5s (incoming message → UI)
- [ ] **Audio transcription (1 min audio)**: < 10s

### API Response Time

- [ ] `GET /api/leads` (50 results): < 500ms (p95)
- [ ] `POST /api/leads/extract`: < 200ms (apenas inicia job)
- [ ] `GET /api/leads/:id`: < 300ms
- [ ] `POST /api/conversations/send`: < 1s

### Métricas de Infraestrutura

- [ ] **Backend CPU**: < 70% em carga normal
- [ ] **Redis memory**: < 500MB para 10k leads
- [ ] **Supabase queries**: < 100ms (média)

---

## 🛡️ Testes de Segurança

### Autenticação & Autorização

- [ ] Endpoint sem token retorna `401 Unauthorized`
- [ ] Token de outro tenant não acessa dados (RLS)
- [ ] Role `user` não consegue deletar leads (apenas admin)
- [ ] SQL injection não funciona (prepared statements)
- [ ] XSS não funciona (inputs sanitizados)

### Rate Limiting

- [ ] 100 requests/min por IP é bloqueado (429)
- [ ] Webhook Evolution API valida assinatura HMAC
- [ ] Login com senha errada bloqueia após 5 tentativas (15 min)

---

## 📊 Testes de Carga (Stress Test)

### Cenário: 100 usuários simultâneos

**Ferramenta**: k6 ou Artillery

```javascript
// k6 script
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 100, // 100 usuários virtuais
  duration: '5m',
};

export default function () {
  let res = http.get('https://api.nexio.ai/api/leads', {
    headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
```

**Critérios**:
- [ ] p95 < 1s
- [ ] Taxa de erro < 1%
- [ ] Backend não crasha

---

## 🐛 Testes de Regressão

Antes de cada deploy:

- [ ] Rodar todos testes unitários (`pnpm test`)
- [ ] Rodar testes de integração (`pnpm test:integration`)
- [ ] Rodar testes E2E críticos (`pnpm test:e2e --grep @critical`)
- [ ] Verificar logs do Sentry (sem novos erros)
- [ ] Smoke test em staging

---

## ✅ Checklist de Aceite Final (MVP)

- [ ] Todas as funcionalidades do MVP funcionam
- [ ] Todos os testes automatizados passam (unit + integration + e2e)
- [ ] Performance atende critérios (< 2s dashboard, < 5s WhatsApp)
- [ ] Segurança: sem vulnerabilidades críticas
- [ ] Responsividade: funciona em mobile, tablet, desktop
- [ ] Dark/Light mode funcionam sem bugs visuais
- [ ] Documentação completa (README, SETUP, API, PROMPTS)
- [ ] Deploy automatizado funciona (CI/CD)
- [ ] Logs e monitoramento configurados (Sentry)
- [ ] Backups automáticos do Supabase configurados

---

## 📝 Relatório de Bugs

Template para reportar bugs:

```markdown
### Bug: [Título curto]

**Severidade**: Alta / Média / Baixa

**Descrição**: [O que aconteceu]

**Passos para reproduzir**:
1. Ir para página X
2. Clicar em Y
3. Observar Z

**Comportamento esperado**: [O que deveria acontecer]

**Comportamento atual**: [O que acontece]

**Screenshots**: [Anexar se possível]

**Ambiente**:
- Browser: Chrome 120
- OS: macOS 14
- Versão: v1.0.0
```

---

## 🎓 Recursos para QA

- [Jest Docs](https://jestjs.io/docs/getting-started)
- [Playwright Docs](https://playwright.dev/docs/intro)
- [k6 Docs](https://k6.io/docs/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
