# Docker Storage: Volumes, Bind Mounts, and Tmpfs - Complete Guide

## The Container Storage Problem

**Here's the issue:** Containers are ephemeral. When you remove a container, all data inside it disappears.

```bash
docker run -it --name tempdb postgres
# Create a database, add tables, insert data...
docker rm tempdb
# Everything is gone forever!
```

**This is a problem when you need to:**
- Keep database data across container restarts
- Share files between containers
- Develop code that updates in real-time
- Store logs for analysis
- Handle sensitive temporary data

**Docker's solution:** Three types of storage mounts, each designed for specific use cases.

---

## Understanding the Three Mount Types

### Visual Overview

```
Host Machine
│
├── Docker-Managed Area (/var/lib/docker/volumes/)
│   └── Volume Mount ────────► Container:/data
│       (Docker controls this)
│
├── Your Project Directory (/home/user/myapp/)
│   └── Bind Mount ──────────► Container:/app
│       (You control this)
│
└── RAM (Memory)
    └── Tmpfs Mount ─────────► Container:/secrets
        (Temporary, never touches disk)
```

### Quick Comparison

| Feature | Volume Mount | Bind Mount | Tmpfs Mount |
|---------|-------------|------------|-------------|
| **Managed by** | Docker | You (host filesystem) | Container runtime |
| **Location** | `/var/lib/docker/volumes/` | Anywhere on host | RAM only |
| **Persistence** | Survives container removal | Survives everything | Lost when container stops |
| **Performance** | Fast | Fast | Fastest |
| **Best for** | Databases, logs | Development, config | Secrets, temp files |
| **Portable** | Yes (Docker managed) | No (host-specific paths) | N/A |
| **Shareable** | Between containers | Between containers & host | No |

---

## Volume Mounts: Docker-Managed Persistence

### What Are Volume Mounts?

Docker creates and manages a directory for you. You don't need to know where it lives - Docker handles everything.

**Think of it like a safety deposit box:** Docker gives you a key (volume name), and you can access your stuff from any container, but Docker manages the physical storage.

### Creating and Using Volumes

#### Create a Volume
```bash
# Create named volume
docker volume create mydata

# Inspect it
docker volume inspect mydata
```

**Output:**
```json
[
    {
        "Name": "mydata",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/mydata/_data",
        "Created": "2025-01-15T10:30:00Z"
    }
]
```

#### Use Volume with Container
```bash
# Mount volume to container
docker run -it --name app1 \
  --mount source=mydata,target=/data \
  ubuntu bash

# Inside container
echo "Hello from app1" > /data/message.txt
exit

# Start another container with same volume
docker run -it --name app2 \
  --mount source=mydata,target=/data \
  ubuntu bash

# Inside app2
cat /data/message.txt
# Output: Hello from app1
```

**The data persists!** Even if you remove both containers, the volume keeps the data.

### Real-World Example: PostgreSQL Database

```bash
# Create volume for database
docker volume create postgres-data

# Run PostgreSQL with volume
docker run -d \
  --name mydb \
  --mount source=postgres-data,target=/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

# Use database, create tables, insert data...

# Stop and remove container
docker stop mydb
docker rm mydb

# Start new container with same volume
docker run -d \
  --name mydb-restored \
  --mount source=postgres-data,target=/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

# All your data is still there!
```

### Volume Management Commands

```bash
# List all volumes
docker volume ls

# Create volume
docker volume create <name>

# Inspect volume
docker volume inspect <name>

# Remove volume
docker volume rm <name>

# Remove all unused volumes (CAREFUL!)
docker volume prune

# Remove volume when removing container
docker rm -v <container>
```

### When to Use Volume Mounts

✅ **Use volumes for:**
- **Databases** (PostgreSQL, MySQL, MongoDB)
- **Application logs** that need to persist
- **User uploads** in web applications
- **Data shared between multiple containers**
- **Production deployments**

❌ **Don't use volumes for:**
- Source code during development (use bind mounts)
- Configuration files you edit frequently (use bind mounts)
- Temporary cache data (use tmpfs)

---

## Bind Mounts: Direct Host Directory Mapping

### What Are Bind Mounts?

A bind mount maps a specific directory from your host machine directly into the container. Changes in either location are immediately reflected in the other.

**Think of it like a window:** You're looking at the same folder from two different places (host and container).

### Creating Bind Mounts

#### Basic Syntax
```bash
docker run -it --name dev \
  --mount type=bind,source=/path/on/host,target=/path/in/container \
  ubuntu bash
```

