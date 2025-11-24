# 🔒 Instruções para Corrigir Erro 401 (Unauthorized)

## Problema Identificado

O erro 401 (Unauthorized) que você está vendo ocorre porque as tabelas do Supabase têm **Row Level Security (RLS)** habilitado, mas **não têm políticas configuradas** para permitir acesso público de leitura.

## Solução

Você precisa aplicar as políticas RLS que foram criadas no arquivo `supabase-rls-policies.sql`.

## Como Aplicar as Políticas

### Opção 1: Usando o Supabase Studio (Recomendado)

1. **Acesse o Supabase Studio**
   - Vá para: https://supabase.com/dashboard
   - Faça login na sua conta
   - Selecione o projeto "Lukaya Griffe"

2. **Abra o SQL Editor**
   - No menu lateral esquerdo, clique em **"SQL Editor"**
   - Clique em **"New query"**

3. **Cole o Script SQL**
   - Abra o arquivo `supabase-rls-policies.sql` que foi criado
   - Copie TODO o conteúdo do arquivo
   - Cole no editor SQL do Supabase

4. **Execute o Script**
   - Clique no botão **"Run"** (ou pressione Ctrl+Enter)
   - Aguarde a execução (pode levar alguns segundos)
   - Você deve ver mensagens de sucesso

5. **Verifique as Políticas**
   - Ao final do script, você verá uma lista de todas as políticas criadas
   - Verifique se aparecem políticas para as tabelas:
     - `products`
     - `categories`
     - `banners`
     - `product_views`
     - `settings`
     - `marketplace_settings`

### Opção 2: Usando a CLI do Supabase (Para usuários avançados)

Se você tem a CLI do Supabase instalada:

```bash
supabase db reset --db-url "sua-connection-string" < supabase-rls-policies.sql
```

## O Que as Políticas Fazem

### Para o Catálogo Público (Visitantes não autenticados):
- ✅ **Leitura permitida**: Produtos, Categorias, Banners, Configurações
- ❌ **Escrita bloqueada**: Não podem criar, editar ou deletar nada

### Para Usuários Autenticados (Admin):
- ✅ **Leitura permitida**: Tudo
- ✅ **Escrita permitida**: Produtos, Categorias, Banners, Configurações
- ✅ **Criação permitida**: Novos produtos, categorias, etc.
- ✅ **Exclusão permitida**: Deletar itens

## Testando Após Aplicar

1. **Limpe o cache do navegador**
   - Pressione `Ctrl+Shift+R` (Windows/Linux)
   - Pressione `Cmd+Shift+R` (Mac)

2. **Recarregue a página**
   - Os erros 401 devem desaparecer
   - O catálogo deve carregar normalmente
   - No painel admin (após login), tudo deve funcionar

3. **Verifique o Console do Navegador**
   - Abra o DevTools (F12)
   - Vá na aba "Console"
   - Você deve ver mensagens de sucesso:
     - ✅ Supabase conectado com sucesso!
     - ✅ Retornados: X produtos
     - ✅ Retornadas: Y categorias

## Problemas Comuns

### Ainda vejo erros 401 após aplicar
- Verifique se o script SQL foi executado completamente sem erros
- Limpe o cache do navegador completamente
- Tente fazer logout e login novamente no painel admin

### Erro ao executar o script SQL
- Verifique se você está no projeto correto do Supabase
- Verifique se tem permissões de administrador no projeto
- Tente executar o script em partes menores

### Não consigo acessar o SQL Editor
- Verifique se você é o owner do projeto
- Verifique se seu plano do Supabase permite acesso ao SQL Editor
- Entre em contato com o suporte do Supabase se necessário

## Segurança

As políticas criadas são seguras porque:
- ✅ Leitura pública apenas para dados que devem ser públicos (produtos, categorias)
- ✅ Escrita restrita apenas a usuários autenticados
- ✅ Dados sensíveis (como marketplace_settings) são acessíveis apenas para autenticados
- ✅ Seguem as melhores práticas do Supabase RLS

## Precisa de Ajuda?

Se você continuar tendo problemas após seguir estas instruções:
1. Verifique os logs do console do navegador (F12 → Console)
2. Verifique os logs do Supabase Studio
3. Entre em contato com informações sobre os erros específicos que está vendo
