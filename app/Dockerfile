FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --only=production

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/* .
COPY src/server.js .

EXPOSE 3000

USER node

CMD ["node", "server.js"]