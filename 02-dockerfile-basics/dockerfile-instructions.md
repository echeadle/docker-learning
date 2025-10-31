# Dockerfile Instructions Reference

**Author:** Your Learning Journey  
**Date Created:** October 31, 2025  
**Topic:** Dockerfile syntax and instructions

---

## Overview

A Dockerfile is a text document containing instructions for building a Docker image. Each instruction creates a new layer in the image. This reference covers the essential Dockerfile instructions you'll use.

---

## Basic Dockerfile Structure

```dockerfile
# Comment
FROM base_image:tag
WORKDIR /app
COPY source destination
RUN command
CMD ["executable", "param1", "param2"]
```

---

## Core Instructions

### `FROM`

**Purpose:** Specifies the base image to build upon. Must be the first instruction (after comments/ARG).

**Syntax:**
```dockerfile
FROM image:tag
FROM image:tag AS stage_name  # For multi-stage builds
```

**Examples:**
```dockerfile
# Use Node.js 18 on Alpine Linux
FROM node:18-alpine

# Use Ubuntu
FROM ubuntu:22.04

# Use official Python
FROM python:3.11-slim

# Multi-stage build with named stage
FROM node:18-alpine AS builder
```

**Best Practices:**
- Always specify a tag (never use `:latest`)
- Prefer slim/alpine variants for smaller images
- Use official images from trusted sources
- Pin specific versions for reproducibility

**Common Base Images:**
- `node:18-alpine` - Node.js (small)
- `python:3.11-slim` - Python (small)
- `nginx:alpine` - Web server
- `ubuntu:22.04` - Full Ubuntu
- `alpine:latest` - Minimal Linux (~5MB)

---

### `WORKDIR`

**Purpose:** Sets the working directory for subsequent instructions. Creates the directory if it doesn't exist.

**Syntax:**
```dockerfile
WORKDIR /path/to/directory
```

**Examples:**
```dockerfile
# Set working directory
WORKDIR /app

# All subsequent commands run in /app
COPY package.json .
RUN npm install

# Can use multiple times
WORKDIR /app
WORKDIR logs  # Now in /app/logs
```

**Best Practices:**
- Use absolute paths
- Set early in Dockerfile
- Don't use `RUN cd` - use WORKDIR instead
- Creates directory automatically if it doesn't exist

**Why Use It:**
```dockerfile
# Without WORKDIR (bad)
RUN cd /app && npm install
COPY . /app
RUN cd /app && npm start

# With WORKDIR (good)
WORKDIR /app
RUN npm install
COPY . .
CMD npm start
```

---

### `COPY`

**Purpose:** Copies files/directories from build context to the image.

**Syntax:**
```dockerfile
COPY source destination
COPY --chown=user:group source destination
```

**Examples:**
```dockerfile
# Copy single file
COPY package.json /app/

# Copy with destination relative to WORKDIR
WORKDIR /app
COPY package.json .

# Copy multiple files
COPY package.json package-lock.json ./

# Copy directory
COPY src/ /app/src/

# Copy everything
COPY . .

# Change ownership
COPY --chown=node:node . /app
```

**Important Notes:**
- Source paths are relative to build context (where you run `docker build`)
- Destination paths can be absolute or relative to WORKDIR
- Use `.dockerignore` to exclude files
- Preserves file metadata (permissions, timestamps)

**Wildcards:**
```dockerfile
# Copy all JSON files
COPY *.json /app/

# Copy all .conf files
COPY config/*.conf /etc/myapp/
```

---

### `ADD`

**Purpose:** Similar to COPY but with extra features (auto-extract tar files, fetch URLs).

**Syntax:**
```dockerfile
ADD source destination
```

**Examples:**
```dockerfile
# Same as COPY
ADD package.json /app/

# Auto-extract tar file
ADD archive.tar.gz /app/

# Fetch from URL (not recommended)
ADD https://example.com/file.txt /app/
```

**Best Practices:**
- **Use COPY instead of ADD** unless you need the extra features
- ADD is less transparent and can have unexpected behavior
- For URLs, use `RUN curl` or `RUN wget` instead
- Only use ADD for auto-extracting local tar files

