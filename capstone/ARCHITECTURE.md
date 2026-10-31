# Blockchain Network Architecture & Flow Diagrams

Visual representations of the distributed blockchain system for presentations and understanding.

## Network Topology

```
┌────────────────────────────────────────────────────────────────┐
│                        Host Machine                             │
│                     (Your Computer)                            │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │           Docker Engine                                   │ │
│  │                                                           │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │         blockchain-network (Bridge)                │  │ │
│  │  │         IP: 172.18.0.0/16                         │  │ │
│  │  │                                                    │  │ │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │  │ │
│  │  │  │   Node 1     │  │   Node 2     │  │   Node 3     │ │  │ │
│  │  │  │ 172.18.0.2   │  │ 172.18.0.3   │  │ 172.18.0.4   │ │  │ │
│  │  │  │ Port: 5000   │  │ Port: 5000   │  │ Port: 5000   │ │  │ │
│  │  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │  │ │
│  │  │         │                 │                 │          │  │ │
│  │  │         └─────────────────┼─────────────────┘          │  │ │
│  │  │                           │                            │  │ │
│  │  └───────────────────────────┼────────────────────────────┘  │ │
│  │                              │                               │ │
│  └──────────────────────────────┼───────────────────────────────┘ │
│                                 │                                 │
│  ┌──────────────────────────────┼───────────────────────────────┐ │
│  │         Port Mapping         │                               │ │
│  │                              │                               │ │
│  │   localhost:5001 ───────> Node 1:5000                      │ │
│  │   localhost:5002 ───────> Node 2:5000                      │ │
│  │   localhost:5003 ───────> Node 3:5000                      │ │
│  │                                                              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Container Internals

```
┌─────────────────────────────────────────────────┐
│         Blockchain Node Container               │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Python 3.11 Runtime Environment          │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Flask Web Server (Port 5000)             │ │
│  │  ├─ /mine         (GET)                   │ │
│  │  ├─ /chain        (GET)                   │ │
│  │  ├─ /transactions (POST)                  │ │
│  │  ├─ /nodes        (POST/GET)              │ │
│  │  └─ /health       (GET)                   │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Blockchain Logic                         │ │
│  │  ├─ Chain (List of Blocks)                │ │
│  │  ├─ Pending Transactions                  │ │
│  │  ├─ Registered Peers                      │ │
│  │  ├─ Proof of Work Algorithm               │ │
│  │  └─ Consensus Mechanism                   │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Environment Variables                    │ │
│  │  ├─ NODE_PORT=5000                        │ │
│  │  └─ PEER_NODES=node2:5000,node3:5000      │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Health Check (Every 30s)                 │ │
│  │  curl http://localhost:5000/health        │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Blockchain Data Structure

```
Chain (Array of Blocks)
│
├─ Block 1 (Genesis)
│  ├─ index: 1
│  ├─ timestamp: 1699999999.999
│  ├─ transactions: []
│  ├─ proof: 100
│  └─ previous_hash: "1"
│
├─ Block 2
│  ├─ index: 2
│  ├─ timestamp: 1700000100.123
│  ├─ transactions: [
│  │    {sender: "0", recipient: "node1", amount: 1}
│  │  ]
│  ├─ proof: 35293
│  └─ previous_hash: "abc123..."
│
├─ Block 3
│  ├─ index: 3
│  ├─ timestamp: 1700000200.456
│  ├─ transactions: [
│  │    {sender: "0", recipient: "node1", amount: 1},
│  │    {sender: "alice", recipient: "bob", amount: 5}
│  │  ]
│  ├─ proof: 119678
│  └─ previous_hash: "def456..."
│
└─ Block N
   ├─ index: N
   ├─ timestamp: ...
   ├─ transactions: [...]
   ├─ proof: ...
   └─ previous_hash: "..."
```

## Request Flow: Mining a Block

```
┌─────────────┐
│   Client    │
│  (Browser/  │
│    curl)    │
└──────┬──────┘
       │
       │ GET /mine
       ▼
┌──────────────────┐
│   Node 1 API     │
│  (Flask Server)  │
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  1. Get last block                           │
│     last_block = blockchain.last_block       │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  2. Run proof-of-work                        │
│     proof = blockchain.proof_of_work()       │
│     [Computing... finding hash with 0000]    │
│     [Takes ~10-30 seconds]                   │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  3. Create reward transaction                │
│     blockchain.new_transaction(              │
│       sender="0",                            │
│       recipient=node_id,                     │
│       amount=1                               │
│     )                                        │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  4. Create new block                         │
│     block = blockchain.new_block(proof)      │
│     [Block is appended to chain]             │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  5. Return response                          │
│     {                                        │
│       "message": "New Block Forged",         │
│       "index": 2,                            │
│       "proof": 35293,                        │
│       "previous_hash": "abc123..."           │
│     }                                        │
└──────┬───────────────────────────────────────┘
       │
       │ JSON Response
       ▼
┌─────────────┐
│   Client    │
│  (Receives  │
│   result)   │
└─────────────┘
```

## Consensus Flow: Resolving Conflicts

