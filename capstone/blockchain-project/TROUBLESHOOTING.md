# Blockchain Network Troubleshooting Guide

Common issues students encounter and how to fix them.

## Issue 1: "Port already in use"

### Symptoms
```bash
$ docker-compose up -d
ERROR: for blockchain-node-1  Cannot start service node1: 
driver failed programming external connectivity on endpoint blockchain-node-1: 
Bind for 0.0.0.0:5001 failed: port is already allocated
```

### Diagnosis
```bash
# Check what's using the port
sudo lsof -i :5001
# or
sudo netstat -tlnp | grep 5001
```

### Solutions

**Option 1: Stop the conflicting service**
```bash
# Kill the process using the port
sudo kill -9 <PID>
```

**Option 2: Change the port in docker-compose.yml**
```yaml
services:
  node1:
    ports:
      - "5101:5000"  # Changed from 5001 to 5101
```

**Option 3: Stop all Docker containers**
```bash
docker-compose down
# or nuclear option:
docker stop $(docker ps -aq)
```

---

## Issue 2: "Container is unhealthy"

### Symptoms
```bash
$ docker-compose ps
NAME                STATUS
blockchain-node-1   Up 2 minutes (unhealthy)
```

### Diagnosis
```bash
# Check logs
docker logs blockchain-node-1

# Manually test health endpoint
docker exec blockchain-node-1 curl http://localhost:5000/health

# Check if Flask is running
docker exec blockchain-node-1 ps aux | grep python
```

### Common Causes & Solutions

**Cause 1: Flask failed to start**
```bash
# Check for Python errors in logs
docker logs blockchain-node-1 | grep -i error

# Solution: Fix code errors and rebuild
docker-compose up -d --build --force-recreate
```

**Cause 2: Health check timing too aggressive**
```yaml
# In docker-compose.yml, increase start_period:
healthcheck:
  start_period: 30s  # Increased from 10s
```

**Cause 3: curl not installed in container**
```dockerfile
# In Dockerfile, ensure curl is installed:
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

---

## Issue 3: "Nodes can't discover each other"

### Symptoms
```bash
$ curl http://localhost:5002/nodes/resolve
{
  "message": "Our chain is authoritative",
  "chain": [...]
}
# Even though Node 1 has a longer chain!
```

### Diagnosis
```bash
# Check network connectivity
docker exec blockchain-node-2 ping node1

# Check if peers are registered
curl http://localhost:5002/info | jq '.peers'

# Verify network configuration
docker network inspect blockchain-network
```

### Solutions

**Solution 1: Check PEER_NODES environment variable**
```yaml
# In docker-compose.yml
environment:
  - PEER_NODES=node1:5000,node2:5000  # Make sure this is set
```

**Solution 2: Verify all containers on same network**
```bash
# All should show blockchain-network
docker inspect blockchain-node-1 | grep NetworkMode
docker inspect blockchain-node-2 | grep NetworkMode
docker inspect blockchain-node-3 | grep NetworkMode
```

**Solution 3: Use Docker service names, not localhost**
```yaml
# ❌ Wrong
environment:
  - PEER_NODES=localhost:5001,localhost:5002

# ✓ Correct
environment:
  - PEER_NODES=node1:5000,node2:5000
```

---

## Issue 4: "Build takes forever"

### Symptoms
```bash
$ docker-compose build
[+] Building 325.3s (12/12) FINISHED
# Should take <2 minutes
```

### Diagnosis
```bash
# Check Docker build context size
du -sh .
# Should be <1MB

