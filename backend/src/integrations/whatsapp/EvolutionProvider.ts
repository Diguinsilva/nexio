import axios from 'axios';
import { IWhatsAppProvider, WhatsAppSendResult, WhatsAppInstanceStatus } from './IWhatsAppProvider';

export class EvolutionProvider implements IWhatsAppProvider {
  readonly providerName = 'evolution_api';

  private baseUrl!: string;
  private apiKey!: string;
  private instance!: string;

  async initialize(credentials: Record<string, any>): Promise<void> {
    this.baseUrl = credentials.api_url || 'http://localhost:8080';
    this.apiKey = credentials.api_key;
    this.instance = credentials.instance;

    if (!this.apiKey || !this.instance) {
      throw new Error('Evolution API credentials incomplete');
    }
  }

  async sendText(to: string, message: string): Promise<WhatsAppSendResult> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/message/sendText/${this.instance}`,
        {
          number: this.cleanPhone(to),
          text: message,
        },
        {
          headers: {
            'apikey': this.apiKey,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        messageId: response.data.key?.id || 'unknown',
        status: 'sent',
      };
    } catch (error: any) {
      console.error('Evolution sendText error:', error.message);
      return {
        messageId: 'error',
        status: 'failed',
        error: error.message,
      };
    }
  }

  async sendAudio(to: string, audioUrl: string): Promise<WhatsAppSendResult> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/message/sendWhatsAppAudio/${this.instance}`,
        {
          number: this.cleanPhone(to),
          audioUrl: audioUrl,
        },
        {
          headers: {
            'apikey': this.apiKey,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        messageId: response.data.key?.id || 'unknown',
        status: 'sent',
      };
    } catch (error: any) {
      return {
        messageId: 'error',
        status: 'failed',
        error: error.message,
      };
    }
  }

  async sendImage(to: string, imageUrl: string, caption?: string): Promise<WhatsAppSendResult> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/message/sendMedia/${this.instance}`,
        {
          number: this.cleanPhone(to),
          mediaUrl: imageUrl,
          caption: caption || '',
        },
        {
          headers: {
            'apikey': this.apiKey,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        messageId: response.data.key?.id || 'unknown',
        status: 'sent',
      };
    } catch (error: any) {
      return {
        messageId: 'error',
        status: 'failed',
        error: error.message,
      };
    }
  }

  async downloadMedia(mediaUrl: string): Promise<Buffer> {
    try {
      const response = await axios.get(mediaUrl, {
        responseType: 'arraybuffer',
      });
      return Buffer.from(response.data);
    } catch (error: any) {
      throw new Error(`Failed to download media: ${error.message}`);
    }
  }

  async getStatus(): Promise<WhatsAppInstanceStatus> {
    try {
      const response = await axios.get(
        `${this.baseUrl}/instance/connectionState/${this.instance}`,
        {
          headers: {
            'apikey': this.apiKey,
          },
        }
      );

      return {
        connected: response.data.state === 'open',
        phoneNumber: response.data.instance?.owner || undefined,
      };
    } catch (error: any) {
      return {
        connected: false,
      };
    }
  }

  async disconnect(): Promise<void> {
    // Evolution API não precisa de disconnect explícito
  }

  private cleanPhone(phone: string): string {
    return phone.replace(/\D/g, '');
  }
}