#### Shorter Syntax (Same Result)
```bash
docker run -it --name dev \
  -v /path/on/host:/path/in/container \
  ubuntu bash
```

**Note:** The `--mount` syntax is more explicit and preferred for scripts. The `-v` syntax is quicker for commands.

### Real-World Example: Node.js Development

**Project structure:**
```
~/myapp/
├── package.json
├── server.js
└── public/
    └── index.html
```

**Dockerfile:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

**Development with bind mount:**
```bash
# Build image
docker build -t myapp .

# Run with bind mount (maps your code into container)
docker run -d \
  --name myapp-dev \
  --mount type=bind,source=$(pwd),target=/app \
  -p 3000:3000 \
  myapp

# Now you can edit server.js on your host
# Changes appear instantly in the container!
```

**With nodemon for auto-restart:**
```bash
# Install nodemon in container
docker run -d \
  --name myapp-dev \
  --mount type=bind,source=$(pwd),target=/app \
  -p 3000:3000 \
  myapp \
  npx nodemon server.js

# Edit code → container automatically restarts!
```

### Real-World Example: Python Flask Development

```bash
# Your project directory
cd ~/flask-app

# Run with bind mount
docker run -d \
  --name flask-dev \
  --mount type=bind,source=$(pwd),target=/app \
  -p 5000:5000 \
  -e FLASK_ENV=development \
  python:3.11-slim \
  flask run --host=0.0.0.0

# Edit Python files on your host
# Flask's debug mode auto-reloads!
```

### Bind Mount with Docker Compose (Preview)

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app              # Bind mount current directory
      - /app/node_modules   # Don't overwrite node_modules
```

This pattern is extremely common in development!

### Read-Only Bind Mounts

Sometimes you want the container to read files but not modify them:

```bash
docker run -it \
  --mount type=bind,source=$(pwd)/config,target=/config,readonly \
  ubuntu bash

# Inside container
cat /config/app.conf     # ✅ Works
echo "test" > /config/app.conf  # ❌ Read-only file system
```

### When to Use Bind Mounts

✅ **Use bind mounts for:**
- **Development** (code hot-reloading)
- **Configuration files** you edit frequently
- **Build artifacts** you want on the host
- **Sharing code** between host and container
- **Testing** with specific host files

❌ **Don't use bind mounts for:**
- Production deployments (use volumes)
- Database storage (use volumes)
- Performance-critical operations (volumes are faster)
- Cross-platform deployments (paths differ between OS)

---

## Tmpfs Mounts: Temporary Memory Storage

### What Are Tmpfs Mounts?

Tmpfs mounts store data in the container's memory (RAM) only. When the container stops, the data is gone. It never touches the disk.

**Think of it like RAM:** Fast, temporary, and disappears when you turn off the power.

### Creating Tmpfs Mounts

```bash
docker run -it \
  --mount type=tmpfs,destination=/tmp/cache \
  ubuntu bash

# Inside container
echo "sensitive data" > /tmp/cache/secret.txt
# This data exists only in RAM
# It will disappear when the container stops
```

### Real-World Example: Handling Secrets

```bash
# Run application with tmpfs for secrets
docker run -d \
  --name secure-app \
  --mount type=tmpfs,destination=/run/secrets,tmpfs-size=10m \
  myapp

# Application reads secrets from /run/secrets
# Secrets never touch disk
# Secrets disappear when container stops
```

### Real-World Example: Build Cache

```bash
# Use tmpfs for temporary build files
docker run --rm \
  --mount type=bind,source=$(pwd),target=/src \
  --mount type=tmpfs,destination=/tmp/build-cache \
  -w /src \
  gcc:latest \
  gcc -o myapp main.c
```

### Tmpfs Options

```bash
# Limit size
docker run -it \
  --mount type=tmpfs,destination=/tmp,tmpfs-size=100m \
  ubuntu bash

# Set permissions
docker run -it \
  --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 \
  ubuntu bash
```

### When to Use Tmpfs Mounts

✅ **Use tmpfs for:**
- **Secrets and passwords** (never persisted)
- **Session data** in web apps
- **Temporary cache** during builds
- **Performance-critical temp files**
- **PIDs, sockets, and state files**

❌ **Don't use tmpfs for:**
- Data you need to persist
- Large datasets (limited by RAM)
- Database storage
- Log files you want to keep

---

## Combining Mount Types

Real applications often use multiple mount types together:

### Example: Full-Stack Development Setup

```bash
# PostgreSQL with volume (persistent data)
docker run -d \
  --name postgres \
  --mount source=db-data,target=/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

