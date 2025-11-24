// Hook para gerenciar classes dark mode
export const useDarkModeClasses = (isDark) => {
  return {
    // Backgrounds - MUITO ESCURO (quase preto)
    bgPrimary: isDark ? 'bg-[#0a0a0a]' : 'bg-white',
    bgSecondary: isDark ? 'bg-[#000000]' : 'bg-gray-50',
    bgTertiary: isDark ? 'bg-[#1a1a1a]' : 'bg-gray-100',
    bgCard: isDark ? 'bg-[#0f0f0f]' : 'bg-white',

    // Text - BRANCO no dark mode
    textPrimary: isDark ? 'text-white' : 'text-gray-800',
    textSecondary: isDark ? 'text-gray-200' : 'text-gray-600',
    textAccent: isDark ? 'text-yellow-400' : 'text-yellow-600',

    // Borders - mais escuras
    border: isDark ? 'border-gray-800' : 'border-gray-200',
    borderLight: isDark ? 'border-gray-900' : 'border-gray-100',

    // Inputs - fundo escuro
    input: isDark ? 'bg-[#1a1a1a] border-gray-800 text-white placeholder-gray-500' : 'bg-white border-gray-300 text-gray-900',

    // Hover - AMARELO CLARO
    hover: isDark ? 'hover:bg-yellow-400/10 hover:text-yellow-300' : 'hover:bg-gray-50',
    hoverBg: isDark ? 'hover:bg-[#1a1a1a]' : 'hover:bg-gray-50',

    // Seleção/Active - AMARELO PADRÃO
    active: isDark ? 'bg-yellow-500/20 text-yellow-400 border-yellow-500' : 'bg-yellow-50 text-yellow-600 border-yellow-200',
    selected: isDark ? 'bg-yellow-500/20 text-white border-yellow-500' : 'bg-yellow-100 text-gray-900',

    // Botões - SEM BRANCO no dark mode
    button: isDark ? 'bg-yellow-500 text-black hover:bg-yellow-400' : 'bg-yellow-500 text-white hover:bg-yellow-600',
    buttonSecondary: isDark ? 'bg-[#1a1a1a] text-white border border-gray-700 hover:bg-yellow-400/10 hover:border-yellow-500' : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50',
  };
};
