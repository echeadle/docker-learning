# Section 7: Capstone Project - Containerizing a Distributed Blockchain Network

## What You'll Build

By the end of this capstone, you'll have a **fully functional, multi-node blockchain network** running in Docker containers that can:

- Mine blocks with proof-of-work
- Synchronize across multiple nodes
- Handle transactions between wallets
- Resolve conflicts using the longest chain rule
- Scale from 3 to 10+ nodes with a single command

**Why this matters:** Blockchain is the perfect capstone because it requires everything you've learned:
- Multi-container orchestration (Docker Compose)
- Container networking (nodes need to discover and talk to each other)
- Volume management (persistent blockchain data)
- Environment variables (configuring each node)
- Layer optimization (faster development iteration)
- Health checks and dependencies (nodes must be ready before syncing)

---

## The Big Picture: What Is a Blockchain Network?

**The Simple Explanation:**

Think of a blockchain as a shared notebook that multiple people write in, but with special rules:
1. Each page (block) is numbered and references the previous page
2. Before adding a page, you must solve a puzzle (proof-of-work)
3. Everyone has a copy of the entire notebook
4. If two people add different pages at the same time, the longest notebook wins

**In our Docker context:**
- Each Docker container = one person with their own copy of the notebook
- Containers communicate over a Docker network to sync their notebooks
- When one container mines a block, it broadcasts to all others
- Conflicts are resolved automatically using consensus rules

---

## Project Architecture

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
│                 ┌────────┴────────┐                │
│                 │  Blockchain DB  │                │
│                 │   (Volume)      │                │
│                 └─────────────────┘                │
└─────────────────────────────────────────────────────┘
```

---

## Phase 1: Building the Blockchain Application

### The Blockchain Core (Python)

First, let's build the blockchain logic. Create `blockchain.py`:

```python
import hashlib
import json
import time
from urllib.parse import urlparse
import requests

class Blockchain:
    def __init__(self):
        self.chain = []
        self.current_transactions = []
        self.nodes = set()
        
        # Create the genesis block
        self.new_block(previous_hash='1', proof=100)
    
    def register_node(self, address):
        """
        Add a new node to the list of nodes
        
        :param address: Address of node. Eg. 'http://192.168.0.5:5000'
        """
        parsed_url = urlparse(address)
        self.nodes.add(parsed_url.netloc)
    
    def valid_chain(self, chain):
        """
        Determine if a given blockchain is valid
        
        :param chain: A blockchain
        :return: True if valid, False if not
        """
        last_block = chain[0]
        current_index = 1
        
        while current_index < len(chain):
            block = chain[current_index]
            
            # Check that the hash of the block is correct
            if block['previous_hash'] != self.hash(last_block):
                return False
            
            # Check that the Proof of Work is correct
            if not self.valid_proof(last_block['proof'], block['proof']):
                return False
            
            last_block = block
            current_index += 1
        
        return True
    
    def resolve_conflicts(self):
        """
        This is our Consensus Algorithm, it resolves conflicts
        by replacing our chain with the longest one in the network.
        
        :return: True if our chain was replaced, False if not
        """
        neighbours = self.nodes
        new_chain = None
        
        # We're only looking for chains longer than ours
        max_length = len(self.chain)
        
        # Grab and verify the chains from all the nodes in our network
        for node in neighbours:
            try:
                response = requests.get(f'http://{node}/chain', timeout=2)
                
                if response.status_code == 200:
                    length = response.json()['length']
                    chain = response.json()['chain']
                    
                    # Check if the length is longer and the chain is valid
                    if length > max_length and self.valid_chain(chain):
                        max_length = length
                        new_chain = chain
            except requests.exceptions.RequestException:
                # Node is unreachable, skip it
                continue
        
        # Replace our chain if we discovered a new, valid chain longer than ours
        if new_chain:
            self.chain = new_chain
            return True
        
        return False
    
    def new_block(self, proof, previous_hash=None):
        """
        Create a new Block in the Blockchain
        
        :param proof: The proof given by the Proof of Work algorithm
        :param previous_hash: Hash of previous Block
        :return: New Block
        """
        block = {
            'index': len(self.chain) + 1,
            'timestamp': time.time(),
            'transactions': self.current_transactions,
            'proof': proof,
            'previous_hash': previous_hash or self.hash(self.chain[-1]),
        }
        
        # Reset the current list of transactions
        self.current_transactions = []
        
        self.chain.append(block)
        return block
    
    def new_transaction(self, sender, recipient, amount):
        """
        Creates a new transaction to go into the next mined Block
        
        :param sender: Address of the Sender
        :param recipient: Address of the Recipient
        :param amount: Amount
        :return: The index of the Block that will hold this transaction
        """
        self.current_transactions.append({
            'sender': sender,
            'recipient': recipient,
            'amount': amount,
        })
        
        return self.last_block['index'] + 1
    
    @property
    def last_block(self):
        return self.chain[-1]
    
    @staticmethod
    def hash(block):
        """
        Creates a SHA-256 hash of a Block
        
        :param block: Block
        """
        # We must make sure that the Dictionary is Ordered, or we'll have inconsistent hashes
        block_string = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()
    
    def proof_of_work(self, last_proof):
        """
        Simple Proof of Work Algorithm:
        - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
        - p is the previous proof, and p' is the new proof
        
        :param last_proof: Previous Proof
        :return: New Proof
        """
        proof = 0
        while self.valid_proof(last_proof, proof) is False:
            proof += 1
        
        return proof
    
    @staticmethod
    def valid_proof(last_proof, proof):
        """
        Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
        
        :param last_proof: Previous Proof
        :param proof: Current Proof
        :return: True if correct, False if not.
        """
        guess = f'{last_proof}{proof}'.encode()
        guess_hash = hashlib.sha256(guess).hexdigest()
        return guess_hash[:4] == "0000"
