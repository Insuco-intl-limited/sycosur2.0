FROM docker.io/node:20.11-alpine3.18 AS base

FROM base AS node-build-stage

RUN apk add --no-cache libc6-compat

#COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

COPY client/package*.json ./
COPY client/yarn.lock* ./
COPY client/pnpm-lock.yaml* ./

RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i; \
  else echo "Lockfile not found." && exit 1; \
  fi

FROM base AS node-run-stage

ARG APP_HOME=/app
WORKDIR ${APP_HOME}

#COPY --from=node-build-stage client/node_modules ./node_modules

COPY ./client/ ${APP_HOME}

RUN addgroup -g 1001 -S nodejs && \
  adduser -S nextjs -u 1001 -G nodejs

RUN chown -R nextjs:nodejs ${APP_HOME}

USER nextjs

CMD [ "npm","run","dev"]


