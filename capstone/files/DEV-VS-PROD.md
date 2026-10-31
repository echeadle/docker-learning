# Development vs Production: Configuration Comparison

This document shows the key differences between development and production configurations, explaining WHY each change matters.

---

## Quick Visual Comparison

```
Development                          Production
├── Build locally                    ├── Use registry images
├── Mount source code                ├── Code baked into image
├── No resource limits               ├── CPU & memory limits
├── Basic health checks              ├── Comprehensive health checks
├── Restart: no                      ├── Restart: unless-stopped
├── Console logging                  ├── Rotated file logging
├── Debug environment                ├── Production environment
└── Minimal security                 └── Hardened security
```

---

## Side-by-Side Configuration

### 1. Image Source

| Development | Production | Why? |
|------------|------------|------|
| `build: .` | `image: registry.com/app:1.0.0` | Production uses immutable, versioned images from a registry. This ensures consistency across all environments and allows rollbacks. |
| Builds on every startup | Pre-built and pushed | Faster deployments, no build dependencies on production servers |
| `latest` tag or no tag | Specific semantic version | `latest` can change unexpectedly. `1.0.0` is guaranteed to be the same image forever |

**Development:**
```yaml
services:
  node1:
    build: .
```

**Production:**
```yaml
services:
  node1:
    image: myregistry.com/blockchain-node:1.0.0
```

---

### 2. Source Code Handling

| Development | Production | Why? |
|------------|------------|------|
| Bind mount: `./app:/app` | No mount | Production images must be immutable. Code changes require new builds and deployments |
| Live reloading | Container restart needed | Development prioritizes fast iteration, production prioritizes stability |
| Local files accessible | Only files in image | Prevents accidental modifications to running production code |

**Development:**
```yaml
volumes:
  - ./app:/app              # Live code reloading
  - /app/node_modules       # Preserve installed packages
```

**Production:**
```yaml
# No volumes for source code!
# Code is COPY'd into image during build
```

---

### 3. Restart Policies

| Development | Production | Why? |
|------------|------------|------|
| `restart: no` | `restart: unless-stopped` | Development wants to see crashes. Production wants automatic recovery |
| Manual restart needed | Automatic restart | Production minimizes downtime, even from crashes |
| Fail fast | Keep running | Different debugging vs reliability goals |

**Development:**
```yaml
services:
  node1:
    # No restart policy (defaults to 'no')
```

**Production:**
```yaml
services:
  node1:
    restart: unless-stopped
```

**Restart policy options:**
- `no` - Never restart (development default)
- `always` - Always restart, even after manual stop
- `unless-stopped` - Restart unless explicitly stopped
- `on-failure:3` - Only restart on errors, max 3 tries

---

### 4. Resource Limits

| Development | Production | Why? |
|------------|------------|------|
| No limits | CPU & memory limits enforced | Prevents one container from consuming all server resources |
| Can use 100% of resources | Guaranteed minimums, hard maximums | Ensures fair resource sharing and prevents OOM killer |
| No process limits | PID limits | Prevents fork bombs and runaway processes |

**Development:**
```yaml
services:
  node1:
    # No resource limits
```

**Production:**
```yaml
services:
  node1:
    deploy:
      resources:
        limits:
          cpus: '1.0'          # Maximum 1 CPU core
          memory: 1G           # Maximum 1GB RAM
        reservations:
          cpus: '0.5'          # Guaranteed 0.5 CPU
          memory: 512M         # Guaranteed 512MB RAM
```

**Real-world impact:**
- Without limits: One misbehaving container can crash the entire server
- With limits: Container is throttled or OOM-killed before affecting others

---

### 5. Health Checks

| Development | Production | Why? |
|------------|------------|------|
| Basic check every 30s | Comprehensive check with tuned intervals | Production needs reliable detection of unhealthy containers |
| Generous timeouts | Appropriate timeouts | Balance between false positives and detection speed |
| Few retries | Multiple retries | Avoid marking healthy containers as unhealthy due to temporary glitches |

**Development:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

**Production:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
  interval: 30s              # Check every 30 seconds
  timeout: 10s               # Fail if takes >10s
  retries: 3                 # 3 failures = unhealthy
  start_period: 15s          # Longer grace period for slower production starts
```

**Health check states:**
- `starting` - During start_period, failures don't count
- `healthy` - All checks passing
- `unhealthy` - Multiple consecutive failures

---

### 6. Logging Configuration

| Development | Production | Why? |
|------------|------------|------|
| Console output | Rotated files | Production needs to prevent disk space exhaustion |
| No size limits | 10MB max per file | Prevents logs from filling disk |
| No rotation | Keep last 3 files | Balance between disk space and debugging history |

**Development:**
```yaml
# Default logging (unlimited size)
```

**Production:**
```yaml
services:
  node1:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"      # Rotate at 10MB
        max-file: "3"        # Keep 3 files (30MB total)
```

**Impact:**
- A chatty application can generate 1GB+ logs per day
- Without rotation, logs eventually fill disk → server crash
- With rotation, disk usage is capped at 30MB per container

---

### 7. Environment Variables

| Development | Production | Why? |
|------------|------------|------|
| `DEBUG=true` | `DEBUG=false` | Production hides internal details |
| `LOG_LEVEL=debug` | `LOG_LEVEL=warning` | Reduces log volume and sensitive data leakage |
| Development database | Production database | Separate data environments |
| Loose security | Strict security | Production requires hardening |

**Development:**
```yaml
environment:
  - NODE_ENV=development
  - DEBUG=true
  - LOG_LEVEL=debug
```

**Production:**
```yaml
environment:
  - NODE_ENV=production
  - LOG_LEVEL=warning
  - PYTHONUNBUFFERED=1       # Ensure logs flush immediately
