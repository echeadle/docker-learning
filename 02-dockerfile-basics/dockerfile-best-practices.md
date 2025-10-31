# Dockerfile Best Practices

**Author:** Your Learning Journey  
**Date Created:** October 31, 2025  
**Topic:** Optimizing Dockerfiles for speed, size, and security

---

## Overview

Building images is easy, but building **good** images requires understanding Docker's layering system, caching, and optimization techniques. This guide covers best practices that professional developers use.

---

## Understanding Image Layers

### How Layers Work

Each Dockerfile instruction creates a new layer:

```dockerfile
FROM node:18-alpine    # Layer 1: Base image
WORKDIR /app           # Layer 2: Create /app directory
COPY package.json .    # Layer 3: Copy package.json
RUN npm install        # Layer 4: Install dependencies
COPY . .               # Layer 5: Copy application code
CMD ["node", "app.js"] # Layer 6: Set default command (metadata only)
```

**Key Concepts:**
- Layers are **read-only**
- Layers are **cached**
- Layers are **stacked** on top of each other
- Only changed layers rebuild (and all layers after them)
- Smaller layers = faster builds and smaller images

---

## Layer Caching

### How Caching Works

Docker caches each layer. If nothing changed, Docker reuses the cached layer.

**Example Build:**
```bash
# First build
docker build -t myapp .
# => All layers built fresh

# Second build (no changes)
docker build -t myapp .
# => All layers from cache (instant!)

# Third build (changed app.js)
docker build -t myapp .
# => Layers up to COPY . . from cache
# => COPY . . and after rebuild
```

### Optimizing for Cache

**Bad (cache breaks easily):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .                    # Copies everything
RUN npm install            # Cache breaks if ANY file changes
CMD ["node", "app.js"]
```

**Good (cache-friendly):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./      # Copy only package files
RUN npm install            # Cache unless package files change
COPY . .                   # Copy code (breaks cache, but npm install cached!)
CMD ["node", "app.js"]
```

**Why This Works:**
- `package.json` changes less frequently than code
- `npm install` is slow and should be cached
- Code changes often but copies quickly

### Order Matters!

**General Rule:** Order instructions from **least** to **most** frequently changing.

```dockerfile
FROM base_image            # 1. Base (rarely changes)
WORKDIR /app              # 2. Working directory (rarely changes)
COPY package*.json ./     # 3. Dependencies list (changes sometimes)
RUN npm install           # 4. Install dependencies (expensive!)
COPY . .                  # 5. Application code (changes often)
CMD ["node", "app.js"]   # 6. Startup command (rarely changes)
```

---

## The .dockerignore File

### What It Does

Like `.gitignore` but for Docker builds. Excludes files from the build context.

