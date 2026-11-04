# ==========================================
# Stage 1: Build the Vue 3 application
# ==========================================
FROM node:24-alpine AS builder

WORKDIR /app

# Install pnpm matching package.json specification
RUN npm install -g pnpm@11.18.0

# Copy dependency definitions
COPY package.json pnpm-lock.yaml ./

# Install dependencies (disable husky & build scripts during container build)
ENV HUSKY=0
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy project source
COPY . .

# Build static bundle directly via vite
RUN ./node_modules/.bin/vite build --configLoader runner

# ==========================================
# Stage 2: Serve with lightweight Nginx
# ==========================================
FROM nginx:alpine

# Copy built static files to Nginx web root
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration with SPA fallback and wasm support
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
