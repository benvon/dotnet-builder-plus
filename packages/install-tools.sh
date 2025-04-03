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

# Extract tool references and install them
grep -o 'Include="[^"]*" Version="[^"]*"' "$PROJECT_FILE" | while read -r line; do
    tool=$(echo "$line" | sed 's/.*Include="\([^"]*\)".*/\1/')
    version=$(echo "$line" | sed 's/.*Version="\([^"]*\)".*/\1/')
    echo "Installing $tool version $version"
    dotnet tool install --tool-path /packages/.dotnet/tools "$tool" --version "$version"
done 