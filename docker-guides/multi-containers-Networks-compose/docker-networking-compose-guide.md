# Docker Networking and Compose: Complete Guide

## The Multi-Container Problem

**Single container world (what you've learned so far):**
```bash
docker run -p 3000:3000 my-web-app
# One container, works great!
```

**Real-world applications:**
```
Frontend (React)  →  Backend (Node.js)  →  Database (PostgreSQL)  →  Cache (Redis)
```

**Questions that arise:**
- How does the frontend container find the backend?
- How does the backend connect to the database?
- Do I need to memorize IP addresses?
- How do I start all 4 containers with one command?

**This guide answers all of these!**

---

## Part 1: Docker Networking Fundamentals

### How Container Networking Works

When you run a container, Docker creates a virtual network interface for it. Think of Docker networking like an apartment building:

```
Your Computer (The Building)
├── Default Bridge Network (Floor 1 - Everyone shares)
│   ├── Container A (Apt 101)
│   ├── Container B (Apt 102)
│   └── Container C (Apt 103)
│
├── Custom Network "myapp" (Floor 2 - Private floor)
│   ├── Container D (Apt 201)
│   └── Container E (Apt 202)
│
└── Host Network (Penthouse - Direct building access)
    └── Container F
```

### The Three Default Networks

Every Docker installation comes with three networks:

```bash
docker network ls
```

**Output:**
```
NETWORK ID     NAME      DRIVER    SCOPE
abc123def456   bridge    bridge    local
789ghi012jkl   host      host      local
345mno678pqr   none      null      local
```

---

## Understanding the Bridge Network

### What is the Bridge Network?

The **bridge network** is Docker's default network. When you run a container without specifying a network, it automatically connects to the bridge.

**Think of it like this:** A bridge network is like having all your containers on the same Wi-Fi network in your house. They can talk to each other, but they need to know each other's IP addresses.

### How Containers Communicate on Bridge

```bash
# Start first container
docker run -d --name web1 nginx

# Start second container  
docker run -d --name web2 nginx

# Inspect the bridge network
docker network inspect bridge
```

**You'll see output like:**
```json
"Containers": {
    "abc123": {
        "Name": "web1",
        "IPv4Address": "172.17.0.2/16"
    },
    "def456": {
        "Name": "web2", 
        "IPv4Address": "172.17.0.3/16"
    }
}
```

**Communication test:**
```bash
# Get inside web1
docker exec -it web1 sh

# Try to reach web2 by IP (works!)
ping 172.17.0.3

# Try to reach web2 by name (DOESN'T WORK on default bridge!)
ping web2
# ping: bad address 'web2'
```

### Bridge Network Limitations

❌ **No automatic DNS** - Can't use container names  
❌ **IP addresses change** - Every restart might get a new IP  
❌ **Not isolated** - All containers on default bridge can see each other  

**This is why we create custom networks!**

---

## Custom (User-Defined) Networks

### Why Custom Networks Are Better

✅ **Automatic DNS** - Containers find each other by name  
✅ **Isolation** - Only containers on the same network can communicate  
✅ **Better control** - You decide who talks to whom  
✅ **Production-ready** - This is how real applications work  

### Creating and Using Custom Networks

```bash
# Create a custom network
docker network create myapp-network

# Verify it was created
docker network ls
# You'll see myapp-network listed

# Start containers on this network
docker run -d --name database --network myapp-network postgres
docker run -d --name backend --network myapp-network my-api
docker run -d --name frontend --network myapp-network my-web
```

### The Magic: DNS Resolution

```bash
# Get inside backend container
docker exec -it backend sh

# Ping database BY NAME (works!)
ping database
# PING database (172.18.0.2): 56 data bytes

# Connect to database (this is what your app does!)
psql -h database -U postgres
# Connected!
```

**How this works:**
- Docker has a built-in DNS server for custom networks
- When you type `database`, Docker resolves it to the container's IP
- No hardcoded IPs needed!

### Real-World Example: Full Stack App

```bash
# Create network
docker network create fullstack-net

# Start PostgreSQL database
docker run -d \
  --name db \
  --network fullstack-net \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

# Start Node.js API (connects to database by name!)
docker run -d \
  --name api \
  --network fullstack-net \
  -e DATABASE_URL=postgresql://postgres:secret@db:5432/mydb \
  my-node-api

# Start React frontend (calls API by name!)
docker run -d \
  --name web \
  --network fullstack-net \
  -p 3000:3000 \
  my-react-app
```

**Inside my-react-app code:**
```javascript
// This works because of Docker DNS!
fetch('http://api:4000/data')
  .then(res => res.json())
  .then(data => console.log(data));
```

---

## Network Isolation

### Proving Isolation

```bash
# Create two separate networks
docker network create app1-network
docker network create app2-network

# App 1 containers
docker run -d --name app1-web --network app1-network nginx
docker run -d --name app1-db --network app1-network postgres

# App 2 containers
docker run -d --name app2-web --network app2-network nginx
docker run -d --name app2-db --network app2-network postgres

# Try to reach app2-db from app1-web (FAILS - isolated!)
docker exec -it app1-web ping app2-db
# ping: bad address 'app2-db'
```

**This isolation is crucial for:**
- Running multiple apps on one server
- Security (containers can't snoop on other networks)
- Clean separation of concerns

### Connecting a Container to Multiple Networks

Sometimes you need a container on multiple networks:

```bash
# Create networks
docker network create frontend-net
docker network create backend-net

# API needs to talk to both frontend and database
docker run -d --name api --network backend-net my-api

# Connect API to frontend network too
docker network connect frontend-net api

# Now API can talk to containers on BOTH networks!
```

**Use case:** API gateway that needs to reach both frontend services and backend databases.

---

## Network Commands Reference

```bash
# List all networks
docker network ls

# Inspect a network (see connected containers)
docker network inspect bridge
docker network inspect myapp-network

# Create a network
docker network create <network-name>
docker network create --driver bridge my-net

# Remove a network
docker network rm <network-name>

# Remove all unused networks
docker network prune

# Connect running container to network
docker network connect <network-name> <container-name>

# Disconnect container from network
docker network disconnect <network-name> <container-name>
```

---

## Part 2: Docker Compose

### The Problem Compose Solves

**Without Compose:**
```bash
docker network create myapp-network
docker volume create db-data
docker run -d --name db --network myapp-network -v db-data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret postgres
docker run -d --name backend --network myapp-network -e DB_HOST=db -p 4000:4000 my-api
docker run -d --name frontend --network myapp-network -e API_URL=http://backend:4000 -p 3000:3000 my-web
```

**That's 4 commands to remember!** And you have to run them in the right order!

**With Compose:**
```bash
docker-compose up
```

**One command. One file. Everything runs.**

---

## Introduction to Docker Compose

### What is Docker Compose?

Docker Compose is a tool for defining and running multi-container applications using a YAML configuration file.

**Think of it as:** A recipe that tells Docker how to set up your entire application stack.

### Basic docker-compose.yml Structure

```yaml
version: '3.8'

services:
  service-name:
    image: image-name
    # or
    build: ./path
    ports:
      - "host:container"
    environment:
      - KEY=value
    volumes:
      - volume-name:/container/path
    depends_on:
      - other-service

volumes:
  volume-name:

networks:
  network-name:
```

---

## Your First Docker Compose File

### Example: Web App + Database

**Project structure:**
```
myapp/
├── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   └── server.js
└── frontend/
    ├── Dockerfile
    └── index.html
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  database:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: myapp
    volumes:
      - db-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: postgresql://postgres:secret@database:5432/myapp
    depends_on:
      - database

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      API_URL: http://backend:4000
    depends_on:
      - backend

volumes:
  db-data:
```

**Start everything:**
```bash
docker-compose up
```

**What happens:**
1. Docker Compose creates a network automatically (myapp_default)
2. Creates the db-data volume
3. Starts database first
4. Starts backend (waits for database)
5. Starts frontend (waits for backend)
6. All containers can reach each other by service name!

---

## Docker Compose Commands

### Essential Commands

```bash
# Start all services (builds if needed)
docker-compose up

# Start in background (detached)
docker-compose up -d

# Rebuild images and start
docker-compose up --build

# Stop all services (keeps containers)
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop, remove containers AND volumes
docker-compose down -v

# View running services
docker-compose ps

# View logs from all services
docker-compose logs

# View logs from specific service
docker-compose logs backend

# Follow logs in real-time
docker-compose logs -f

# Execute command in running service
docker-compose exec backend sh

# Restart a service
docker-compose restart backend

# Build or rebuild services
docker-compose build

# Pull images for services
docker-compose pull
```

---

## Docker Compose Service Definitions

### Image vs Build

**Using an existing image:**
```yaml
services:
  database:
    image: postgres:15
```

**Building from Dockerfile:**
```yaml
services:
  backend:
    build: ./backend
```

**Build with custom Dockerfile name:**
```yaml
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
```

### Ports

**Port mapping syntax:**
```yaml
services:
  web:
    ports:
      - "3000:3000"      # host:container
      - "8080:80"        # Different host port
      - "127.0.0.1:3000:3000"  # Bind to localhost only
```

### Environment Variables

**Three ways to set environment variables:**

**Method 1: Inline**
```yaml
services:
  backend:
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://user:pass@db:5432/mydb
```

**Method 2: List format**
```yaml
services:
  backend:
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
```

**Method 3: .env file**
```yaml
services:
  backend:
    env_file:
      - .env
```

**.env file:**
```
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@db:5432/mydb
```

### Volumes

**Named volumes:**
```yaml
services:
  database:
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

**Bind mounts:**
```yaml
services:
  web:
    volumes:
      - ./src:/app/src          # Development hot-reload
      - ./config:/app/config:ro  # Read-only config
```

**Mix both:**
```yaml
services:
  app:
    volumes:
      - ./src:/app/src           # Bind mount for code
      - /app/node_modules        # Don't overwrite node_modules
      - app-logs:/var/log/app    # Named volume for logs

volumes:
  app-logs:
```

### Dependencies

**depends_on:**
```yaml
services:
  backend:
    depends_on:
      - database
      - redis
```

**What this does:**
- Starts `database` and `redis` before `backend`
- When you `docker-compose up backend`, it automatically starts dependencies

**Important note:** `depends_on` only waits for containers to START, not for them to be READY. The database might still be initializing!

**Better approach with health checks:**
```yaml
services:
  database:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  backend:
    depends_on:
      database:
        condition: service_healthy
```

### Networks in Compose

**Compose creates a default network automatically:**
```yaml
# No network config needed - all services can talk!
services:
  web:
    image: nginx
  api:
    image: my-api
  db:
    image: postgres
# web, api, and db can all reach each other by service name
```

**Custom networks for isolation:**
```yaml
services:
  frontend:
    networks:
      - frontend-net
  
  api:
    networks:
      - frontend-net
      - backend-net
  
  database:
    networks:
      - backend-net

networks:
  frontend-net:
  backend-net:
```

**Now:**
- `frontend` can reach `api` (both on frontend-net)
- `api` can reach `database` (both on backend-net)
- `frontend` CANNOT reach `database` (different networks)

---

## Real-World Docker Compose Examples

### Example 1: MERN Stack (MongoDB, Express, React, Node)

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:6
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
    volumes:
      - mongo-data:/data/db
    ports:
      - "27017:27017"

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      MONGO_URI: mongodb://admin:password123@mongodb:27017
      NODE_ENV: development
    depends_on:
      - mongodb
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      REACT_APP_API_URL: http://localhost:5000
    depends_on:
      - backend
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  mongo-data:
```

**Start it:**
```bash
docker-compose up --build
```

**Access:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000
- MongoDB: localhost:27017

---

### Example 2: WordPress + MySQL

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  db:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
    volumes:
      - db-data:/var/lib/mysql
    restart: always

  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp-data:/var/www/html
    depends_on:
      - db
    restart: always

volumes:
  db-data:
  wp-data:
```

**Start:**
```bash
docker-compose up -d
```

**Visit:** http://localhost:8080

---

### Example 3: Python Flask + Redis + Nginx

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  web:
    build: ./app
    environment:
      REDIS_HOST: redis
      REDIS_PORT: 6379
    depends_on:
      - redis

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - web
```

---

### Example 4: Microservices Architecture

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  # API Gateway
  gateway:
    build: ./gateway
    ports:
      - "8080:8080"
    depends_on:
      - users-service
      - orders-service
      - products-service

  # User Service
  users-service:
    build: ./services/users
    environment:
      DATABASE_URL: postgresql://postgres:secret@users-db:5432/users
    depends_on:
      - users-db

  users-db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: users
    volumes:
      - users-data:/var/lib/postgresql/data

  # Orders Service
  orders-service:
    build: ./services/orders
    environment:
      DATABASE_URL: postgresql://postgres:secret@orders-db:5432/orders
    depends_on:
      - orders-db

  orders-db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: orders
    volumes:
      - orders-data:/var/lib/postgresql/data

  # Products Service
  products-service:
    build: ./services/products
    environment:
      DATABASE_URL: postgresql://postgres:secret@products-db:5432/products
    depends_on:
      - products-db

  products-db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: products
    volumes:
      - products-data:/var/lib/postgresql/data

volumes:
  users-data:
  orders-data:
  products-data:
```

---

## Development vs Production Compose Files

### The Strategy: Multiple Compose Files

**docker-compose.yml (base - shared config):**
```yaml
version: '3.8'

services:
  database:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp

  backend:
    build: ./backend
    depends_on:
      - database

  frontend:
    build: ./frontend
    depends_on:
      - backend
```

**docker-compose.dev.yml (development overrides):**
```yaml
version: '3.8'

services:
  database:
    environment:
      POSTGRES_PASSWORD: devpassword
    ports:
      - "5432:5432"  # Expose for local access

  backend:
    volumes:
      - ./backend:/app  # Hot reload
      - /app/node_modules
    environment:
      NODE_ENV: development
    command: npm run dev

  frontend:
    volumes:
      - ./frontend:/app  # Hot reload
      - /app/node_modules
    environment:
      NODE_ENV: development
```

**docker-compose.prod.yml (production overrides):**
```yaml
version: '3.8'

services:
  database:
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # From .env
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: always

  backend:
    environment:
      NODE_ENV: production
    restart: always

  frontend:
    environment:
      NODE_ENV: production
    restart: always

volumes:
  db-data:
```

**Usage:**
```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**Or create shortcuts:**
```bash
# Add to package.json scripts or Makefile
dev:
  docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

prod:
  docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Troubleshooting Docker Networking & Compose

### Problem 1: Container Can't Reach Another Container

**Symptom:**
```bash
docker exec backend curl database:5432
# curl: (6) Could not resolve host: database
```

**Diagnosis:**
```bash
# Check if both containers are on the same network
docker network inspect myapp-network
```

**Solutions:**
- Ensure both containers are on the same custom network
- Verify container names are correct (they're case-sensitive!)
- Default bridge doesn't support DNS - use custom network

### Problem 2: Port Already in Use

**Symptom:**
```bash
docker-compose up
# ERROR: for web  Cannot start service web: 
# driver failed: Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Find what's using the port:**
```bash
# Linux/Mac
sudo lsof -i :3000

# Or
netstat -an | grep 3000
```

**Solutions:**
- Stop the other process
- Change the port in docker-compose.yml: `"3001:3000"`
- Use `docker-compose down` to clean up old containers

### Problem 3: Changes Not Showing Up

**Symptom:** You changed code but the container still shows old code

**Solutions:**
```bash
# Rebuild images
docker-compose up --build

# Or force recreation
docker-compose up --force-recreate

# Nuclear option - start fresh
docker-compose down
docker-compose up --build
```

### Problem 4: Cannot Connect to Database

**Symptom:**
```
backend    | Error: connect ECONNREFUSED database:5432
```

**Common causes:**
1. Database container still starting up
2. Wrong hostname in connection string
3. Wrong credentials

**Solution - Add healthcheck:**
```yaml
services:
  database:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      
  backend:
    depends_on:
      database:
        condition: service_healthy
```

### Problem 5: Volume Data Not Persisting

**Check volumes:**
```bash
# List volumes
docker volume ls

# Inspect specific volume
docker volume inspect myapp_db-data
```

**Common mistakes:**
- Forgot to define volume in `volumes:` section
- Used anonymous volume (different each time)
- Used `docker-compose down -v` (deletes volumes!)

**Solution:**
```yaml
services:
  database:
    volumes:
      - db-data:/var/lib/postgresql/data  # Named volume

volumes:
  db-data:  # Must define here!
```

### Problem 6: Container Exits Immediately

**Check logs:**
```bash
docker-compose logs backend
```

**Common causes:**
- Crash on startup (check error in logs)
- Missing environment variable
- Wrong CMD in Dockerfile

### Problem 7: Can't Access Container from Host

**Symptom:** http://localhost:3000 doesn't work

**Check:**
```bash
# Is it running?
docker-compose ps

# Is port exposed?
docker-compose port web 3000
```

**Solution:**
```yaml
services:
  web:
    ports:
      - "3000:3000"  # Make sure this is set!
```

---

## Docker Compose Best Practices

### 1. Use .env Files for Secrets

**Bad:**
```yaml
services:
  database:
    environment:
      POSTGRES_PASSWORD: supersecret123  # Don't hardcode!
```

**Good:**
```yaml
services:
  database:
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
```

**.env file:**
```
DB_PASSWORD=supersecret123
```

**Add .env to .gitignore!**

### 2. Name Your Volumes and Networks

**Bad:**
```yaml
services:
  db:
    volumes:
      - /var/lib/postgresql/data  # Anonymous volume
```

**Good:**
```yaml
services:
  db:
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

### 3. Use Health Checks

```yaml
services:
  database:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    depends_on:
      database:
        condition: service_healthy
```

### 4. Restart Policies for Production

```yaml
services:
  web:
    restart: always          # Always restart
    # or
    restart: on-failure      # Only on error
    # or
    restart: unless-stopped  # Manual stops persist
```

### 5. Organize with Labels

```yaml
services:
  web:
    labels:
      com.myapp.description: "Web frontend"
      com.myapp.environment: "production"
```

### 6. Resource Limits (Production)

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

---

## Quick Reference

### Network Commands
```bash
# List networks
docker network ls

# Create network
docker network create myapp-net

# Inspect network
docker network inspect myapp-net

# Connect container to network
docker network connect myapp-net container-name

# Remove network
docker network rm myapp-net

# Remove unused networks
docker network prune
```

### Compose Commands
```bash
# Start services
docker-compose up
docker-compose up -d                    # Detached
docker-compose up --build              # Rebuild images

# Stop services
docker-compose stop                     # Stop (keep containers)
docker-compose down                     # Stop and remove
docker-compose down -v                  # Also remove volumes

# View status
docker-compose ps                       # List services
docker-compose logs                     # View logs
docker-compose logs -f backend         # Follow specific service

# Execute commands
docker-compose exec backend sh         # Get shell in service

# Build/Pull
docker-compose build                    # Build images
docker-compose pull                     # Pull images

# Restart
docker-compose restart backend         # Restart one service
docker-compose restart                 # Restart all
```

### Compose File Skeleton
```yaml
version: '3.8'

services:
  service-name:
    image: image:tag           # Use image OR build
    # or
    build: ./path              # Build from Dockerfile
    
    ports:
      - "host:container"
    
    environment:
      KEY: value
    # or
    env_file: .env
    
    volumes:
      - named-vol:/path
      - ./local:/path
    
    networks:
      - network-name
    
    depends_on:
      - other-service
    
    restart: always
    
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s

volumes:
  named-vol:

networks:
  network-name:
```

---

## Testing Your Network Setup

### Test 1: Verify DNS Resolution

```bash
# Start two containers on custom network
docker network create test-net
docker run -d --name container1 --network test-net busybox sleep 3600
docker run -d --name container2 --network test-net busybox sleep 3600

# Test DNS
docker exec container1 ping -c 2 container2
# Should work!

# Clean up
docker rm -f container1 container2
docker network rm test-net
```

### Test 2: Verify Isolation

```bash
# Create two networks
docker network create net1
docker network create net2

# Containers on different networks
docker run -d --name c1 --network net1 busybox sleep 3600
docker run -d --name c2 --network net2 busybox sleep 3600

# Try to ping (should FAIL)
docker exec c1 ping c2
# ping: bad address 'c2'

# Clean up
docker rm -f c1 c2
docker network rm net1 net2
```

### Test 3: Compose Networking

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  web:
    image: nginx
  api:
    image: busybox
    command: sleep 3600
```

```bash
# Start
docker-compose up -d

# Test connectivity
docker-compose exec api ping web
# Should work!

# Clean up
docker-compose down
```

---

## Common Patterns

### Pattern 1: Frontend + Backend + Database

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - db-data:/var/lib/postgresql/data

  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://postgres:secret@postgres:5432/mydb
    depends_on:
      - postgres

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      API_URL: http://backend:4000
    depends_on:
      - backend

volumes:
  db-data:
```

### Pattern 2: Development with Hot Reload

```yaml
version: '3.8'

services:
  web:
    build: .
    volumes:
      - ./src:/app/src           # Code changes reload
      - /app/node_modules        # Don't overwrite
    environment:
      NODE_ENV: development
    command: npm run dev         # Development server
```

### Pattern 3: Nginx Reverse Proxy

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api
      - frontend

  api:
    build: ./api
    expose:
      - "4000"

  frontend:
    build: ./frontend
    expose:
      - "3000"
```

**nginx.conf:**
```nginx
http {
  upstream api {
    server api:4000;
  }
  
  upstream frontend {
    server frontend:3000;
  }
  
  server {
    location /api {
      proxy_pass http://api;
    }
    
    location / {
      proxy_pass http://frontend;
    }
  }
}
```

---

## Key Takeaways

1. **Default bridge network:**
   - No DNS resolution
   - Use IP addresses
   - Good for quick tests only

2. **Custom networks:**
   - Automatic DNS (use container names!)
   - Network isolation
   - Production-ready
   - Always use these in real projects

3. **Docker Compose:**
   - One file defines entire stack
   - Automatic network creation
   - Service discovery built-in
   - `docker-compose up` is magic

4. **Best practices:**
   - Use custom networks, not default bridge
   - Use named volumes, not anonymous
   - Add health checks for databases
   - Use `.env` for secrets
   - Separate dev/prod configs

5. **Communication patterns:**
   - Containers on same network use service names
   - Frontend connects to backend by name
   - Backend connects to database by name
   - No hardcoded IPs ever!

---

## What's Next?

Now that you've mastered networking and Compose, you're ready for:
- **Container orchestration** - Kubernetes, Docker Swarm
- **CI/CD integration** - Automated builds and deployments
- **Production deployment** - Security, monitoring, scaling
- **Advanced Compose** - Secrets management, configs, stacks

**Remember:** Docker Compose is how most teams develop locally. Master this, and you'll be productive on any Docker-based project!

You now have all the fundamentals:
- ✅ Images and Dockerfiles (Layer optimization)
- ✅ Storage (Volumes, bind mounts, tmpfs)
- ✅ Networking (Custom networks, DNS)
- ✅ Compose (Multi-container apps)

**You're ready to build real applications with Docker!** 🎉🐳
