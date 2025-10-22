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
COPY --from=build /app/prisma ./prisma
"# Install only production deps (prisma is in dependencies), then generate client"
RUN npm ci --omit=dev
RUN npx prisma generate
COPY --from=build /app/dist ./dist
# uploads directory for media files
RUN mkdir -p /app/uploads
ENV PORT=4000
EXPOSE 4000
"# Run database migrations on container start, then launch the server"
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