```
┌──────────┐                  ┌──────────┐                  ┌──────────┐
│  Node 1  │                  │  Node 2  │                  │  Node 3  │
│ Length:4 │                  │ Length:2 │                  │ Length:3 │
└────┬─────┘                  └────┬─────┘                  └────┬─────┘
     │                             │                             │
     │  Node 2 realizes it's       │                             │
     │  behind, triggers consensus │                             │
     │                             │                             │
     │        ┌───────────────────►│                             │
     │        │ GET /chain         │                             │
     │        │                    │                             │
     │        │  Response:         │                             │
     │◄───────┤  length: 4         │                             │
     │        │  chain: [...]      │                             │
     │                             │                             │
     │                             │        ┌───────────────────►│
     │                             │        │ GET /chain         │
     │                             │        │                    │
     │                             │        │  Response:         │
     │                             │◄───────┤  length: 3         │
     │                             │        │  chain: [...]      │
     │                             │                             │
     │        Node 2 compares:     │                             │
     │        - Node 1: length 4 ✓ (longest!)                   │
     │        - Node 3: length 3                                │
     │                             │                             │
     │        Node 2 validates     │                             │
     │        Node 1's chain       │                             │
     │        (checks all hashes)  │                             │
     │                             │                             │
     │        Node 2 replaces      │                             │
     │        its chain with       │                             │
     │        Node 1's chain       │                             │
     │                             │                             │
┌────┴─────┐                  ┌────┴─────┐                  ┌────┴─────┐
│  Node 1  │                  │  Node 2  │                  │  Node 3  │
│ Length:4 │                  │ Length:4 │ ✓ Synced!        │ Length:3 │
└──────────┘                  └──────────┘                  └──────────┘
```

## Docker Compose Lifecycle

```
$ docker-compose up -d --build
│
├─► Phase 1: Build Images
│   ┌────────────────────────────────────┐
│   │ 1. Read Dockerfile                 │
│   │ 2. Pull base image (python:3.11)   │
│   │ 3. Install dependencies            │
│   │ 4. Copy application code           │
│   │ 5. Configure health check          │
│   │ 6. Tag as blockchain-project_node1 │
│   └────────────────────────────────────┘
│
├─► Phase 2: Create Network
│   ┌────────────────────────────────────┐
│   │ Create blockchain-network          │
│   │ Type: bridge                       │
│   │ Subnet: 172.18.0.0/16             │
│   └────────────────────────────────────┘
│
├─► Phase 3: Start Node 1 (Bootstrap)
│   ┌────────────────────────────────────┐
│   │ 1. Create container                │
│   │ 2. Attach to network               │
│   │ 3. Set environment variables       │
│   │ 4. Map port 5001:5000              │
│   │ 5. Start Flask app                 │
│   │ 6. Wait for health check (10s)     │
│   │ 7. Status: healthy ✓               │
│   └────────────────────────────────────┘
│
├─► Phase 4: Start Node 2 (Waits for Node 1)
│   ┌────────────────────────────────────┐
│   │ 1. Wait for Node 1 healthy         │
│   │ 2. Create container                │
│   │ 3. Attach to network               │
│   │ 4. Set environment variables       │
│   │ 5. Map port 5002:5000              │
│   │ 6. Start Flask app                 │
│   │ 7. Register peer: node1            │
│   │ 8. Wait for health check (10s)     │
│   │ 9. Status: healthy ✓               │
│   └────────────────────────────────────┘
│
└─► Phase 5: Start Node 3 (Waits for Nodes 1 & 2)
    ┌────────────────────────────────────┐
    │ 1. Wait for Node 1 healthy         │
    │ 2. Wait for Node 2 healthy         │
    │ 3. Create container                │
    │ 4. Attach to network               │
    │ 5. Set environment variables       │
    │ 6. Map port 5003:5000              │
    │ 7. Start Flask app                 │
    │ 8. Register peers: node1, node2    │
    │ 9. Wait for health check (10s)     │
    │ 10. Status: healthy ✓              │
    └────────────────────────────────────┘

Result: All 3 nodes running and healthy!
```

## Health Check Flow

```
Every 30 seconds:
┌────────────────────────────────────────┐
│  Docker Engine Health Check            │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  Execute in Container:                 │
│  curl -f http://localhost:5000/health  │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  Flask responds with:                  │
│  {                                     │
│    "status": "healthy",                │
│    "node_id": "abc123..."              │
│  }                                     │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  HTTP 200 OK?                          │
│  ├─ Yes → Container Status: healthy    │
│  └─ No  → Retry (3 times)             │
│           └─ Still failing → unhealthy │
└────────────────────────────────────────┘
```

## Transaction Flow

```
User Creates Transaction
│
├─► POST /transactions/new
│   {
│     "sender": "alice",
│     "recipient": "bob",
│     "amount": 5
│   }
│
├─► Node 1 adds to pending transactions
│   blockchain.current_transactions.append({...})
│
├─► Response: "Transaction will be added to Block 3"
│
│   [Transaction is pending, not yet in blockchain]
│
├─► User mines a block on Node 1
│   GET /mine
│
├─► Node 1 includes pending transactions in new block
│   {
│     "index": 3,
│     "transactions": [
│       {sender: "0", recipient: "node1", amount: 1},  ← Coinbase
│       {sender: "alice", recipient: "bob", amount: 5}  ← User's transaction
│     ]
│   }
│
├─► Block is added to Node 1's chain
│   blockchain.chain.append(new_block)
│
└─► Other nodes sync via consensus
    Node 2: GET /nodes/resolve
    Node 3: GET /nodes/resolve
    
    Result: Transaction is now in all chains!
```

