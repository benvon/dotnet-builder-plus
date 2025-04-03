#!/bin/bash

# Check if project file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <project-file>"
    exit 1
fi

# Read project file
PROJECT_FILE="$1"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file $PROJECT_FILE not found"
    exit 1
fi

# Create a temporary project and restore packages
TEMP_DIR=$(mktemp -d)
cp "$PROJECT_FILE" "$TEMP_DIR/packages.csproj"
cd "$TEMP_DIR" && dotnet restore
rm -rf "$TEMP_DIR" 