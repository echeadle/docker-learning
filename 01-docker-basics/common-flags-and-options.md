# Docker Common Flags and Options

**Author:** Your Learning Journey  
**Date Created:** October 31, 2025  
**Topic:** Understanding frequently used Docker flags and their purposes

---

## Overview

Docker commands accept many flags that modify their behavior. This guide covers the most commonly used flags you'll encounter daily.

---

## Interactive Flags

### `-i` or `--interactive`

**Purpose:** Keeps STDIN open even if not attached.

**When to use:**
- Running shells or REPLs
- Applications that need user input
- Interactive debugging sessions

**Example:**
```bash
# Won't work well without -i
docker run ubuntu bash  # Can't type commands

# Works properly
docker run -i ubuntu bash
```

---

### `-t` or `--tty`

**Purpose:** Allocates a pseudo-TTY (terminal).

**When to use:**
- Makes the terminal behave like a "real" terminal
- Enables proper text formatting and control sequences
- Shows colored output properly

**Example:**
```bash
# Without -t (weird output)
docker run -i ubuntu bash

# With -t (normal terminal behavior)
docker run -it ubuntu bash
```

---

### `-it` (Combined)

**Purpose:** Interactive terminal - the most common combination for shells.

**When to use:**
- **Every time you want to interact with a container shell**
- Python/Node.js REPLs
- Database clients
- Any interactive program

**Examples:**
```bash
# Ubuntu shell
docker run -it ubuntu bash

# Python REPL
docker run -it python:3.11-alpine python

# Alpine shell (uses sh instead of bash)
docker run -it alpine sh

# Node.js REPL
docker run -it node:18-alpine node
```

**Detaching:**
- `Ctrl+P` then `Ctrl+Q` - Detach but keep container running
- `exit`, `Ctrl+D`, or `Ctrl+C` - Exit and stop container

---

## Background Execution

### `-d` or `--detach`

**Purpose:** Run container in background (detached mode).

**When to use:**
- Web servers
- Databases
- Background workers
- Any long-running service

**Example:**
```bash
# Run nginx in background
docker run -d --name web nginx:1.25-alpine

# Check it's running
docker ps

# View logs
docker logs web

# Stop it later
docker stop web
```

**Important:** 
- Can't use `-it` and `-d` together (they're opposites)
- Use `docker logs -f` to follow logs of detached containers
- Use `docker attach` to attach to a detached container

---

## Automatic Cleanup

### `--rm`

**Purpose:** Automatically remove container when it exits.

**When to use:**
- Temporary containers
- One-off commands
- Testing/experimentation
- When you don't need to keep the container

**Examples:**
```bash
# Run Python script and auto-cleanup
docker run --rm -v $(pwd):/app python:3.11 python /app/script.py

# Temporary shell for testing
docker run --rm -it ubuntu bash

# Quick command execution
docker run --rm alpine echo "Hello World"
```

**Benefits:**
- No manual cleanup needed
- Saves disk space
- Good practice for temporary tasks

**Don't use `--rm` when:**
- You need to inspect logs after container stops
- You want to restart the container
- You're debugging and need the stopped container

---

## Naming

### `--name`

**Purpose:** Assign a custom name to the container.

**When to use:**
- **Always, for containers you'll reference later**
- Makes commands more readable
- Easier than using container IDs

**Examples:**
```bash
# Without --name (Docker assigns random name like "angry_einstein")
docker run -d nginx

# With --name (easy to remember and use)
docker run -d --name web nginx

# Now you can use the name
docker logs web
docker stop web
docker start web
```

**Naming Tips:**
- Use descriptive names: `web-server`, `postgres-db`, `redis-cache`
- Use lowercase and hyphens (not spaces or special characters)
- Names must be unique across all containers

---

## Port Mapping

### `-p` or `--publish`

**Purpose:** Publish container ports to the host machine.

**Syntax:**
```bash
-p HOST_PORT:CONTAINER_PORT
```

**Examples:**
```bash
# Map host port 8080 to container port 80
docker run -d -p 8080:80 --name web nginx

# Access in browser: http://localhost:8080

# Map multiple ports
docker run -d \
  -p 8080:80 \
  -p 8443:443 \
  --name web nginx

# Let Docker choose random host port
docker run -d -p 80 nginx

# Bind to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx
```

**Security Note:**
- Only expose ports you actually need
- Bind to `127.0.0.1` for localhost-only access
- Use firewalls to protect exposed ports

---

## Environment Variables

### `-e` or `--env`

**Purpose:** Set environment variables inside the container.

**Examples:**
```bash
# Single environment variable
docker run -e DATABASE_URL=postgres://localhost/db myapp

# Multiple variables
docker run \
  -e DATABASE_URL=postgres://localhost/db \
  -e DEBUG=true \
  -e PORT=3000 \
  myapp

# Load from .env file
docker run --env-file .env myapp
```

