import axios from 'axios';
import FormData from 'form-data';
import { ITranscriptionProvider, TranscriptionResult } from './ITranscriptionProvider';

export class WhisperProvider implements ITranscriptionProvider {
  readonly providerName = 'openai_whisper';

  private apiKey!: string;
  private baseUrl = 'https://api.openai.com/v1';

  async initialize(credentials: Record<string, any>): Promise<void> {
    this.apiKey = credentials.api_key;

    if (!this.apiKey) {
      throw new Error('OpenAI API key is required');
    }
  }

  async transcribe(audioBuffer: Buffer, language = 'pt'): Promise<TranscriptionResult> {
    try {
      const formData = new FormData();
      formData.append('file', audioBuffer, {
        filename: 'audio.mp3',
        contentType: 'audio/mpeg',
      });
      formData.append('model', 'whisper-1');
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
        language: language,
      };
    } catch (error: any) {
      throw new Error(`Whisper transcription error: ${error.message}`);
    }
  }
}
