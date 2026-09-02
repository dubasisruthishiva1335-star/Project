# Multi-stage Dockerfile for the NestJS backend located in backend/
# This lives at the repository root so Railway can build the backend
# service directly without needing to infer a build plan from the
# monorepo root (admin-web/, backend/, landing-web/, mobile-app/).

# ---- Builder stage ----
FROM node:18-alpine AS builder
WORKDIR /app

RUN apk add --no-cache openssl

# Copy dependency manifests first for better layer caching
COPY backend/package.json backend/package-lock.json* ./
RUN npm install

# Copy the backend source files needed for build
COPY backend/ .

# Generate the Prisma client and build the NestJS app
RUN npx prisma generate
RUN npm run build

# ---- Runner stage ----
FROM node:18-alpine AS runner
WORKDIR /app

RUN apk add --no-cache openssl

ENV NODE_ENV=production

# Copy built app, production dependencies, and Prisma schema needed at runtime
COPY --from=builder /app/package.json /app/package-lock.json* ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

EXPOSE 4000

CMD ["sh", "-c", "npx prisma db push && npm run seed && npm start"]
