# O Que é a "IA" no Nexio.AI?

Explicação simples e direta sobre a Inteligência Artificial no sistema.

---

## 🤖 O Que É?

A **IA** no Nexio.AI é o **OpenAI GPT-4o** (ChatGPT avançado) que você chama via API para automatizar tarefas que normalmente um vendedor humano faria.

**Não é nada mágico**. É simplesmente:
1. Você envia um texto (prompt) para a API da OpenAI
2. Ela retorna uma resposta inteligente
3. Você usa essa resposta no sistema

---

## 💡 Exemplos Práticos

### 1. Gerar Mensagem Personalizada

**Sem IA** (manual):
```
Você: *abre lead no sistema*
Você: *escreve manualmente*: "Olá João, vi que você tem uma pizzaria..."
Você: *envia no WhatsApp*
```

**Com IA** (automático):
```javascript
// Sistema lê dados do lead
const lead = {
  name: "João Silva",
  company: "Pizzaria Bella",
  city: "São Paulo"
}

// Sistema envia para OpenAI
const prompt = `
Gere mensagem para ${lead.name}, dono da ${lead.company} em ${lead.city}.
Objetivo: oferecer automação de vendas.
Tom: consultivo, 2-3 frases.
`;

// OpenAI retorna:
"Olá João! Vi que você tem a Pizzaria Bella em São Paulo.
Imagino que captar clientes novos seja um desafio constante, não é?
Posso te mostrar como automatizar isso via WhatsApp?"
```

**Resultado**: Sistema envia essa mensagem automaticamente para o lead.

---

### 2. Transcrever Áudio do WhatsApp

**Problema**: Lead envia áudio no WhatsApp. Vendedor precisa ouvir manualmente.

**Solução com IA** (Whisper):
```javascript
// Lead envia áudio de 1 minuto
const audioFile = "audio.mp3";

// Sistema envia para OpenAI Whisper
const transcription = await openai.audio.transcriptions.create({
  file: audioFile,
  model: "whisper-1",
  language: "pt"
});

// Retorna texto:
"Oi, tenho interesse em conhecer a solução.
Quanto custa por mês?"
```

**Resultado**: Você vê o texto sem precisar ouvir o áudio.

---

### 3. Classificar Intenção do Lead

**Problema**: Lead responde "talvez mais tarde". É interesse ou desculpa?

**Solução com IA**:
```javascript
const message = "talvez mais tarde";

const prompt = `
Classifique a intenção desta resposta:
"${message}"

Opções: interesse, objeção, neutro, negativo
Retorne JSON: { "intent": "...", "confidence": 0.8 }
`;

// OpenAI retorna:
{
  "intent": "objeção",
  "confidence": 0.85,
  "reason": "Resposta evasiva, provavelmente não interessado"
}
```

**Resultado**: Sistema marca lead como "baixa prioridade" automaticamente.

---

### 4. Follow-up Automático

**Problema**: Lead não respondeu há 3 dias. Vendedor esquece de fazer follow-up.

**Solução com IA**:
```javascript
// Sistema detecta: lead sem resposta há 3 dias

const prompt = `
Gere mensagem de follow-up para lead que não respondeu há 3 dias.
Mensagem original: "Olá! Quer automatizar vendas?"
Resposta: Nenhuma.

Gere nova mensagem: tom leve, oferecer valor.
`;

// OpenAI retorna:
"Oi! Sei que a rotina é corrida.
Fiz um checklist de '5 formas de vender mais via WhatsApp'
que acho que vai te ajudar. Quer que eu mande?"
```

**Resultado**: Sistema envia essa mensagem automaticamente após 3 dias.

---

## 🔧 Como Funciona Tecnicamente?

### Passo a Passo:

1. **Lead é criado** (extraído do Google Maps)
2. **Backend chama OpenAI API**:
   ```javascript
   const response = await openai.chat.completions.create({
     model: "gpt-4o",
     messages: [
       {
         role: "system",
         content: "Você é um SDR consultivo."
       },
       {
         role: "user",
         content: `Gere mensagem para ${lead.name}...`
       }
     ],
     temperature: 0.7,  // criatividade (0 = robótico, 1 = muito criativo)
     max_tokens: 150    // tamanho máximo da resposta
   });
   ```

3. **OpenAI retorna resposta**:
   ```json
   {
     "choices": [{
       "message": {
         "content": "Olá João! Vi que você tem..."
       }
     }]
   }
   ```

4. **Sistema salva mensagem** no banco de dados
5. **Sistema envia via Evolution API** para o WhatsApp do lead

---

## 💰 Quanto Custa?

**OpenAI GPT-4o** cobra por "tokens" (palavras):
- **Entrada**: $2.50 por 1 milhão de tokens (~750k palavras)
- **Saída**: $10.00 por 1 milhão de tokens

