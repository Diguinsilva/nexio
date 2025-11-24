import axios from 'axios';

const EVOLUTION_API_URL = process.env.EVOLUTION_API_URL || 'http://localhost:8080';
const EVOLUTION_API_KEY = process.env.EVOLUTION_API_KEY || '';
const EVOLUTION_INSTANCE = process.env.EVOLUTION_INSTANCE || '';

export class EvolutionService {
  private baseUrl: string;
  private apiKey: string;
  private instance: string;

  constructor() {
    this.baseUrl = EVOLUTION_API_URL;
    this.apiKey = EVOLUTION_API_KEY;
    this.instance = EVOLUTION_INSTANCE;
  }

  // Enviar mensagem de texto
  async sendText(phone: string, message: string) {
    try {
      const response = await axios.post(
        `${this.baseUrl}/message/sendText/${this.instance}`,
        {
          number: this.cleanPhone(phone),
          text: message,
        },
        {
          headers: {
            'apikey': this.apiKey,
            'Content-Type': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error: any) {
      console.error('Evolution API sendText error:', error.message);
      throw new Error(`Erro ao enviar mensagem: ${error.message}`);
    }
  }

  // Enviar áudio
  async sendAudio(phone: string, audioUrl: string) {
    try {
      const response = await axios.post(
        `${this.baseUrl}/message/sendWhatsAppAudio/${this.instance}`,
        {
          number: this.cleanPhone(phone),
          audioUrl: audioUrl,
        },
        {
          headers: {
            'apikey': this.apiKey,
            'Content-Type': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error: any) {
      console.error('Evolution API sendAudio error:', error.message);
      throw new Error(`Erro ao enviar áudio: ${error.message}`);
    }
  }

  // Baixar mídia (áudio, imagem)
  async downloadMedia(mediaUrl: string): Promise<Buffer> {
    try {
      const response = await axios.get(mediaUrl, {
        responseType: 'arraybuffer',
      });
      return Buffer.from(response.data);
    } catch (error: any) {
      console.error('Evolution API downloadMedia error:', error.message);
      throw new Error(`Erro ao baixar mídia: ${error.message}`);
    }
  }

  // Verificar status da instância
  async getInstanceStatus() {
    try {
      const response = await axios.get(
        `${this.baseUrl}/instance/connectionState/${this.instance}`,
        {
          headers: {
            'apikey': this.apiKey,
          },
        }
      );
      return response.data;
    } catch (error: any) {
      console.error('Evolution API getInstanceStatus error:', error.message);
      throw new Error(`Erro ao verificar status: ${error.message}`);
    }
  }

  // Limpar telefone (formato: 5511999999999)
  private cleanPhone(phone: string): string {
    return phone.replace(/\D/g, '');
  }
}

export const evolutionService = new EvolutionService();
