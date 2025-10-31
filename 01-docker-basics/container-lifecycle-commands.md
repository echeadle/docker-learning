# Docker Container Lifecycle Commands

**Author:** Your Learning Journey  
**Date Created:** October 30, 2025  
**Topic:** Basic Docker container management commands

---

## Overview

These commands manage the complete lifecycle of Docker containers - from creation to removal.

---

## Commands

### `docker create`

**Purpose:** Creates a container from an image but does NOT start it.

**Syntax:**
```bash
docker create [OPTIONS] IMAGE [COMMAND] [ARG...]
```

**Common Options:**
- `--name` - Assign a name to the container
- `--env` or `-e` - Set environment variables
- `-p` - Publish container ports to host
- `-v` - Mount volumes
- `--read-only` - Mount container's root filesystem as read-only (security)
- `--user` - Set username or UID (security - avoid running as root)

**Examples:**
```bash
# Create a named nginx container
docker create --name my-nginx nginx:1.25-alpine

# Create with port mapping
docker create --name web -p 8080:80 nginx:1.25-alpine

# Create with environment variable
docker create --name app -e DATABASE_URL=postgres://db:5432 myapp:latest
```

**Security Notes:**
- Always specify image tags (never use `:latest` in production)
- Use `--read-only` when the container doesn't need to write to its filesystem
- Use `--user` to run as non-root user

---

### `docker start`

**Purpose:** Starts one or more stopped containers.

**Syntax:**
```bash
docker start [OPTIONS] CONTAINER [CONTAINER...]
```

**Common Options:**
- `-a` or `--attach` - Attach STDOUT/STDERR and forward signals
- `-i` or `--interactive` - Attach container's STDIN

**Examples:**
```bash
# Start a container
docker start my-nginx

# Start and attach to see output
docker start -a my-nginx

# Start multiple containers
docker start container1 container2 container3
```

**Notes:**
- Works on containers in "created" or "exited" state
- Container keeps running in background unless you attach

---

### `docker attach`

**Purpose:** Attach local standard input, output, and error streams to a running container.

**Syntax:**
```bash
docker attach [OPTIONS] CONTAINER
```

**Common Options:**
- `--no-stdin` - Do not attach STDIN
- `--sig-proxy` - Proxy all received signals to the process (default true)

**Examples:**
```bash
# Attach to a running container
docker attach my-nginx

# Attach without STDIN
docker attach --no-stdin my-nginx
```

**Important:**
- Use `Ctrl+P` then `Ctrl+Q` to detach WITHOUT stopping the container
- Using `Ctrl+C` or typing `exit` may stop the container
- Good for interactive processes, not ideal for services

**Security Notes:**
- Be careful with attach - you're connected to the main process
- Consider using `docker exec` for interactive shells instead

---

### `docker logs`

**Purpose:** Fetch and display logs from a container.

**Syntax:**
```bash
docker logs [OPTIONS] CONTAINER
```

**Common Options:**
- `-f` or `--follow` - Follow log output (like `tail -f`)
- `--tail N` - Show only last N lines
- `-t` or `--timestamps` - Show timestamps
- `--since` - Show logs since timestamp or relative (e.g., "10m")
- `--until` - Show logs before timestamp

**Examples:**
```bash
# View all logs
docker logs my-nginx

# Follow logs in real-time
docker logs -f my-nginx

# Show last 100 lines with timestamps
docker logs --tail 100 -t my-nginx

# Show logs from last 10 minutes
docker logs --since 10m my-nginx
```

**Security Notes:**
- ⚠️ NEVER log sensitive data (passwords, API keys, tokens)
- Logs are stored on the host - can contain security information
- Consider log rotation to prevent disk space issues
- Use structured logging for better security monitoring

---

### `docker stop`

**Purpose:** Gracefully stop one or more running containers.

**Syntax:**
```bash
docker stop [OPTIONS] CONTAINER [CONTAINER...]
```

**Common Options:**
- `-t` or `--time` - Seconds to wait before killing (default 10)

**Examples:**
```bash
# Stop a container
docker stop my-nginx

# Stop with custom timeout
docker stop -t 30 my-nginx

# Stop multiple containers
docker stop container1 container2 container3
```

**How it works:**
1. Sends SIGTERM signal (graceful shutdown)
2. Waits for timeout period (default 10 seconds)
3. Sends SIGKILL if still running (forced termination)

**Notes:**
- Prefer `docker stop` over `docker kill` for graceful shutdown
- Allows applications to cleanup resources properly
- Important for database containers to flush data

---

### `docker rm`

**Purpose:** Remove one or more stopped containers.

**Syntax:**
```bash
docker rm [OPTIONS] CONTAINER [CONTAINER...]
```

**Common Options:**
- `-f` or `--force` - Force removal of running container
- `-v` or `--volumes` - Remove associated anonymous volumes

**Examples:**
```bash
# Remove a stopped container
docker rm my-nginx

# Force remove a running container
docker rm -f my-nginx

# Remove container and its volumes
docker rm -v my-nginx

# Remove all stopped containers
docker container prune
```

**Security Notes:**
- Always remove containers you no longer need
- Stopped containers can contain sensitive data in their filesystem
- Use `docker container prune` regularly to clean up
- Consider `--rm` flag with `docker run` for temporary containers

---

### `docker image`

**Purpose:** Parent command for managing images.

**Syntax:**
```bash
docker image COMMAND
```

**Common Subcommands:**
- `ls` - List images
- `rm` - Remove images
- `pull` - Pull image from registry
- `push` - Push image to registry
- `inspect` - Display detailed information
- `prune` - Remove unused images
- `tag` - Create a tag for an image

