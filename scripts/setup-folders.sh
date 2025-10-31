#!/bin/bash

# Docker Learning Folder Setup Script
# This script creates the directory structure for the Docker learning repository
#
# Usage: Run this script from the root of your docker-learning directory
#   cd docker-learning
#   ./scripts/setup-folders.sh

echo "🐳 Setting up Docker Learning folder structure..."
echo ""

# Create main directories
directories=(
    "01-docker-basics"
    "02-dockerfile-basics"
    "03-docker-compose"
    "04-networking"
    "05-volumes-and-data"
    "06-security-deep-dive"
)

# Create each directory
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ $dir already exists"
    else
        mkdir -p "$dir"
        echo "✓ Created $dir"
    fi
done

echo ""
echo "✅ Folder structure setup complete!"
echo ""
echo "Directory structure:"
echo "docker-learning/"
for dir in "${directories[@]}"; do
    echo "├── $dir/"
done
echo ""
