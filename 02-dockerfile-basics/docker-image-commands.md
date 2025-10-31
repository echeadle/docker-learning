# Docker Image Commands

**Author:** Your Learning Journey  
**Date Created:** October 31, 2025  
**Topic:** Building and managing Docker images

---

## Overview

This section covers commands for building custom Docker images, executing commands in running containers, and managing images on your system.

---

## Commands

### `docker build`

**Purpose:** Build a Docker image from a Dockerfile.

**Syntax:**
```bash
docker build [OPTIONS] PATH
```

**Common Options:**
- `-t` or `--tag` - Name and optionally tag the image (format: name:tag)
- `-f` or `--file` - Specify Dockerfile name (default: Dockerfile)
- `--no-cache` - Build without using cache
- `--build-arg` - Set build-time variables
- `--target` - Build a specific stage in multi-stage builds
- `--pull` - Always attempt to pull newer version of base image

**Examples:**
```bash
# Build image from Dockerfile in current directory
docker build .

# Build and tag the image
docker build -t myapp:1.0 .

# Build with a specific Dockerfile
docker build -f Dockerfile.dev -t myapp:dev .

# Build without cache (forces rebuild of all layers)
docker build --no-cache -t myapp:1.0 .

# Build with build arguments
docker build --build-arg NODE_VERSION=18 -t myapp:1.0 .

# Build and tag with multiple tags
docker build -t myapp:1.0 -t myapp:latest .
```

**The Build Context:**
- The `.` (or PATH) is the "build context" - all files Docker can access
- Only files in the build context can be copied into the image
- Keep build context small for faster builds
- Use `.dockerignore` to exclude unnecessary files

**Understanding Tags:**
```bash
# Image name format: [registry/][username/]name[:tag]
docker build -t myapp .              # Tag: latest (default)
docker build -t myapp:1.0 .          # Tag: 1.0
docker build -t myapp:dev .          # Tag: dev
docker build -t user/myapp:1.0 .     # With username
```

**Common Errors:**
- `COPY failed: file not found` - File not in build context
- `denied: requested access to the resource is denied` - Permission issue or wrong registry
- Build hangs - Check network connectivity or large build context