**Exemplo real**:
- 1 mensagem gerada = ~150 tokens = $0.001 (R$ 0,005)
- 1.000 mensagens/mês = ~$1-2 USD (R$ 5-10)
- Transcrição de áudio (1 min) = ~$0.006 (R$ 0,03)

**Total estimado**:
- 1.000 leads/mês
- 2.000 mensagens geradas
- 500 áudios transcritos
- **Custo**: ~R$ 100-200/mês

Ver preços: https://openai.com/api/pricing/

---

## 🎯 O Que a IA NÃO Faz

❌ **Não toma decisões sozinha** (você configura as regras)
❌ **Não envia mensagens sem você configurar** (precisa ativar "auto-send")
❌ **Não aprende sozinha** (você define os prompts)
❌ **Não substitui vendedor 100%** (vendedor fecha negócio)

✅ **Automatiza tarefas repetitivas**
✅ **Gera textos personalizados em escala**
✅ **Economiza tempo do vendedor**

---

## 🛡️ Segurança dos Dados

**Pergunta**: "A OpenAI vai usar meus dados?"

**Resposta**: Não, se você usar a API comercial:
- Dados **NÃO são usados** para treinar modelos
- Dados são **deletados após 30 dias**
- Você pode **desabilitar retenção** totalmente

Ver política: https://openai.com/enterprise-privacy

---

## 🚀 Alternativas à OpenAI

Se não quiser usar OpenAI, pode trocar por:

1. **Anthropic Claude** (similar ao GPT-4o)
   - Preço similar
   - Melhor para textos longos
   - API: https://anthropic.com

2. **Groq** (GPT-4o via Groq - mais barato)
   - 10x mais rápido
   - Preço: ~70% menor
   - API: https://groq.com

3. **Ollama** (rodar localmente - grátis)
   - LLaMA 3, Mistral, etc
   - Precisa de GPU (custo de VPS maior)
   - Sem taxa por token

4. **Gemini 1.5** (Google)
   - Grátis até certo limite
   - API: https://ai.google.dev

---

## 📊 Comparação: Com vs Sem IA

| Tarefa | Sem IA (manual) | Com IA (automático) |
|--------|----------------|---------------------|
| Gerar mensagem | 2-3 min/lead | 2 segundos |
| Transcrever áudio | Ouvir 1 min | 5 segundos |
| Follow-up | Esquecer 70% | 100% automático |
| Classificar intent | Subjetivo | Objetivo + score |
| Trabalhar 24/7 | Impossível | Sim |

**Economia estimada**: 5-10 horas/semana por vendedor

---

## 🧪 Testar Antes de Implementar

Você pode testar a OpenAI agora mesmo:

1. Crie conta: https://platform.openai.com
2. Ganhe **$5 grátis** (suficiente para ~5.000 mensagens)
3. Teste no Playground: https://platform.openai.com/playground

**Exemplo de prompt**:
```
Você é um SDR consultivo.
Gere mensagem para João, dono de pizzaria em SP.
Objetivo: oferecer automação de vendas.
Tom: amigável, 2 frases.
```

Clique "Submit" e veja a mágica acontecer!

---

## ❓ Dúvidas Frequentes

### 1. "Precisa ter OpenAI?"
Sim, a menos que você implemente outro LLM (Claude, Groq, etc).

### 2. "Dá pra rodar sem IA?"
Sim! Você pode:
- Gerar mensagens manualmente (sem auto-geração)
- Não transcrever áudios (ouvir manualmente)
- Fazer follow-up manual

Mas aí perde 70% do valor do sistema.

### 3. "A IA vai errar às vezes?"
Sim. Por isso sempre recomendamos:
- Vendedor revisar mensagens antes de enviar (opcional)
- Monitorar qualidade das respostas
- Ajustar prompts com o tempo

### 4. "Como melhorar os prompts?"
Documentamos 7 prompts otimizados em `docs/PROMPTS.md`.
Você pode ajustá-los conforme seu nicho.

---

## 📝 Resumo Simples

**IA no Nexio.AI = OpenAI GPT-4o fazendo tarefas de vendedor**

- ✅ Gera mensagens personalizadas
- ✅ Transcreve áudios do WhatsApp
- ✅ Classifica intenção de respostas
- ✅ Faz follow-up automático
- ✅ Economiza 5-10h/semana

**Custo**: ~R$ 100-200/mês para 1-2k leads
**Alternativas**: Claude, Groq, Gemini, Ollama

**Documentação OpenAI**: https://platform.openai.com/docs

---

**Próximo passo**: Configure sua chave da OpenAI seguindo `docs/SETUP.md` → Passo 3
