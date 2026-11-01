# Pinned by digest for reproducible builds; Dependabot proposes updates monthly.
FROM node:24-slim@sha256:c86ecead9e55a5210ac1727de38a4ca840bf03dcaf34dc9749addbf383b1920c AS build
WORKDIR /app
COPY package.json package-lock.json ./
# Only better-sqlite3's install script runs: it downloads the prebuilt binary (no Python needed).
RUN npm ci --ignore-scripts && npm rebuild better-sqlite3
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:24-slim@sha256:c86ecead9e55a5210ac1727de38a4ca840bf03dcaf34dc9749addbf383b1920c
WORKDIR /app
ENV NODE_ENV=production
# Fly mounts the data volume as root: the process starts as root, hands the data folder to the
# image's unprivileged "node" user, then switches to it for good (src/privileges.ts).
ENV RUN_AS_UID=1000 RUN_AS_GID=1000
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
COPY drizzle ./drizzle
CMD ["node", "dist/index.js"]
