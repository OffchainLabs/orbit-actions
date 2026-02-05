FROM node:18-slim

# Install dependencies for Foundry and git
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Install Yarn Classic (v1) - matches the repo's yarn.lock format
RUN npm install -g --force yarn@1.22.22

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json yarn.lock ./

# Install dependencies (using --ignore-scripts like CI does, then forge install separately)
RUN yarn install --frozen-lockfile --ignore-scripts

# Copy the rest of the repository
COPY . .

# Build contracts
RUN forge build
