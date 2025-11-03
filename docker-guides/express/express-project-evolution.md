# Express Project - Dockerfile Evolution

## Version 1: Your Original (Works!)

```dockerfile
FROM node
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
```

**Pros:**

-   Works correctly
-   Uses WORKDIR
-   Uses exec form CMD

**Issues:**

-   No version pinning (node:latest implicit)
-   Poor cache usage (npm install always reruns)
-   Runs as root
-   Large image size

---

## Version 2: Optimized for Caching

```dockerfile
FROM node:18-alpine
WORKDIR /app

# Copy package.json FIRST (for better caching)
COPY package.json .

# Install dependencies (only reruns if package.json changes)
RUN npm install

# Copy rest of application
COPY . .

# Use non-root user
USER node

# Start application
CMD ["node", "server.js"]
```

**Improvements:**

-   ✅ Specific version: node:18-alpine
-   ✅ Better caching: package.json copied separately
-   ✅ Security: USER node
-   ✅ Smaller image: alpine variant

**Build time comparison:**

```bash
# First build: Both take ~30 seconds

# Change server.js and rebuild:
# v1: ~30 seconds (reinstalls packages!)
# v2: ~2 seconds (uses cached npm install!)
```

---

## Version 3: Production Ready

```dockerfile
FROM node:18-alpine
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application
COPY server.js .

# Create non-root user and switch
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser && \
    chown -R appuser:appgroup /app
USER appuser

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node -e "require('http').get('http://localhost:80', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

# Start application
CMD ["node", "server.js"]
```

**Additional improvements:**

-   ✅ npm ci instead of npm install (faster, more reliable)
-   ✅ --only=production (no dev dependencies)
-   ✅ Clean npm cache
-   ✅ Custom non-root user
-   ✅ EXPOSE documents port
-   ✅ HEALTHCHECK for monitoring
-   ✅ Only copy needed files

---

## Build & Run Commands

### Version 1 (Your Original)

```bash
docker build -t express-app:v1 .
docker run -d -p 3000:80 --name express-v1 express-app:v1
```

### Version 2 (Optimized Caching)

```bash
docker build -t express-app:v2 .
docker run -d -p 3000:80 --name express-v2 express-app:v2
```

### Version 3 (Production)

```bash
docker build -t express-app:v3 .
docker run -d -p 3000:80 --name express-v3 express-app:v3
```

**Access all versions at:** http://localhost:3000

---

## Testing Cache Performance

### Test v1 (Poor caching)

```bash
# Build first time
time docker build -t express-app:v1 .

# Change server.js (just add a comment)
echo "// test" >> server.js

# Build again - watch it reinstall packages!
time docker build -t express-app:v1 .
# Takes ~30 seconds (npm install reruns)
```

### Test v2 (Good caching)

```bash
# Build first time
time docker build -t express-app:v2 .

# Change server.js
echo "// test" >> server.js

# Build again - packages are cached!
time docker build -t express-app:v2 .
# Takes ~2 seconds (npm install cached!)
```

---

## Image Size Comparison

```bash
docker image ls | grep express-app

# Expected results:
# express-app:v1    ~1000 MB  (node:latest)
# express-app:v2    ~180 MB   (node:18-alpine)
# express-app:v3    ~170 MB   (optimized node:18-alpine)
```

---

## Your server.js Analysis

```javascript
const HOST = "0.0.0.0"; // ✅ Correct for Docker!
const PORT = 80; // ✅ Standard HTTP port

app.listen(PORT, HOST);
```

**Why 0.0.0.0?**

-   Inside Docker, binding to `localhost` won't work from outside
-   `0.0.0.0` means "listen on all interfaces"
-   This allows Docker's port mapping to work

---

## .dockerignore Recommendation

Create `.dockerignore` in the same directory:

```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.DS_Store
```

**Why?**

-   Don't copy node_modules (we install fresh with npm install)
-   Faster builds (smaller context)
-   Smaller images

---

## Debugging Commands

```bash
# Check if container is running
docker ps

# View logs
docker logs express-v2

# Shell into container
docker exec -it express-v2 sh

# Inside container, check:
pwd                    # Should be /app
ls -la                # See files
ps aux                # See processes
curl localhost:80     # Test locally
```

---

## Common Issues & Solutions

### Port already in use

```bash
# Error: port 3000 is already allocated
# Solution: Use different port or stop other container
docker run -d -p 3001:80 --name express express-app:v2
```

### Can't reach the server

```bash
# Check container logs
docker logs express-v2

# Make sure you're mapping to port 80 (not 3000)
docker run -d -p 3000:80 express-app:v2
#              host:container
#              ^^^^  ^^^
#              3000  80 (what server.js uses)
```

### npm install fails

```bash
# Check if package.json was copied
docker run --rm express-app:v2 ls -la /app

# Try building with --no-cache
docker build --no-cache -t express-app:v2 .
```

---

## Performance Metrics

## My Actual Performance Metrics

| Metric                | v1 (Poor Caching) | v2 (Good Caching) | Improvement       |
| --------------------- | ----------------- | ----------------- | ----------------- |
| First build           | 6.30s             | 6.92s             | -                 |
| Rebuild (code change) | 6.33s             | 3.07s             | **53% faster!**   |
| Savings per rebuild   | -                 | 3.26s             | **53% reduction** |

**Conclusion:** Layer caching optimization saved 53% of rebuild time!

---

## What You Learned

**From Project 1 to Project 2:**

-   ✅ WORKDIR makes Dockerfile cleaner
-   ✅ Exec form CMD is better
-   ✅ Real application with dependencies

**New concepts:**

-   Layer caching optimization
-   Why order matters in Dockerfile
-   Port binding with 0.0.0.0
-   Production vs development builds

---

## Next Experiments

-   [ ] Try all three versions and compare build times
-   [ ] Create .dockerignore and see if build is faster
-   [ ] Modify server.js and rebuild to see caching in action
-   [ ] Add more routes to server.js
-   [ ] Try different port mappings
-   [ ] Use docker exec to explore the running container

---

## Your Notes

**Build times you measured:**

-   **What was different from project 1:**

-   **Questions:**

-   **Next improvements you want to try:**

-
