import { useState } from 'react';
import type { Lead } from '@/types/lead';

interface LeadCardProps {
  lead: Lead;
  onView?: (id: string) => void;
  onMove?: (id: string, newStage: string) => void;
  draggable?: boolean;
}

export default function LeadCard({ lead, onView, onMove, draggable = false }: LeadCardProps) {
  const [isDragging, setIsDragging] = useState(false);

  const handleDragStart = (e: React.DragEvent) => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('leadId', lead.id);
    setIsDragging(true);
  };

  const handleDragEnd = () => {
    setIsDragging(false);
  };

  const getScoreColor = (score: number) => {
    if (score >= 70) return 'var(--color-success)';
    if (score >= 40) return 'var(--color-warning)';
    return 'var(--color-error)';
  };

  const getStageLabel = (stage: string) => {
    const labels: Record<string, string> = {
      new: 'Novo',
      contacted: 'Contatado',
      qualified: 'Qualificado',
      proposal: 'Proposta',
      closed_won: 'Ganho',
      closed_lost: 'Perdido',
      descartado: 'Descartado'
    };
    return labels[stage] || stage;
  };

  return (
    <div
      className={`lead-card ${isDragging ? 'dragging' : ''}`}
      draggable={draggable}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onClick={() => onView?.(lead.id)}
    >
      {/* Header */}
      <div className="lead-card-header">
        <div className="lead-info">
          <h3 className="lead-name">{lead.name}</h3>
          {lead.company_name && <p className="lead-company">{lead.company_name}</p>}
        </div>
        <div
          className="lead-score"
          style={{ borderColor: getScoreColor(lead.score) }}
        >
          <span style={{ color: getScoreColor(lead.score) }}>{lead.score}</span>
        </div>
      </div>

      {/* Body */}
      <div className="lead-card-body">
        {lead.phone && (
          <div className="lead-detail">
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
            </svg>
            <span>{lead.phone}</span>
          </div>
        )}

        {lead.email && (
          <div className="lead-detail">
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
              <polyline points="22,6 12,13 2,6" />
            </svg>
            <span className="truncate">{lead.email}</span>
          </div>
        )}

        {lead.city && (
          <div className="lead-detail">
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
            <span>{lead.city}{lead.state ? `, ${lead.state}` : ''}</span>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="lead-card-footer">
        {/* Tags */}
        {lead.tags && lead.tags.length > 0 && (
          <div className="lead-tags">
            {lead.tags.slice(0, 2).map((tag, idx) => (
              <span key={idx} className="badge badge-primary">
                {tag}
              </span>
            ))}
            {lead.tags.length > 2 && (
              <span className="badge">+{lead.tags.length - 2}</span>
            )}
          </div>
        )}

        {/* Source badge */}
        <div className="lead-source">
          <span className="badge">{lead.source}</span>
        </div>
      </div>

      {/* ICP Match (se disponível) */}
      {lead.icp_match_score !== undefined && lead.icp_match_score > 0 && (
        <div className="lead-icp-match">
          <div className="icp-progress-bar">
            <div
              className="icp-progress-fill"
              style={{
                width: `${lead.icp_match_score}%`,
                background: `linear-gradient(90deg, ${getScoreColor(lead.icp_match_score)} 0%, var(--color-primary) 100%)`
              }}
            />
          </div>
          <p className="icp-match-text">
            ICP Match: {lead.icp_match_score}%
          </p>
        </div>
      )}
    </div>
  );
}
