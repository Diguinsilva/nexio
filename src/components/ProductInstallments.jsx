import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { CreditCard } from 'lucide-react';

/**
 * Calcula o valor da parcela com juros compostos
 */
const calculateInstallmentValue = (price, installments, interestRate) => {
  if (interestRate === 0 || !interestRate) {
    return price / installments;
  }

  const monthlyRate = interestRate / 100;
  const installmentValue =
    (price * monthlyRate * Math.pow(1 + monthlyRate, installments)) /
    (Math.pow(1 + monthlyRate, installments) - 1);

  return installmentValue;
};

/**
 * Componente de exibição de parcelas configurável
 */
export const ProductInstallments = ({ product, darkMode = false, showAll = false }) => {
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const { data, error } = await supabase
        .from('installment_settings')
        .select('*')
        .eq('id', 1)
        .single();

      if (error && error.code !== 'PGRST116') {
        console.warn('Configurações de parcelamento não encontradas');
        setSettings(null);
      } else {
        setSettings(data);
      }
    } catch (error) {
      console.error('Erro ao carregar configurações:', error);
      setSettings(null);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return null;
  }

  // Se não há configurações ou está desabilitado, usar fallback antigo
  if (!settings || !settings.installment_enabled) {
    return (
      <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'} mt-1`}>
        ou 6x de R$ {(product.price / 6).toFixed(2)}
      </p>
    );
  }

  const { installment_options, min_installment_value } = settings;

  // Filtrar opções válidas (parcela mínima respeitada)
  const validOptions = installment_options.filter((option) => {
    const installmentValue = calculateInstallmentValue(
      product.price,
      option.installments,
      option.interest_rate
    );
    return installmentValue >= min_installment_value;
  });

  if (validOptions.length === 0) {
    return (
      <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'} mt-1`}>
        Pagamento à vista
      </p>
    );
  }

  // Mostrar todas as opções ou apenas a melhor
  const optionsToShow = showAll ? validOptions : validOptions.slice(0, 1);

  return (
    <div className="mt-1 space-y-0.5">
      {optionsToShow.map((option, index) => {
        const installmentValue = calculateInstallmentValue(
          product.price,
          option.installments,
          option.interest_rate
        );

        const hasInterest = option.interest_rate > 0;

        return (
          <div key={index} className="flex items-center gap-1">
            {index === 0 && <CreditCard className="w-3 h-3 text-gray-400" />}
            <p
              className={`text-sm ${
                darkMode ? 'text-gray-400' : 'text-gray-600'
              } ${hasInterest ? 'text-xs' : ''}`}
            >
              {option.installments}x de R$ {installmentValue.toFixed(2)}
              {hasInterest ? (
                <span className="text-xs text-orange-500 ml-1">
                  (com juros de {option.interest_rate}%)
                </span>
              ) : (
                <span className="text-green-600 ml-1">sem juros</span>
              )}
            </p>
          </div>
        );
      })}

      {!showAll && validOptions.length > 1 && (
        <p className="text-xs text-gray-400 italic">
          +{validOptions.length - 1} opção(ões) de parcelamento
        </p>
      )}
    </div>
  );
};

/**
 * Componente de preço melhorado com comparativo
 */
export const ProductPriceEnhanced = ({ product, darkMode = false }) => {
  const [settings, setSettings] = useState(null);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const { data } = await supabase
        .from('installment_settings')
        .select('show_price_comparison')
        .eq('id', 1)
        .single();

      setSettings(data);
    } catch (error) {
      console.error('Erro ao carregar configurações:', error);
      setSettings({ show_price_comparison: false });
    }
  };

  const hasDiscount = product.discount_percentage && product.discount_percentage > 0;
  const showComparison = settings?.show_price_comparison !== false;

  return (
    <div className="space-y-1">
      {hasDiscount && product.original_price && product.original_price > 0 && showComparison && (
        <>
          {/* Formato "De X por Y" */}
          <div className="flex items-baseline gap-2">
            <span className="text-xs text-gray-500">De</span>
            <span className={`text-sm line-through ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
              R$ {product.original_price.toFixed(2)}
            </span>
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-xs text-green-600 font-semibold">Por</span>
            <span
              className={`text-xl sm:text-2xl font-bold ${
                hasDiscount ? 'text-red-500' : darkMode ? 'text-yellow-400' : 'text-yellow-600'
              }`}
            >
              R$ {product.price.toFixed(2)}
            </span>
          </div>
          {/* Badge de economia */}
          <div className="inline-block px-2 py-1 bg-green-100 text-green-700 text-xs font-bold rounded">
            Economize R$ {(product.original_price - product.price).toFixed(2)} (
            {product.discount_percentage}% OFF)
          </div>
        </>
      )}

      {(!hasDiscount || !product.original_price || product.original_price <= 0) && (
        <p
          className={`text-lg sm:text-xl font-bold ${
            darkMode ? 'text-yellow-400' : 'text-yellow-600'
          }`}
        >
          R$ {product.price.toFixed(2)}
        </p>
      )}
    </div>
  );
};

export default ProductInstallments;
