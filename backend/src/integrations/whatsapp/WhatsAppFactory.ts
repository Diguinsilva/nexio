import { IWhatsAppProvider } from './IWhatsAppProvider';
import { EvolutionProvider } from './EvolutionProvider';
import { ZapiProvider } from './ZapiProvider';

/**
 * Factory para criar instâncias de provedores WhatsApp
 */
export class WhatsAppFactory {
  private static providers: Map<string, new () => IWhatsAppProvider> = new Map([
    ['evolution_api', EvolutionProvider],
    ['zapi', ZapiProvider],
    // Adicione novos provedores aqui
    // ['uazapi', UazapiProvider],
    // ['twilio', TwilioProvider],
  ]);

  /**
   * Cria e inicializa um provedor WhatsApp
   */
  static async createProvider(
    providerSlug: string,
    credentials: Record<string, any>
  ): Promise<IWhatsAppProvider> {
    const ProviderClass = this.providers.get(providerSlug);

    if (!ProviderClass) {
      throw new Error(`WhatsApp provider "${providerSlug}" not found. Available: ${Array.from(this.providers.keys()).join(', ')}`);
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
   * Registrar novo provedor dinamicamente
   */
  static registerProvider(slug: string, providerClass: new () => IWhatsAppProvider): void {
    this.providers.set(slug, providerClass);
  }
}
