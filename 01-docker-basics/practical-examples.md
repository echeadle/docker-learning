# Practical Docker Examples

**Your Hands-On Learning Journey**  
**Date:** October 31, 2025  
**Source:** Udemy Docker Course - Early Lessons

---

## Overview

This document captures real commands you've run and lessons learned from actual practice. These are not theoretical - these are commands that worked (and sometimes didn't work) during your learning.

---

## Lesson 1: Container Lifecycle with Ubuntu

### The Manual Way (Create → Start → Attach)

```bash
# 1. Search for Ubuntu image on Docker Hub
docker search ubuntu

# 2. Create a container (but don't start it yet)
docker create --name=foo -it ubuntu bash

# 3. Check container status (won't show up - it's not running)
docker container ls
# or
docker ps

# 4. See ALL containers including stopped ones
docker ps -a

# 5. Start the container
docker start foo

# 6. Now it shows as running
docker container ls

# 7. Attach to the running container
docker attach foo
# You're now inside the container!
# Try: ls, pwd, cat /etc/os-release

# 8. Exit the container (this stops it)
exit

# 9. View the logs (everything that happened in the container)
docker logs foo

# 10. Start it again
docker start foo

# 11. Attach again
docker attach foo
```

**What You Learned:**
- Containers can be in different states: created, running, stopped
- `docker ps` only shows running containers
- `docker ps -a` shows all containers
- Exiting a shell stops the container

---

## Lesson 2: The Easier Way with `docker run`

### One Command Instead of Three

```bash
# Instead of: create → start → attach
# Just use: run

docker run --name=bar -it ubuntu bash
# You're immediately inside the container!
```

**What You Learned:**
- `docker run` = `docker create` + `docker start` + `docker attach`
- This is what most people use
- Much faster for interactive work

---

## Lesson 3: Container Cleanup

### Cleaning Up After Experiments

```bash
# Can't remove a running container
docker rm foo
# Error! Container is running

# Must stop it first
docker stop foo

# Check it's stopped
docker container ls -a

# Now you can remove it
docker rm foo

# Verify it's gone
docker container ls -a
```

**What You Learned:**
- Must stop containers before removing them
- Or use `docker rm -f` to force removal (not recommended)
- Or use `--rm` flag with `docker run` for auto-cleanup

---

## Common Workflow Patterns You've Used

### Pattern 1: Quick Interactive Session
```bash
# Create, start, and enter container in one command
docker run --name=mycontainer -it ubuntu bash

# Do your work inside...

# Exit (stops container)
exit

# Clean up
docker rm mycontainer
```

### Pattern 2: Better - Auto-Cleanup
```bash
# Use --rm to automatically remove when you exit
docker run --rm -it ubuntu bash

# Do your work...

# Exit - container automatically removed!
exit
```

### Pattern 3: Persistent Container
```bash
# Create a container you want to keep
docker run --name=dev-env -it ubuntu bash

# Exit but don't remove
exit

# Come back later
docker start dev-env
docker attach dev-env
```

---

## Your Command History Analysis

From your actual commands, here are the key sequences:

### Sequence 1: First Time Creating a Container
```bash
docker search ubuntu          # Find the image
docker create --name=foo -it ubuntu bash  # Create it
docker ps                     # Check if running (it's not)
docker start foo             # Start it
docker attach foo            # Connect to it
```

### Sequence 2: Working with Logs
```bash
docker logs foo              # See what happened in the container
docker start foo             # Start again
docker attach foo            # Connect again
```

### Sequence 3: Cleanup Process
```bash
docker rm foo                # Try to remove (fails - still running)
docker stop foo              # Stop first
docker container ls -a       # Verify it's stopped
docker rm foo                # Now remove it
docker container ls -a       # Verify it's gone
```

### Sequence 4: The Shortcut
```bash
docker run --name=bar -it ubuntu bash  # One command!
```

---

## Common Mistakes You Encountered (Learning Moments!)

### Mistake 1: Trying to Remove Running Container
```bash
docker rm foo
# Error: You cannot remove a running container
```
**Solution:** Stop it first with `docker stop foo`

### Mistake 2: Typo in Command
```bash
docker container ls-a        # Missing space!
```
**Solution:** `docker container ls -a` (with space)

### Mistake 3: Running `docker logs` Without Container Name
```bash
docker logs                  # Missing container name!
```
**Solution:** `docker logs foo` (specify which container)

---

## Experiments to Try Next

Based on what you've learned, try these:

### Experiment 1: Background Container
```bash
# Run nginx in background
docker run -d --name web -p 8080:80 nginx:1.25-alpine

# Check it's running
docker ps

# Visit http://localhost:8080 in browser

# View logs
docker logs web

# Stop and remove
docker stop web
docker rm web
```

### Experiment 2: Temporary Container
```bash
# Run and auto-remove when done
docker run --rm -it alpine sh

# Try some commands inside:
ls
pwd
cat /etc/os-release

# Exit - container automatically deleted!
exit
```

### Experiment 3: Multiple Containers
```bash
# Create several containers
docker run -d --name web1 -p 8081:80 nginx:1.25-alpine
docker run -d --name web2 -p 8082:80 nginx:1.25-alpine
docker run -d --name web3 -p 8083:80 nginx:1.25-alpine

# List them all
docker ps

# Stop them all
docker stop web1 web2 web3

# Remove them all
docker rm web1 web2 web3
```

---

## Images You've Used So Far

```bash
# List your downloaded images
docker image ls
```

**Expected to see:**
- `ubuntu` - Your interactive learning environment
- Possibly `nginx` if you tried the experiment

---

## Your Notes

_Add observations, questions, and discoveries here:_

**Questions I have:**
- 
- 

**Things that surprised me:**
- 
- 

**Commands I use most:**
- 
- 

**Tricks I discovered:**
Remove all containers:

    docker container ls -aq | xargs docker container rm

Remove all images:

    docker image ls -aq | xargs docker rmi - 

---

## Quick Commands for Copy-Paste

```bash
# Quick interactive Ubuntu
docker run --rm -it ubuntu bash

# Quick interactive Alpine (smaller)
docker run --rm -it alpine sh

# Quick interactive Python
docker run --rm -it python:3.11-alpine python

# See all containers (running and stopped)
docker ps -a

# Clean up all stopped containers
docker container prune

# See all downloaded images
docker image ls
```

---

**Next Lesson Preview:** You'll probably learn about Dockerfiles next - how to create your own custom images!