# Node.js API with bind mount (development)
docker run -d \
  --name api \
  --mount type=bind,source=$(pwd)/api,target=/app \
  --mount type=tmpfs,destination=/tmp \
  --link postgres:db \
  -p 3000:3000 \
  node:18-alpine \
  npm run dev

# React frontend with bind mount (development)
docker run -d \
  --name frontend \
  --mount type=bind,source=$(pwd)/frontend,target=/app \
  -p 3001:3000 \
  node:18-alpine \
  npm start
```

**What's happening:**
- Database data persists in volume (survives restarts)
- API code is bind-mounted (live updates during development)
- Temp files in API use tmpfs (fast, memory-based)
- Frontend code is bind-mounted (hot-reloading)

---

## Common Patterns and Best Practices

### Pattern 1: Development vs Production

**Development:**
```bash
docker run -d \
  --mount type=bind,source=$(pwd),target=/app \
  myapp npm run dev
```

**Production:**
```bash
docker run -d \
  --mount source=app-logs,target=/var/log/app \
  myapp npm start
```

### Pattern 2: Exclude node_modules in Bind Mount

When using bind mounts for Node.js, you don't want to overwrite `node_modules`:

**docker-compose.yml:**
```yaml
services:
  app:
    build: .
    volumes:
      - .:/app                    # Bind mount project
      - /app/node_modules         # Exclude node_modules
      - logs:/var/log/app         # Volume for logs
```

This prevents your host's `node_modules` from conflicting with the container's.

### Pattern 3: Multiple Containers Sharing Data

```bash
# Create shared volume
docker volume create shared-data

# Container 1 writes data
docker run -d \
  --name writer \
  --mount source=shared-data,target=/data \
  alpine \
  sh -c 'while true; do date >> /data/log.txt; sleep 1; done'

# Container 2 reads data
docker run -it \
  --name reader \
  --mount source=shared-data,target=/data \
  alpine \
  tail -f /data/log.txt
```

### Pattern 4: Backup and Restore

**Backup a volume:**
```bash
# Create backup of volume
docker run --rm \
  --mount source=mydata,target=/data \
  --mount type=bind,source=$(pwd),target=/backup \
  ubuntu \
  tar czf /backup/mydata-backup.tar.gz /data
```

**Restore a volume:**
```bash
# Create new volume
docker volume create mydata-restored

# Restore from backup
docker run --rm \
  --mount source=mydata-restored,target=/data \
  --mount type=bind,source=$(pwd),target=/backup \
  ubuntu \
  tar xzf /backup/mydata-backup.tar.gz -C /
```

---

## Troubleshooting Storage Issues

### Problem 1: Permission Denied on Bind Mount

**Symptom:**
```bash
docker run -it \
  --mount type=bind,source=$(pwd),target=/app \
  ubuntu bash

# Inside container
touch /app/test.txt
# touch: cannot touch '/app/test.txt': Permission denied
```

**Cause:** User ID mismatch between host and container

**Solution 1 - Run as your user:**
```bash
docker run -it \
  --user $(id -u):$(id -g) \
  --mount type=bind,source=$(pwd),target=/app \
  ubuntu bash
```

**Solution 2 - Fix in Dockerfile:**
```dockerfile
FROM ubuntu
RUN useradd -u 1000 -m appuser
USER appuser
WORKDIR /app
```

### Problem 2: Volume Not Persisting Data

**Check if volume exists:**
```bash
docker volume ls | grep mydata
```

**Check container is using the volume:**
```bash
docker inspect mycontainer | grep -A 10 Mounts
```

**Common mistake - forgetting to create volume:**
```bash
# Wrong - creates anonymous volume
docker run --mount source=mydata,target=/data ubuntu

# Right - create volume first
docker volume create mydata
docker run --mount source=mydata,target=/data ubuntu
```

### Problem 3: Bind Mount Path Doesn't Exist

**Symptom:**
```bash
docker run --mount type=bind,source=/nonexistent,target=/data ubuntu
# Error: invalid mount config: source path must exist
```

**Solution:**
```bash
# Create directory first
mkdir -p /path/to/mount
docker run --mount type=bind,source=/path/to/mount,target=/data ubuntu
```

### Problem 4: Tmpfs Running Out of Memory

**Symptom:** Container crashes or becomes unresponsive

**Diagnosis:**
```bash
docker stats
# Check memory usage
```

**Solution - Limit tmpfs size:**
```bash
docker run --mount type=tmpfs,destination=/tmp,tmpfs-size=100m ubuntu
```

### Problem 5: Cannot Remove Volume

**Symptom:**
```bash
docker volume rm mydata
# Error: volume is in use
```

**Solution:**
```bash
# Find containers using the volume
docker ps -a --filter volume=mydata

