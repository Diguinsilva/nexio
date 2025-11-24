# Frontend Dockerfile - Nexio.AI
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

# Build Vite (production)
RUN pnpm build

# Estágio de produção - servir com nginx
FROM nginx:alpine

# Copiar build para nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração customizada do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Rodar nginx
CMD ["nginx", "-g", "daemon off;"]
