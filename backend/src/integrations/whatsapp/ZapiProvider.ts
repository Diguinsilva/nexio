import axios from 'axios';
import { IWhatsAppProvider, WhatsAppSendResult, WhatsAppInstanceStatus } from './IWhatsAppProvider';

export class ZapiProvider implements IWhatsAppProvider {
  readonly providerName = 'zapi';

  private instanceId!: string;
  private token!: string;
  private baseUrl = 'https://api.z-api.io/instances';

  async initialize(credentials: Record<string, any>): Promise<void> {
    this.instanceId = credentials.instance_id;
    this.token = credentials.token;

    if (!this.instanceId || !this.token) {
      throw new Error('Zapi credentials incomplete');
    }
  }

  private getEndpoint(path: string): string {
    return `${this.baseUrl}/${this.instanceId}/token/${this.token}/${path}`;
  }

  async sendText(to: string, message: string): Promise<WhatsAppSendResult> {
    try {
      const response = await axios.post(
        this.getEndpoint('send-text'),
        {
          phone: this.cleanPhone(to),
          message,
        }
      );

      return {
        messageId: response.data.messageId || 'unknown',
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

  async sendAudio(to: string, audioUrl: string): Promise<WhatsAppSendResult> {
    try {
      const response = await axios.post(
        this.getEndpoint('send-audio'),
        {
          phone: this.cleanPhone(to),
          audio: audioUrl,
        }
      );

      return {
        messageId: response.data.messageId || 'unknown',
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
        this.getEndpoint('send-image'),
        {
          phone: this.cleanPhone(to),
          image: imageUrl,
          caption: caption || '',
        }
      );

      return {
        messageId: response.data.messageId || 'unknown',
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
        this.getEndpoint('status')
      );

      return {
        connected: response.data.connected === true,
        phoneNumber: response.data.phone,
      };
    } catch (error: any) {
      return {
        connected: false,
      };
    }
  }

  async disconnect(): Promise<void> {
    // Zapi não precisa de disconnect
  }

  private cleanPhone(phone: string): string {
    return phone.replace(/\D/g, '');
  }
}
