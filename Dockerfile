FROM node:18-slim

# Install dependencies for Foundry, git, and jq (for JSON parsing in upgrade scripts)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry
ENV PATH="/root/.foundry/bin:${PATH}"
RUN curl -L https://foundry.paradigm.xyz | bash && foundryup

# Install Yarn Classic (v1) - matches the repo's yarn.lock format
RUN npm install -g --force yarn@1.22.22

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json yarn.lock ./

# --ignore-scripts: forge install runs separately after full copy
RUN yarn install --frozen-lockfile --ignore-scripts

COPY . .
# forge install can't run here: it clones git submodules, but .dockerignore
# excludes .git/. CI runs forge install on the host so lib/ is copied in above.
RUN forge build
RUN yarn build:cli

ENTRYPOINT ["node", "/app/dist/cli/index.js"]
