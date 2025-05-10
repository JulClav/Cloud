#!/bin/sh
# web/entrypoint.sh

set -e

# Default API_URL if API_URL_FOR_FRONTEND is not set (will be set by Nomad)
DEFAULT_API_URL="http://localhost:8000"

# Use environment variable API_URL_FOR_FRONTEND passed by Nomad
# Fallback to DEFAULT_API_URL if not set
export EFFECTIVE_API_URL="${API_URL_FOR_FRONTEND:-$DEFAULT_API_URL}"

# Create config.json inside the './dist' directory.
# The WORKDIR in the Dockerfile is /app, so this resolves to /app/dist/config.json
echo "{\"endpoint\": \"${EFFECTIVE_API_URL}\"}" > ./dist/config.json

echo "Frontend API URL has been configured for vite preview:"
cat ./dist/config.json
echo "---"

# Execute the command passed as CMD from the Dockerfile (e.g., npm run preview ...)
exec "$@"