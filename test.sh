#!/bin/bash

set -e

echo "Running FastComments Nim SDK tests..."

# Check required environment variables
if [ -z "$FASTCOMMENTS_API_KEY" ] || [ -z "$FASTCOMMENTS_TENANT_ID" ]; then
  echo "Error: FASTCOMMENTS_API_KEY and FASTCOMMENTS_TENANT_ID environment variables must be set"
  exit 1
fi

# Run unit tests
echo "Running unit tests..."
nim c -r tests/test_sso.nim

echo ""
echo "Running integration tests..."
nim c -r tests/test_sso_integration.nim

echo ""
echo "✓ All tests passed!"
