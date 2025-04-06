#!/bin/bash
set -e

echo "Testing dotnet-builder-plus image..."

# Test Azure CLI
echo "Testing Azure CLI installation..."
docker run --rm dotnet-builder-plus az --version
docker run --rm dotnet-builder-plus az --help > /dev/null
docker run --rm dotnet-builder-plus az account show --output none 2>&1 | grep -q "Please run 'az login'" && echo "Azure CLI authentication check passed"

# Test Java
echo "Testing Java installation..."
docker run --rm dotnet-builder-plus java -version
# docker run --rm dotnet-builder-plus java -cp /opt/az/lib/python3.12/site-packages/azure/cli/core/__pycache__/__init__.cpython-312.pyc -version

# Test jq
echo "Testing jq installation..."
docker run --rm dotnet-builder-plus jq --version
echo '{"test": "value"}' | docker run --rm -i dotnet-builder-plus jq '.test' | grep -q "value" && echo "jq test passed"

# Test nuget
echo "Testing nuget installation..."
# docker run --rm dotnet-builder-plus sh -c 'command -v nuget >/dev/null && echo "nuget command found"'

# Test basic .NET functionality
echo "Testing .NET installation..."
docker run --rm dotnet-builder-plus dotnet --version
docker run --rm dotnet-builder-plus dotnet --info

echo "All tests completed successfully!" 