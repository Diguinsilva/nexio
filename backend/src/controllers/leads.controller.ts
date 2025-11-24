import { Request, Response } from 'express';
import { supabaseService } from '../services/supabase.service';
import { apifyService } from '../services/apify.service';
import { enrichmentService } from '../services/enrichment.service';
import { extractLeadsQueue, enrichLeadQueue } from '../jobs/queue';
import { logger } from '../utils/logger';

/**
 * GET /api/leads
 * Buscar leads com filtros
 */
export async function searchLeads(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const { search, stage, source, minScore, tags, limit, offset } = req.query;

    const supabase = supabaseService.getClient();

    let query = supabase
      .from('leads')
      .select('*')
      .eq('tenant_id', tenantId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(Number(offset) || 0, (Number(offset) || 0) + (Number(limit) || 50) - 1);

    if (search) {
      query = query.or(`name.ilike.%${search}%,phone.ilike.%${search}%,email.ilike.%${search}%,company_name.ilike.%${search}%`);
    }

    if (stage) {
      query = query.eq('stage', stage);
    }

    if (source) {
      query = query.eq('source', source);
    }

    if (minScore) {
      query = query.gte('score', Number(minScore));
    }

    if (tags && Array.isArray(tags)) {
      query = query.contains('tags', tags);
    }

    const { data, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data,
      pagination: {
        total: count,
        limit: Number(limit) || 50,
        offset: Number(offset) || 0
      }
    });
  } catch (error: any) {
    logger.error('Error searching leads:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao buscar leads',
      message: error.message
    });
  }
}

/**
 * GET /api/leads/:id
 * Obter detalhes completos de um lead
 */
export async function getLeadById(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const tenantId = req.user!.tenantId;

    const supabase = supabaseService.getClient();

    // Buscar lead
    const { data: lead, error: leadError } = await supabase
      .from('leads')
      .select('*')
      .eq('id', id)
      .eq('tenant_id', tenantId)
      .single();

    if (leadError) throw leadError;

    if (!lead) {
      return res.status(404).json({
        success: false,
        error: 'Lead não encontrado'
      });
    }

    // Buscar conversas do lead
    const { data: conversations, error: convError } = await supabase
      .from('conversations')
      .select('*')
      .eq('lead_id', id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (convError) logger.warn('Error fetching conversations:', convError);

    // Buscar tarefas do lead
    const { data: tasks, error: tasksError } = await supabase
      .from('tasks')
      .select('*')
      .eq('lead_id', id)
      .order('due_date', { ascending: true });

    if (tasksError) logger.warn('Error fetching tasks:', tasksError);

    res.json({
      success: true,
      data: {
        ...lead,
        conversations: conversations || [],
        tasks: tasks || []
      }
    });
  } catch (error: any) {
    logger.error('Error getting lead:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao buscar lead',
      message: error.message
    });
  }
}

/**
 * POST /api/leads
 * Criar lead manualmente
 */
export async function createLead(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const userId = req.user!.id;
    const leadData = req.body;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .from('leads')
      .insert({
        ...leadData,
        tenant_id: tenantId,
        created_by: userId
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      data
    });
  } catch (error: any) {
    logger.error('Error creating lead:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao criar lead',
      message: error.message
    });
  }
}

/**
 * PATCH /api/leads/:id
 * Atualizar lead
 */
export async function updateLead(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const tenantId = req.user!.tenantId;
    const updates = req.body;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .from('leads')
      .update(updates)
      .eq('id', id)
      .eq('tenant_id', tenantId)
      .select()
      .single();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Lead não encontrado'
      });
    }

    res.json({
      success: true,
      data
    });
  } catch (error: any) {
    logger.error('Error updating lead:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao atualizar lead',
      message: error.message
    });
  }
}

/**
 * DELETE /api/leads/:id
 * Soft delete de lead
 */
export async function deleteLead(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const tenantId = req.user!.tenantId;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .from('leads')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
      .eq('tenant_id', tenantId)
      .select()
      .single();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Lead não encontrado'
      });
    }

    res.json({
      success: true,
      message: 'Lead deletado com sucesso'
    });
  } catch (error: any) {
    logger.error('Error deleting lead:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao deletar lead',
      message: error.message
    });
  }
}

/**
 * POST /api/leads/extract
 * Extrair leads de URL do Google Maps via Apify
 */
export async function extractLeadsFromMaps(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const userId = req.user!.id;
    const { url, limit, autoEnrich } = req.body;

    logger.info(`Starting lead extraction from Maps URL: ${url}`);

    // Criar job de extração no BullMQ
    const job = await extractLeadsQueue.add('extract-maps-leads', {
      tenantId,
      userId,
      url,
      limit,
      autoEnrich
    });

    // Registrar job no banco
    const supabase = supabaseService.getClient();
    await supabase.from('import_jobs').insert({
      id: job.id,
      tenant_id: tenantId,
      created_by: userId,
      file_name: `Maps: ${url}`,
      file_url: url,
      status: 'pending',
      total_rows: limit,
      metadata: { type: 'maps_extraction', url, limit }
    });

    res.status(202).json({
      success: true,
      message: 'Extração iniciada com sucesso',
      jobId: job.id,
      estimatedTime: `${Math.ceil(limit / 10)} minutos`
    });
  } catch (error: any) {
    logger.error('Error starting lead extraction:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao iniciar extração de leads',
      message: error.message
    });
  }
}