```

**What's happening here:**

1. **Genesis Block**: Every blockchain starts with a hardcoded first block
2. **Proof of Work**: Mining requires finding a number that creates a hash with 4 leading zeros
3. **Chain Validation**: Ensures each block correctly references the previous one
4. **Consensus**: When chains conflict, the longest valid chain wins
5. **Node Registration**: Nodes discover and track each other

---

### The API Server (Flask)

Create `app.py` to expose the blockchain via HTTP:

```python
from flask import Flask, jsonify, request
from blockchain import Blockchain
from uuid import uuid4
import os

# Instantiate our Node
app = Flask(__name__)

# Generate a globally unique address for this node
node_identifier = str(uuid4()).replace('-', '')

# Instantiate the Blockchain
blockchain = Blockchain()

# Get node configuration from environment
NODE_PORT = os.getenv('NODE_PORT', '5000')
PEER_NODES = os.getenv('PEER_NODES', '').split(',') if os.getenv('PEER_NODES') else []

@app.route('/mine', methods=['GET'])
def mine():
    """
    Mine a new block
    """
    # We run the proof of work algorithm to get the next proof...
    last_block = blockchain.last_block
    last_proof = last_block['proof']
    proof = blockchain.proof_of_work(last_proof)
    
    # We must receive a reward for finding the proof.
    # The sender is "0" to signify that this node has mined a new coin.
    blockchain.new_transaction(
        sender="0",
        recipient=node_identifier,
        amount=1,
    )
    
    # Forge the new Block by adding it to the chain
    previous_hash = blockchain.hash(last_block)
    block = blockchain.new_block(proof, previous_hash)
    
    response = {
        'message': "New Block Forged",
        'index': block['index'],
        'transactions': block['transactions'],
        'proof': block['proof'],
        'previous_hash': block['previous_hash'],
    }
    return jsonify(response), 200

@app.route('/transactions/new', methods=['POST'])
def new_transaction():
    """
    Create a new transaction
    """
    values = request.get_json()
    
    # Check that the required fields are in the POST'ed data
    required = ['sender', 'recipient', 'amount']
    if not all(k in values for k in required):
        return 'Missing values', 400
    
    # Create a new Transaction
    index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
    
    response = {'message': f'Transaction will be added to Block {index}'}
    return jsonify(response), 201

