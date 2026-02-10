FROM node:18-slim

# Install dependencies for Foundry, git, and jq (for JSON parsing in upgrade scripts)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry (pinned to 2026-02-10 nightly for reproducible builds)
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup --version nightly-e788798a511a32e896b127560e2269fb2c43eddd

# Install Yarn Classic (v1) - matches the repo's yarn.lock format
RUN npm install -g --force yarn@1.22.22

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json yarn.lock ./

# --ignore-scripts: forge install runs separately after full copy
RUN yarn install --frozen-lockfile --ignore-scripts

COPY . .
RUN forge build
RUN yarn build:cli

ENTRYPOINT ["node", "/app/dist/cli/index.js"]
