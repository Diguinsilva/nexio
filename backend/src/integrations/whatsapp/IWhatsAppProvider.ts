// Interface base para provedores WhatsApp
export interface WhatsAppMessage {
  to: string;
  text?: string;
  mediaUrl?: string;
  mediaType?: 'audio' | 'image' | 'video' | 'document';
}

export interface WhatsAppSendResult {
  messageId: string;
  status: 'sent' | 'queued' | 'failed';
  error?: string;
}

export interface WhatsAppInstanceStatus {
  connected: boolean;
  qrCode?: string;
  phoneNumber?: string;
}

export interface IWhatsAppProvider {
  // Identificação do provedor
  readonly providerName: string;

  // Inicializar com credenciais
  initialize(credentials: Record<string, any>): Promise<void>;

  // Enviar mensagem de texto
  sendText(to: string, message: string): Promise<WhatsAppSendResult>;

  // Enviar áudio
  sendAudio(to: string, audioUrl: string): Promise<WhatsAppSendResult>;

  // Enviar imagem
  sendImage(to: string, imageUrl: string, caption?: string): Promise<WhatsAppSendResult>;

  // Baixar mídia
  downloadMedia(mediaUrl: string): Promise<Buffer>;

  // Verificar status da conexão
  getStatus(): Promise<WhatsAppInstanceStatus>;

  // Desconectar
  disconnect(): Promise<void>;
}