**Security Notes:**
- Never include secrets in the Dockerfile
- Use `.dockerignore` to exclude sensitive files
- Don't use `ADD` with URLs (security risk) - use `RUN curl` instead
- Pin base image versions (don't use `:latest`)

---

### `docker exec`

**Purpose:** Execute a command in a running container.

**Syntax:**
```bash
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

**Common Options:**
- `-i` or `--interactive` - Keep STDIN open
- `-t` or `--tty` - Allocate a pseudo-TTY
- `-d` or `--detach` - Run command in background
- `-u` or `--user` - Username or UID
- `-w` or `--workdir` - Working directory inside container
- `-e` or `--env` - Set environment variables

**Examples:**
```bash
# Open interactive shell in running container
docker exec -it myapp bash

# Run a single command
docker exec myapp ls -la /app

# Run command as specific user
docker exec -u root myapp apt-get update

# Run command in specific directory
docker exec -w /app myapp npm test

# Run command in background
docker exec -d myapp touch /tmp/flag

# Run command with environment variable
docker exec -e DEBUG=true myapp node app.js
```

**Common Use Cases:**
- Debugging running containers
- Running tests inside containers
- Checking logs or file contents
- Installing packages for debugging (not recommended for production)
- Running database migrations
- Checking application status

**Interactive Shells:**
```bash
# Bash (most containers)
docker exec -it myapp bash

# Sh (Alpine Linux)
docker exec -it myapp sh

# Check which shell is available
docker exec -it myapp cat /etc/shells
```

**Important Notes:**
- Container must be **running** (not stopped or created)
- Changes made with `exec` are NOT saved in the image
- Commands run with `exec` don't trigger container restart
- Different from `docker attach` - exec creates new process

**Difference from `docker run`:**
- `docker run` - Creates and starts a NEW container
- `docker exec` - Runs command in EXISTING running container

---

### `docker rmi`

**Purpose:** Remove one or more images from the local system.

**Syntax:**
```bash
docker rmi [OPTIONS] IMAGE [IMAGE...]
```

**Common Options:**
- `-f` or `--force` - Force removal of image
- `--no-prune` - Don't delete untagged parent images

**Examples:**
```bash
# Remove image by name
docker rmi myapp:1.0

# Remove image by ID
docker rmi 3a5e9b8f7c2d

# Remove multiple images
docker rmi myapp:1.0 myapp:1.1 nginx:latest

# Force remove (even if containers are using it)
docker rmi -f myapp:1.0

# Remove by short ID
docker rmi 3a5
```

**Common Errors:**
```bash
# Error: image is being used by stopped container
# Solution: Remove container first or use -f
docker rm container_name
docker rmi image_name

# Or force it
docker rmi -f image_name
```

**Related Commands:**
```bash
# List all images
docker image ls

# Remove unused images
docker image prune

# Remove all unused images (not just dangling)
docker image prune -a

# Remove specific images by pattern
docker rmi $(docker images 'myapp:*' -q)
```

**Security Notes:**
- Always verify what you're deleting
- Keep production images tagged and organized
- Regular cleanup prevents disk space issues

---

### `docker image ls`

**Purpose:** List images on the local system.

**Syntax:**
```bash
docker image ls [OPTIONS] [REPOSITORY[:TAG]]
```

**Shorthand:**
```bash
docker images
```

**Common Options:**
- `-a` or `--all` - Show all images (including intermediate)
- `-q` or `--quiet` - Only show image IDs
- `-f` or `--filter` - Filter output
- `--format` - Format output using template
- `--digests` - Show digests
- `--no-trunc` - Don't truncate output

**Examples:**
```bash
# List all images
docker image ls

# List specific image
docker image ls myapp

# List with specific tag
docker image ls myapp:1.0

# Show only image IDs
docker image ls -q

# Filter by label
docker image ls --filter "label=maintainer=me"

# Filter dangling images (untagged)
docker image ls --filter "dangling=true"

# Custom format
docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Show image digests
docker image ls --digests
```

**Understanding Output:**
```
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
myapp         1.0       3a5e9b8f7c2d   2 hours ago    150MB
myapp         latest    3a5e9b8f7c2d   2 hours ago    150MB
nginx         alpine    8e75cbc5b25c   2 days ago     41MB
```

- **REPOSITORY** - Image name
- **TAG** - Version/variant
- **IMAGE ID** - Unique identifier (first 12 chars of SHA-256)
- **CREATED** - When the image was built
- **SIZE** - Disk space used

**Dangling Images:**
Images with `<none>` as repository/tag - usually intermediate layers or old builds.

```bash
# Remove dangling images
docker image prune
```

---

### `docker image prune`

**Purpose:** Remove unused images to free up disk space.

**Syntax:**
```bash
docker image prune [OPTIONS]
```

**Common Options:**
- `-a` or `--all` - Remove all unused images (not just dangling)
- `-f` or `--force` - Don't prompt for confirmation
- `--filter` - Filter which images to prune

**Examples:**
```bash
# Remove dangling images (interactive prompt)
docker image prune

# Remove all unused images
docker image prune -a

# Remove without prompting
docker image prune -f

# Remove images older than 24 hours
docker image prune -a --filter "until=24h"

# Remove with label filter
docker image prune --filter "label=deprecated=true"
```

**What Gets Removed:**
- **Without `-a`**: Only dangling images (`<none>:<none>`)
- **With `-a`**: Any image not used by existing containers

**Disk Space Recovery:**
```bash
# See current disk usage
docker system df

# Remove unused images
docker image prune -a

# Check disk usage again
docker system df
```

**Safety Tips:**
- Always review what will be deleted
- Don't use `-a` if you have stopped containers you plan to restart
- Images can be re-pulled/rebuilt, but it takes time
- Consider tagging important images to prevent deletion

---

## Common Workflows

### Building and Running Your Image
```bash
# 1. Build the image
docker build -t myapp:1.0 .

# 2. List images to verify
docker image ls myapp

# 3. Run a container from your image
docker run -d -p 8080:3000 --name myapp myapp:1.0

# 4. Execute commands inside running container
docker exec -it myapp bash

# 5. Stop and remove container
docker stop myapp
docker rm myapp

# 6. Remove image when done
docker rmi myapp:1.0
```

### Debugging a Container
```bash
# Start container
docker run -d --name myapp myapp:1.0

# Check if it's running
docker ps

# View logs
docker logs myapp

# Execute shell to investigate
docker exec -it myapp bash

# Inside container, check things:
ls -la
ps aux
cat /app/log.txt
env

# Exit shell
exit

# Check what went wrong and rebuild
```

### Updating an Image
```bash
# Build new version
docker build -t myapp:2.0 .

# Run new version
docker run -d -p 8080:3000 --name myapp-v2 myapp:2.0

# Test it...

# If good, stop old version
docker stop myapp
docker rm myapp

# Clean up old image
docker rmi myapp:1.0
```

### Cleanup Workflow
```bash
# See what's using space
docker system df

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# See space saved
docker system df
```

---

## Quick Reference

| Command | Purpose | Common Usage |
|---------|---------|--------------|
| `docker build -t name .` | Build image | `docker build -t myapp:1.0 .` |
| `docker exec -it container bash` | Shell into container | `docker exec -it myapp bash` |
| `docker rmi image` | Remove image | `docker rmi myapp:1.0` |
| `docker image ls` | List images | `docker image ls` |
| `docker image prune -a` | Clean unused images | `docker image prune -a` |

---

## Your Notes

_Add your discoveries and examples here as you build images:_

**Builds I've done:**
- 
- 

**Debugging tips I learned:**
- 
- 

**Common issues I encountered:**
- 
- 

**Useful exec commands:**
- 
- 

---

## Next Steps

- [ ] Build your first custom image
- [ ] Practice docker exec for debugging
- [ ] Learn Dockerfile instructions
- [ ] Understand image layers and caching
- [ ] Optimize builds with .dockerignore

---

**Related:** See `dockerfile-instructions.md` for Dockerfile syntax reference
