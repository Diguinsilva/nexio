// Interface base para provedores de transcrição
export interface TranscriptionResult {
  text: string;
  confidence?: number;
  language?: string;
  duration?: number;
}

export interface ITranscriptionProvider {
  // Identificação do provedor
  readonly providerName: string;

  // Inicializar com credenciais
  initialize(credentials: Record<string, any>): Promise<void>;

  // Transcrever áudio
  transcribe(audioBuffer: Buffer, language?: string): Promise<TranscriptionResult>;
}
