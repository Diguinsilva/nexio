import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { toast } from 'react-toastify';
import {
  DndContext,
  DragOverlay,
  closestCorners,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  useDroppable,
} from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates } from '@dnd-kit/sortable';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import {
  UserPlus,
  Send,
  MessageCircle,
  CheckCircle,
  XCircle,
  Plus,
  Phone,
  Mail,
  Calendar,
  DollarSign,
  Tag,
  MoreVertical,
  Trash2,
  Edit,
  Eye,
  GripVertical
} from 'lucide-react';

// Mapeamento de ícones
const iconMap = {
  UserPlus,
  Send,
  MessageCircle,
  CheckCircle,
  XCircle
};

// Componente de Card de Lead (Draggable)
const LeadCard = ({ lead, onEdit, onDelete, onView }) => {
  const [showMenu, setShowMenu] = useState(false);

  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: lead.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  const isOverdue = lead.next_followup_date && new Date(lead.next_followup_date) < new Date();

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`bg-white dark:bg-[#111111] rounded-xl shadow-md p-4 mb-3 hover:shadow-2xl transition-all border-l-4 border-2 group ${
        isOverdue ? 'border-l-red-500 border-red-200 dark:border-red-400 dark:border-red-800' : 'border-l-blue-500 border-blue-200 dark:border-blue-400 dark:border-blue-800'
      } ${isDragging ? 'shadow-2xl ring-4 ring-blue-300 dark:ring-blue-600 bg-blue-50 dark:bg-blue-900/20' : ''}`}
    >
      <div className="flex items-start justify-between mb-3">
        <div
          {...attributes}
          {...listeners}
          className="cursor-move p-1 hover:bg-gray-100 dark:hover:bg-[#333333] rounded transition-colors flex-shrink-0 mr-2"
          title="Arraste para mover"
        >
          <GripVertical className="w-5 h-5 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300" />
        </div>
        <div className="flex-1 min-w-0">
          <h4 className="font-bold text-gray-900 dark:text-white text-base mb-1 truncate">{lead.name}</h4>
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-400">
              <Phone className="w-3.5 h-3.5 text-blue-500 dark:text-blue-400" />
              <span className="truncate">{lead.phone}</span>
            </div>
            {lead.email && (
              <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-400">
                <Mail className="w-3.5 h-3.5 text-blue-500 dark:text-blue-400" />
                <span className="truncate">{lead.email}</span>
              </div>
            )}
          </div>
        </div>
        <div className="relative ml-2">
          <button
            onClick={(e) => {
              e.stopPropagation();
              console.log('Menu toggle clicked, current state:', showMenu);
              setShowMenu(!showMenu);
            }}
            className="p-1.5 hover:bg-blue-100 dark:hover:bg-[#333333] rounded-lg transition-colors bg-gray-50 dark:bg-[#202020] border border-gray-300 dark:border-gray-700"
            type="button"
          >
            <MoreVertical className="w-4 h-4 text-gray-700 dark:text-gray-300" />
          </button>
          {showMenu && (
            <>
              <div
                className="fixed inset-0 z-[9999]"
                onClick={(e) => {
                  e.stopPropagation();
                  setShowMenu(false);
                }}
              ></div>
              <div className="absolute right-0 top-8 bg-white dark:bg-[#202020] shadow-2xl rounded-lg border-2 border-gray-300 dark:border-gray-700 z-[10000] w-44 overflow-hidden">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    console.log('Ver detalhes clicked');
                    onView(lead);
                    setShowMenu(false);
                  }}
                  className="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-blue-100 dark:hover:bg-blue-900/30 text-gray-800 dark:text-gray-200 transition-colors border-b border-gray-200 dark:border-gray-700"
                  type="button"
                >
                  <Eye className="w-4 h-4 text-blue-600 dark:text-blue-400" />
                  <span>Ver detalhes</span>
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    console.log('Editar clicked');
                    onEdit(lead);
                    setShowMenu(false);
                  }}
                  className="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-green-100 dark:hover:bg-green-900/30 text-gray-800 dark:text-gray-200 transition-colors border-b border-gray-200 dark:border-gray-700"
                  type="button"
                >
                  <Edit className="w-4 h-4 text-green-600 dark:text-green-400" />
                  <span>Editar</span>
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    console.log('Excluir clicked');
                    onDelete(lead.id);
                    setShowMenu(false);
                  }}
                  className="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-red-100 dark:hover:bg-red-900/30 text-red-700 dark:text-red-400 transition-colors"
                  type="button"
                >
                  <Trash2 className="w-4 h-4" />
                  <span>Excluir</span>
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {lead.estimated_value && (
        <div className="flex items-center gap-1.5 text-sm font-bold text-green-600 bg-green-50 px-3 py-2 rounded-lg mt-2">
          <DollarSign className="w-4 h-4" />
          R$ {parseFloat(lead.estimated_value).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </div>
      )}

      {lead.next_followup_date && (
        <div
          className={`flex items-center gap-1.5 text-xs mt-2 px-2 py-1.5 rounded-lg ${
            isOverdue
              ? 'text-red-700 font-semibold bg-red-50'
              : 'text-gray-600 bg-gray-50'
          }`}
        >
          <Calendar className="w-3.5 h-3.5" />
          <span>
            {isOverdue ? '🔴 Atrasado: ' : '📅 Próximo: '}
            {new Date(lead.next_followup_date).toLocaleDateString('pt-BR')}
          </span>
        </div>
      )}

      {lead.tags && lead.tags.length > 0 && (
        <div className="flex flex-wrap gap-1.5 mt-3">
          {lead.tags.map((tag, idx) => (
            <span
              key={idx}
              className="inline-flex items-center gap-1 px-2.5 py-1 bg-gradient-to-r from-blue-100 to-blue-50 text-blue-700 text-xs rounded-full font-medium"
            >
              <Tag className="w-3 h-3" />
              {tag}
            </span>
          ))}
        </div>
      )}

      <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100">
        <div className="flex items-center gap-1 text-xs text-gray-600 bg-gray-50 px-2 py-1 rounded">
          <MessageCircle className="w-3.5 h-3.5" />
          <span className="font-medium">{lead.interactions_count || 0}</span>
        </div>
        <div className="flex items-center gap-1 text-xs text-gray-600 bg-gray-50 px-2 py-1 rounded">
          <Send className="w-3.5 h-3.5" />
          <span className="font-medium">{lead.catalogs_sent_count || 0} catálogos</span>
        </div>
      </div>
    </div>
  );
};

