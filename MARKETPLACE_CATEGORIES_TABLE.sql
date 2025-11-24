-- =====================================================
-- TABELA PARA SINCRONIZAÇÃO DE CATEGORIAS COM MARKETPLACES
-- Sistema: Lucaya Griffe E-commerce
-- =====================================================

-- Tabela de mapeamento: categorias locais <-> marketplaces
CREATE TABLE IF NOT EXISTS marketplace_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- Categoria local
  local_category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,

  -- Marketplace
  marketplace VARCHAR(50) NOT NULL,
  marketplace_category_id VARCHAR(255) NOT NULL, -- ID no marketplace
  marketplace_url TEXT, -- Link da categoria no marketplace

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_published BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE,
  sync_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'synced', 'error', 'disabled'
  last_error TEXT,

  -- Metadados
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(local_category_id, marketplace),
  UNIQUE(marketplace, marketplace_category_id)
);

-- Índices para performance
CREATE INDEX idx_marketplace_categories_local ON marketplace_categories(local_category_id);
CREATE INDEX idx_marketplace_categories_marketplace ON marketplace_categories(marketplace, marketplace_category_id);
CREATE INDEX idx_marketplace_categories_sync_status ON marketplace_categories(sync_status);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_marketplace_categories_updated_at
    BEFORE UPDATE ON marketplace_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE marketplace_categories ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Todos podem ver categorias de marketplace" ON marketplace_categories
    FOR SELECT USING (true);

CREATE POLICY "Admins podem gerenciar categorias de marketplace" ON marketplace_categories
    FOR ALL USING (auth.role() = 'authenticated');

-- Atualizar tabela de logs para suportar categorias
-- Adicionar colunas opcionais para categorias no log
ALTER TABLE marketplace_sync_log
  ADD COLUMN IF NOT EXISTS local_category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS marketplace_category_id VARCHAR(255);

-- Índice para logs de categorias
CREATE INDEX IF NOT EXISTS idx_sync_log_category ON marketplace_sync_log(local_category_id);

-- =====================================================
-- FIM DO SCRIPT
-- Execute este script no SQL Editor do Supabase
-- =====================================================
