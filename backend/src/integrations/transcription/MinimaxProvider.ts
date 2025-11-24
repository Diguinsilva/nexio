import axios from 'axios';
import FormData from 'form-data';
import { ITranscriptionProvider, TranscriptionResult } from './ITranscriptionProvider';

export class MinimaxProvider implements ITranscriptionProvider {
  readonly providerName = 'minimax';

  private apiKey!: string;
  private baseUrl = 'https://api.minimax.chat/v1';

  async initialize(credentials: Record<string, any>): Promise<void> {
    this.apiKey = credentials.api_key;

    if (!this.apiKey) {
      throw new Error('Minimax API key is required');
    }
  }

  async transcribe(audioBuffer: Buffer, language = 'pt'): Promise<TranscriptionResult> {
    try {
      const formData = new FormData();
      formData.append('file', audioBuffer, {
        filename: 'audio.ogg',
        contentType: 'audio/ogg',
      });
      formData.append('model', 'speech-01');
      formData.append('language', language);

      const response = await axios.post(
        `${this.baseUrl}/audio/transcriptions`,
        formData,
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            ...formData.getHeaders(),
          },
        }
      );

      return {
        text: response.data.text,
        confidence: 0.95, // Minimax não retorna confidence
        language: language,
      };
    } catch (error: any) {
      throw new Error(`Minimax transcription error: ${error.message}`);
    }
  }
}