@app.route('/chain', methods=['GET'])
def full_chain():
    """
    Return the full blockchain
    """
    response = {
        'chain': blockchain.chain,
        'length': len(blockchain.chain),
    }
    return jsonify(response), 200

@app.route('/nodes/register', methods=['POST'])
def register_nodes():
    """
    Register new nodes
    """
    values = request.get_json()
    
    nodes = values.get('nodes')
    if nodes is None:
        return "Error: Please supply a valid list of nodes", 400
    
    for node in nodes:
        blockchain.register_node(node)
    
    response = {
        'message': 'New nodes have been added',
        'total_nodes': list(blockchain.nodes),
    }
    return jsonify(response), 201

@app.route('/nodes/resolve', methods=['GET'])
def consensus():
    """
    Resolve conflicts between nodes
    """
    replaced = blockchain.resolve_conflicts()
    
    if replaced:
        response = {
            'message': 'Our chain was replaced',
            'new_chain': blockchain.chain
        }
    else:
        response = {
            'message': 'Our chain is authoritative',
            'chain': blockchain.chain
        }
    
    return jsonify(response), 200

@app.route('/health', methods=['GET'])
def health():
    """
    Health check endpoint
    """
    return jsonify({'status': 'healthy', 'node_id': node_identifier}), 200

@app.route('/info', methods=['GET'])
def info():
    """
    Get node information
    """
    return jsonify({
        'node_id': node_identifier,
        'port': NODE_PORT,
        'chain_length': len(blockchain.chain),
        'peers': list(blockchain.nodes),
    }), 200

if __name__ == '__main__':
    # Register peer nodes on startup
    for peer in PEER_NODES:
        if peer:  # Only register non-empty peers
            blockchain.register_node(f'http://{peer}')
    
    app.run(host='0.0.0.0', port=int(NODE_PORT))
```

**API Endpoints Explained:**

- `GET /mine` - Mine a new block (proof-of-work)
- `POST /transactions/new` - Add a transaction to pending pool
- `GET /chain` - View the entire blockchain
- `POST /nodes/register` - Add peer nodes
- `GET /nodes/resolve` - Trigger consensus algorithm
- `GET /health` - Docker health check
- `GET /info` - Node status and metrics

---

### Requirements File

Create `requirements.txt`:

```txt
Flask==3.0.0
requests==2.31.0
```

---

## Phase 2: Containerizing the Blockchain

### The Dockerfile

Create `Dockerfile`:

```dockerfile
# Use Python 3.11 slim for smaller image size
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies first (layer optimization!)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY blockchain.py .
COPY app.py .

# Expose the port
EXPOSE 5000

# Health check - ensures node is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')"

# Run the application
CMD ["python", "app.py"]
```

**Why this Dockerfile is optimized:**

1. **Slim base image** - Reduces size from 1GB to 200MB
2. **Layer caching** - Dependencies install only when `requirements.txt` changes
3. **Health check** - Docker can monitor if the blockchain node is responsive
4. **No cache pip installs** - Prevents bloating the image with pip cache

---

### Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Blockchain Node 1 (Bootstrap node)
  node1:
    build: .
    container_name: blockchain-node-1
    ports:
      - "5001:5000"
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node2:5000,node3:5000
    networks:
      - blockchain-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped

  # Blockchain Node 2
  node2:
    build: .
    container_name: blockchain-node-2
    ports:
      - "5002:5000"
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node1:5000,node3:5000
    networks:
      - blockchain-net
    depends_on:
      node1:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped

  # Blockchain Node 3
  node3:
    build: .
    container_name: blockchain-node-3
    ports:
      - "5003:5000"
    environment:
      - NODE_PORT=5000
      - PEER_NODES=node1:5000,node2:5000
    networks:
      - blockchain-net
    depends_on:
      node1:
        condition: service_healthy
      node2:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped

networks:
  blockchain-net:
    driver: bridge
    name: blockchain-network

# Optional: Add volumes for persistent blockchain data
# volumes:
#   node1-data:
#   node2-data:
#   node3-data:
```

**Key Docker Compose Concepts in Action:**

