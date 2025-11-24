# Frontend Dockerfile - Nexio.AI
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar TODAS as dependências (incluindo devDependencies para o build)
RUN npm install

# Copiar código fonte
COPY . .

# Build Vite (production)
RUN npm run build

# Estágio de produção - servir com nginx
FROM nginx:alpine

# Copiar build para nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração customizada do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Rodar nginx
CMD ["nginx", "-g", "daemon off;"]