// Componente de Coluna do Kanban
const KanbanColumn = ({ column, leads, onAddLead, onEditLead, onDeleteLead, onViewLead }) => {
  const Icon = iconMap[column.icon] || UserPlus;
  const colorClasses = {
    blue: 'bg-blue-500',
    yellow: 'bg-yellow-500',
    purple: 'bg-purple-500',
    green: 'bg-green-500',
    red: 'bg-red-500',
    gray: 'bg-gray-500',
  };

  const bgColor = colorClasses[column.color] || 'bg-gray-500';

  // Tornar a coluna uma zona de drop
  const { setNodeRef, isOver } = useDroppable({
    id: `column-${column.id}`,
    data: {
      type: 'column',
      columnId: column.id,
    },
  });

  return (
    <div
      ref={setNodeRef}
      className={`flex flex-col h-full bg-gray-50 dark:bg-[#202020] rounded-lg p-4 transition-colors ${
        isOver ? 'bg-blue-50 dark:bg-blue-900/20 ring-2 ring-blue-300 dark:ring-blue-600' : ''
      }`}
    >
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className={`${bgColor} p-2 rounded-lg`}>
            <Icon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-white">{column.name}</h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">{leads.length} leads</p>
          </div>
        </div>
        <button
          onClick={() => onAddLead(column.id)}
          className="p-2 hover:bg-white dark:hover:bg-[#333333] rounded-lg transition-colors"
        >
          <Plus className="w-5 h-5 text-gray-600 dark:text-gray-300" />
        </button>
      </div>

      <SortableContext items={leads.map((l) => l.id)}>
        <div className="flex-1 space-y-2 overflow-y-auto">
          {leads.map((lead) => (
            <LeadCard
              key={lead.id}
              lead={lead}
              onEdit={onEditLead}
              onDelete={onDeleteLead}
              onView={onViewLead}
            />
          ))}
        </div>
      </SortableContext>
    </div>
  );
};

