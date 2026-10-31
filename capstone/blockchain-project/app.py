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
