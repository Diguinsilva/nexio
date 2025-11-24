import { Router } from 'express';
import * as leadsController from '../controllers/leads.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { validateMiddleware } from '../middleware/validate.middleware';
import { z } from 'zod';

const router = Router();

// Todas as rotas requerem autenticação
router.use(authMiddleware);

// Schemas de validação
const extractLeadsSchema = z.object({
  url: z.string().url('URL inválida'),
  limit: z.number().int().min(1).max(500).default(50),
  autoEnrich: z.boolean().default(true)
});

const createLeadSchema = z.object({
  name: z.string().min(1),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  company_name: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  address: z.string().optional(),
  age: z.number().int().optional(),
  income_estimate: z.number().optional(),
  tags: z.array(z.string()).optional(),
  notes: z.string().optional(),
  source: z.enum(['manual', 'maps', 'csv', 'api', 'n8n']).default('manual')
});

const updateLeadSchema = z.object({
  name: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  company_name: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  stage: z.enum(['new', 'contacted', 'qualified', 'proposal', 'closed_won', 'closed_lost', 'descartado']).optional(),
  status: z.enum(['active', 'archived', 'deleted']).optional(),
  tags: z.array(z.string()).optional(),
  notes: z.string().optional(),
  score: z.number().int().min(0).max(100).optional()
});

const searchLeadsSchema = z.object({
  search: z.string().optional(),
  stage: z.string().optional(),
  source: z.string().optional(),
  minScore: z.number().int().min(0).max(100).optional(),
  tags: z.array(z.string()).optional(),
  limit: z.number().int().min(1).max(100).default(50),
  offset: z.number().int().min(0).default(0)
});

const importCsvSchema = z.object({
  file_url: z.string().url(),
  mapping: z.record(z.string()),
  deduplicateBy: z.enum(['phone', 'email', 'cnpj']).optional()
});

// ==================== ROTAS ====================

/**
 * GET /api/leads
 * Lista leads com filtros
 */
router.get(
  '/',
  validateMiddleware(searchLeadsSchema, 'query'),
  leadsController.searchLeads
);

/**
 * GET /api/leads/:id
 * Obter detalhes de um lead
 */
router.get('/:id', leadsController.getLeadById);

/**
 * POST /api/leads
 * Criar lead manualmente
 */
router.post(
  '/',
  validateMiddleware(createLeadSchema, 'body'),
  leadsController.createLead
);

/**
 * PATCH /api/leads/:id
 * Atualizar lead
 */
router.patch(
  '/:id',
  validateMiddleware(updateLeadSchema, 'body'),
  leadsController.updateLead
);

/**
 * DELETE /api/leads/:id
 * Deletar lead (soft delete)
 */
router.delete('/:id', leadsController.deleteLead);

/**
 * POST /api/leads/extract
 * Extrair leads de URL do Google Maps via Apify
 */
router.post(
  '/extract',
  validateMiddleware(extractLeadsSchema, 'body'),
  leadsController.extractLeadsFromMaps
);

/**
 * GET /api/leads/extract/:jobId
 * Verificar status de extração
 */
router.get('/extract/:jobId', leadsController.getExtractionStatus);

/**
 * POST /api/leads/import
 * Importar leads de CSV/Excel
 */
router.post(
  '/import',
  validateMiddleware(importCsvSchema, 'body'),
  leadsController.importLeadsFromCsv
);

/**
 * GET /api/leads/import/:jobId
 * Verificar status de importação
 */
router.get('/import/:jobId', leadsController.getImportStatus);

/**
 * POST /api/leads/bulk/move
 * Mover múltiplos leads de stage
 */
router.post('/bulk/move', leadsController.bulkMoveLeads);

/**
 * POST /api/leads/bulk/delete
 * Deletar múltiplos leads
 */
router.post('/bulk/delete', leadsController.bulkDeleteLeads);

/**
 * GET /api/leads/export/csv
 * Exportar leads para CSV
 */
router.get('/export/csv', leadsController.exportLeadsToCsv);

/**
 * POST /api/leads/:id/enrich
 * Enriquecer lead manualmente
 */
router.post('/:id/enrich', leadsController.enrichLead);

/**
 * POST /api/leads/:id/calculate-icp
 * Calcular ICP match score
 */
router.post('/:id/calculate-icp', leadsController.calculateIcpMatch);

export default router;
