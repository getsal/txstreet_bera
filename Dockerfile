# BeraStreet Frontend - Nginx Static Server
# BeraStreet Frontend - Nginx Static Server
FROM node:18-alpine AS builder

# Install build dependencies for native modules
RUN apk --update --no-cache add python3 make g++

WORKDIR /app

# Build arguments for API endpoints
ARG VUE_APP_REST_API=http://localhost:8080
ARG VUE_APP_WS_SERVER=http://localhost:8081
ARG VUE_APP_REST_API_BERA=${VUE_APP_REST_API}

# Set environment for build
ENV VUE_APP_REST_API=${VUE_APP_REST_API}
ENV VUE_APP_WS_SERVER=${VUE_APP_WS_SERVER}
ENV VUE_APP_REST_API_BERA=${VUE_APP_REST_API_BERA}
ENV NODE_OPTIONS="--openssl-legacy-provider"


# Install dependencies
COPY package*.json yarn.lock* ./
RUN npm install

# Copy source and build
COPY . .
RUN npm run build

# ===================
# Production image with Nginx
# ===================
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Custom nginx config for SPA
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Gzip compression \
    gzip on; \
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml; \
    \
    # Cache static assets \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    \
    # SPA fallback \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