1. **Service Dependencies**: Node 2 waits for Node 1 to be healthy before starting
2. **Health Checks**: Each node confirms it's ready before others depend on it
3. **Networks**: All nodes share `blockchain-net` for peer-to-peer communication
4. **Environment Variables**: Each node knows its port and peers
5. **Port Mapping**: Nodes accessible via localhost:5001, 5002, 5003
6. **Restart Policy**: Nodes automatically restart if they crash

---

## Phase 3: Running Your Blockchain Network

### Building and Starting

```bash
# Build all images
docker-compose build

# Start the network
docker-compose up -d

# Watch the logs
docker-compose logs -f

# Check status
docker-compose ps
```

**Expected output:**
```
NAME                  COMMAND             STATUS          PORTS
blockchain-node-1     "python app.py"     Up (healthy)    0.0.0.0:5001->5000/tcp
blockchain-node-2     "python app.py"     Up (healthy)    0.0.0.0:5002->5000/tcp
blockchain-node-3     "python app.py"     Up (healthy)    0.0.0.0:5003->5000/tcp
```

---

### Testing the Blockchain

#### 1. Check Node Status

```bash
# Node 1
curl http://localhost:5001/info

# Node 2
curl http://localhost:5002/info

# Node 3
curl http://localhost:5003/info
```

#### 2. View Initial Blockchain (Should only have genesis block)

```bash
curl http://localhost:5001/chain
```

**Expected response:**
```json
{
  "chain": [
    {
      "index": 1,
      "previous_hash": "1",
      "proof": 100,
      "timestamp": 1699999999.999,
      "transactions": []
    }
  ],
  "length": 1
}
```

#### 3. Mine a Block on Node 1

```bash
curl http://localhost:5001/mine
```

**Response:**
```json
{
  "message": "New Block Forged",
  "index": 2,
  "proof": 35293,
  "previous_hash": "abc123...",
  "transactions": [
    {
      "sender": "0",
      "recipient": "node1-uuid",
      "amount": 1
    }
  ]
}
```

#### 4. Check Chain Length on All Nodes

```bash
# Node 1 (mined the block)
curl http://localhost:5001/chain | jq '.length'
# Output: 2

# Node 2 (hasn't synced yet)
curl http://localhost:5002/chain | jq '.length'
# Output: 1

# Node 3 (hasn't synced yet)
curl http://localhost:5003/chain | jq '.length'
# Output: 1
```

**Notice**: Nodes 2 and 3 still have length 1! This is expected - they haven't synced yet.

#### 5. Trigger Consensus on Node 2

```bash
curl http://localhost:5002/nodes/resolve
```

**Response:**
```json
{
  "message": "Our chain was replaced",
  "new_chain": [...]
}
```

Now Node 2 has synced with Node 1's longer chain!

#### 6. Create a Transaction

```bash
curl -X POST http://localhost:5001/transactions/new \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "alice",
    "recipient": "bob",
    "amount": 5
  }'
```

#### 7. Mine the Transaction into a Block

```bash
# Mine on Node 1
curl http://localhost:5001/mine

# Check the new block includes the transaction
curl http://localhost:5001/chain | jq '.chain[-1].transactions'
```

---

## Phase 4: Understanding Distributed Consensus

### The Consensus Challenge

**Scenario**: Two nodes mine blocks at the same time. Which one wins?

```bash
# Terminal 1: Mine on Node 1
curl http://localhost:5001/mine

# Terminal 2: Immediately mine on Node 2
curl http://localhost:5002/mine
```

**What happens?**
- Node 1 has block #3 with proof X
- Node 2 has block #3 with proof Y
- These are conflicting blocks!

**Resolution:**
```bash
# Trigger consensus on Node 1
curl http://localhost:5001/nodes/resolve

# Trigger consensus on Node 2
curl http://localhost:5002/nodes/resolve
```

The node with the longest chain wins. If both chains are the same length, the first node to propagate its chain to the majority wins.

### Testing Consensus Manually

Create a test script `test_consensus.sh`:

