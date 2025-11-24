// Edge Function para chamar webhook n8n sem problemas de CORS
// Suporta múltiplos webhooks configurados
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WebhookResult {
  id?: string
  name: string
  url: string
  success: boolean
  status: number
  data?: any
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { payload, webhook_url, webhook_secret, webhook_id } = await req.json()

    // Criar cliente Supabase com autenticação do usuário
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Caso 1: Testar um webhook específico (webhook_url passado no request)
    if (webhook_url) {
      return await callSingleWebhook(webhook_url, webhook_secret, payload, null, supabaseClient)
    }

    // Caso 2: Testar um webhook específico por ID
    if (webhook_id) {
      console.log('🔍 Buscando webhook com ID:', webhook_id)

      const { data: webhook, error: webhookError } = await supabaseClient
        .from('sdr_webhooks')
        .select('*')
        .eq('id', webhook_id)
        .single()

      console.log('📊 Resultado da busca:', { webhook, error: webhookError })

      if (webhookError) {
        console.error('❌ Erro ao buscar webhook:', webhookError)
        return new Response(
          JSON.stringify({
            error: `Erro ao buscar webhook: ${webhookError.message}`,
            details: webhookError,
            hint: 'Verifique se a tabela sdr_webhooks existe e se as políticas RLS estão corretas'
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (!webhook) {
        console.warn('⚠️ Webhook não encontrado com ID:', webhook_id)
        return new Response(
          JSON.stringify({ error: 'Webhook não encontrado' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      console.log('✅ Webhook encontrado:', webhook.name)
      return await callSingleWebhook(webhook.webhook_url, webhook.webhook_secret, payload, webhook.id, supabaseClient)
    }

    // Caso 3: Chamar todos os webhooks ativos
    const { data: webhooks, error: fetchError } = await supabaseClient
      .from('sdr_webhooks')
      .select('*')
      .eq('enabled', true)
      .order('execution_order', { ascending: true })

    if (fetchError) {
      throw new Error(`Erro ao buscar webhooks: ${fetchError.message}`)
    }

    if (!webhooks || webhooks.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'Nenhum webhook ativo configurado',
          success: false
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Chamar todos os webhooks em paralelo
    const results: WebhookResult[] = await Promise.all(
      webhooks.map(async (webhook) => {
        try {
          const response = await fetch(webhook.webhook_url, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              ...(webhook.webhook_secret && { 'X-Webhook-Secret': webhook.webhook_secret })
            },
            body: JSON.stringify(payload)
          })

          let responseData
          try {
            responseData = await response.json()
          } catch {
            responseData = await response.text()
          }

          const success = response.ok
          const error = success ? null : `HTTP ${response.status}: ${response.statusText}`

          // Atualizar status do webhook
          await supabaseClient
            .from('sdr_webhooks')
            .update({
              last_call: new Date().toISOString(),
              last_status: success ? 'success' : 'error',
              last_error: error,
              updated_at: new Date().toISOString()
            })
            .eq('id', webhook.id)

          return {
            id: webhook.id,
            name: webhook.name,
            url: webhook.webhook_url,
            success,
            status: response.status,
            data: responseData,
            error
          }
        } catch (error) {
          // Atualizar status com erro de conexão
          await supabaseClient
            .from('sdr_webhooks')
            .update({
              last_call: new Date().toISOString(),
              last_status: 'error',
              last_error: error.message,
              updated_at: new Date().toISOString()
            })
            .eq('id', webhook.id)

          return {
            id: webhook.id,
            name: webhook.name,
            url: webhook.webhook_url,
            success: false,
            status: 0,
            error: error.message
          }
        }
      })
    )

    // Verificar se pelo menos um webhook teve sucesso
    const hasSuccess = results.some(r => r.success)
    const allSuccess = results.every(r => r.success)

    return new Response(
      JSON.stringify({
        success: hasSuccess,
        all_success: allSuccess,
        total: results.length,
        succeeded: results.filter(r => r.success).length,
        failed: results.filter(r => !r.success).length,
        results
      }),
      {
        status: hasSuccess ? 200 : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Erro:', error)

    return new Response(
      JSON.stringify({
        error: error.message,
        success: false
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Função auxiliar para chamar um webhook único e atualizar status
async function callSingleWebhook(
  url: string,
  secret: string | null,
  payload: any,
  webhookId: string | null,
  supabaseClient: any
) {
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(secret && { 'X-Webhook-Secret': secret })
      },
      body: JSON.stringify(payload)
    })

    let responseData
    try {
      responseData = await response.json()
    } catch {
      responseData = await response.text()
    }

    const success = response.ok
    const error = success ? null : `HTTP ${response.status}: ${response.statusText}`

    // Atualizar status no banco se tiver ID
    if (webhookId) {
      await supabaseClient
        .from('sdr_webhooks')
        .update({
          last_call: new Date().toISOString(),
          last_status: success ? 'success' : 'error',
          last_error: error,
          updated_at: new Date().toISOString()
        })
        .eq('id', webhookId)
    }

    return new Response(
      JSON.stringify({
        success,
        status: response.status,
        data: responseData,
        error
      }),
      {
        status: response.ok ? 200 : response.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    // Atualizar status com erro de conexão
    if (webhookId) {
      await supabaseClient
        .from('sdr_webhooks')
        .update({
          last_call: new Date().toISOString(),
          last_status: 'error',
          last_error: error.message,
          updated_at: new Date().toISOString()
        })
        .eq('id', webhookId)
    }

    return new Response(
      JSON.stringify({
        error: error.message,
        success: false
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}
