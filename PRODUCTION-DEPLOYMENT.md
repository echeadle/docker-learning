# Docker Compose Production Deployment: From Development to Enterprise Scale

Docker Compose has evolved from a purely development tool into a production-capable orchestration platform. While traditionally focused on development workflows, **Compose now supports essential production features including resource limits, health checks, secrets management, and rolling updates**—though critical high-availability features still require Docker Swarm or Kubernetes. This guide provides a comprehensive roadmap for deploying blockchain network applications with multiple nodes, progressing from basic development setups through production-hardening to advanced enterprise configurations.

Understanding the production deployment landscape is crucial: **Compose works well for single-server production deployments** but lacks native clustering and automatic failover. For multi-server high availability, you'll need Docker Swarm (which uses the same Compose file format) or Kubernetes. The latest Compose Specification has removed version numbers entirely, unifying features from legacy versions 2.x and 3.x into a rolling standard that's implemented in Compose v2.

## Moving from Development to Production

### The Multiple Compose File Strategy

Rather than maintaining separate Compose files, Docker recommends **defining a production override file** (e.g., `docker-compose.prod.yml`) that applies production-specific changes over your base `docker-compose.yml`. 

**Deploy using:**
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

This approach keeps your development and production configurations synchronized while isolating environment-specific settings.

### Critical Changes for Production

**1. Remove Volume Bindings for Application Code**

Development relies on bind mounts for live reloading:
```yaml
# ❌ Development only
volumes:
  - ./app:/code
```

Production images must be immutable with code baked in:
```yaml
# ✅ Production
# No bind mounts - code is in the image
```

**2. Pin Specific Image Versions**

Never use `latest` tags in production:
```yaml
# ❌ Risky
image: nginx:latest

# ✅ Good
image: nginx:1.25.3

# ✅ Best (immutable)
image: nginx@sha256:0ed5d5928d4737458944eb604cc8509e245c3e19d02ad83935398bc4b991aac7
```

**3. Adjust Port Mappings**

Development exposes ports directly:
```yaml
# Development
ports:
  - "8080:80"
```

Production uses reverse proxies:
```yaml
# Production
expose:
  - 80
# Let nginx handle external access
```

**4. Change Environment Variables**

Development uses debug mode:
```yaml
# Development
environment:
  - DEBUG=true
  - LOG_LEVEL=debug
```

Production optimizes for performance:
```yaml
# Production
environment:
  - DEBUG=false
  - LOG_LEVEL=warning
```

**5. Configure Restart Policies**

Development fails fast:
```yaml
# Development
restart: "no"
```

Production ensures availability:
```yaml
# Production
restart: unless-stopped
```

---

## Basic Production Hardening

### Resource Limits

Prevent runaway containers from consuming all system resources:

```yaml
services:
  blockchain-node:
    image: myregistry.com/blockchain-node:1.2.3
    deploy:
      resources:
        limits:
          cpus: '2.0'        # Maximum 2 CPU cores
          memory: 4G         # Maximum 4GB RAM
        reservations:
          cpus: '1.0'        # Guaranteed 1 CPU core
          memory: 2G         # Guaranteed 2GB RAM
```

**Limits** define maximum consumption—the container cannot exceed these values.  
**Reservations** guarantee minimum resources—the scheduler ensures these resources are available.

### Health Checks

Enable automatic recovery from failure states:

```yaml
services:
  api:
    image: myapi:1.0.0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s          # Check every 30 seconds
      timeout: 10s           # Fail if check takes >10s
      retries: 3             # Mark unhealthy after 3 failures
      start_period: 40s      # Grace period for startup
      start_interval: 5s     # Check more frequently during startup
```

**Database health checks:**
- PostgreSQL: `["CMD-SHELL", "pg_isready -U postgres"]`
- MySQL: `["CMD-SHELL", "mysql --user=root --password=$$MYSQL_ROOT_PASSWORD --execute \"SHOW DATABASES;\""]`
- Redis: `["CMD", "redis-cli", "ping"]`

### Network Isolation

Implement defense in depth with multiple security zones:

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
  database:
    driver: bridge
    internal: true           # No external connectivity

services:
  nginx:
    networks:
      - frontend
    ports:
      - "80:80"
      
  api:
    networks:
      - frontend             # Accepts requests from nginx
      - backend              # Communicates with workers
      
  worker:
    networks:
      - backend              # Processes jobs
      - database             # Accesses database
      
  postgres:
    networks:
      - database             # Completely isolated
