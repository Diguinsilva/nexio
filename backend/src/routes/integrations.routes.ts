import { Router, Request, Response } from 'express';
import { integrationsService } from '../services/integrations.service';

const router = Router();

// Middleware fictício para obter tenant_id (você deve implementar seu auth)
function getTenantId(req: Request): string {
  // TODO: Extrair tenant_id do JWT do usuário
  return req.headers['x-tenant-id'] as string || 'default-tenant';
}

/**
 * GET /api/integrations
 * Lista todas as integrações configuradas do tenant
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const tenantId = getTenantId(req);
    const integrations = await integrationsService.listTenantIntegrations(tenantId);

    res.status(200).json({
      success: true,
      data: integrations,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/integrations/providers
 * Lista provedores disponíveis para configurar
 */
router.get('/providers', async (req: Request, res: Response) => {
  try {
    const type = req.query.type as string | undefined;
    const providers = await integrationsService.listAvailableProviders(type);

    res.status(200).json({
      success: true,
      data: providers,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/integrations
 * Cria nova integração para o tenant
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const tenantId = getTenantId(req);
    const { provider_slug, name, credentials, set_as_default } = req.body;

    if (!provider_slug || !name || !credentials) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: provider_slug, name, credentials',
      });
    }

    const integration = await integrationsService.createIntegration(
      tenantId,
      provider_slug,
      name,
      credentials,
      set_as_default !== false // default true
    );

    res.status(201).json({
      success: true,
      data: integration,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * PATCH /api/integrations/:id
 * Atualiza integração existente
 */
router.patch('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const integration = await integrationsService.updateIntegration(id, updates);

    res.status(200).json({
      success: true,
      data: integration,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /api/integrations/:id
 * Deleta integração
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await integrationsService.deleteIntegration(id);

    res.status(200).json({
      success: true,
      message: 'Integration deleted',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/integrations/test
 * Testa credenciais antes de salvar
 */
router.post('/test', async (req: Request, res: Response) => {
  try {
    const { provider_slug, credentials } = req.body;

    if (!provider_slug || !credentials) {
      return res.status(400).json({
        success: false,
        error: 'Missing provider_slug or credentials',
      });
    }

    const result = await integrationsService.testIntegration(
      provider_slug,
      credentials
    );

    res.status(200).json({
      success: result.success,
      message: result.message,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

export default router;