# Check what's being sent to Docker daemon
docker-compose build 2>&1 | head -5
```

### Solutions

**Solution 1: Create .dockerignore**
```bash
# Create file
cat > .dockerignore << 'EOF'
__pycache__
*.pyc
.git
node_modules
.vscode
.idea
.DS_Store
EOF
```

**Solution 2: Clear Docker build cache**
```bash
docker builder prune -a
```

**Solution 3: Use BuildKit**
```bash
export DOCKER_BUILDKIT=1
docker-compose build
```

---

## Issue 5: "Mining takes too long / too fast"

### Symptoms
```bash
# Mining completes instantly (no proof-of-work)
$ time curl http://localhost:5001/mine
real    0m0.05s

# OR mining takes 10+ minutes
$ time curl http://localhost:5001/mine
real    12m30.442s
```

### Diagnosis
```python
# Check difficulty in blockchain.py
@staticmethod
def valid_proof(last_proof, proof):
    guess = f'{last_proof}{proof}'.encode()
    guess_hash = hashlib.sha256(guess).hexdigest()
    return guess_hash[:4] == "0000"  # <-- Number of zeros = difficulty
```

### Solutions

**For Testing (faster mining):**
```python
# blockchain.py, line ~144
return guess_hash[:3] == "000"  # 3 zeros = ~1 second
```

**For Demo (moderate difficulty):**
```python
return guess_hash[:4] == "0000"  # 4 zeros = ~30 seconds (default)
```

**For Production (harder mining):**
```python
return guess_hash[:5] == "00000"  # 5 zeros = ~5 minutes
```

**Dynamic Difficulty (Advanced):**
```python
class Blockchain:
    def __init__(self):
        self.chain = []
        self.current_transactions = []
        self.nodes = set()
        self.difficulty = int(os.getenv('MINING_DIFFICULTY', '4'))
    
    def valid_proof(self, last_proof, proof):
        guess = f'{last_proof}{proof}'.encode()
        guess_hash = hashlib.sha256(guess).hexdigest()
        return guess_hash[:self.difficulty] == "0" * self.difficulty
```

Then set via environment:
```yaml
environment:
  - MINING_DIFFICULTY=3  # For testing
```

---

## Issue 6: "Cannot connect from browser"

### Symptoms
```bash
# Works from terminal
$ curl http://localhost:5001/chain
{"chain": [...]}

# Fails from browser
XMLHttpRequest error: CORS policy
```

### Solution

Add CORS support to Flask:

**1. Update requirements.txt:**
```txt
Flask==3.0.0
requests==2.31.0
flask-cors==4.0.0
```

**2. Update app.py:**
```python
from flask import Flask, jsonify, request
from flask_cors import CORS
from blockchain import Blockchain

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# ... rest of code
```

**3. Rebuild:**
```bash
docker-compose up -d --build
```

---

## Issue 7: "Out of memory / Container crashes"

### Symptoms
```bash
$ docker logs blockchain-node-1
Killed

$ docker stats
CONTAINER           MEM USAGE / LIMIT
blockchain-node-1   1.5GiB / 2GiB
```

### Solutions

**Solution 1: Add memory limits**
```yaml
# docker-compose.yml
services:
  node1:
    # ... existing config ...
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

**Solution 2: Reduce difficulty temporarily**
```python
# blockchain.py - use easier proof-of-work
return guess_hash[:3] == "000"
```

**Solution 3: Increase Docker's memory allocation**
```bash
# Docker Desktop → Settings → Resources → Memory
# Increase from 2GB to 4GB
```

---

## Issue 8: "Consensus always fails"

### Symptoms
```bash
$ curl http://localhost:5002/nodes/resolve
{
  "message": "Our chain is authoritative"
}
# Even when other nodes have longer chains
```

### Diagnosis
```bash
# Check if nodes are registered
curl http://localhost:5002/info | jq '.peers'
# Should show: ["node1:5000", "node3:5000"]

# Check if peers are reachable
docker exec blockchain-node-2 curl http://node1:5000/health
docker exec blockchain-node-2 curl http://node3:5000/health
```

### Solutions