```

### Environment Variable Management

**Never hardcode secrets in Compose files**:

```yaml
# ❌ Bad - secrets in version control
environment:
  - DATABASE_PASSWORD=mysecret123

# ✅ Good - use variable substitution
environment:
  - DATABASE_PASSWORD=${DB_PASSWORD}
```

Use `.env` files with proper priority:

```yaml
services:
  api:
    env_file:
      - ./common.env         # Shared settings
      - ./production.env     # Production overrides
```

**Environment variable precedence** (highest to lowest):
1. Values in `environment:` section
2. Values from `env_file:` (last file wins)
3. Values from shell environment

### Logging Configuration

The default `json-file` driver has no rotation, which can fill production disks:

```yaml
services:
  api:
    logging:
      driver: local
      options:
        max-size: "10m"      # Rotate at 10MB
        max-file: "5"        # Keep 5 files (50MB total)
```

**For centralized logging:**
- GELF (ELK Stack): `driver: gelf` with `gelf-address: "udp://logstash:12201"`
- Fluentd: `driver: fluentd` with `fluentd-address: "fluentd:24224"`
- Cloud: `awslogs` for CloudWatch, `gcplogs` for Google Cloud Logging

**Use YAML anchors to apply globally:**

```yaml
x-logging: &default-logging
  driver: local
  options:
    max-size: "10m"
    max-file: "5"

services:
  api:
    logging: *default-logging
  worker:
    logging: *default-logging
```

### Restart Policies

Ensure high availability through automatic recovery:

```yaml
services:
  api:
    restart: unless-stopped    # Restart unless manually stopped
    
  worker:
    restart: on-failure        # Only restart on error
    
  # For Swarm deployments
  validator:
    deploy:
      restart_policy:
        condition: on-failure    # none, on-failure, any
        delay: 5s               # Wait between restarts
        max_attempts: 3         # Maximum failed attempts
        window: 120s            # Success window
```

---

## Advanced Production Features

### Horizontal Scaling

Scale services across multiple containers:

```yaml
services:
  validator-node:
    image: myregistry.com/validator:1.0.0
    deploy:
      mode: replicated
      replicas: 5            # Run 5 instances
    environment:
      - NETWORK_ID=1214
      - BOOTNODE_ENODE=${BOOTNODE_ENODE}
    networks:
      - blockchain-net
```

**Deploy modes:**
- `replicated` (default): Run specified number of tasks
- `global`: Run exactly one task per node
- `replicated-job`: Execute tasks until completion

### Static IP Assignment

Critical for blockchain bootnodes:

```yaml
networks:
  blockchain-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.254.0/28

services:
  bootnode:
    image: myregistry.com/bootnode:1.0.0
    networks:
      blockchain-net:
        ipv4_address: 172.16.254.2
```

### Load Balancing

**VIP (Virtual IP) mode** assigns a virtual IP with automatic routing:

```yaml
services:
  api:
    deploy:
      endpoint_mode: vip      # Default
      replicas: 3
```

**DNS round-robin mode** returns multiple IPs for client-side load balancing:

```yaml
services:
  api:
    deploy:
      endpoint_mode: dnsrr
```

For HTTP/HTTPS workloads, add a reverse proxy (NGINX or Traefik) for advanced features.

### Secrets Management

Docker Secrets provide secure credential distribution:

```yaml
services:
  api:
    image: myapi:1.0.0
    secrets:
      - db_password
      - api_key
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - API_KEY_FILE=/run/secrets/api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```

**Long syntax for granular control:**

```yaml
services:
  api:
    secrets:
      - source: db_password
        target: /run/secrets/db_pass    # Custom path
        uid: "103"                       # File ownership
        gid: "103"
        mode: 0440                       # File permissions
```

### Rolling Updates

Zero-downtime deployments with automatic rollback:

```yaml
services:
  api:
    image: myapi:${VERSION}
    deploy:
      replicas: 6
      update_config:
        parallelism: 2           # Update 2 at a time
        delay: 10s               # Wait 10s between batches
        failure_action: rollback # Rollback on failure
        monitor: 60s             # Monitor for 60s
        max_failure_ratio: 0.2   # Tolerate 20% failures
        order: start-first       # Brief overlap for zero downtime
```

**Update order:**
- `stop-first` (default): Stop old before starting new (may cause downtime)
- `start-first`: Start new before stopping old (requires extra capacity)

**Automatic rollback:**

```yaml
services:
  api:
    deploy:
      rollback_config:
        parallelism: 3
        delay: 5s
        failure_action: pause
        monitor: 30s
        max_failure_ratio: 0.1
