# Docker Quick Reference

A consolidated cheat sheet of the most commonly used Docker commands and patterns.

---

## Container Lifecycle

```bash
# Search for images
docker search IMAGE_NAME

# Create container (doesn't start it)
docker create --name NAME IMAGE

# Start container
docker start NAME

# Stop container
docker stop NAME

# Remove container
docker rm NAME

# Run (create + start + attach in one command)
docker run --name NAME IMAGE

# Run with auto-cleanup
docker run --rm IMAGE
```

## Most Used Commands

```bash
# List running containers
docker ps
# or
docker container ls

# List all containers (including stopped)
docker ps -a

# List images
docker images
# or
docker image ls

# View logs
docker logs NAME
docker logs -f NAME  # follow

# Execute command in running container
docker exec -it NAME /bin/sh

# Attach to running container
docker attach NAME
```

## Essential Flags

```bash
# Interactive terminal
-it              # Use for shells: docker run -it ubuntu bash

# Background/detached
-d               # Use for services: docker run -d nginx

# Auto-remove when stopped
--rm             # Use for temporary: docker run --rm ubuntu

# Port mapping
-p HOST:CONTAINER   # Example: docker run -p 8080:80 nginx

# Volume mounting
-v HOST:CONTAINER   # Example: docker run -v $(pwd):/app myapp

# Environment variables
-e KEY=VALUE     # Example: docker run -e DEBUG=true myapp

# Run as user (not root)
--user UID:GID   # Example: docker run --user 1000:1000 myapp

# Name the container
--name NAME      # Example: docker run --name web nginx
```

## Security Quick Wins

```bash
# Run as non-root user
docker run --user 1000:1000 IMAGE

# Read-only filesystem
docker run --read-only IMAGE

# Limit resources
docker run --memory="512m" --cpus="1.0" IMAGE

# Scan image for vulnerabilities
docker scout cves IMAGE
```

## Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything unused (careful!)
docker system prune -a

# See disk usage
docker system df
```

## Common Patterns

### Quick Interactive Shell
```bash
# Ubuntu
docker run --rm -it ubuntu bash

# Alpine (smaller)
docker run --rm -it alpine sh

# Python REPL
docker run --rm -it python:3.11-alpine python
```

### Web Server with Port Mapping
```bash
docker run -d \
  --name web \
  -p 8080:80 \
  nginx:1.25-alpine
```

### Interactive Development Container
```bash
docker run -it \
  --name dev \
  -v $(pwd):/app \
  -w /app \
  ubuntu bash
```

### Temporary Container (Auto-Remove)
```bash
docker run -it \
  --rm \
  --name temp \
  python:3.11-alpine \
  /bin/sh
```

### With Environment Variables
```bash
docker run -d \
  --name app \
  -e DATABASE_URL="postgres://localhost/db" \
  -e DEBUG="false" \
  myapp:latest
```

### Persistent Named Container
```bash
# Create it
docker run --name myapp -it ubuntu bash

# Exit but don't remove
exit

# Come back later
docker start myapp
docker attach myapp
```

---

## Real Command Sequences

### First Time Setup
```bash
docker search ubuntu         # Find image
docker pull ubuntu          # Download (optional - run does this)
docker run -it ubuntu bash  # Create and start
```

### Working with a Container
```bash
docker ps                   # Is it running?
docker logs NAME           # What happened?
docker stop NAME           # Stop it
docker start NAME          # Start again
docker rm NAME             # Remove it
```

### Quick Testing
```bash
docker run --rm -it ubuntu bash   # Use and auto-delete
```

---

## Tips & Tricks

- Use `-d` for detached mode (background)
- Use `--rm` to auto-remove container when it stops
- Use `-it` for interactive terminal
- Always specify image tags (not `:latest`)
- Name your containers with `--name`

---

*This will be expanded as you learn more commands and patterns.*