**Solution 1: Verify peers registered on startup**
```python
# app.py - check this code exists:
if __name__ == '__main__':
    for peer in PEER_NODES:
        if peer:
            blockchain.register_node(f'http://{peer}')
    
    app.run(host='0.0.0.0', port=int(NODE_PORT))
```

**Solution 2: Manually register peers**
```bash
curl -X POST http://localhost:5002/nodes/register \
  -H "Content-Type: application/json" \
  -d '{
    "nodes": ["http://node1:5000", "http://node3:5000"]
  }'
```

**Solution 3: Check blockchain validation**
```python
# blockchain.py - ensure valid_chain() is working:
def valid_chain(self, chain):
    last_block = chain[0]
    current_index = 1
    
    while current_index < len(chain):
        block = chain[current_index]
        
        # Check hash
        if block['previous_hash'] != self.hash(last_block):
            print(f"Invalid hash at block {current_index}")  # Add debugging
            return False
        
        # Check proof
        if not self.valid_proof(last_block['proof'], block['proof']):
            print(f"Invalid proof at block {current_index}")  # Add debugging
            return False
        
        last_block = block
        current_index += 1
    
    return True
```

---

## Issue 9: "Docker Compose won't start"

### Symptoms
```bash
$ docker-compose up -d
ERROR: yaml.scanner.ScannerError: mapping values are not allowed here
```

### Diagnosis
```bash
# Validate YAML syntax
docker-compose config --quiet

# If it passes, check for:
# - Incorrect indentation
# - Missing colons
# - Quotes around special characters
```

### Common YAML Mistakes

**❌ Wrong indentation:**
```yaml
services:
  node1:
  ports:
    - "5001:5000"  # Should be indented under node1
```

**✓ Correct:**
```yaml
services:
  node1:
    ports:
      - "5001:5000"
```

**❌ Missing quotes:**
```yaml
environment:
  - PEER_NODES=node1:5000,node2:5000  # Colon confuses YAML
```

**✓ Correct:**
```yaml
environment:
  - "PEER_NODES=node1:5000,node2:5000"
```

---

## Issue 10: "Transactions disappear after restart"

### Symptoms
```bash
# Before restart: 5 blocks
$ curl http://localhost:5001/chain | jq '.length'
5

# After restart: only 1 block (genesis)
$ docker-compose restart node1
$ curl http://localhost:5001/chain | jq '.length'
1
```

### Cause
Blockchain data is only stored in memory, not persisted to disk.

### Solution: Add persistent volumes

**1. Update docker-compose.yml:**
```yaml
version: '3.8'

services:
  node1:
    # ... existing config ...
    volumes:
      - node1-data:/app/data
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node2:5000,node3:5000
      - BLOCKCHAIN_DATA_DIR=/app/data

volumes:
  node1-data:
  node2-data:
  node3-data:
```

**2. Update blockchain.py to save/load from disk:**
```python
import os
import json

class Blockchain:
    def __init__(self):
        self.data_dir = os.getenv('BLOCKCHAIN_DATA_DIR', '/app/data')
        self.chain = []
        self.current_transactions = []
        self.nodes = set()
        
        # Load existing chain or create genesis
        self.load_chain()
    
    def save_chain(self):
        os.makedirs(self.data_dir, exist_ok=True)
        with open(f'{self.data_dir}/chain.json', 'w') as f:
            json.dump(self.chain, f)
    
    def load_chain(self):
        chain_file = f'{self.data_dir}/chain.json'
        if os.path.exists(chain_file):
            with open(chain_file, 'r') as f:
                self.chain = json.load(f)
        else:
            # Create genesis block
            self.new_block(previous_hash='1', proof=100)
    
    def new_block(self, proof, previous_hash=None):
        block = {
            'index': len(self.chain) + 1,
            'timestamp': time.time(),
            'transactions': self.current_transactions,
            'proof': proof,
            'previous_hash': previous_hash or self.hash(self.chain[-1]),
        }
        
        self.current_transactions = []
        self.chain.append(block)
        self.save_chain()  # Persist to disk
        return block
```

