FROM node:22-alpine

WORKDIR /app/functions
COPY functions/package.json functions/package-lock.json ./
RUN npm ci --omit=dev
COPY functions/server.js ./

RUN mkdir -p /app/public
COPY index.html /app/public/index.html
COPY logo.svg /app/public/logo.svg

ENV PORT=4137
ENV STATIC_ROOT=/app/public
EXPOSE 4137

CMD ["node", "server.js"]