```

### Security Hardening

Run containers with minimal privileges:

```yaml
services:
  api:
    image: myapi:1.0.0
    user: "1000:1000"              # Non-root user
    read_only: true                # Read-only root filesystem
    security_opt:
      - no-new-privileges:true     # Prevent privilege escalation
    cap_drop:
      - ALL                        # Drop all capabilities
    cap_add:
      - NET_BIND_SERVICE          # Add only required capabilities
    tmpfs:
      - /tmp                       # Writable temp directory
```

### Production Monitoring

Integrate Prometheus and Grafana:

```yaml
services:
  prometheus:
    image: prom/prometheus:v2.55.0
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:11.3.0
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards:ro

volumes:
  prometheus_data:
  grafana_data:
```

### Automated Backups

Run backup services as sidecars:

```yaml
services:
  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backup:
    image: prodrigestivill/postgres-backup-local
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=mydb
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - SCHEDULE=@daily
      - BACKUP_KEEP_DAYS=7
      - BACKUP_KEEP_WEEKS=4
      - BACKUP_KEEP_MONTHS=6
    volumes:
      - ./backups:/backups
    depends_on:
      - postgres

volumes:
  postgres_data:
```

---

## Complete Blockchain Network Example

This section demonstrates the progressive enhancement approach with three configuration levels.

### Level 1: Development Configuration

Simple setup for local development with live code reloading:

```yaml
# docker-compose.yml
services:
  bootnode:
    build:
      context: ./blockchain
      dockerfile: Dockerfile
    command: 
      - --nodekeyhex=${BOOTNODE_KEY}
      - --nodiscover
      - --networkid=1214
    networks:
      - blockchain-net

  validator:
    build:
      context: ./blockchain
      dockerfile: Dockerfile
    command:
      - --bootnodes=${BOOTNODE_ENODE}
      - --mine
      - --networkid=1214
    depends_on:
      - bootnode
    networks:
      - blockchain-net

  api:
    build: ./api
    ports:
      - "3000:3000"
    volumes:
      - ./api:/app          # Live code reloading
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - RPC_URL=http://rpc-node:8545
    depends_on:
      - rpc-node
    networks:
      - blockchain-net

  rpc-node:
    build:
      context: ./blockchain
      dockerfile: Dockerfile
    command:
      - --bootnodes=${BOOTNODE_ENODE}
      - --http
      - --http.addr=0.0.0.0
      - --http.api=eth,web3,net
      - --networkid=1214
    expose:
      - 8545
    depends_on:
      - bootnode
    networks:
      - blockchain-net

networks:
  blockchain-net:
    driver: bridge
```

### Level 2: Basic Production

Production-hardened configuration with essential security and reliability features:

```yaml
# docker-compose.prod.yml
services:
  bootnode:
    image: myregistry.com/blockchain-node:1.2.3
    command: 
      - --nodekeyhex=${BOOTNODE_KEY}
      - --nodiscover
      - --ipcdisable
      - --networkid=1214
      - --netrestrict=172.20.0.0/24
    networks:
      blockchain-net:
        ipv4_address: 172.20.0.10
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
    logging:
      driver: local
      options:
        max-size: "10m"
        max-file: "5"

  validator:
    image: myregistry.com/blockchain-node:1.2.3
    command:
      - --bootnodes=enode://${BOOTNODE_ID}@172.20.0.10:30303
      - --mine
      - --miner.threads=2
      - --networkid=1214
      - --netrestrict=172.20.0.0/24
    depends_on:
      - bootnode
    networks:
      - blockchain-net
    restart: unless-stopped
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
    logging:
      driver: local
      options:
        max-size: "10m"
        max-file: "5"

  api:
    image: myregistry.com/blockchain-api:1.0.0
    environment:
      - NODE_ENV=production
      - RPC_URL=http://rpc-node:8545
      - DB_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    depends_on:
      rpc-node:
        condition: service_healthy
      postgres:
        condition: service_healthy
    networks:
      - blockchain-net
      - backend
    restart: on-failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1.0'
          memory: 2G

  rpc-node:
    image: myregistry.com/blockchain-node:1.2.3
    command:
      - --bootnodes=enode://${BOOTNODE_ID}@172.20.0.10:30303
      - --http
      - --http.addr=0.0.0.0
      - --http.api=eth,web3,net
      - --networkid=1214
    expose:
      - 8545
    depends_on:
      - bootnode
    networks:
      - blockchain-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8545"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: apiuser
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: blockchain_api
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U apiuser"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:1.25-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - api
    networks:
      - blockchain-net
    restart: unless-stopped

