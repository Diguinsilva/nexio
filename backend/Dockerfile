# Backend Dockerfile - Nexio.AI
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar package files
COPY package.json pnpm-lock.yaml* ./

# Instalar pnpm
RUN npm install -g pnpm

# Instalar dependências
RUN pnpm install --frozen-lockfile

# Copiar código fonte
COPY . .

# Build TypeScript
RUN pnpm build

# Estágio de produção
FROM node:20-alpine

WORKDIR /app

# Instalar pnpm
RUN npm install -g pnpm

# Copiar package files
COPY package.json pnpm-lock.yaml* ./

# Instalar apenas dependências de produção
RUN pnpm install --prod --frozen-lockfile

# Copiar build do estágio anterior
COPY --from=builder /app/dist ./dist

# Expor porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Rodar aplicação
CMD ["node", "dist/app.js"]
