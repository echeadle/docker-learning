# Docker Quick Reference

A consolidated cheat sheet of the most commonly used Docker commands and patterns.

---

## Container Lifecycle

```bash
# Create container
docker create --name NAME IMAGE

# Start container
docker start NAME

# Stop container
docker stop NAME

# Remove container
docker rm NAME

# Run (create + start)
docker run --name NAME IMAGE
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

### Web Server with Port Mapping
```bash
docker run -d \
  --name web \
  -p 8080:80 \
  nginx:1.25-alpine
```

### Interactive Container
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

---

## Tips & Tricks

- Use `-d` for detached mode (background)
- Use `--rm` to auto-remove container when it stops
- Use `-it` for interactive terminal
- Always specify image tags (not `:latest`)
- Name your containers with `--name`

---

*This will be expanded as you learn more commands and patterns.*