```bash
#!/bin/bash

echo "=== Initial State ==="
echo "Node 1 chain length:"
curl -s http://localhost:5001/chain | jq '.length'
echo "Node 2 chain length:"
curl -s http://localhost:5002/chain | jq '.length'

echo -e "\n=== Mining 3 blocks on Node 1 ==="
for i in {1..3}; do
    curl -s http://localhost:5001/mine | jq '.index'
    sleep 1
done

echo -e "\n=== Node 1 now has longer chain ==="
echo "Node 1 chain length:"
curl -s http://localhost:5001/chain | jq '.length'

echo -e "\n=== Triggering consensus on Node 2 ==="
curl -s http://localhost:5002/nodes/resolve | jq '.message'

echo -e "\n=== After consensus ==="
echo "Node 1 chain length:"
curl -s http://localhost:5001/chain | jq '.length'
echo "Node 2 chain length:"
curl -s http://localhost:5002/chain | jq '.length'
```

Run it:
```bash
chmod +x test_consensus.sh
./test_consensus.sh
```

---

## Phase 5: Scaling the Network

### Adding More Nodes

Want to simulate a larger network? Edit `docker-compose.yml` to add nodes 4-10:

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

Or use `docker-compose scale` (requires modifying the compose file to remove explicit container names):

```bash
docker-compose up --scale node=10
```

### Dynamic Node Discovery

For a production blockchain, nodes should discover each other automatically. You could add:

1. **Service Registry** (e.g., Consul, etcd)
2. **DNS-based Discovery** (Docker service names)
3. **Gossip Protocol** (nodes share peer lists)

---

## Phase 6: Advanced Features

### Persistent Blockchain Storage

Add volumes to preserve blockchain data:

```yaml
services:
  node1:
    # ... existing config ...
    volumes:
      - node1-data:/app/data
    environment:
      - BLOCKCHAIN_DATA_DIR=/app/data

volumes:
  node1-data:
  node2-data:
  node3-data:
```

Modify `blockchain.py` to save/load from disk:

```python
import json
import os

class Blockchain:
    def __init__(self):
        self.data_dir = os.getenv('BLOCKCHAIN_DATA_DIR', './data')
        self.chain = []
        self.current_transactions = []
        self.nodes = set()
        
        # Load existing chain or create genesis block
        if os.path.exists(f'{self.data_dir}/chain.json'):
            self.load_chain()
        else:
            self.new_block(previous_hash='1', proof=100)
    
    def save_chain(self):
        os.makedirs(self.data_dir, exist_ok=True)
        with open(f'{self.data_dir}/chain.json', 'w') as f:
            json.dump(self.chain, f)
    
    def load_chain(self):
        with open(f'{self.data_dir}/chain.json', 'r') as f:
            self.chain = json.load(f)
    
    def new_block(self, proof, previous_hash=None):
        block = {
            # ... existing code ...
        }
        self.chain.append(block)
        self.save_chain()  # Persist to disk
        return block
```

### Monitoring Dashboard

Add a lightweight monitoring service:

```yaml
  dashboard:
    image: nginx:alpine
    container_name: blockchain-dashboard
    ports:
      - "8080:80"
    volumes:
      - ./dashboard:/usr/share/nginx/html
    networks:
      - blockchain-net
```

Create `dashboard/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Blockchain Network Monitor</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .node { 
            border: 1px solid #ccc; 
            padding: 15px; 
            margin: 10px; 
            border-radius: 5px; 
        }
        .healthy { background-color: #d4edda; }
        .unhealthy { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>Blockchain Network Status</h1>
    <div id="nodes"></div>
    
    <script>
        const nodes = ['node1:5000', 'node2:5000', 'node3:5000'];
        
        async function updateStatus() {
            const container = document.getElementById('nodes');
            container.innerHTML = '';
            
            for (const node of nodes) {
                try {
                    const response = await fetch(`http://${node}/info`);
                    const data = await response.json();
                    
                    container.innerHTML += `
                        <div class="node healthy">
                            <h3>Node: ${node}</h3>
                            <p>Chain Length: ${data.chain_length}</p>
                            <p>Peers: ${data.peers.length}</p>
                            <p>ID: ${data.node_id.substring(0, 8)}...</p>
                        </div>
                    `;
                } catch (error) {
                    container.innerHTML += `
                        <div class="node unhealthy">
                            <h3>Node: ${node}</h3>
                            <p>Status: Offline</p>
                        </div>
                    `;
                }
            }
        }
        
        // Update every 5 seconds
        setInterval(updateStatus, 5000);
        updateStatus();
    </script>