# Remove those containers
docker rm <container-id>

# Now remove volume
docker volume rm mydata
```

---

## Advanced Techniques

### 1. Volume Drivers

Docker supports different volume drivers for advanced storage:

```bash
# Use NFS driver
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.100,rw \
  --opt device=:/path/to/nfs/share \
  nfs-volume
```

### 2. Named Volumes in Dockerfile

```dockerfile
FROM postgres:15
VOLUME /var/lib/postgresql/data
```

When you run this image, Docker automatically creates an anonymous volume for that path.

### 3. Volume Labeling and Organization

```bash
# Create volume with labels
docker volume create \
  --label project=myapp \
  --label environment=production \
  myapp-prod-data

# Find volumes by label
docker volume ls --filter label=project=myapp
```

### 4. Sharing Volumes Between Compose Services

**docker-compose.yml:**
```yaml
version: '3.8'

volumes:
  shared-data:      # Named volume

services:
  writer:
    image: alpine
    volumes:
      - shared-data:/data
    command: sh -c 'while true; do date >> /data/log.txt; sleep 1; done'
  
  reader:
    image: alpine
    volumes:
      - shared-data:/data
    command: tail -f /data/log.txt
```

---

## Decision Tree: Which Mount Type?

```
Need to persist data?
│
├─ YES ─► Data generated by container?
│         │
│         ├─ YES ─► Are you developing locally?
│         │         │
│         │         ├─ NO ─► USE VOLUME MOUNT
│         │         │        (Database, logs, user uploads)
│         │         │
│         │         └─ YES ─► USE VOLUME MOUNT for data
│         │                   USE BIND MOUNT for code
│         │
│         └─ NO ──► Editing files on host?
│                   │
│                   ├─ YES ─► USE BIND MOUNT
│                   │          (Development, config files)
│                   │
│                   └─ NO ──► USE VOLUME MOUNT
│                              (Shared data, backups)
│
└─ NO ──► Is data sensitive?
          │
          ├─ YES ─► USE TMPFS MOUNT
          │          (Secrets, passwords)
          │
          └─ NO ──► USE TMPFS MOUNT
                     (Temp cache, build artifacts)
```

---

## Quick Reference: Mount Commands

### Volume Mounts

```bash
# Create volume
docker volume create mydata

# Use with --mount (recommended)
docker run --mount source=mydata,target=/data ubuntu

# Use with -v (shorter)
docker run -v mydata:/data ubuntu

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Remove volume
docker volume rm mydata

# Remove unused volumes
docker volume prune
```

### Bind Mounts

```bash
# Use with --mount (recommended)
docker run --mount type=bind,source=/host/path,target=/container/path ubuntu

# Use with -v (shorter)
docker run -v /host/path:/container/path ubuntu

# Read-only bind mount
docker run --mount type=bind,source=/host/path,target=/container/path,readonly ubuntu

# Current directory shortcut
docker run -v $(pwd):/app ubuntu
```

### Tmpfs Mounts

```bash
# Use with --mount
docker run --mount type=tmpfs,destination=/tmp ubuntu

# With size limit
docker run --mount type=tmpfs,destination=/tmp,tmpfs-size=100m ubuntu

# Use with --tmpfs (shorter)
docker run --tmpfs /tmp ubuntu
```

---

## Storage Patterns by Use Case

### Database (PostgreSQL/MySQL/MongoDB)
```bash
docker volume create db-data
docker run -d \
  --name database \
  --mount source=db-data,target=/var/lib/postgresql/data \
  postgres:15
```
**Why:** Volume persists data across container restarts

### Web App Development (Node.js/Python)
```bash
docker run -d \
  --mount type=bind,source=$(pwd),target=/app \
  --mount type=tmpfs,destination=/tmp \
  -p 3000:3000 \
  myapp npm run dev
```
**Why:** Bind mount for live code updates, tmpfs for temp files

### Nginx with Static Files
```bash
docker volume create web-content
docker run -d \
  --mount source=web-content,target=/usr/share/nginx/html \
  -p 80:80 \
  nginx