networks:
  blockchain-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  backend:
    driver: bridge
    internal: true

volumes:
  postgres_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Key improvements from development:**
- Removed bind mounts and build directives
- Added specific image tags
- Configured restart policies
- Implemented health checks
- Set resource limits
- Added network isolation
- Configured log rotation
- Introduced secrets for credentials

### Level 3: Enterprise Production

Advanced configuration with complete security hardening, monitoring, backups, and rolling updates:

```yaml
# docker-compose.enterprise.yml

x-logging: &default-logging
  driver: local
  options:
    max-size: "10m"
    max-file: "5"

services:
  bootnode:
    image: myregistry.com/blockchain-node:1.2.3
    command: 
      - --nodekeyhex=${BOOTNODE_KEY}
      - --nodiscover
      - --ipcdisable
      - --networkid=1214
      - --netrestrict=172.20.0.0/24
    networks:
      blockchain-net:
        ipv4_address: 172.20.0.10
    restart: unless-stopped
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    tmpfs:
      - /tmp
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
    logging: *default-logging

  validator:
    image: myregistry.com/blockchain-node:1.2.3
    command:
      - --bootnodes=enode://${BOOTNODE_ID}@172.20.0.10:30303
      - --mine
      - --miner.threads=2
      - --networkid=1214
      - --netrestrict=172.20.0.0/24
    depends_on:
      - bootnode
    networks:
      - blockchain-net
    restart: unless-stopped
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp
      - /root/.ethereum
    deploy:
      mode: replicated
      replicas: 5
      update_config:
        parallelism: 1
        delay: 30s
        failure_action: rollback
        monitor: 60s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
      placement:
        constraints:
          - node.role == worker
        preferences:
          - spread: node.labels.zone
    logging: *default-logging

  api:
    image: myregistry.com/blockchain-api:${VERSION:-1.0.0}
    environment:
      - NODE_ENV=production
      - RPC_URL=http://rpc-node:8545
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=blockchain_api
      - DB_USER=apiuser
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - JWT_SECRET_FILE=/run/secrets/jwt_secret
    secrets:
      - db_password
      - jwt_secret
    depends_on:
      rpc-node:
        condition: service_healthy
        restart: true
      postgres:
        condition: service_healthy
        restart: true
    networks:
      - blockchain-net
      - backend
      - monitoring
    restart: on-failure
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      mode: replicated
      replicas: 3
      update_config:
        parallelism: 1
        delay: 15s
        failure_action: rollback
        monitor: 45s
        max_failure_ratio: 0.2
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
    logging: *default-logging

  rpc-node:
    image: myregistry.com/blockchain-node:1.2.3
    command:
      - --bootnodes=enode://${BOOTNODE_ID}@172.20.0.10:30303
      - --http
      - --http.addr=0.0.0.0
      - --http.api=eth,web3,net
      - --http.corsdomain=*
      - --networkid=1214
      - --netrestrict=172.20.0.0/24
    expose:
      - 8545
    depends_on:
      - bootnode
    networks:
      - blockchain-net
    restart: unless-stopped
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp
      - /root/.ethereum
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8545"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    logging: *default-logging

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: apiuser
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: blockchain_api
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init:/docker-entrypoint-initdb.d:ro
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U apiuser -d blockchain_api"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 20s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    logging: *default-logging

  nginx:
    image: nginx:1.25-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - static_files:/usr/share/nginx/html:ro
    depends_on:
      - api
    networks:
      - blockchain-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    logging: *default-logging

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
    logging: *default-logging

  backup:
    image: prodrigestivill/postgres-backup-local
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=blockchain_api
      - POSTGRES_USER=apiuser
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
      - SCHEDULE=0 2 * * *
      - BACKUP_KEEP_DAYS=30
      - BACKUP_KEEP_WEEKS=8
      - BACKUP_KEEP_MONTHS=12
    secrets:
      - db_password
    volumes:
      - ./backups:/backups
    depends_on:
      - postgres
    networks:
      - backend
    restart: unless-stopped
    logging: *default-logging

  prometheus:
    image: prom/prometheus:v2.55.0
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    networks:
      - monitoring
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
    logging: *default-logging

  grafana:
    image: grafana/grafana:11.3.0
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD_FILE=/run/secrets/grafana_password
      - GF_USERS_ALLOW_SIGN_UP=false
    secrets:
      - grafana_password
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    depends_on:
      - prometheus
    networks:
      - monitoring
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
    logging: *default-logging

  node-exporter:
    image: prom/node-exporter:latest
    command:
      - '--path.rootfs=/host'
    volumes:
      - /:/host:ro,rslave
    networks:
      - monitoring
    restart: unless-stopped
    deploy:
      mode: global
    logging: *default-logging

networks:
  blockchain-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  backend:
    driver: bridge
    internal: true
  monitoring:
    driver: bridge
    internal: true

volumes:
  postgres_data:
  redis_data:
  static_files:
  prometheus_data:
  grafana_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
  grafana_password:
    file: ./secrets/grafana_password.txt
```

