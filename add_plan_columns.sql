-- SQL para adicionar colunas de plano na tabela companies
-- Execute este script no Supabase SQL Editor

ALTER TABLE companies
ADD COLUMN IF NOT EXISTS plan_type VARCHAR(50) DEFAULT 'Performance',
ADD COLUMN IF NOT EXISTS plan_monthly_limit INTEGER DEFAULT 70;

-- Comentários para referência:
-- plan_type: 'Performance' (70 leads/mês) ou 'Avançado' (115 leads/mês)
-- plan_monthly_limit: 70 ou 115

-- Exemplo de atualização de plano para uma empresa:
-- UPDATE companies SET plan_type = 'Avançado', plan_monthly_limit = 115 WHERE id = 1;
