# Multi-Language Docker Examples

**Author:** Your Learning Journey  
**Date Created:** October 31, 2025  
**Topic:** Building Docker images for different programming languages

---

## Overview

Docker isn't tied to any single programming language. This document captures your examples of building images for Node.js, Express.js, PHP, Python/Flask, and other stacks you explore.

---

## Node.js with Serve Module

### Project Structure
```
serve-project/
├── Dockerfile
├── .dockerignore
├── public/
│   ├── index.html
│   └── styles.css
└── package.json
```

### Dockerfile
```dockerfile
# Your Dockerfile here

```

### Build and Run
```bash
# Build
docker build -t serve_image .

# Run with port mapping
docker run -p 3001:3000 --name=serve_container serve_image

# Access at: http://localhost:3001
```

### What You Learned
- 
- 
- 

### Issues Encountered
- 
- 

---

## Express.js Application

### Project Structure
```
express-app/
├── Dockerfile
├── .dockerignore
├── src/
│   └── app.js
├── package.json
└── package-lock.json
```

### Dockerfile
```dockerfile
# Your Dockerfile here

```

### Build and Run
```bash
# Build
docker build -t express-app .

# Run
docker run -d -p 3000:3000 --name=express express-app

# Check logs
docker logs express

# Shell into container
docker exec -it express bash
```

### What You Learned
- 
- 
- 

### Optimization Notes
**Before optimization:**
- Build time: ___ minutes
- Image size: ___ MB

**After optimization:**
- Build time: ___ minutes
- Image size: ___ MB

**What changed:**
- 
- 

---

## PHP Application

### Project Structure
```
php-app/
├── Dockerfile
├── .dockerignore
├── public/
│   └── index.php
└── ...
```

### Dockerfile
```dockerfile
# Your Dockerfile here

```

### Build and Run
```bash
# Build


# Run


# Access at: http://localhost:____
```

### What You Learned
- 
- 
- 

---

## Python with Flask

### Project Structure
```
flask-app/
├── Dockerfile
├── .dockerignore
├── app.py
├── requirements.txt
└── templates/
    └── index.html
```

### Dockerfile
```dockerfile
# Your Dockerfile here

```

### requirements.txt
```
flask==3.0.0
# Add other dependencies

```

### Build and Run
```bash
# Build


# Run


# Access at: http://localhost:____
```

### What You Learned
- 
- 
- 

---

## Comparison Table

| Language | Base Image | Build Time | Final Size | Notes |
|----------|-----------|------------|------------|-------|
| Node.js (serve) | | | | |
| Express.js | | | | |
| PHP | | | | |
| Python/Flask | | | | |

---

## Port Mapping Examples

```bash
# Map host port 8080 to container port 3000
docker run -p 8080:3000 myapp

# Map host port 3001 to container port 3000
docker run -p 3001:3000 myapp

# Let Docker choose random port
docker run -P myapp

# Check what port was assigned
docker port container_name
```

---

## Common Patterns Across Languages

### Development Pattern
```dockerfile
FROM language_image
WORKDIR /app
COPY package_file .
RUN install_command
COPY . .
EXPOSE port
CMD ["start_command"]
```

### Production Pattern
```dockerfile
FROM language_image
WORKDIR /app
COPY package_file .
RUN install_production_only && \
    cleanup_command
COPY . .
USER non_root_user
EXPOSE port
CMD ["start_command"]
```

---

## Language-Specific Tips

### Node.js / Express
```dockerfile
# Use Alpine for smaller images
FROM node:18-alpine

# Install production dependencies only
RUN npm ci --only=production

# Use the built-in node user
USER node
```

### Python / Flask
```dockerfile
# Use slim variant
FROM python:3.11-slim

# Install without cache
RUN pip install --no-cache-dir -r requirements.txt

# Use nobody user
USER nobody
```

### PHP
```dockerfile
# Common base images
FROM php:8.2-apache
FROM php:8.2-fpm-alpine

# Install extensions
RUN docker-php-ext-install pdo pdo_mysql
```

---

## Networking Between Containers

_Notes for when you learn about Docker networks and linking containers:_

### Database Connection Example
```bash
# Create network


# Run database


# Run app with connection


```

---

## Your Experiments

### Experiment 1: [Description]
**What I tried:**
- 

**Dockerfile:**
```dockerfile


```

**Result:**
- 

---

### Experiment 2: [Description]
**What I tried:**
- 

**Dockerfile:**
```dockerfile


```

**Result:**
- 

---

## Useful Commands for All Languages

```bash
# Build with custom Dockerfile name
docker build -f Dockerfile.dev -t myapp:dev .

# Build with build arguments
docker build --build-arg VERSION=1.0 -t myapp .

# Interactive debugging
docker run -it --rm myapp /bin/sh

# Check what's running inside
docker exec -it myapp ps aux

# View environment variables
docker exec myapp env

# Check disk usage
docker exec myapp df -h

# View network configuration
docker exec myapp ip addr
```

---

## Troubleshooting Common Issues

### Port Already in Use
```bash
# Error: port is already allocated
# Solution: Use different host port or stop conflicting service
docker run -p 3001:3000 myapp  # Use 3001 instead
# Or
lsof -i :3000  # Find what's using port 3000
```

### Can't Connect to Container
```bash
# Check if container is running
docker ps

# Check logs for errors
docker logs container_name

# Check port mapping
docker port container_name

# Test from inside container
docker exec -it container_name curl localhost:3000
```

### File Not Found Errors
```bash
# Check .dockerignore isn't excluding needed files
cat .dockerignore

# Check what's in the image
docker run --rm myapp ls -la

# Check WORKDIR is set correctly
docker exec myapp pwd
```

---

## Performance Comparisons

_Track build and run performance across different implementations:_

| Metric | Node/Serve | Express | PHP | Flask |
|--------|-----------|---------|-----|-------|
| First build (cold) | | | | |
| Rebuild (warm cache) | | | | |
| Image size | | | | |
| Startup time | | | | |
| Memory usage | | | | |

---

## Next Topics to Explore

- [ ] Environment-specific builds (dev vs prod)
- [ ] Multi-stage builds for smaller images
- [ ] Docker Compose for multi-container apps
- [ ] Container orchestration basics
- [ ] CI/CD integration

---

**Related:** See `dockerfile-instructions.md` for Dockerfile syntax and `dockerfile-best-practices.md` for optimization techniques