**3. Rebuild and restart:**
```bash
docker-compose down -v  # Warning: deletes old data
docker-compose up -d --build
```

---

## General Debugging Workflow

### Step 1: Check Container Status
```bash
docker-compose ps
# Look for: Up, Up (healthy), Restarting, Exit 1
```

### Step 2: Read Logs
```bash
docker-compose logs -f
# Look for: Python errors, Connection refused, Port conflicts
```

### Step 3: Test Connectivity
```bash
# External (from host)
curl http://localhost:5001/health

# Internal (between containers)
docker exec blockchain-node-1 ping node2
docker exec blockchain-node-1 curl http://node2:5000/health
```

### Step 4: Inspect Configuration
```bash
# View resolved compose file
docker-compose config

# Inspect container
docker inspect blockchain-node-1

# Check network
docker network inspect blockchain-network
```

### Step 5: Nuclear Option (Clean Slate)
```bash
# Stop everything
docker-compose down -v

# Remove all related containers
docker rm -f $(docker ps -a | grep blockchain | awk '{print $1}')

# Remove network
docker network rm blockchain-network

# Remove images
docker rmi $(docker images | grep blockchain | awk '{print $3}')

# Start fresh
docker-compose up -d --build
```

---

## Common Error Messages Decoded

### "Cannot connect to the Docker daemon"
**Meaning:** Docker service isn't running  
**Fix:** `sudo systemctl start docker` (Linux) or start Docker Desktop (Mac/Windows)

### "Error response from daemon: conflict"
**Meaning:** Container/network with that name already exists  
**Fix:** `docker-compose down` then try again

### "address already in use"
**Meaning:** Port conflict  
**Fix:** Change ports in docker-compose.yml or kill the conflicting process

### "no such file or directory"
**Meaning:** File missing or incorrect path  
**Fix:** Check file exists: `ls -la blockchain.py app.py`

### "ModuleNotFoundError: No module named 'flask'"
**Meaning:** Dependencies not installed  
**Fix:** `docker-compose build --no-cache`

### "Health check failed"
**Meaning:** Container started but app isn't responding  
**Fix:** Check logs with `docker logs blockchain-node-1`

---

## Prevention Tips

✅ Always check `docker-compose ps` before assuming something works  
✅ Read logs with `docker-compose logs -f` while testing  
✅ Use `.dockerignore` to keep builds fast  
✅ Test health endpoints manually before running automated tests  
✅ Keep backups of working docker-compose.yml configurations  
✅ Use `--build` flag when code changes  
✅ Document any non-standard configurations  

---

## Quick Reference: Essential Commands

```bash
# View all logs
docker-compose logs -f

# Restart single service
docker-compose restart node1

# Rebuild after code change
docker-compose up -d --build --force-recreate

# Check health
curl http://localhost:5001/health

# Shell access
docker exec -it blockchain-node-1 /bin/bash

# Network connectivity test
docker exec blockchain-node-1 ping node2

# Clean slate
docker-compose down -v && docker-compose up -d --build
```

---

## Still Stuck?

### Collect Debug Information

```bash
# 1. System info
docker --version
docker-compose --version
uname -a

# 2. Container status
docker-compose ps

# 3. Logs
docker-compose logs > debug_logs.txt

# 4. Network info
docker network inspect blockchain-network > network_info.txt

# 5. Container config
docker inspect blockchain-node-1 > container_info.txt

# Share these files when asking for help!
```

### Check the GitHub Issues
Search for your error message - someone else probably had the same issue!

### Ask for Help
Include:
1. What you're trying to do
2. What error you're seeing
3. Logs (use `docker-compose logs`)
4. Your docker-compose.yml
5. Docker version

---

**Remember:** Most issues are configuration problems, not code bugs. Double-check environment variables, network settings, and port mappings first!
