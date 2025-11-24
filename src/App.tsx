import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-5xl font-bold text-white mb-4">
          Nexio.AI
        </h1>
        <p className="text-xl text-primary-100 mb-8">
          Plataforma B2B SaaS de Automação de Vendas com Agentes de IA
        </p>
        <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20">
          <p className="text-white text-lg mb-4">Build em produção funcionando!</p>
          <button
            onClick={() => setCount((count) => count + 1)}
            className="bg-gradient-primary text-white px-6 py-3 rounded-lg font-semibold hover:opacity-90 transition-opacity"
          >
            Contador: {count}
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;
