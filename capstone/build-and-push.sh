#!/bin/bash

# Production Image Build and Push Script
# This script builds Docker images and pushes them to your registry
#
# Usage:
#   ./build-and-push.sh              # Build and push using .env.production
#   ./build-and-push.sh 1.2.3        # Override version
#   ./build-and-push.sh --test-only  # Build and test, don't push

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
log_info "Checking prerequisites..."

if ! command_exists docker; then
    log_error "Docker is not installed!"
    exit 1
fi

if ! command_exists jq; then
    log_warning "jq not installed. Install for better output formatting."
    log_warning "  Ubuntu/Debian: sudo apt-get install jq"
    log_warning "  macOS: brew install jq"
fi

log_success "Prerequisites OK"

# Parse arguments
TEST_ONLY=false
VERSION_OVERRIDE=""

for arg in "$@"; do
    case $arg in
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [VERSION]"
            echo ""
            echo "Options:"
            echo "  --test-only    Build and test without pushing"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Use version from .env.production"
            echo "  $0 1.2.3              # Build version 1.2.3"
            echo "  $0 --test-only        # Build and test only"
            exit 0
            ;;
        *)
            VERSION_OVERRIDE=$arg
            shift
            ;;
    esac
done

# Load environment variables
if [ -f .env.production ]; then
    log_info "Loading configuration from .env.production"
    set -a
    source .env.production
    set +a
    log_success "Configuration loaded"
else
    log_error ".env.production not found!"
    log_error "Copy .env.production.template to .env.production and configure it."
    exit 1
fi

# Override version if specified
if [ -n "$VERSION_OVERRIDE" ]; then
    VERSION=$VERSION_OVERRIDE
    log_info "Using version override: $VERSION"
fi

# Validate required variables
if [ -z "$DOCKER_REGISTRY" ]; then
    log_error "DOCKER_REGISTRY not set in .env.production!"
    exit 1
fi

if [ -z "$VERSION" ]; then
    log_error "VERSION not set! Provide version in .env.production or as argument."
    exit 1
fi

# Construct image name
IMAGE_NAME="${DOCKER_REGISTRY}/blockchain-node"
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"

log_info "Image to build: $IMAGE_TAG"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    log_error "Dockerfile not found in current directory!"
    exit 1
fi

# Check Docker daemon
log_info "Checking Docker daemon..."
if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon is not running!"
    exit 1
fi
log_success "Docker daemon running"

# Check registry authentication (unless test-only)
if [ "$TEST_ONLY" = false ]; then
    log_info "Checking registry authentication..."
    
    # Extract registry hostname
    REGISTRY_HOST=$(echo $DOCKER_REGISTRY | cut -d'/' -f1)
    
    # Try to get auth config
    if docker info | grep -q "Username:"; then
        log_success "Authenticated to Docker registry"
    else
        log_warning "Not authenticated to registry!"
        log_warning "Run: docker login $REGISTRY_HOST"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Build the image
log_info "Building Docker image..."
log_info "This may take a few minutes..."

BUILD_START=$(date +%s)

if docker build -t $IMAGE_TAG .; then
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    log_success "Build completed in ${BUILD_TIME}s"
else
    log_error "Build failed!"
    exit 1
fi

# Get image size
IMAGE_SIZE=$(docker images $IMAGE_TAG --format "{{.Size}}")
log_info "Image size: $IMAGE_SIZE"

# Run basic tests
log_info "Running basic tests..."

# Test 1: Check Python version
log_info "Test 1/4: Checking Python..."
if docker run --rm $IMAGE_TAG python --version; then
    log_success "Python OK"
else
    log_error "Python test failed!"
    exit 1
fi

# Test 2: Check Flask installation
log_info "Test 2/4: Checking Flask..."
if docker run --rm $IMAGE_TAG python -c "import flask; print(f'Flask {flask.__version__}')"; then
    log_success "Flask OK"
else
    log_error "Flask test failed!"
    exit 1
fi

# Test 3: Check requests library
log_info "Test 3/4: Checking requests library..."
if docker run --rm $IMAGE_TAG python -c "import requests; print(f'Requests {requests.__version__}')"; then
    log_success "Requests library OK"
else
    log_error "Requests library test failed!"
    exit 1
fi

# Test 4: Check application files
log_info "Test 4/4: Checking application files..."
if docker run --rm $IMAGE_TAG ls -la /app/blockchain.py /app/app.py; then
    log_success "Application files present"
else
    log_error "Application files missing!"
    exit 1
fi

log_success "All tests passed!"

# Test-only mode ends here
if [ "$TEST_ONLY" = true ]; then
    log_success "Test-only mode: Build and tests complete"
    log_info "Image: $IMAGE_TAG"
    log_info "To push manually: docker push $IMAGE_TAG"
    exit 0
fi

# Push to registry
log_info "Pushing image to registry..."
log_info "Destination: $IMAGE_TAG"

PUSH_START=$(date +%s)

if docker push $IMAGE_TAG; then
    PUSH_END=$(date +%s)
    PUSH_TIME=$((PUSH_END - PUSH_START))
    log_success "Push completed in ${PUSH_TIME}s"
else
    log_error "Push failed!"
    log_error "Check your registry authentication: docker login $REGISTRY_HOST"
    exit 1
fi

# Tag as latest (optional)
read -p "Also tag as 'latest'? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    LATEST_TAG="${IMAGE_NAME}:latest"
    log_info "Tagging as latest..."
    docker tag $IMAGE_TAG $LATEST_TAG
    
    log_info "Pushing latest tag..."
    if docker push $LATEST_TAG; then
        log_success "Latest tag pushed"
    else
        log_warning "Failed to push latest tag (not critical)"
    fi
fi

# Summary
echo ""
log_success "════════════════════════════════════════"
log_success "  Build and Push Complete!"
log_success "════════════════════════════════════════"
echo ""
log_info "Image: $IMAGE_TAG"
log_info "Size: $IMAGE_SIZE"
log_info "Build time: ${BUILD_TIME}s"
log_info "Push time: ${PUSH_TIME}s"
echo ""
log_info "Next steps:"
echo "  1. Update .env.production with VERSION=${VERSION}"
echo "  2. Deploy: docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
echo "  3. Verify: docker compose ps"
echo ""

# Generate deployment command
log_info "Deployment command:"
echo "  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
