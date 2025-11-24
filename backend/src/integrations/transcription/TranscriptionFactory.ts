import { ITranscriptionProvider } from './ITranscriptionProvider';
import { MinimaxProvider } from './MinimaxProvider';
import { WhisperProvider } from './WhisperProvider';

/**
 * Factory para criar instâncias de provedores de transcrição
 */
export class TranscriptionFactory {
  private static providers: Map<string, new () => ITranscriptionProvider> = new Map([
    ['minimax', MinimaxProvider],
    ['openai_whisper', WhisperProvider],
    // Adicione novos provedores aqui
    // ['assemblyai', AssemblyAIProvider],
  ]);

  /**
   * Cria e inicializa um provedor de transcrição
   */
  static async createProvider(
    providerSlug: string,
    credentials: Record<string, any>
  ): Promise<ITranscriptionProvider> {
    const ProviderClass = this.providers.get(providerSlug);

    if (!ProviderClass) {
      throw new Error(`Transcription provider "${providerSlug}" not found`);
    }

    const provider = new ProviderClass();
    await provider.initialize(credentials);
    return provider;
  }

  /**
   * Lista provedores disponíveis
   */
  static getAvailableProviders(): string[] {
    return Array.from(this.providers.keys());
  }

  /**
   * Registrar novo provedor
   */
  static registerProvider(slug: string, providerClass: new () => ITranscriptionProvider): void {
    this.providers.set(slug, providerClass);
  }
}
