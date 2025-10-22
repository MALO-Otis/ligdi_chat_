# --- Build stage (Debian-based for Prisma/openssl compatibility) ---
FROM node:20-slim AS build
RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY prisma ./prisma
RUN npx prisma generate
COPY src ./src
RUN npm run build

# --- Runtime stage (Debian-based) ---
FROM node:20-slim AS runtime
RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/package*.json ./
COPY --from=build /app/prisma ./prisma
# Install only production deps (prisma is in dependencies), then generate client
RUN npm ci --omit=dev
RUN npx prisma generate
COPY --from=build /app/dist ./dist
# uploads directory for media files
RUN mkdir -p /app/uploads
ENV PORT=4000
EXPOSE 4000
# Apply migrations if present; otherwise push schema (first deploy), then launch
CMD ["sh", "-c", "npx prisma migrate deploy || npx prisma db push && node dist/index.js"]