## Proof of Work Visualization

```
Mining Block 2 (finding valid proof)

Last Proof: 100

Attempt 1:  proof = 0
            hash(100 + 0) = "a3f2b9..." ✗ (doesn't start with 0000)

Attempt 2:  proof = 1
            hash(100 + 1) = "7d8e4c..." ✗

Attempt 3:  proof = 2
            hash(100 + 2) = "f9a1b7..." ✗

[... thousands of attempts ...]

Attempt 35293:  proof = 35293
                hash(100 + 35293) = "00001a3b2c..." ✓ (starts with 0000!)

BLOCK MINED! Proof = 35293

Time taken: ~30 seconds
Computational cost: 35,293 hash calculations
```

## Network Partition Scenario

```
Normal Operation:
┌────────┐    ┌────────┐    ┌────────┐
│ Node 1 │────│ Node 2 │────│ Node 3 │
│ Block:5│    │ Block:5│    │ Block:5│
└────────┘    └────────┘    └────────┘
    All nodes synchronized

Network Partition (Node 2 disconnected):
┌────────┐    ┌────────┐    ┌────────┐
│ Node 1 │ ✗  │ Node 2 │ ✗  │ Node 3 │
│ Block:5│    │ Block:5│    │ Block:5│
└────────┘    └────────┘    └────────┘
                Node 2 isolated

Mining continues on both sides:
┌────────┐    ┌────────┐    ┌────────┐
│ Node 1 │    │ Node 2 │    │ Node 3 │
│ Block:7│    │ Block:6│    │ Block:7│
└────────┘    └────────┘    └────────┘
   Nodes 1&3       Node 2
   mine 2 blocks   mines 1 block
   
Network restored:
┌────────┐    ┌────────┐    ┌────────┐
│ Node 1 │────│ Node 2 │────│ Node 3 │
│ Block:7│    │ Block:6│    │ Block:7│
└────────┘    └────────┘    └────────┘

Node 2 triggers consensus:
┌────────┐    ┌────────┐    ┌────────┐
│ Node 1 │────│ Node 2 │────│ Node 3 │
│ Block:7│    │ Block:7│    │ Block:7│
└────────┘    └────────┘    └────────┘
        Node 2's chain replaced
        (longest chain wins!)
```

## API Endpoints Map

```
┌─────────────────────────────────────────────────────────────┐
│                     Blockchain Node API                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Read Operations                                            │
│  ├─ GET  /chain          → View entire blockchain          │
│  ├─ GET  /health         → Health check status             │
│  ├─ GET  /info           → Node metadata                   │
│  └─ GET  /nodes/resolve  → Trigger consensus               │
│                                                             │
│  Write Operations                                           │
│  ├─ GET  /mine           → Mine new block (creates state)  │
│  ├─ POST /transactions   → Add pending transaction         │
│  └─ POST /nodes/register → Add peer nodes                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Docker Commands Cheat Sheet

```
┌─────────────────────────────────────────────────────────────┐
│  Building & Starting                                         │
├─────────────────────────────────────────────────────────────┤
│  docker-compose build                Build images            │
│  docker-compose up -d                Start detached         │
│  docker-compose up -d --build        Build + start          │
│  docker-compose restart node1        Restart one service    │
├─────────────────────────────────────────────────────────────┤
│  Monitoring                                                  │
├─────────────────────────────────────────────────────────────┤
│  docker-compose ps                   List containers        │
│  docker-compose logs -f              Follow all logs        │
│  docker-compose logs -f node1        Follow node1 logs      │
│  docker stats                        Resource usage         │
├─────────────────────────────────────────────────────────────┤
│  Stopping & Cleaning                                         │
├─────────────────────────────────────────────────────────────┤
│  docker-compose stop                 Stop containers        │
│  docker-compose down                 Stop + remove          │
│  docker-compose down -v              + remove volumes       │
│  docker-compose down --rmi all       + remove images        │
├─────────────────────────────────────────────────────────────┤
│  Debugging                                                   │
├─────────────────────────────────────────────────────────────┤
│  docker exec -it node1 /bin/bash     Shell access          │
│  docker logs blockchain-node-1       View container logs    │
│  docker inspect blockchain-node-1    Detailed info         │
│  docker network inspect              Network details        │
│    blockchain-network                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Use These Diagrams For:

✅ **Presentations** - Visual slides for lectures  
✅ **Documentation** - Include in README or guides  
✅ **Debugging** - Reference when troubleshooting  
✅ **Student Understanding** - Help visualize concepts  
✅ **Code Reviews** - Explain architecture decisions  

All diagrams are ASCII art - compatible with any text editor or markdown viewer!