</body>
</html>
```

---

## Troubleshooting Guide

### Problem: Nodes can't communicate

**Symptoms:**
```bash
curl http://localhost:5002/nodes/resolve
# Returns: "message": "Our chain is authoritative"
# (Even though Node 1 has a longer chain)
```

**Diagnosis:**
```bash
# Check if nodes are on the same network
docker network inspect blockchain-network

# Check if nodes can reach each other
docker exec blockchain-node-1 ping node2
```

**Solutions:**
1. Ensure all services use `networks: blockchain-net`
2. Use Docker service names (not localhost) for `PEER_NODES`
3. Check firewall rules if using Docker on remote servers

### Problem: Health checks failing

**Symptoms:**
```bash
docker-compose ps
# Shows: blockchain-node-1 (unhealthy)
```

**Diagnosis:**
```bash
# Check logs
docker logs blockchain-node-1

# Manually test health endpoint
docker exec blockchain-node-1 curl http://localhost:5000/health
```

**Solutions:**
1. Increase `start_period` in health check (app needs more startup time)
2. Install `curl` in Dockerfile: `RUN apt-get update && apt-get install -y curl`
3. Change health check to use Python instead of curl

### Problem: Mining is too slow/fast

**Symptoms:**
- Blocks mine instantly (no proof-of-work)
- Mining takes 5+ minutes

**Solution:**

Adjust difficulty in `blockchain.py`:

```python
@staticmethod
def valid_proof(last_proof, proof):
    guess = f'{last_proof}{proof}'.encode()
    guess_hash = hashlib.sha256(guess).hexdigest()
    # Change number of leading zeros for difficulty
    return guess_hash[:4] == "0000"  # 4 zeros = ~30 seconds
    # return guess_hash[:3] == "000"  # 3 zeros = ~1 second
    # return guess_hash[:5] == "00000" # 5 zeros = ~5 minutes
```

### Problem: Containers crash after mining

**Symptoms:**
```bash
docker logs blockchain-node-1
# Shows: MemoryError or killed
```

**Solution:**

Add memory limits to `docker-compose.yml`:

```yaml
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

### Problem: Can't access nodes from browser

**Symptoms:**
- `curl http://localhost:5001/chain` works from terminal
- Browser shows "Connection refused"

**Solution:**

Add CORS support to `app.py`:

```python
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
```

Update `requirements.txt`:
```txt
Flask==3.0.0
requests==2.31.0
flask-cors==4.0.0
```

---

## Performance Optimization

### 1. Use Multi-Stage Builds

Optimize the Dockerfile for production:

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app

# Copy only the dependencies from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy application
COPY blockchain.py app.py ./

EXPOSE 5000
CMD ["python", "app.py"]
```

### 2. Optimize Proof-of-Work

For testing, use adaptive difficulty:

```python
class Blockchain:
    def __init__(self):
        # ... existing code ...
        self.difficulty = int(os.getenv('MINING_DIFFICULTY', '4'))
    
    def valid_proof(self, last_proof, proof):
        guess = f'{last_proof}{proof}'.encode()
        guess_hash = hashlib.sha256(guess).hexdigest()
        return guess_hash[:self.difficulty] == "0" * self.difficulty
```

Set via environment:
```yaml
environment:
  - MINING_DIFFICULTY=3  # Easier for testing
```

### 3. Reduce Log Verbosity

```yaml
services:
  node1:
    # ... existing config ...
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## Extensions and Challenges

### Challenge 1: Add Transaction Validation

**Goal**: Prevent negative balances and invalid transactions

**Hint**: Track wallet balances and validate before accepting transactions

### Challenge 2: Implement Transaction Fees

**Goal**: Miners should earn transaction fees plus block reward

