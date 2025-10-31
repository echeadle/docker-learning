# Docker Security Notes - Basics

## Core Security Principles

### 1. Never Run as Root
**Why:** Root user inside a container has elevated privileges. If the container is compromised, the attacker has root access.

**How to avoid:**
```bash
# In Dockerfile (you'll learn this soon)
USER 1000:1000

# Or when creating container
docker create --user 1000:1000 IMAGE
```

### 2. Use Specific Image Tags
**Why:** The `:latest` tag can change without warning, introducing vulnerabilities or breaking changes.

**Bad:**
```bash
docker pull nginx:latest  # Don't do this in production
```

**Good:**
```bash
docker pull nginx:1.25-alpine  # Specific, predictable version
```

### 3. Minimal Images
**Why:** Smaller images have fewer packages, reducing attack surface.

**Recommendation:**
- Use Alpine-based images when possible (e.g., `nginx:1.25-alpine`)
- Consider distroless images for even better security

### 4. Clean Up Regularly
**Why:** Old containers and images may contain:
- Sensitive data
- Known vulnerabilities
- Unused resources

**Commands:**
```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything unused (careful!)
docker system prune -a
```

### 5. Never Log Sensitive Data
**Why:** Logs are stored on the host filesystem and can be accessed by anyone with Docker access.

**Bad:**
```python
print(f"Connecting with password: {password}")  # Don't do this!
```

**Good:**
```python
print("Connecting to database...")  # Log the action, not the secret
```

## Security Checklist for Beginners

- [ ] Specified exact image versions (no `:latest`)
- [ ] Checked if I need to run as root (usually no)
- [ ] Reviewed logs for sensitive information
- [ ] Cleaned up stopped containers
- [ ] Used read-only filesystem when possible
- [ ] Limited published ports to only what's needed

## Tools to Learn Later

- **Docker Scout:** Scan images for vulnerabilities
- **Trivy:** Open-source vulnerability scanner
- **Docker Bench:** Security audit script
- **Falco:** Runtime security monitoring

## Common Mistakes

1. **Exposing all ports:** Only publish (`-p`) ports you actually need
2. **Running everything as root:** Almost never necessary
3. **Ignoring image sources:** Only pull from trusted registries
4. **Hardcoding secrets:** Use environment variables or secret management
5. **Not updating:** Old images have known vulnerabilities

## Resources

- [Docker Security Documentation](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

---

**Your Security Notes:**

_Document security issues you encounter, solutions you find, and best practices you discover:_

- 
- 
- 