---

### `RUN`

**Purpose:** Executes commands during image build. Creates a new layer.

**Syntax:**
```dockerfile
# Shell form (runs in /bin/sh -c)
RUN command

# Exec form (doesn't invoke shell)
RUN ["executable", "param1", "param2"]
```

**Examples:**
```dockerfile
# Install packages
RUN apt-get update && apt-get install -y curl

# Install Node dependencies
RUN npm install

# Create directories
RUN mkdir -p /app/logs

# Chain commands with &&
RUN apt-get update && \
    apt-get install -y curl wget && \
    apt-get clean

# Multiple commands
RUN npm install && \
    npm run build && \
    npm prune --production
```

**Best Practices:**
- Combine commands with `&&` to reduce layers
- Clean up in the same RUN instruction
- Use `\` for multi-line commands
- Install only necessary packages

**Optimization Example:**
```dockerfile
# Bad - Creates 3 layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean

# Good - Creates 1 layer
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

---

### `CMD`

**Purpose:** Specifies the default command to run when container starts. Only the last CMD in Dockerfile is used.

**Syntax:**
```dockerfile
# Exec form (preferred)
CMD ["executable", "param1", "param2"]

# Shell form
CMD command param1 param2
```

**Examples:**
```dockerfile
# Start Node.js app
CMD ["node", "app.js"]

# Start with npm
CMD ["npm", "start"]

# Shell form
CMD node app.js

# Python app
CMD ["python", "app.py"]

# Nginx
CMD ["nginx", "-g", "daemon off;"]
```

**Important Notes:**
- Only one CMD per Dockerfile (last one wins)
- Can be overridden at runtime: `docker run myapp python other.py`
- Prefer exec form (JSON array) over shell form
- Don't confuse with RUN (RUN executes at build time, CMD at runtime)

**CMD vs RUN:**
```dockerfile
RUN npm install   # Runs during build
CMD ["npm", "start"]  # Runs when container starts
```

---

### `ENTRYPOINT`

**Purpose:** Configures container to run as an executable. Not easily overridden.

**Syntax:**
```dockerfile
# Exec form (preferred)
ENTRYPOINT ["executable", "param1"]

# Shell form
ENTRYPOINT command param1
```

**Examples:**
```dockerfile
# Make container run like a command
ENTRYPOINT ["python", "app.py"]

# Combined with CMD for default arguments
ENTRYPOINT ["python", "app.py"]
CMD ["--port", "8080"]

# Can override CMD: docker run myapp --port 3000
```

**ENTRYPOINT vs CMD:**
- ENTRYPOINT - Defines the main executable
- CMD - Provides default arguments to ENTRYPOINT
- Both can be used together

**Example:**
```dockerfile
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]

# Runs: nginx -g daemon off;
# Override CMD: docker run myapp -t
# Now runs: nginx -t
```

---

### `ENV`

**Purpose:** Sets environment variables available during build and runtime.

**Syntax:**
```dockerfile
ENV key=value
ENV key1=value1 key2=value2
```

**Examples:**
```dockerfile
# Set Node environment
ENV NODE_ENV=production

# Set multiple variables
ENV APP_HOME=/app \
    PORT=3000 \
    DEBUG=false

# Use in subsequent instructions
ENV APP_DIR=/app
WORKDIR $APP_DIR
COPY . $APP_DIR
```

**Important Notes:**
- Variables persist in the final image
- Available to all subsequent instructions
- Can be overridden at runtime: `docker run -e PORT=8080 myapp`
- Use for configuration that should persist

---

### `EXPOSE`

**Purpose:** Documents which ports the container listens on. Doesn't actually publish ports.

**Syntax:**
```dockerfile
EXPOSE port
EXPOSE port/protocol
```

**Examples:**
```dockerfile
# Expose HTTP port
EXPOSE 3000

# Expose multiple ports
EXPOSE 3000 8080

# Specify protocol
EXPOSE 3000/tcp
EXPOSE 53/udp
```

**Important Notes:**
- **Documentation only** - doesn't publish ports
- Still need `-p` flag: `docker run -p 8080:3000 myapp`
- Good practice to document what your app uses
- Helps with `-P` flag (publish all exposed ports)