**Hint**: Modify `new_transaction()` to include a fee field

### Challenge 3: Add a Frontend

**Goal**: Build a React/Vue dashboard to visualize the blockchain

**Hint**: Use the existing API endpoints and Docker's network

### Challenge 4: Implement Wallet System

**Goal**: Users should have private keys to sign transactions

**Hint**: Use `cryptography` library for public/private key pairs

### Challenge 5: Add Block Validation Rules

**Goal**: Blocks must contain at least one transaction (besides coinbase)

**Hint**: Modify `new_block()` to reject empty blocks

---

## Complete Project Structure

```
blockchain-network/
│
├── docker-compose.yml          # Multi-node orchestration
├── Dockerfile                  # Container definition
├── .dockerignore              # Exclude unnecessary files
│
├── blockchain.py              # Core blockchain logic
├── app.py                     # Flask API server
├── requirements.txt           # Python dependencies
│
├── test_consensus.sh          # Automated testing
├── .env                       # Environment variables (optional)
│
└── dashboard/                 # Monitoring UI
    └── index.html
```

---

## Deployment to Production

### Using Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Deploy the stack
docker stack deploy -c docker-compose.yml blockchain

# Scale to 10 nodes
docker service scale blockchain_node=10

# Check status
docker service ls
docker stack ps blockchain
```

### Using Kubernetes

Create `kubernetes-deployment.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blockchain-node
spec:
  replicas: 5
  selector:
    matchLabels:
      app: blockchain
  template:
    metadata:
      labels:
        app: blockchain
    spec:
      containers:
      - name: blockchain
        image: your-registry/blockchain:latest
        ports:
        - containerPort: 5000
        env:
        - name: NODE_PORT
          value: "5000"
---
apiVersion: v1
kind: Service
metadata:
  name: blockchain-service
spec:
  type: LoadBalancer
  selector:
    app: blockchain
  ports:
  - port: 80
    targetPort: 5000
```

Deploy:
```bash
kubectl apply -f kubernetes-deployment.yml
kubectl get pods
kubectl get services
```

---

## Key Takeaways

By completing this capstone, you've demonstrated mastery of:

1. **Multi-Container Orchestration** - Running coordinated services
2. **Container Networking** - Peer-to-peer communication
3. **Health Checks** - Ensuring service reliability
4. **Environment Configuration** - Dynamic node setup
5. **Volumes and Persistence** - Stateful applications
6. **Scaling** - Growing from 3 to N nodes
7. **API Design** - RESTful blockchain interface
8. **Distributed Systems** - Consensus and synchronization

**Real-world applications:**
- Cryptocurrency nodes
- Distributed databases
- Microservices architectures
- P2P applications
- IoT device networks

---

## Quick Reference Commands

```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f node1

# Stop all nodes
docker-compose down

# Rebuild after code changes
docker-compose up -d --build --force-recreate

# Scale to 5 nodes
docker-compose up -d --scale node=5

# Execute command in container
docker exec blockchain-node-1 curl http://localhost:5000/chain

# Remove all containers and volumes
docker-compose down -v

# View network details
docker network inspect blockchain-network

# Monitor resource usage
docker stats
```

---

## Next Steps

After mastering this capstone, you're ready to:

1. **Deploy real applications** with Docker in production
2. **Explore Kubernetes** for large-scale orchestration
3. **Implement CI/CD pipelines** with Docker
4. **Optimize images** for security and size
5. **Build microservices** using Docker patterns

**Congratulations on completing the Docker course!** You now have hands-on experience with containerized distributed systems - a skill that's in high demand across the industry.

---

## Additional Resources

- **Docker Documentation**: https://docs.docker.com
- **Blockchain Basics**: https://www.investopedia.com/terms/b/blockchain.asp
- **Flask Documentation**: https://flask.palletsprojects.com
- **Python Requests Library**: https://requests.readthedocs.io
- **Docker Compose Specification**: https://docs.docker.com/compose/compose-file/

**Pro tip**: Experiment with breaking things! Try shutting down nodes, mining on isolated chains, and forcing conflicts. Understanding how distributed systems fail is just as important as understanding how they work.