**Examples:**
```bash
# List all images
docker image ls

# List with filtering
docker image ls nginx

# Remove an image
docker image rm nginx:1.25-alpine

# Remove unused images
docker image prune

# Inspect image details
docker image inspect nginx:1.25-alpine
```

**Security Notes:**
- Only pull images from trusted registries
- Scan images for vulnerabilities: `docker scout cves IMAGE`
- Remove unused images regularly - they take up space and may have vulnerabilities
- Check image signatures when available

---

### `docker container`

**Purpose:** Parent command for managing containers.

**Syntax:**
```bash
docker container COMMAND
```

**Common Subcommands:**
- `ls` - List containers
- `rm` - Remove containers
- `stop` - Stop containers
- `start` - Start containers
- `restart` - Restart containers
- `inspect` - Display detailed information
- `prune` - Remove all stopped containers
- `logs` - Fetch logs
- `exec` - Execute command in running container

**Examples:**
```bash
# List running containers
docker container ls

# List all containers (including stopped)
docker container ls -a

# Inspect container details
docker container inspect my-nginx

# Remove all stopped containers
docker container prune

# Execute command in running container
docker container exec -it my-nginx /bin/sh
```

**Useful Filters:**
```bash
# Show only container IDs
docker container ls -q

# Filter by status
docker container ls --filter "status=exited"

# Show with custom format
docker container ls --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

### `docker run`

**Purpose:** Creates AND starts a container in one command (combines `create` + `start` + `attach`).

**Syntax:**
```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

**Common Options:**
- `--name` - Assign a name to the container
- `-i` or `--interactive` - Keep STDIN open (for interactive use)
- `-t` or `--tty` - Allocate a pseudo-TTY (terminal)
- `-d` or `--detach` - Run container in background
- `-p` - Publish container ports to host
- `-v` - Mount volumes
- `-e` or `--env` - Set environment variables
- `--rm` - Automatically remove container when it exits
- `--read-only` - Mount container's root filesystem as read-only (security)
- `--user` - Set username or UID (security)

**Examples:**
```bash
# Run interactive Ubuntu container
docker run --name=bar -it ubuntu bash

# Run nginx in background
docker run -d --name web -p 8080:80 nginx:1.25-alpine

# Run temporary container (auto-removes when stopped)
docker run --rm -it python:3.11-alpine python

# Run with environment variable
docker run -d --name app -e DATABASE_URL=postgres://db:5432 myapp:latest

# Run as non-root user
docker run --user 1000:1000 --name secure-app myapp:latest
```

**Important:**
- `docker run` is the most commonly used command
- Use `-d` for services that run in background (web servers, databases)
- Use `-it` for interactive sessions (shells, REPLs)
- Use `--rm` for temporary containers you don't need to keep
- Combines three operations: `create` → `start` → `attach` (if `-it`)

**Detaching from Interactive Containers:**
- `Ctrl+P` then `Ctrl+Q` - Detach without stopping the container
- `exit` or `Ctrl+D` or `Ctrl+C` - Exit and stop the container

**Security Notes:**
- Always use `--user` to avoid running as root
- Use `--rm` for temporary containers to ensure cleanup
- Combine with `--read-only` when container doesn't need write access

---

### `docker search`

**Purpose:** Search for images on Docker Hub (or configured registry).

**Syntax:**
```bash
docker search [OPTIONS] TERM
```

**Common Options:**
- `--filter` or `-f` - Filter results (e.g., stars, is-official)
- `--limit` - Max number of results (default 25)
- `--no-trunc` - Don't truncate output

**Examples:**
```bash
# Search for Ubuntu images
docker search ubuntu

# Search for official images only
docker search --filter is-official=true ubuntu

# Search for images with at least 100 stars
docker search --filter stars=100 nginx

# Search and limit results
docker search --limit 5 python
```

**Notes:**
- Shows image name, description, stars, official status, and automated build status
- Official images are maintained by Docker or the software vendor
- Higher star count generally indicates more popular/trusted images
- Always verify the publisher before pulling images

**Security Notes:**
- Only use official images or verified publishers when possible
- Check the number of stars and downloads as indicators of trustworthiness
- Be cautious of images with similar names to popular images (typosquatting)
- Review the image's Dockerfile and source code when available

---

## Common Workflow Example

```bash
# 1. Create a container
docker create --name my-app \
  -p 8080:80 \
  --user 1000:1000 \
  --read-only \
  nginx:1.25-alpine

# 2. Start the container
docker start my-app

# 3. Check if it's running
docker container ls

# 4. View logs
docker logs -f my-app

# 5. Stop the container
docker stop my-app

# 6. Remove the container
docker rm my-app
```

---

## Quick Tips

✅ **DO:**
- Use specific image tags (e.g., `nginx:1.25-alpine`)
- Name your containers with `--name`
- Clean up stopped containers regularly
- Check logs before removing containers
- Use `docker container prune` to clean up

❌ **DON'T:**
- Use `:latest` tag in production
- Run containers as root user
- Leave stopped containers indefinitely
- Log sensitive information
- Forget to specify resource limits (coming in advanced topics)

---

## Your Notes

_Add your own discoveries, tips, and examples here as you learn:_

- 
- 
- 

---

## Related Topics to Explore

- [ ] `docker run` (combines create + start)
- [ ] `docker exec` (better for interactive shells)
- [ ] Container resource limits
- [ ] Container networking basics
- [ ] Volume management

---

**Next:** Image commands and Dockerfile basics
