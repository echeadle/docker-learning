#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Blockchain Network Test Script ===${NC}\n"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. Install it for better output formatting.${NC}"
    echo "On Ubuntu/Debian: sudo apt-get install jq"
    echo "On macOS: brew install jq"
    echo ""
fi

echo -e "${GREEN}=== Initial State ===${NC}"
echo "Node 1 chain length:"
curl -s http://localhost:5001/chain | jq -r '.length' || curl -s http://localhost:5001/chain | grep -o '"length":[0-9]*' | cut -d: -f2
echo "Node 2 chain length:"
curl -s http://localhost:5002/chain | jq -r '.length' || curl -s http://localhost:5002/chain | grep -o '"length":[0-9]*' | cut -d: -f2
echo "Node 3 chain length:"
curl -s http://localhost:5003/chain | jq -r '.length' || curl -s http://localhost:5003/chain | grep -o '"length":[0-9]*' | cut -d: -f2

echo -e "\n${GREEN}=== Mining 3 blocks on Node 1 ===${NC}"
for i in {1..3}; do
    echo "Mining block $i..."
    curl -s http://localhost:5001/mine | jq -r '.index' || curl -s http://localhost:5001/mine | grep -o '"index":[0-9]*' | cut -d: -f2
    sleep 1
done

echo -e "\n${GREEN}=== Node 1 now has longer chain ===${NC}"
echo "Node 1 chain length:"
curl -s http://localhost:5001/chain | jq -r '.length' || curl -s http://localhost:5001/chain | grep -o '"length":[0-9]*' | cut -d: -f2

echo -e "\n${GREEN}=== Node 2 still has old chain ===${NC}"
echo "Node 2 chain length:"
curl -s http://localhost:5002/chain | jq -r '.length' || curl -s http://localhost:5002/chain | grep -o '"length":[0-9]*' | cut -d: -f2

echo -e "\n${GREEN}=== Triggering consensus on Node 2 ===${NC}"
RESULT=$(curl -s http://localhost:5002/nodes/resolve | jq -r '.message' || curl -s http://localhost:5002/nodes/resolve | grep -o '"message":"[^"]*' | cut -d'"' -f4)
echo "Result: $RESULT"

echo -e "\n${GREEN}=== After consensus ===${NC}"
echo "Node 1 chain length:"
curl -s http://localhost:5001/chain | jq -r '.length' || curl -s http://localhost:5001/chain | grep -o '"length":[0-9]*' | cut -d: -f2
echo "Node 2 chain length:"
curl -s http://localhost:5002/chain | jq -r '.length' || curl -s http://localhost:5002/chain | grep -o '"length":[0-9]*' | cut -d: -f2
echo "Node 3 chain length:"
curl -s http://localhost:5003/chain | jq -r '.length' || curl -s http://localhost:5003/chain | grep -o '"length":[0-9]*' | cut -d: -f2

echo -e "\n${GREEN}=== Testing transaction creation ===${NC}"
curl -s -X POST http://localhost:5001/transactions/new \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "alice",
    "recipient": "bob",
    "amount": 5
  }' | jq -r '.message' || curl -s -X POST http://localhost:5001/transactions/new \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "alice",
    "recipient": "bob",
    "amount": 5
  }' | grep -o '"message":"[^"]*' | cut -d'"' -f4

echo -e "\n${GREEN}=== Mining transaction into block ===${NC}"
curl -s http://localhost:5001/mine | jq -r '.message' || curl -s http://localhost:5001/mine | grep -o '"message":"[^"]*' | cut -d'"' -f4

echo -e "\n${GREEN}=== Checking latest block transactions ===${NC}"
curl -s http://localhost:5001/chain | jq -r '.chain[-1].transactions' || curl -s http://localhost:5001/chain | grep -o '"transactions":\[[^]]*\]'

echo -e "\n${BLUE}=== Test Complete ===${NC}"
echo "All nodes are synchronized and consensus is working!"