**Security Warning:**
- ⚠️ **Never put secrets in command line** (visible in `docker ps` and logs)
- Use Docker secrets or secret management tools for production
- Use `.env` files carefully (don't commit secrets to git)

---

## Volume Mounting

### `-v` or `--volume`

**Purpose:** Mount directories or files from host to container.

**Syntax:**
```bash
-v HOST_PATH:CONTAINER_PATH
```

**Examples:**
```bash
# Mount current directory to /app
docker run -v $(pwd):/app myapp

# Mount with read-only
docker run -v $(pwd):/app:ro myapp

# Named volume
docker run -v mydata:/data postgres

# Mount specific file
docker run -v $(pwd)/config.json:/app/config.json myapp
```

**Use cases:**
- Share code for development
- Persist database data
- Share configuration files
- Access host files

---

## User and Security

### `--user`

**Purpose:** Run container as specific user (not root).

**Syntax:**
```bash
--user UID:GID
# or
--user USERNAME
```

**Examples:**
```bash
# Run as user ID 1000
docker run --user 1000:1000 myapp

# Run as current user
docker run --user $(id -u):$(id -g) myapp

# Run as specific user
docker run --user appuser myapp
```

**Why this matters:**
- Root in container = root privileges if container is compromised
- Non-root user limits damage from security breaches
- Best practice for production

---

### `--read-only`

**Purpose:** Mount container's root filesystem as read-only.

**Example:**
```bash
docker run --read-only --name app myapp
```

**When to use:**
- Applications that don't need to write to filesystem
- Extra security layer
- Prevents malware from persisting changes

**Note:** May need to mount writable `/tmp`:
```bash
docker run --read-only --tmpfs /tmp myapp
```

---

## Resource Limits

### `--memory` or `-m`

**Purpose:** Limit container memory usage.

**Examples:**
```bash
# Limit to 512 MB
docker run --memory="512m" myapp

# Limit to 2 GB
docker run --memory="2g" myapp
```

---

### `--cpus`

**Purpose:** Limit CPU usage.

**Examples:**
```bash
# Limit to 1 CPU
docker run --cpus="1.0" myapp

# Limit to half a CPU
docker run --cpus="0.5" myapp

# Combine with memory
docker run --cpus="1.0" --memory="512m" myapp
```

**Why limit resources:**
- Prevent runaway containers
- Ensure fair resource distribution
- Production best practice

---

## Help and Information

### `--help`

**Purpose:** Show help for any Docker command.

**Examples:**
```bash
docker --help
docker run --help
docker create --help
docker ps --help
```

**Pro tip:** Always check `--help` when learning a new command!

---

## Common Flag Combinations

### Web Server (Background)
```bash
docker run -d \
  --name web \
  -p 8080:80 \
  nginx:1.25-alpine
```

### Interactive Development
```bash
docker run -it \
  --rm \
  --name dev \
  -v $(pwd):/app \
  -w /app \
  python:3.11-alpine \
  sh
```

### Secure Production App
```bash
docker run -d \
  --name app \
  --user 1000:1000 \
  --read-only \
  --memory="512m" \
  --cpus="1.0" \
  -p 8080:8080 \
  -e DATABASE_URL=postgres://db:5432 \
  myapp:1.0.0
```

### Temporary Testing
```bash
docker run -it \
  --rm \
  --name test \
  ubuntu bash
```

---

## Quick Reference Table

| Flag | Purpose | Example |
|------|---------|---------|
| `-i` | Interactive (keep STDIN open) | `docker run -i ubuntu` |
| `-t` | Allocate TTY | `docker run -t ubuntu` |
| `-it` | Interactive terminal | `docker run -it ubuntu bash` |
| `-d` | Detached (background) | `docker run -d nginx` |
| `--rm` | Auto-remove on exit | `docker run --rm ubuntu` |
| `--name` | Name the container | `docker run --name web nginx` |
| `-p` | Port mapping | `docker run -p 8080:80 nginx` |
| `-e` | Environment variable | `docker run -e DEBUG=true app` |
| `-v` | Volume mount | `docker run -v $(pwd):/app app` |
| `--user` | Run as specific user | `docker run --user 1000:1000 app` |
| `--read-only` | Read-only filesystem | `docker run --read-only app` |
| `--memory` | Memory limit | `docker run --memory="512m" app` |
| `--cpus` | CPU limit | `docker run --cpus="1.0" app` |

---

## Your Discoveries

_Add notes about flags you discover or patterns that work well for your use cases:_

- 
- 
- 

---

## Next Steps

- [ ] Practice using different flag combinations
- [ ] Learn about Docker networks (`--network`)
- [ ] Explore volume management in detail
- [ ] Study Docker Compose for multi-container apps
