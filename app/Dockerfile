# Stage 1: Install dependencies
FROM node:20-alpine AS deps

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production image
FROM node:20-alpine AS production

RUN addgroup -g 1001 -S nodejs && \
    adduser  -u 1001 -S nodeapp -G nodejs

WORKDIR /app

COPY --from=deps --chown=nodeapp:nodejs /app/node_modules ./node_modules
COPY --chown=nodeapp:nodejs index.js ./
COPY --chown=nodeapp:nodejs package.json ./

USER nodeapp

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "index.js"]