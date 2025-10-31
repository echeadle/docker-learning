# Dockerfile Basics

**Status:** Ready for learning - framework created!

## 📚 Available Documentation

This section contains reference materials for building custom Docker images:

### Core References
- **docker-image-commands.md** - Commands for building and managing images (`docker build`, `docker exec`, `docker rmi`)
- **dockerfile-instructions.md** - Complete Dockerfile syntax reference (FROM, RUN, COPY, CMD, WORKDIR, etc.)
- **dockerfile-best-practices.md** - Optimization techniques (.dockerignore, layer caching, image size)
- **multi-language-examples.md** - Template for your Node, Express, PHP, Flask examples

## 🎯 What You'll Learn

- [ ] How to write Dockerfiles
- [ ] Building images with `docker build`
- [ ] Understanding image layers and caching
- [ ] Using `.dockerignore` to optimize builds
- [ ] Setting WORKDIR properly
- [ ] Running commands inside containers with `docker exec`
- [ ] Building images for different languages
- [ ] Image optimization techniques

## 🚀 Quick Start

When you begin this section:

1. **Read the references** - Start with `docker-image-commands.md` and `dockerfile-instructions.md`
2. **Create your first Dockerfile** - Follow along with course examples
3. **Document your work** - Add examples to `multi-language-examples.md`
4. **Optimize** - Apply techniques from `dockerfile-best-practices.md`

## 📝 Sample Commands You'll Use

```bash
# Build an image
docker build -t myapp:1.0 .

# Run with port mapping
docker run -p 8080:3000 --name myapp myapp:1.0

# Execute commands in running container
docker exec -it myapp bash

# Remove containers and images
docker rm myapp
docker rmi myapp:1.0

# List and clean up
docker image ls
docker image prune -a
```

## 💡 Learning Path

**Lesson Order (Recommended):**
1. Read `docker-image-commands.md` - Understand the build commands
2. Read `dockerfile-instructions.md` - Learn Dockerfile syntax
3. Build your first image (Node.js serve)
4. Build an Express app
5. Read `dockerfile-best-practices.md` - Learn optimization
6. Create `.dockerignore` file
7. Optimize your Express build
8. Try PHP or Flask (optional)
9. Document everything in `multi-language-examples.md`

## 🎓 Key Concepts

### Dockerfile
A text file containing instructions for building an image. Each instruction creates a layer.

### Image Layers
Docker images are built in layers. Each Dockerfile instruction adds a layer. Layers are cached for faster rebuilds.

### Build Context
All files in the directory where you run `docker build`. Use `.dockerignore` to exclude files.

### Port Mapping
`-p HOST_PORT:CONTAINER_PORT` - Connects host port to container port.

## 🔧 Files You'll Create

As you work through this section, you'll create:
- Dockerfiles for each project
- `.dockerignore` files
- Various web applications (Node, Express, PHP, Flask)

Add them all to this directory and document them!

## ✅ Section Completion Checklist

- [ ] Built first image from Dockerfile
- [ ] Used `docker exec` to debug a container
- [ ] Created and used `.dockerignore`
- [ ] Optimized a Dockerfile for caching
- [ ] Built images for multiple languages
- [ ] Understand WORKDIR usage
- [ ] Practiced port mapping
- [ ] Cleaned up images with `docker rmi`

---

**Next Section:** Docker Compose - Multi-container applications