**Enterprise enhancements:**
- Complete security hardening (read-only filesystems, dropped capabilities, non-root users)
- Sophisticated rolling updates with automatic rollback
- Placement constraints for multi-zone distribution
- Redis for caching and session management
- Automated daily backups with retention policies
- Comprehensive monitoring (Prometheus, Grafana, node-exporter)
- Multiple secrets for different services
- Resource reservations for guaranteed performance

---

## When to Use What

### Docker Compose (Standalone)
**Best for:** Single-server production deployments

✅ Use when:
- Application fits on one server
- Manual intervention during outages is acceptable
- No automatic failover required
- Simple scaling needs

### Docker Swarm
**Best for:** Multi-server clusters with HA

✅ Use when:
- Need high availability across multiple nodes
- Want to keep Compose file compatibility
- Require automatic failover
- Multi-zone deployments

### Kubernetes
**Best for:** Large-scale, enterprise deployments

✅ Use when:
- Deploying dozens to hundreds of services
- Need advanced auto-scaling
- Require multi-cloud deployments
- Want service mesh integration
- Team has K8s expertise

---

## Deployment Commands

### Development
```bash
# Start development environment
docker compose up -d

# Watch for changes and auto-reload
docker compose watch

# View logs
docker compose logs -f
```

### Production (Single File)
```bash
# Deploy to production
docker compose -f docker-compose.prod.yml up -d

# Update specific service
docker compose -f docker-compose.prod.yml up -d --no-deps api

# Scale service
docker compose -f docker-compose.prod.yml up -d --scale validator=5
```

### Production (Layered Files)
```bash
# Deploy with production overrides
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View effective configuration
docker compose -f docker-compose.yml -f docker-compose.prod.yml config

# Update with zero downtime
docker compose -f docker-compose.yml -f docker-compose.prod.yml build api
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --no-deps api
```

### Docker Swarm
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml blockchain

# Update service
docker service update --image myregistry.com/api:1.1.0 blockchain_api

# Scale service
docker service scale blockchain_validator=10

# Remove stack
docker stack rm blockchain
```

---

## Production Checklist

Before deploying to production, verify:

- [ ] All images use specific version tags (not `latest`)
- [ ] Resource limits configured on all services
- [ ] Health checks implemented with appropriate intervals
- [ ] Restart policies configured (`unless-stopped` or `on-failure`)
- [ ] Logging configured with rotation
- [ ] Secrets used for all credentials (not environment variables)
- [ ] Network isolation implemented (internal networks for databases)
- [ ] Security hardening applied (read-only filesystem, dropped capabilities)
- [ ] Monitoring and alerting configured
- [ ] Backup automation in place
- [ ] Recovery procedures documented and tested
- [ ] Update strategy defined (rolling updates, rollback procedures)

---

## Key Takeaways

1. **Progressive Enhancement**: Start with basic production hardening, add advanced features as needed

2. **Never Use `latest`**: Always pin specific image versions or use digest-based references

3. **Secrets Management**: Use Docker secrets, never hardcode credentials

4. **Resource Limits**: Prevent resource exhaustion with limits and reservations

5. **Health Checks**: Enable automatic recovery from failure states

6. **Network Isolation**: Implement defense in depth with multiple security zones

7. **Logging**: Configure rotation to prevent disk exhaustion

8. **Know Your Scale**: Use Compose for single-server, Swarm for multi-server, Kubernetes for enterprise

9. **Test Backups**: Untested backups are indistinguishable from no backups

10. **Monitor Everything**: You can't improve what you don't measure

---

## Additional Resources

- [Official Docker Compose Documentation](https://docs.docker.com/compose/)
- [Compose Production Guide](https://docs.docker.com/compose/how-tos/production/)
- [Docker Secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Compose File Reference](https://docs.docker.com/reference/compose-file/)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)

---

**Remember**: Good production deployment is about layering best practices progressively. Start with the essentials that prevent common failures, then add sophisticated features as your requirements grow. The blockchain network examples show this progression clearly—each level builds on the previous one, allowing you to deploy exactly the complexity your situation demands.
