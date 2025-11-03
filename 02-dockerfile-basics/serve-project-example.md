# Your First Dockerfile - Serve Project

**Date:** October 31, 2025  
**Location:** `docker-guides/serve/`  
**Purpose:** Static file server using Node.js serve package

---

## Project Structure
```
docker-guides/
└── serve/
    ├── Dockerfile
    ├── display/
    │   ├── index.html
    │   └── (other static files)
    └── (your files)
```

---

## Version 1: Original from Course

### Dockerfile (v1)
```dockerfile
FROM node:latest
RUN npm install -g serve
COPY ./display ./display
CMD serve ./display
```

### Build and Run
```bash
# Build
docker build -t serve_image .

# Run with port mapping
docker run -p 3001:3000 --name serve_container serve_image

# Access: http://localhost:3001
```

### What You Learned
- How to use FROM to specify base image
- RUN executes commands during build
- COPY moves files into the image
- CMD specifies what runs when container starts
- Port mapping with -p maps host:container ports

### Issues/Observations
- Image size: ~1000 MB (node:latest is huge!)
- Using :latest tag (not recommended for production)
- No WORKDIR set
- Running as root user
- CMD in shell form

---

## Version 2: Optimized

### Dockerfile (v2)
```dockerfile
FROM node:18-alpine
WORKDIR /app
RUN npm install -g serve
COPY ./display ./display
USER node
CMD ["serve", "./display"]
```

### Improvements Made
1. ✅ Changed `node:latest` → `node:18-alpine` (specific version, much smaller)
2. ✅ Added `WORKDIR /app` (sets working directory)
3. ✅ Added `USER node` (security - don't run as root)
4. ✅ Changed CMD to exec form `["serve", "./display"]` (more reliable)

### Build and Compare
```bash
# Build v2
docker build -t serve_image:v2 .

# Compare sizes
docker image ls | grep serve_image

# REPOSITORY      TAG    SIZE
# serve_image     v1     1000MB
# serve_image     v2     150MB
```

**Result:** 85% size reduction! 🎉

---

## Commands You Used

```bash
# Build
docker build -t serve_image .

# Run in background with port mapping
docker run -d -p 3001:3000 --name serve_container serve_image

# Check if running
docker ps

# View logs
docker logs serve_container

# Stop
docker stop serve_container

# Remove
docker rm serve_container

# Remove image
docker rmi serve_image
```

---

## Port Mapping Explained

```
-p 3001:3000
   ^^^^  ^^^^
   Host  Container

Your computer:3001  →  Container:3000
```

When you visit `http://localhost:3001`, it forwards to port 3000 inside the container where `serve` is listening.

---

## What's in display/ folder?

_Document what files you're serving:_

- index.html - 
- styles.css - 
- images/ - 

---

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs serve_container

# Try running interactively
docker run -it serve_image /bin/sh
```

### Can't access localhost:3001
```bash
# Check container is running
docker ps

# Check port mapping
docker port serve_container

# Try from inside container
docker exec -it serve_container curl localhost:3000
```

### Files not showing up
```bash
# Check what was copied
docker run --rm serve_image ls -la /display
```

---

## Performance Metrics

| Metric | v1 (node:latest) | v2 (node:alpine) |
|--------|------------------|------------------|
| Build time (cold) | ___  | ___ |
| Build time (warm) | ___  | ___ |
| Image size | ~1000 MB | ~150 MB |
| Container startup | ___  | ___ |

---

## Next Steps

- [ ] Try rebuilding with cached layers
- [ ] Add a .dockerignore file
- [ ] Experiment with different port mappings
- [ ] Try docker exec to explore the container
- [ ] Add more files to display/

---

## Your Notes

**What surprised you:**
- 

**What was confusing:**
- 

**What you want to try next:**
- 
