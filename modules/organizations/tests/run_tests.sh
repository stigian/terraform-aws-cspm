#!/bin/bash
# Organizations Module Test Runner
# Run this from the organizations module directory

set -e

echo "🧪 Running Organizations Module Unit Tests..."
echo "================================================"

# Change to module directory if not already there
cd "$(dirname "$0")/.."

# Initialize if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Run tests
echo "🚀 Running terraform test..."
terraform test

echo "✅ All tests completed!"
echo ""
echo "💡 To run individual tests:"
echo "   terraform test -filter=test_name"
echo ""
echo "💡 To run with verbose output:"
echo "   terraform test -verbose"