---

### `USER`

**Purpose:** Sets the user/group for subsequent instructions and container runtime.

**Syntax:**
```dockerfile
USER username
USER uid:gid
```

**Examples:**
```dockerfile
# Switch to node user
USER node

# Use numeric IDs
USER 1000:1000

# Create user first, then switch
RUN useradd -m appuser
USER appuser

# Common pattern
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
USER node
CMD ["node", "app.js"]
```

**Security Best Practice:**
- **Never run as root in production**
- Create a non-root user
- Switch to that user before CMD
- Many base images provide non-root users (e.g., `node` user in Node images)

---

### `ARG`

**Purpose:** Defines build-time variables (not available at runtime).

**Syntax:**
```dockerfile
ARG variable_name
ARG variable_name=default_value
```

**Examples:**
```dockerfile
# Define argument
ARG NODE_VERSION=18

# Use in FROM
FROM node:${NODE_VERSION}-alpine

# Define with default
ARG APP_ENV=production
ENV NODE_ENV=$APP_ENV

# Build with custom value
# docker build --build-arg NODE_VERSION=20 -t myapp .
```

**ARG vs ENV:**
- ARG - Build-time only
- ENV - Build-time and runtime
- Use ARG for things that change between builds
- Use ENV for runtime configuration

---

### `LABEL`

**Purpose:** Adds metadata to the image.

**Syntax:**
```dockerfile
LABEL key="value"
LABEL key1="value1" key2="value2"
```

**Examples:**
```dockerfile
# Add metadata
LABEL maintainer="yourname@example.com"
LABEL version="1.0"
LABEL description="My awesome app"

# Multiple labels
LABEL com.example.version="1.0" \
      com.example.release-date="2025-10-31" \
      com.example.license="MIT"
```

**Common Use Cases:**
- Maintainer information
- Version tracking
- Build information
- License info

---

### `VOLUME`

**Purpose:** Creates a mount point for persistent data.

**Syntax:**
```dockerfile
VOLUME /path/to/directory
VOLUME ["/path1", "/path2"]
```

**Examples:**
```dockerfile
# Single volume
VOLUME /data

# Multiple volumes
VOLUME /data /logs

# Named volumes at runtime
# docker run -v mydata:/data myapp
```

**Notes:**
- Usually better to specify volumes at runtime with `-v`
- Documents where data should persist
- Can't specify host path in Dockerfile (security)

---

## Complete Example Dockerfile

```dockerfile
# Use official Node.js image
FROM node:18-alpine

# Set metadata
LABEL maintainer="yourname@example.com"
LABEL version="1.0"

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY . .

# Create non-root user and switch to it
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

# Document exposed port
EXPOSE 3000

# Health check (optional, covered in advanced topics)
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node healthcheck.js || exit 1

# Start application
CMD ["node", "app.js"]
```

---

## Your Dockerfile Examples

_As you create Dockerfiles, paste them here with notes:_

### Example 1: [Project Name]
```dockerfile
# Paste your Dockerfile here

```

**What it does:**
- 

**What I learned:**
- 

---

### Example 2: [Project Name]
```dockerfile
# Paste your Dockerfile here

```

**What it does:**
- 

**What I learned:**
- 

---

## Common Patterns

### Node.js Application
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
USER node
EXPOSE 3000
CMD ["node", "app.js"]
```

### Python Application
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER nobody
EXPOSE 8000
CMD ["python", "app.py"]
```

### Static Website (nginx)
```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## Instruction Order Matters

**For Build Cache Efficiency:**

```dockerfile
# Good - Dependencies change less often than code
COPY package.json .
RUN npm install
COPY . .

# Bad - Code changes break cache for npm install
COPY . .
RUN npm install
```

Order from least to most frequently changing!

---

## Next Steps

- [ ] Create your first Dockerfile
- [ ] Understand layer caching
- [ ] Learn about .dockerignore
- [ ] Practice multi-stage builds
- [ ] Optimize for production

---

**Related:** See `docker-image-commands.md` for build commands and `dockerfile-best-practices.md` for optimization
