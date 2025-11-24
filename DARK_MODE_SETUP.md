# 🌙 Dark Mode - Guia de Configuração

## Problema Atual
Os toggles de Dark Mode estão na UI, mas:
- ✅ **Dark Mode do Catálogo**: Funcionando
- ❌ **Dark Mode do Painel Admin**: NÃO aplicado nas classes CSS

## Passo 1: Execute a Migration no Supabase

1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **SQL Editor**
4. Copie e execute o SQL abaixo:

```sql
-- Adicionar colunas de dark mode
ALTER TABLE settings
  ADD COLUMN IF NOT EXISTS dark_mode_admin BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS dark_mode_catalog BOOLEAN DEFAULT false;

-- Verificar se foi criado
SELECT id, store_name, dark_mode_admin, dark_mode_catalog
FROM settings
WHERE id = 1;
```

## Passo 2: Status Atual do Código

### ✅ O que JÁ funciona:
- Settings.jsx salva `dark_mode_admin` e `dark_mode_catalog`
- App.jsx carrega essas configurações
- Dark Mode do Catálogo está 100% implementado com classes condicionais

### ❌ O que NÃO funciona:
- As classes CSS do painel admin não mudam quando `darkModeAdmin` é true
- Falta aplicar classes condicionais baseadas em `darkModeAdmin`

## Passo 3: Implementação Necessária

O painel admin usa muitas classes como:
- `bg-white` → precisa ser `${darkModeAdmin ? 'bg-[#202020]' : 'bg-white'}`
- `text-gray-800` → precisa ser `${darkModeAdmin ? 'text-white' : 'text-gray-800'}`
- `bg-gray-50` → precisa ser `${darkModeAdmin ? 'bg-[#111111]' : 'bg-gray-50'}`

## Por que é "simples" de implementar?

É só aplicar o mesmo padrão usado no catálogo para o painel admin:

```jsx
// ANTES (fixo)
<div className="bg-white text-gray-800">

// DEPOIS (condicional)
<div className={`${darkModeAdmin ? 'bg-[#202020] text-white' : 'bg-white text-gray-800'}`}>
```

## Próximos Passos

1. Execute a migration SQL (Passo 1)
2. Modifique App.jsx para aplicar classes condicionais no painel admin
3. Teste alternando os toggles em Configurações → Sistema → Controle de Dark Mode
4. Faça commit e push

## Referência de Cores Dark Mode

```css
/* Padrão Dark Mode Lukaya Griffe */
Background principal: #111111
Background secundário: #202020
Background hover: #333333
Texto: white
Accent: text-yellow-400
Borders: border-gray-700
```
