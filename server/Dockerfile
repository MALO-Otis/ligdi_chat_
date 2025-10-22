# --- Build stage ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY prisma ./prisma
RUN npx prisma generate
COPY src ./src
RUN npm run build

# --- Runtime stage ---
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/package*.json ./
"# Install all deps (including dev) so Prisma CLI is available at runtime for migrations"
RUN npm ci
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/dist ./dist
# uploads directory for media files
RUN mkdir -p /app/uploads
ENV PORT=4000
EXPOSE 4000
"# Run database migrations on container start, then launch the server"
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
