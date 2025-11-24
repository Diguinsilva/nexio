export type LeadStage =
  | 'new'
  | 'contacted'
  | 'qualified'
  | 'proposal'
  | 'closed_won'
  | 'closed_lost'
  | 'descartado';

export type LeadStatus = 'active' | 'archived' | 'deleted';

export type LeadSource = 'manual' | 'maps' | 'csv' | 'api' | 'n8n';

export interface Lead {
  id: string;
  tenant_id: string;
  created_by?: string;

  // Dados básicos
  name: string;
  phone?: string;
  email?: string;
  company_name?: string;

  // Localização
  city?: string;
  state?: string;
  address?: string;

  // Dados adicionais
  age?: number;
  income_estimate?: number;
  score: number;

  // Origem e classificação
  source: LeadSource;
  source_url?: string;
  stage: LeadStage;
  status: LeadStatus;

  // Tags e notas
  tags: string[];
  notes?: string;

  // Dados brutos
  raw_data?: Record<string, any>;
  enrichment_data?: Record<string, any>;

  // ICP Match
  icp_match_score?: number;
  icp_match_reason?: string;

  // Timestamps
  created_at: string;
  updated_at: string;
  last_contact_at?: string;
  deleted_at?: string;
}

export interface LeadWithRelations extends Lead {
  conversations?: Conversation[];
  tasks?: Task[];
}

export interface Conversation {
  id: string;
  tenant_id: string;
  lead_id: string;
  user_id?: string;

  message?: string;
  message_type: 'text' | 'audio' | 'image' | 'video' | 'document' | 'system';
  direction: 'in' | 'out';

  media_url?: string;
  media_size?: number;
  media_duration?: number;

  transcript?: string;
  transcript_confidence?: number;

  whatsapp_message_id?: string;
  status: 'sent' | 'delivered' | 'read' | 'failed';
  metadata?: Record<string, any>;

  created_at: string;
  sent_at?: string;
  delivered_at?: string;
  read_at?: string;
}

export interface Task {
  id: string;
  tenant_id: string;
  lead_id: string;
  assigned_to?: string;
  created_by?: string;

  title: string;
  description?: string;
  type: 'follow_up' | 'call' | 'email' | 'proposal' | 'meeting' | 'other';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'in_progress' | 'completed' | 'cancelled';

  due_date?: string;
  completed_at?: string;
  created_at: string;
  updated_at: string;
}

export interface ImportJob {
  id: string;
  tenant_id: string;
  created_by?: string;

  file_name?: string;
  file_url?: string;
  file_size?: number;

  status: 'pending' | 'processing' | 'completed' | 'failed';

  total_rows: number;
  processed_rows: number;
  success_rows: number;
  failed_rows: number;

  mapping?: Record<string, string>;
  errors?: any[];

  started_at?: string;
  completed_at?: string;
  created_at: string;
}

export interface DashboardStats {
  total_leads: number;
  leads_today: number;
  leads_this_week: number;
  leads_this_month: number;
  by_stage: Record<LeadStage, number>;
  by_source: Record<LeadSource, number>;
  avg_score: number;
  high_score_leads: number;
  conversion_rate: number;
}

export interface LeadFilters {
  search?: string;
  stage?: LeadStage;
  source?: LeadSource;
  minScore?: number;
  tags?: string[];
  city?: string;
  limit?: number;
  offset?: number;
}

export interface CreateLeadInput {
  name: string;
  phone?: string;
  email?: string;
  company_name?: string;
  city?: string;
  state?: string;
  address?: string;
  age?: number;
  income_estimate?: number;
  tags?: string[];
  notes?: string;
  source?: LeadSource;
}

export interface UpdateLeadInput {
  name?: string;
  phone?: string;
  email?: string;
  company_name?: string;
  city?: string;
  state?: string;
  stage?: LeadStage;
  status?: LeadStatus;
  tags?: string[];
  notes?: string;
  score?: number;
}

export interface ExtractLeadsInput {
  url: string;
  limit: number;
  autoEnrich?: boolean;
}