// Componente Principal do Kanban
const LeadsKanban = () => {
  const [columns, setColumns] = useState([]);
  const [leads, setLeads] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeId, setActiveId] = useState(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedColumnId, setSelectedColumnId] = useState(null);
  const [editingLead, setEditingLead] = useState(null);

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      // Carregar colunas
      const { data: columnsData, error: columnsError } = await supabase
        .from('kanban_columns')
        .select('*')
        .eq('is_active', true)
        .order('order_index');

      if (columnsError) throw columnsError;
      setColumns(columnsData || []);

      // Carregar leads
      const { data: leadsData, error: leadsError } = await supabase
        .from('leads')
        .select('*')
        .eq('status', 'active')
        .order('order_in_column');

      if (leadsError) throw leadsError;
      setLeads(leadsData || []);
    } catch (error) {
      console.error('Erro ao carregar dados:', error);
      toast.error('Erro ao carregar Kanban de leads');
    } finally {
      setLoading(false);
    }
  };

  const handleDragStart = (event) => {
    setActiveId(event.active.id);
  };

  const handleDragEnd = async (event) => {
    const { active, over } = event;
    setActiveId(null);

    if (!over) {
      console.log('Drag ended without valid drop target');
      return;
    }

    const activeLeadId = active.id;

    // Determinar o ID da coluna de destino
    let targetColumnId = null;

    // Se o over tem dados de coluna (quando drop na área da coluna)
    if (over.data?.current?.type === 'column') {
      targetColumnId = over.data.current.columnId;
    } else {
      // Se o over é um card, pegar a coluna desse card
      const overLead = leads.find((l) => l.id === over.id);
      if (overLead) {
        targetColumnId = overLead.column_id;
      }
    }

    if (!targetColumnId) {
      console.error('Target column ID not found');
      toast.error('Erro: Coluna de destino não encontrada');
      return;
    }

    // Encontrar o lead arrastado
    const activeLead = leads.find((l) => l.id === activeLeadId);
    if (!activeLead) {
      console.error('Active lead not found');
      toast.error('Erro: Lead não encontrado');
      return;
    }

    // Se não mudou de coluna, não fazer nada
    if (activeLead.column_id === targetColumnId) {
      console.log('Lead already in target column');
      return;
    }

    const targetColumn = columns.find((c) => c.id === targetColumnId);
    if (!targetColumn) {
      console.error('Target column not found');
      toast.error('Erro: Coluna de destino não encontrada');
      return;
    }

    // Atualizar UI otimisticamente
    setLeads((prevLeads) =>
      prevLeads.map((lead) =>
        lead.id === activeLeadId ? { ...lead, column_id: targetColumnId } : lead
      )
    );

    try {
      console.log('Moving lead:', { leadId: activeLeadId, fromColumn: activeLead.column_id, toColumn: targetColumnId });

      // Tentar usar a função RPC primeiro
      const { error: rpcError } = await supabase.rpc('move_lead_to_column', {
        p_lead_id: activeLeadId,
        p_to_column_id: targetColumnId,
      });

      // Se a função RPC não existir, fazer update direto
      if (rpcError && rpcError.code === '42883') {
        console.warn('RPC function not found, using direct update');
        const { error: updateError } = await supabase
          .from('leads')
          .update({
            column_id: targetColumnId,
            last_contact_date: new Date().toISOString()
          })
          .eq('id', activeLeadId);

        if (updateError) throw updateError;
      } else if (rpcError) {
        throw rpcError;
      }

      toast.success(`Lead movido para "${targetColumn.name}"`);
    } catch (error) {
      console.error('Erro ao mover lead:', error);
      toast.error(`Erro ao mover lead: ${error.message || 'Erro desconhecido'}`);

      // Reverter mudança otimista
      setLeads((prevLeads) =>
        prevLeads.map((lead) =>
          lead.id === activeLeadId ? { ...lead, column_id: activeLead.column_id } : lead
        )
      );
    }
  };

  const handleAddLead = (columnId) => {
    setSelectedColumnId(columnId);
    setEditingLead(null);
    setShowAddModal(true);
  };

  const handleEditLead = (lead) => {
    console.log('Editando lead:', lead);
    setEditingLead(lead);
    setSelectedColumnId(lead.column_id);
    setShowAddModal(true);
  };

  const handleDeleteLead = async (leadId) => {
    console.log('Tentando excluir lead:', leadId);
    if (!confirm('Tem certeza que deseja excluir este lead?')) {
      console.log('Exclusão cancelada pelo usuário');
      return;
    }

    try {
      console.log('Enviando requisição de exclusão para o Supabase...');
      const { error } = await supabase.from('leads').delete().eq('id', leadId);

      if (error) {
        console.error('Erro do Supabase ao excluir:', error);
        throw error;
      }

      console.log('Lead excluído com sucesso no banco');
      setLeads((prev) => prev.filter((l) => l.id !== leadId));
      toast.success('Lead excluído com sucesso');
    } catch (error) {
      console.error('Erro ao excluir lead:', error);
      toast.error(`Erro ao excluir lead: ${error.message || 'Erro desconhecido'}`);
    }
  };

  const handleViewLead = (lead) => {
    console.log('Visualizando lead:', lead);
    // Abrir modal de edição em modo somente leitura
    setEditingLead({ ...lead, viewOnly: true });
    setShowAddModal(true);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-yellow-500"></div>
      </div>
    );
  }

  return (
    <div className="p-6 h-full flex flex-col">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Pipeline de Leads</h2>
        <p className="text-gray-600 dark:text-gray-400 mt-1">Arraste e solte os leads entre as colunas</p>
      </div>

      <DndContext
        sensors={sensors}
        collisionDetection={closestCorners}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 flex-1">
          {columns.map((column) => {
            const columnLeads = leads.filter((lead) => lead.column_id === column.id);
            return (
              <KanbanColumn
                key={column.id}
                column={column}
                leads={columnLeads}
                onAddLead={handleAddLead}
                onEditLead={handleEditLead}
                onDeleteLead={handleDeleteLead}
                onViewLead={handleViewLead}
              />
            );
          })}
        </div>

        <DragOverlay>
          {activeId ? (
            (() => {
              const draggedLead = leads.find((l) => l.id === activeId);
              return draggedLead ? (
                <div className="bg-white rounded-xl shadow-2xl p-4 opacity-95 border-l-4 border-blue-500 border-2 border-blue-300 transform scale-105 ring-4 ring-blue-200">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <h4 className="font-bold text-gray-900 text-base">{draggedLead.name}</h4>
                      <div className="flex items-center gap-2 text-xs text-gray-600 mt-1">
                        <Phone className="w-3.5 h-3.5 text-blue-500" />
                        <span>{draggedLead.phone}</span>
                      </div>
                    </div>
                  </div>
                  {draggedLead.estimated_value && (
                    <div className="flex items-center gap-1.5 text-sm font-bold text-green-600 bg-green-50 px-3 py-2 rounded-lg mt-2">
                      <DollarSign className="w-4 h-4" />
                      R$ {parseFloat(draggedLead.estimated_value).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                    </div>
                  )}
                </div>
              ) : (
                <div className="bg-blue-500 text-white rounded-lg shadow-2xl p-4 opacity-90 font-semibold">
                  Movendo lead...
                </div>
              );
            })()
          ) : null}
        </DragOverlay>
      </DndContext>

      {/* Modal de adicionar/editar lead */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-[#202020] rounded-lg p-4 sm:p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg sm:text-xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
              {editingLead?.viewOnly ? 'Visualizar Lead' : editingLead ? 'Editar Lead' : 'Novo Lead'}
            </h3>

            <form
              onSubmit={async (e) => {
                e.preventDefault();
                const formData = new FormData(e.target);

                const leadData = {
                  name: formData.get('name'),
                  phone: formData.get('phone'),
                  email: formData.get('email') || null,
                  company: formData.get('company') || null,
                  estimated_value: parseFloat(formData.get('estimated_value')) || null,
                  source: formData.get('source') || null,
                  notes: formData.get('notes') || null,
                  next_followup_date: formData.get('next_followup_date') || null,
                  column_id: editingLead ? editingLead.column_id : selectedColumnId,
                  status: 'active',
                };

                try {
                  if (editingLead) {
                    // Atualizar lead existente
                    const { error } = await supabase
                      .from('leads')
                      .update(leadData)
                      .eq('id', editingLead.id);

                    if (error) throw error;

                    setLeads((prev) =>
                      prev.map((l) => (l.id === editingLead.id ? { ...l, ...leadData } : l))
                    );
                    toast.success('Lead atualizado com sucesso!');
                  } else {
                    // Criar novo lead
                    const { data, error } = await supabase
                      .from('leads')
                      .insert([leadData])
                      .select()
                      .single();

                    if (error) throw error;

                    setLeads((prev) => [...prev, data]);
                    toast.success('Lead criado com sucesso!');
                  }

                  setShowAddModal(false);
                  setEditingLead(null);
                } catch (error) {
                  console.error('Erro ao salvar lead:', error);
                  toast.error('Erro ao salvar lead');
                }
              }}
              className="space-y-4"
            >
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Nome */}
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nome <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="name"
                    defaultValue={editingLead?.name || ''}
                    required
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                    placeholder="Nome do lead"
                  />
                </div>

                {/* Telefone */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Telefone <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="tel"
                    name="phone"
                    defaultValue={editingLead?.phone || ''}
                    required
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                    placeholder="(00) 00000-0000"
                  />
                </div>

                {/* Email */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Email
                  </label>
                  <input
                    type="email"
                    name="email"
                    defaultValue={editingLead?.email || ''}
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                    placeholder="email@exemplo.com"
                  />
                </div>

                {/* Empresa */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Empresa
                  </label>
                  <input
                    type="text"
                    name="company"
                    defaultValue={editingLead?.company || ''}
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                    placeholder="Nome da empresa"
                  />
                </div>

                {/* Valor Estimado */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Valor Estimado (R$)
                  </label>
                  <input
                    type="number"
                    name="estimated_value"
                    step="0.01"
                    defaultValue={editingLead?.estimated_value || ''}
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                    placeholder="0,00"
                  />
                </div>

                {/* Origem */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Origem
                  </label>
                  <select
                    name="source"
                    defaultValue={editingLead?.source || ''}
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                  >
                    <option value="">Selecione</option>
                    <option value="website">Website</option>
                    <option value="indicacao">Indicação</option>
                    <option value="redes_sociais">Redes Sociais</option>
                    <option value="whatsapp">WhatsApp</option>
                    <option value="email">Email</option>
                    <option value="telefone">Telefone</option>
                    <option value="evento">Evento</option>
                    <option value="outro">Outro</option>
                  </select>
                </div>

                {/* Data do Próximo Follow-up */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Próximo Follow-up
                  </label>
                  <input
                    type="date"
                    name="next_followup_date"
                    defaultValue={editingLead?.next_followup_date || ''}
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                  />
                </div>

                {/* Notas */}
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Notas
                  </label>
                  <textarea
                    name="notes"
                    rows="3"
                    defaultValue={editingLead?.notes || ''}
                    disabled={editingLead?.viewOnly}
                    className="w-full px-3 py-2.5 sm:py-2 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent resize-none text-base bg-white dark:bg-[#111111] text-gray-900 dark:text-white disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed"
                    placeholder="Anotações sobre o lead..."
                  ></textarea>
                </div>
              </div>

              {/* Botões */}
              <div className="flex flex-col-reverse sm:flex-row gap-3 justify-end pt-4 border-t dark:border-gray-700">
                <button
                  type="button"
                  onClick={() => {
                    setShowAddModal(false);
                    setEditingLead(null);
                  }}
                  className="w-full sm:w-auto px-4 py-3 sm:py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-[#111111] rounded-lg hover:bg-gray-200 dark:hover:bg-[#333333] transition-colors font-medium"
                >
                  {editingLead?.viewOnly ? 'Fechar' : 'Cancelar'}
                </button>
                {!editingLead?.viewOnly && (
                  <button
                    type="submit"
                    className="w-full sm:w-auto px-4 py-3 sm:py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 transition-colors font-medium"
                  >
                    {editingLead ? 'Salvar Alterações' : 'Criar Lead'}
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default LeadsKanban;
