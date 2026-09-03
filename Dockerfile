FROM node:20-bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

# Install backend dependencies
COPY backend/package*.json ./
RUN npm install

# Copy backend source
COPY backend/ .

EXPOSE 4000

CMD ["node", "server.js"]