```
**Why:** Volume allows updating content without rebuilding image

### Processing Secrets
```bash
docker run --rm \
  --mount type=tmpfs,destination=/secrets,tmpfs-size=10m \
  myapp process-credentials
```
**Why:** Tmpfs ensures secrets never touch disk

### Log Aggregation
```bash
docker volume create app-logs
docker run -d \
  --mount source=app-logs,target=/var/log/app \
  myapp
```
**Why:** Volume persists logs for analysis

---

## Common Pitfalls and How to Avoid Them

### Pitfall 1: Anonymous Volumes

**Bad - Creates anonymous volume:**
```bash
docker run -v /data ubuntu
# Docker creates random volume name like "abc123def456"
```

**Good - Use named volumes:**
```bash
docker volume create mydata
docker run -v mydata:/data ubuntu
```

### Pitfall 2: Bind Mount Overwrites Container Files

**Problem:**
```bash
# Container has /app/node_modules
docker run -v $(pwd):/app myapp
# Your host's /app (without node_modules) overwrites container's /app
# node_modules disappear!
```

**Solution - Exclude specific paths:**
```yaml
# docker-compose.yml
volumes:
  - .:/app
  - /app/node_modules    # Don't overwrite this
```

### Pitfall 3: Forgetting to Remove Volumes

```bash
# Remove container
docker rm mycontainer
# Volume still exists! Taking up space

# Fix: Remove volume too
docker rm -v mycontainer    # Removes container AND anonymous volumes
docker volume rm mydata     # Manually remove named volume
```

### Pitfall 4: Wrong Permissions on Bind Mounts

**Problem:** Container runs as root, creates files as root, you can't edit them

**Solution:**
```dockerfile
FROM ubuntu
RUN useradd -u 1000 -m appuser
USER appuser
```

Or run with your UID:
```bash
docker run --user $(id -u):$(id -g) -v $(pwd):/app ubuntu
```

### Pitfall 5: Using Bind Mounts in Production

**Don't do this in production:**
```bash
docker run -v /home/user/myapp:/app myapp  # ❌ Host-specific path
```

**Do this instead:**
```bash
docker volume create app-data
docker run -v app-data:/app myapp          # ✅ Portable volume
```

---

## Testing Your Storage Setup

### Verify Volume Persistence

```bash
# Create container with volume
docker run -it --name test1 -v mydata:/data ubuntu bash
echo "persistent data" > /data/test.txt
exit

# Remove container
docker rm test1

# Create new container with same volume
docker run -it --name test2 -v mydata:/data ubuntu bash
cat /data/test.txt
# Should show "persistent data"
```

### Verify Bind Mount Updates

```bash
# Terminal 1
echo "version 1" > test.txt
docker run -it -v $(pwd):/app ubuntu bash
cat /app/test.txt
# Shows "version 1"

# Terminal 2 (while container is running)
echo "version 2" > test.txt

# Back to Terminal 1 (inside container)
cat /app/test.txt
# Should show "version 2" immediately!
```

### Verify Tmpfs Temporary Nature

```bash
# Create container with tmpfs
docker run -it --name tmptest --tmpfs /tmp ubuntu bash
echo "temporary" > /tmp/data.txt
exit

# Start container again
docker start -ai tmptest
cat /tmp/data.txt
# File is gone! (tmpfs cleared on stop)
```

---

## Key Takeaways

1. **Volume Mounts** = Docker-managed, persistent, for production
   - Use for databases, logs, and production data
   
2. **Bind Mounts** = Host-managed, convenient, for development
   - Use for live code updates and configuration
   
3. **Tmpfs Mounts** = Memory-only, temporary, fast
   - Use for secrets and temporary cache

4. **Choose based on:**
   - Persistence needs (volume or tmpfs?)
   - Who manages the storage (Docker or you?)
   - Development vs production
   - Performance requirements

5. **Best practices:**
   - Always use named volumes (not anonymous)
   - Use bind mounts only for development
   - Backup important volumes regularly
   - Clean up unused volumes with `docker volume prune`

---

## What's Next?

Now that you understand Docker storage, you're ready for:
- **Docker Compose** - defining volumes in YAML
- **Multi-container apps** - sharing data between services
- **Orchestration** - managing volumes at scale
- **Backup strategies** - protecting production data

**Remember:** Every Docker application needs a storage strategy. Master these three mount types, and you'll be equipped to handle any persistence scenario!