/**
 * GET /api/leads/extract/:jobId
 * Verificar status de extração
 */
export async function getExtractionStatus(req: Request, res: Response) {
  try {
    const { jobId } = req.params;
    const tenantId = req.user!.tenantId;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .from('import_jobs')
      .select('*')
      .eq('id', jobId)
      .eq('tenant_id', tenantId)
      .single();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Job não encontrado'
      });
    }

    // Buscar job no BullMQ para informações em tempo real
    const job = await extractLeadsQueue.getJob(jobId);
    const state = await job?.getState();
    const progress = await job?.progress;

    res.json({
      success: true,
      data: {
        ...data,
        state,
        progress
      }
    });
  } catch (error: any) {
    logger.error('Error getting extraction status:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao buscar status da extração',
      message: error.message
    });
  }
}

/**
 * POST /api/leads/import
 * Importar leads de CSV
 */
export async function importLeadsFromCsv(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const userId = req.user!.id;
    const { file_url, mapping, deduplicateBy } = req.body;

    // TODO: Implementar importação de CSV
    // Similar ao extractLeadsFromMaps, mas processando CSV

    res.status(501).json({
      success: false,
      error: 'Funcionalidade em desenvolvimento'
    });
  } catch (error: any) {
    logger.error('Error importing CSV:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao importar CSV',
      message: error.message
    });
  }
}

/**
 * GET /api/leads/import/:jobId
 * Status de importação CSV
 */
export async function getImportStatus(req: Request, res: Response) {
  // Similar ao getExtractionStatus
  return getExtractionStatus(req, res);
}

/**
 * POST /api/leads/bulk/move
 * Mover múltiplos leads de stage
 */
export async function bulkMoveLeads(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const { leadIds, newStage } = req.body;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .from('leads')
      .update({ stage: newStage })
      .in('id', leadIds)
      .eq('tenant_id', tenantId)
      .select();

    if (error) throw error;

    res.json({
      success: true,
      message: `${data.length} leads movidos para ${newStage}`,
      data
    });
  } catch (error: any) {
    logger.error('Error bulk moving leads:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao mover leads',
      message: error.message
    });
  }
}

/**
 * POST /api/leads/bulk/delete
 * Deletar múltiplos leads
 */
export async function bulkDeleteLeads(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const { leadIds } = req.body;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .from('leads')
      .update({ deleted_at: new Date().toISOString() })
      .in('id', leadIds)
      .eq('tenant_id', tenantId)
      .select();

    if (error) throw error;

    res.json({
      success: true,
      message: `${data.length} leads deletados`,
      data
    });
  } catch (error: any) {
    logger.error('Error bulk deleting leads:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao deletar leads',
      message: error.message
    });
  }
}

/**
 * GET /api/leads/export/csv
 * Exportar leads para CSV
 */
export async function exportLeadsToCsv(req: Request, res: Response) {
  try {
    const tenantId = req.user!.tenantId;
    const { stage } = req.query;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .rpc('export_leads_csv', {
        p_tenant_id: tenantId,
        p_stage: stage as string || null
      });

    if (error) throw error;

    // Converter para CSV
    const csv = [
      'Name,Phone,Email,Company,City,State,Score,Stage,Created At',
      ...data.map((row: any) =>
        `"${row.name}","${row.phone || ''}","${row.email || ''}","${row.company_name || ''}","${row.city || ''}","${row.state || ''}",${row.score},"${row.stage}","${row.created_at}"`
      )
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="leads-${Date.now()}.csv"`);
    res.send(csv);
  } catch (error: any) {
    logger.error('Error exporting CSV:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao exportar CSV',
      message: error.message
    });
  }
}

/**
 * POST /api/leads/:id/enrich
 * Enriquecer lead manualmente
 */
export async function enrichLead(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const tenantId = req.user!.tenantId;

    // Adicionar job de enriquecimento
    const job = await enrichLeadQueue.add('enrich-lead', {
      leadId: id,
      tenantId
    });

    res.status(202).json({
      success: true,
      message: 'Enriquecimento iniciado',
      jobId: job.id
    });
  } catch (error: any) {
    logger.error('Error enriching lead:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao enriquecer lead',
      message: error.message
    });
  }
}

/**
 * POST /api/leads/:id/calculate-icp
 * Calcular ICP match score
 */
export async function calculateIcpMatch(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const tenantId = req.user!.tenantId;

    const supabase = supabaseService.getClient();

    const { data, error } = await supabase
      .rpc('calculate_icp_match', {
        p_lead_id: id
      });

    if (error) throw error;

    res.json({
      success: true,
      data
    });
  } catch (error: any) {
    logger.error('Error calculating ICP match:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao calcular ICP match',
      message: error.message
    });
  }
}
