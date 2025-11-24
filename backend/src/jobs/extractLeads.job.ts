import { Job } from 'bullmq';
import { apifyService } from '../services/apify.service';
import { supabaseService } from '../services/supabase.service';
import { logger } from '../utils/logger';

interface ExtractLeadsJobData {
  tenantId: string;
  userId: string;
  url: string;
  limit: number;
  autoEnrich: boolean;
}

/**
 * Processar job de extração de leads do Google Maps via Apify
 */
export async function processExtractLeadsJob(job: Job<ExtractLeadsJobData>) {
  const { tenantId, userId, url, limit, autoEnrich } = job.data;

  logger.info(`[Job ${job.id}] Starting lead extraction from Maps URL: ${url}`);

  try {
    // 1. Atualizar status do job
    await updateJobStatus(job.id as string, tenantId, 'processing', 0);

    // 2. Iniciar extração no Apify
    logger.info(`[Job ${job.id}] Starting Apify actor...`);
    const runId = await apifyService.startGoogleMapsExtraction(url, limit);

    await job.updateProgress(10);

    // 3. Aguardar conclusão do Apify (polling)
    logger.info(`[Job ${job.id}] Waiting for Apify run ${runId} to complete...`);
    const results = await apifyService.waitForRun(runId, (progress) => {
      // Atualizar progresso (10% a 70%)
      job.updateProgress(10 + (progress * 0.6));
    });

    await job.updateProgress(70);

    logger.info(`[Job ${job.id}] Apify extraction completed. Processing ${results.length} leads...`);

    // 4. Processar e inserir leads no banco
    const supabase = supabaseService.getClient();
    const insertedLeads: any[] = [];
    let successCount = 0;
    let failedCount = 0;

    for (let i = 0; i < results.length; i++) {
      const rawLead = results[i];

      try {
        // Transformar dados do Apify para formato do banco
        const leadData = transformApifyResult(rawLead, tenantId, userId);

        // Inserir lead
        const { data, error } = await supabase
          .from('leads')
          .insert(leadData)
          .select()
          .single();

        if (error) {
          logger.warn(`[Job ${job.id}] Error inserting lead ${i + 1}:`, error);
          failedCount++;
        } else {
          insertedLeads.push(data);
          successCount++;
        }

        // Atualizar progresso (70% a 95%)
        const progressPct = 70 + ((i + 1) / results.length) * 25;
        await job.updateProgress(progressPct);
      } catch (error: any) {
        logger.error(`[Job ${job.id}] Error processing lead ${i + 1}:`, error);
        failedCount++;
      }
    }

    // 5. Atualizar status final do job
    await updateJobStatus(
      job.id as string,
      tenantId,
      'completed',
      100,
      {
        total_rows: results.length,
        processed_rows: results.length,
        success_rows: successCount,
        failed_rows: failedCount
      }
    );

    await job.updateProgress(100);

    logger.info(`[Job ${job.id}] Extraction completed: ${successCount} success, ${failedCount} failed`);

    // 6. Se autoEnrich, disparar jobs de enriquecimento
    if (autoEnrich && insertedLeads.length > 0) {
      logger.info(`[Job ${job.id}] Triggering enrichment for ${insertedLeads.length} leads...`);
      const { enrichLeadQueue } = require('./queue');

      for (const lead of insertedLeads) {
        await enrichLeadQueue.add('enrich-lead', {
          leadId: lead.id,
          tenantId
        });
      }
    }

    return {
      success: true,
      totalLeads: results.length,
      successCount,
      failedCount,
      insertedLeads: insertedLeads.map((l) => l.id)
    };
  } catch (error: any) {
    logger.error(`[Job ${job.id}] Fatal error during extraction:`, error);

    // Atualizar status como falha
    await updateJobStatus(job.id as string, tenantId, 'failed', 0, {
      error_message: error.message
    });

    throw error;
  }
}

/**
 * Transformar resultado do Apify para formato do banco
 */
function transformApifyResult(
  apifyResult: any,
  tenantId: string,
  userId: string
): any {
  return {
    tenant_id: tenantId,
    created_by: userId,
    name: apifyResult.title || apifyResult.name || 'Nome não disponível',
    phone: cleanPhone(apifyResult.phone || apifyResult.phoneNumber),
    email: apifyResult.email || null,
    company_name: apifyResult.title || null,
    address: apifyResult.address || apifyResult.fullAddress || null,
    city: extractCity(apifyResult.address || apifyResult.city),
    state: extractState(apifyResult.address || apifyResult.state),
    source: 'maps',
    source_url: apifyResult.url || null,
    score: calculateInitialScore(apifyResult),
    tags: extractTags(apifyResult),
    raw_data: apifyResult, // Salvar dados brutos
    notes: apifyResult.description || null
  };
}

/**
 * Limpar e formatar telefone
 */
function cleanPhone(phone: string | undefined): string | null {
  if (!phone) return null;

  // Remover caracteres não numéricos
  let cleaned = phone.replace(/\D/g, '');

  // Se começar com 0, remover
  if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }

  // Se não começar com +55, adicionar
  if (!cleaned.startsWith('55')) {
    cleaned = '55' + cleaned;
  }

  // Adicionar + no início
  return '+' + cleaned;
}

/**
 * Extrair cidade de endereço
 */
function extractCity(address: string | undefined): string | null {
  if (!address) return null;

  // Lógica simplificada - ajustar conforme formato do Apify
  const parts = address.split(',');
  if (parts.length >= 2) {
    return parts[parts.length - 2].trim();
  }

  return null;
}

/**
 * Extrair estado de endereço
 */
function extractState(address: string | undefined): string | null {
  if (!address) return null;

  // Lógica simplificada
  const stateMatch = address.match(/[A-Z]{2}$/);
  return stateMatch ? stateMatch[0] : null;
}

/**
 * Calcular score inicial baseado em dados disponíveis
 */
function calculateInitialScore(data: any): number {
  let score = 0;

  if (data.phone) score += 30;
  if (data.email) score += 20;
  if (data.website) score += 15;
  if (data.rating && data.rating >= 4) score += 20;
  if (data.reviewsCount && data.reviewsCount >= 10) score += 15;

  return Math.min(score, 100);
}

/**
 * Extrair tags relevantes
 */
function extractTags(data: any): string[] {
  const tags: string[] = [];

  if (data.categoryName) {
    tags.push(data.categoryName);
  }

  if (data.rating) {
    if (data.rating >= 4.5) tags.push('high-rating');
    else if (data.rating < 3) tags.push('low-rating');
  }

  if (data.isAdvertisement) {
    tags.push('sponsored');
  }

  if (data.website) {
    tags.push('has-website');
  }

  return tags;
}

/**
 * Atualizar status do import_job
 */
async function updateJobStatus(
  jobId: string,
  tenantId: string,
  status: string,
  progress: number,
  extra: any = {}
) {
  const supabase = supabaseService.getClient();

  await supabase
    .from('import_jobs')
    .update({
      status,
      ...extra,
      ...(status === 'processing' && !extra.started_at
        ? { started_at: new Date().toISOString() }
        : {}),
      ...(status === 'completed' || status === 'failed'
        ? { completed_at: new Date().toISOString() }
        : {})
    })
    .eq('id', jobId)
    .eq('tenant_id', tenantId);
}
