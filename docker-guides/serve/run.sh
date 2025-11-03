# Your original
docker build -t serve_image:v1 .
docker image ls serve_image:v1

# Improved version (save as Dockerfile.optimized)
docker build -f Dockerfile.optimized -t serve_image:v2 .
docker image ls serve_image:v2