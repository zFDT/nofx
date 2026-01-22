#!/bin/bash
# Build script that reads version.json and passes to docker-compose

# Read version.json
VERSION=$(jq -r '.version' version.json)
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(jq -r '.branch' version.json)
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Building with version info:"
echo "  VERSION: $VERSION"
echo "  COMMIT: $COMMIT"
echo "  BRANCH: $BRANCH"
echo "  BUILD_DATE: $BUILD_DATE"

# Export variables for docker-compose
export VERSION
export COMMIT
export BRANCH
export BUILD_DATE

# Build with docker-compose
docker-compose build --no-cache "$@"
