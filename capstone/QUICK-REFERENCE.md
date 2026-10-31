# Blockchain Network - Quick Reference

## Essential Commands

### Starting/Stopping

```bash
# Start network
docker-compose up -d

# Start with build
docker-compose up -d --build

# Stop network
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Restart a single node
docker-compose restart node1
```

### Monitoring

```bash
# View all logs
docker-compose logs -f

# View specific node logs
docker-compose logs -f node1

# Check container status
docker-compose ps

# Resource usage
docker stats

# Inspect network
docker network inspect blockchain-network
```

### API Testing (curl)

```bash
# Get blockchain
curl http://localhost:5001/chain | jq

# Mine a block
curl http://localhost:5001/mine | jq

# Create transaction
curl -X POST http://localhost:5001/transactions/new \
  -H "Content-Type: application/json" \
  -d '{"sender": "alice", "recipient": "bob", "amount": 5}'

# Trigger consensus
curl http://localhost:5002/nodes/resolve | jq

# Node info
curl http://localhost:5001/info | jq

# Health check
curl http://localhost:5001/health
```

### Debugging

```bash
# Execute command in container
docker exec blockchain-node-1 curl http://localhost:5000/chain

# Shell access
docker exec -it blockchain-node-1 /bin/bash

# Check Python errors
docker logs blockchain-node-1 | grep Error

# Network connectivity test
docker exec blockchain-node-1 ping node2
```

### Common Workflows

#### Simulate Consensus Conflict

```bash
# Terminal 1: Mine on Node 1
curl http://localhost:5001/mine

# Terminal 2: Mine on Node 2
curl http://localhost:5002/mine

# Resolve on Node 3
curl http://localhost:5003/nodes/resolve
```

#### Test Full Transaction Flow

```bash
# 1. Create transaction
curl -X POST http://localhost:5001/transactions/new \
  -H "Content-Type: application/json" \
  -d '{"sender": "alice", "recipient": "bob", "amount": 10}'

# 2. Mine block
curl http://localhost:5001/mine

# 3. Verify in chain
curl http://localhost:5001/chain | jq '.chain[-1].transactions'

# 4. Sync other nodes
curl http://localhost:5002/nodes/resolve
curl http://localhost:5003/nodes/resolve
```

#### Performance Testing

```bash
# Mine 10 blocks and time it
time for i in {1..10}; do curl -s http://localhost:5001/mine > /dev/null; done

# Parallel mining (test conflicts)
curl http://localhost:5001/mine & 
curl http://localhost:5002/mine & 
curl http://localhost:5003/mine &
wait
```

### Cleanup

```bash
# Remove all containers
docker-compose down

# Remove images too
docker-compose down --rmi all

# Nuclear option (remove everything)
docker-compose down -v --rmi all --remove-orphans
```

### Image Management

```bash
# View images
docker images | grep blockchain

# Remove old images
docker image prune -a

# Check image size
docker images blockchain-project_node1 --format "{{.Size}}"
```

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| "Port already in use" | `docker-compose down` or change ports in compose file |
| "Health check failing" | Check logs: `docker logs blockchain-node-1` |
| "Nodes not syncing" | Verify network: `docker network inspect blockchain-network` |
| "Build failed" | Clear cache: `docker-compose build --no-cache` |
| "Out of memory" | Add limits in compose file under `deploy.resources.limits` |

## One-Liners

```bash
# Get chain length of all nodes
for port in 5001 5002 5003; do echo "Node $port:"; curl -s http://localhost:$port/chain | jq '.length'; done

# Check all node health
for port in 5001 5002 5003; do echo "Node $port:"; curl -s http://localhost:$port/health | jq '.status'; done

# Mine on all nodes simultaneously
for port in 5001 5002 5003; do curl -s http://localhost:$port/mine & done; wait

# Trigger consensus on all nodes
for port in 5001 5002 5003; do echo "Node $port:"; curl -s http://localhost:$port/nodes/resolve | jq '.message'; done
```

## Environment Variables

Available in `docker-compose.yml`:

- `NODE_PORT` - Port the Flask app listens on (default: 5000)
- `PEER_NODES` - Comma-separated list of peer addresses

Example:
```yaml
environment:
  - NODE_PORT=5000
  - PEER_NODES=node1:5000,node2:5000
```

## Docker Compose Shortcuts

```bash
# Rebuild only changed services
docker-compose up -d --build

# Force recreate containers
docker-compose up -d --force-recreate

# Scale to N nodes (requires service name, not container_name)
docker-compose up -d --scale node=5

# View compose config
docker-compose config

# Validate compose file
docker-compose config --quiet
```

## Tips

1. **Always check logs first**: `docker-compose logs -f`
2. **Use jq for pretty JSON**: Install with `sudo apt-get install jq` (Ubuntu) or `brew install jq` (macOS)
3. **Test health before API calls**: `curl http://localhost:5001/health`
4. **Consensus takes time**: Wait 2-3 seconds between mine and resolve
5. **Use the test script**: `./test_consensus.sh` runs full workflow

## Key Files

- `blockchain.py` - Core blockchain logic
- `app.py` - Flask API server
- `docker-compose.yml` - Network configuration
- `Dockerfile` - Container image definition
- `test_consensus.sh` - Automated testing

---

**Pro Tip**: Keep this file open in a terminal window while experimenting with the blockchain!