**Why You Need It:**
- Faster builds (smaller context to send to Docker daemon)
- Smaller images (don't include unnecessary files)
- Security (don't accidentally include secrets)

### Creating .dockerignore

Create `.dockerignore` in the same directory as your Dockerfile:

```
# .dockerignore example

# Git files
.git
.gitignore
.gitattributes

# Node.js
node_modules/
npm-debug.log
yarn-error.log

# Testing
coverage/
.nyc_output/
*.test.js
*.spec.js

# Documentation
README.md
docs/
*.md

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# CI/CD
.github/
.gitlab-ci.yml
Jenkinsfile

# Environment files (IMPORTANT for security!)
.env
.env.local
.env.*.local
*.pem
*.key

# Build artifacts
dist/
build/
tmp/

# Logs
logs/
*.log
```

### Common Patterns

```
# Exclude all markdown files
*.md

# But keep README
!README.md

# Exclude directory
node_modules/

# Exclude all .txt files in any directory
**/*.txt
```

### Example: Node.js Project

**Project structure:**
```
my-app/
├── .dockerignore
├── .git/
├── node_modules/
├── src/
│   ├── app.js
│   └── routes/
├── tests/
├── Dockerfile
├── package.json
├── package-lock.json
└── README.md
```

**.dockerignore:**
```
.git
.gitignore
node_modules
npm-debug.log
coverage
.vscode
.idea
*.md
tests
.env
```

**Result:**
- Build context: ~1MB (just src/ and package files)
- Without .dockerignore: ~200MB (includes node_modules, .git, etc.)

---

## WORKDIR Best Practices

### Why Use WORKDIR

**Bad:**
```dockerfile
RUN cd /app && npm install
RUN cd /app && npm start
```

**Good:**
```dockerfile
WORKDIR /app
RUN npm install
CMD ["npm", "start"]
```

### WORKDIR Guidelines

1. **Set it early:**
```dockerfile
FROM node:18-alpine
WORKDIR /app              # Set early
COPY package*.json ./
RUN npm install
COPY . .
```

2. **Use absolute paths:**
```dockerfile
WORKDIR /app              # Good
WORKDIR app               # Bad (relative path)
```

3. **Creates directories automatically:**
```dockerfile
WORKDIR /app/data/logs    # Creates all directories
```

4. **Use consistently:**
```dockerfile
WORKDIR /app
COPY . .                  # Copies to /app
RUN npm install           # Runs in /app
CMD ["node", "app.js"]   # Runs in /app
```

---

## Combining RUN Commands

### Why Combine Commands

Each RUN creates a new layer. More layers = larger image.

**Bad (3 layers):**
```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
```

**Good (1 layer):**
```dockerfile
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Multi-line Commands

Use `\` for readability:

```dockerfile
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        vim \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Cleanup in Same Layer

**Bad:**
```dockerfile
RUN apt-get install -y build-tools
RUN rm -rf /tmp/*         # New layer, doesn't reduce previous layer!
```

**Good:**
```dockerfile
RUN apt-get install -y build-tools && \
    rm -rf /tmp/*         # Cleanup in same layer
```

---

## Minimizing Image Size

### Choose Smaller Base Images

```dockerfile
# Large (~800MB)
FROM node:18

# Medium (~150MB)
FROM node:18-slim

# Small (~120MB)
FROM node:18-alpine
```

**Alpine Linux:**
- Tiny (~5MB base)
- Uses `musl` instead of `glibc` (may have compatibility issues)
- Uses `apk` package manager
- Missing some common tools

**When to use Alpine:**
- Production images
- Simple applications
- When size matters

**When NOT to use Alpine:**
- Complex native dependencies
- When you need specific glibc features
- Development (use full images for better debugging)

### Remove Unnecessary Files

```dockerfile
# Install dependencies and clean up
RUN apt-get update && \
    apt-get install -y build-essential && \
    npm install && \
    apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

### Use Multi-Stage Builds (Advanced)

```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm ci --only=production
CMD ["node", "dist/app.js"]
```

**Benefits:**
- Build tools only in build stage
- Final image only has runtime dependencies
- Much smaller final image

---

## Security Best Practices

### Don't Run as Root

**Bad:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "app.js"]    # Runs as root!
```

**Good:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
USER node                  # Switch to non-root user
CMD ["node", "app.js"]
```

### Pin Base Image Versions

**Bad:**
```dockerfile
FROM node:latest          # Can break anytime!
```

**Good:**
```dockerfile
FROM node:18.17-alpine    # Specific version
```

### Don't Include Secrets

**Bad:**
```dockerfile
ENV API_KEY=secret123     # Anyone can see this!
```

**Good:**
```dockerfile
# Pass at runtime
# docker run -e API_KEY=secret123 myapp
```

Or use Docker secrets:
```bash
docker secret create api_key /path/to/key
docker service create --secret api_key myapp
```

### Scan for Vulnerabilities

```bash
# Scan your image
docker scout cves myapp:latest

# Or use trivy
trivy image myapp:latest
```

---

## Common Optimization Patterns

### Node.js Optimization

```dockerfile
FROM node:18-alpine

# Install production dependencies only
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application
COPY . .

# Don't run as root
USER node

EXPOSE 3000
CMD ["node", "app.js"]
```

### Python Optimization

```dockerfile
FROM python:3.11-slim

# Install dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Don't run as root
USER nobody

EXPOSE 8000
CMD ["python", "app.py"]
```

---

## Checking Your Work

### Build Time
```bash
# See how long each step takes
time docker build -t myapp .
```

### Image Size
```bash
# Check image size
docker image ls myapp

# See layer sizes
docker history myapp
```

### Build Cache
```bash
# Force rebuild without cache
docker build --no-cache -t myapp .

# Then rebuild with cache
docker build -t myapp .
# Compare times!
```

---

## Your Optimization Notes

_Track your improvements here:_

### Optimization 1:
**What I changed:**
- 

**Result:**
- Build time: X minutes → Y minutes
- Image size: X MB → Y MB

---

### Optimization 2:
**What I changed:**
- 

**Result:**
- Build time: X minutes → Y minutes
- Image size: X MB → Y MB

---

## Quick Checklist

Before building for production, verify:

- [ ] Used specific base image tag (not `:latest`)
- [ ] Created `.dockerignore` file
- [ ] Ordered instructions from least to most frequently changing
- [ ] Combined RUN commands where possible
- [ ] Used smallest appropriate base image
- [ ] Removed build dependencies and temp files
- [ ] Switched to non-root USER
- [ ] No secrets in Dockerfile or image
- [ ] Tested build cache efficiency
- [ ] Scanned for vulnerabilities

---

## Next Steps

- [ ] Create a .dockerignore for your project
- [ ] Optimize instruction order
- [ ] Measure build time improvements
- [ ] Compare image sizes
- [ ] Practice with different base images

---

**Related:** See `dockerfile-instructions.md` for instruction syntax and `docker-image-commands.md` for build commands
