# Distributed Blockchain Network with Docker

A fully functional, containerized blockchain network demonstrating distributed consensus, proof-of-work mining, and peer-to-peer synchronization.

## Quick Start

### Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- curl (for testing)
- jq (optional, for pretty output)

### Run the Network

```bash
# Build and start all nodes
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Stop the Network

```bash
docker-compose down
```

## Project Structure

```
blockchain-project/
├── blockchain.py           # Core blockchain logic
├── app.py                 # Flask API server
├── requirements.txt       # Python dependencies
├── Dockerfile            # Container definition
├── docker-compose.yml    # Multi-node orchestration
├── .dockerignore        # Build optimization
├── test_consensus.sh    # Automated testing
└── README.md           # This file
```

## Testing the Blockchain

### 1. Check Node Health

```bash
# Node 1
curl http://localhost:5001/health

# Node 2
curl http://localhost:5002/health

# Node 3
curl http://localhost:5003/health
```

### 2. View the Blockchain

```bash
curl http://localhost:5001/chain | jq
```

### 3. Mine a Block

```bash
curl http://localhost:5001/mine | jq
```

### 4. Create a Transaction

```bash
curl -X POST http://localhost:5001/transactions/new \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "alice",
    "recipient": "bob",
    "amount": 5
  }'
```

### 5. Trigger Consensus

```bash
# Node 2 syncs with the network
curl http://localhost:5002/nodes/resolve | jq
```

### 6. Run Automated Tests

```bash
chmod +x test_consensus.sh
./test_consensus.sh
```

## API Endpoints

| Method | Endpoint              | Description                    |
|--------|-----------------------|--------------------------------|
| GET    | `/chain`              | Get the full blockchain        |
| GET    | `/mine`               | Mine a new block               |
| POST   | `/transactions/new`   | Create a new transaction       |
| POST   | `/nodes/register`     | Register peer nodes            |
| GET    | `/nodes/resolve`      | Trigger consensus algorithm    |
| GET    | `/health`             | Health check                   |
| GET    | `/info`               | Node information               |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Docker Network                      │
│                  (blockchain-net)                    │
│                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│
│  │   Node 1    │  │   Node 2    │  │   Node 3    ││
│  │  (Miner)    │  │  (Miner)    │  │  (Miner)    ││
│  │  Port: 5001 │  │  Port: 5002 │  │  Port: 5003 ││
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘│
│         │                │                │        │
│         └────────────────┼────────────────┘        │
│                          │                          │
└─────────────────────────────────────────────────────┘
```

## How It Works

### Proof of Work

Each block requires finding a number (proof) that when hashed with the previous proof, produces a hash with 4 leading zeros. This takes ~10-30 seconds per block.

### Consensus

When nodes disagree on the blockchain state, they resolve conflicts using the "longest chain rule" - the longest valid chain wins.

### Node Discovery

Nodes know about each other through the `PEER_NODES` environment variable in `docker-compose.yml`.

## Troubleshooting

### Nodes Can't Communicate

```bash
# Check network
docker network inspect blockchain-network

# Test connectivity
docker exec blockchain-node-1 ping node2
```

### Health Checks Failing

```bash
# View logs
docker logs blockchain-node-1

# Manually test health
docker exec blockchain-node-1 curl http://localhost:5000/health
```

### Rebuild After Code Changes

```bash
docker-compose down
docker-compose up -d --build --force-recreate
```

## Scaling the Network

### Add More Nodes

Edit `docker-compose.yml` and add:

```yaml
  node4:
    build: .
    container_name: blockchain-node-4
    ports:
      - "5004:5000"
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node1:5000,node2:5000,node3:5000
    networks:
      - blockchain-net
    depends_on:
      node1:
        condition: service_healthy
    restart: unless-stopped
```

Then restart:

```bash
docker-compose up -d --build
```

## Advanced Features

### Adjust Mining Difficulty

Edit `blockchain.py` line 144:

```python
# Easier (faster mining)
return guess_hash[:3] == "000"

# Harder (slower mining)
return guess_hash[:5] == "00000"
```

### Enable Persistent Storage

Uncomment the volumes section in `docker-compose.yml` and add volume mounts to each service.

### Monitor Resource Usage

```bash
docker stats
```

## Learning Objectives

This project demonstrates:

- Multi-container orchestration with Docker Compose
- Container networking and service discovery
- Health checks and dependencies
- Environment variable configuration
- RESTful API design
- Distributed consensus algorithms
- Proof-of-work mining
- Blockchain fundamentals

## Next Steps

1. Add transaction validation (prevent negative balances)
2. Implement transaction fees for miners
3. Build a web dashboard to visualize the blockchain
4. Add wallet system with public/private keys
5. Implement block validation rules

## Resources

- [Docker Documentation](https://docs.docker.com)
- [Flask Documentation](https://flask.palletsprojects.com)
- [Blockchain Basics](https://www.investopedia.com/terms/b/blockchain.asp)

## License

Educational project - feel free to modify and extend!