```

---

### 8. Network Configuration

| Development | Production | Why? |
|------------|------------|------|
| Simple bridge network | Named, configured network | Production needs predictable network names |
| Default settings | Custom subnet | Control IP address range |
| No encryption | Encrypted overlay | Security for multi-host deployments |

**Development:**
```yaml
networks:
  blockchain-net:
    driver: bridge
```

**Production:**
```yaml
networks:
  blockchain-net:
    driver: bridge
    name: blockchain-network-prod    # Explicit name
    driver_opts:
      com.docker.network.bridge.name: br-blockchain-prod
```

---

### 9. Security Hardening

| Development | Production | Why? |
|------------|------------|------|
| Root user | Non-root user | Principle of least privilege |
| All capabilities | Dropped capabilities | Reduce attack surface |
| Writable filesystem | Read-only filesystem | Prevent malicious modifications |

**Development:**
```yaml
# No security hardening
```

**Production:**
```yaml
services:
  node1:
    security_opt:
      - no-new-privileges:true    # Prevent privilege escalation
    # Optional but recommended:
    # user: "1000:1000"            # Run as non-root
    # read_only: true              # Read-only root filesystem
    # cap_drop:                    # Drop all capabilities
    #   - ALL
```

---

### 10. Dependencies and Startup Order

| Development | Production | Why? |
|------------|------------|------|
| Simple `depends_on` | Conditional dependencies | Production waits for actual readiness, not just startup |
| No restart triggers | Restart dependents | Cascade restarts when dependencies restart |

**Development:**
```yaml
services:
  node2:
    depends_on:
      - node1           # Just wait for start
```

**Production:**
```yaml
services:
  node2:
    depends_on:
      node1:
        condition: service_healthy    # Wait for health check
        restart: true                 # Restart if node1 restarts
```

---

### 11. Port Exposure

| Development | Production | Why? |
|------------|------------|------|
| All ports exposed | Minimal exposure | Reduce attack surface |
| Debug ports open | Debug ports closed | Prevent unauthorized access |
| Host networking sometimes | Bridge networking always | Better isolation |

**Development:**
```yaml
ports:
  - "5001:5000"
  - "9229:9229"      # Debug port
```

**Production:**
```yaml
ports:
  - "5001:5000"      # Only necessary ports
# No debug ports exposed!
```

---

## Complete Side-by-Side Example

### Development (docker-compose.yml)

```yaml
version: '3.8'

services:
  node1:
    build: .                                    # ← Build locally
    container_name: blockchain-node-1
    ports:
      - "5001:5000"
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node2:5000,node3:5000
      - DEBUG=true                              # ← Debug mode
    networks:
      - blockchain-net
    healthcheck:                                # ← Basic health check
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    # No restart policy                         # ← Fail fast
    # No resource limits                        # ← Use all resources
    # No logging config                         # ← Unlimited logs

networks:
  blockchain-net:
    driver: bridge
```

### Production (docker-compose.prod.yml)

```yaml
version: '3.8'

services:
  node1:
    image: myregistry.com/blockchain-node:1.0.0 # ← Registry image
    # No container_name (allows scaling)
    ports:
      - "5001:5000"
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node2:5000,node3:5000
      - LOG_LEVEL=warning                       # ← Production logging
      - PYTHONUNBUFFERED=1
    networks:
      - blockchain-net
    restart: unless-stopped                     # ← Auto-restart
    healthcheck:                                # ← Enhanced health check
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s                         # ← Longer start period
    deploy:                                     # ← Resource limits
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    logging:                                    # ← Log rotation
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:                               # ← Security hardening
      - no-new-privileges:true

networks:
  blockchain-net:
    driver: bridge
    name: blockchain-network-prod               # ← Explicit name
```

---

## Migration Checklist

When moving from development to production:

### Images
- [ ] Build production images
- [ ] Push to container registry
- [ ] Use semantic versioning (1.0.0, not latest)
- [ ] Test images before deployment

### Configuration
- [ ] Remove all bind mounts
- [ ] Add resource limits
- [ ] Configure restart policies
- [ ] Set up log rotation
- [ ] Update environment variables (DEBUG=false, etc.)
- [ ] Add security hardening

### Infrastructure
- [ ] Set up production server
- [ ] Configure firewall
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Document deployment process

### Deployment
- [ ] Test deployment process
- [ ] Verify all health checks pass
- [ ] Test blockchain functionality
- [ ] Monitor resource usage
- [ ] Set up alerts

---

## Common Mistakes to Avoid

### ❌ Using `latest` tag in production
```yaml
image: myapp:latest  # BAD - can change unexpectedly
```
**Fix:**
```yaml
image: myapp:1.2.3   # GOOD - specific version
```

### ❌ No resource limits
Without limits, one container can crash the server.

**Fix:**
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
```

### ❌ No log rotation
Logs grow infinitely and fill disk.

**Fix:**
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### ❌ Mounting source code in production
```yaml
volumes:
  - ./app:/app  # BAD - mutable production code
```

**Fix:** Bake code into image during build (no volume)

### ❌ No restart policy
Container crashes → service down until manual restart.

**Fix:**
```yaml
restart: unless-stopped
```

---

## Summary

The key principle: **Development optimizes for iteration speed, production optimizes for reliability and security**.

| Concern | Development | Production |
|---------|------------|------------|
| **Speed** | Fast iteration | Stable operation |
| **Security** | Minimal | Hardened |
| **Resources** | Unlimited | Limited |
| **Failures** | Fail fast | Auto-recover |
| **Logs** | Unlimited | Rotated |
| **Images** | Local builds | Registry |
| **Code** | Live reload | Immutable |

**Remember:** Every production change has a reason. Don't skip hardening steps just because "it works in development"—production has different failure modes and attack vectors.
