#!/bin/bash

# This script runs the pana tool on a package
# Usage: ./tools/pana.sh package_name
#   or: ./tools/pana.sh --help

set -euo pipefail

# Function to display help
show_help() {
    echo "Usage: $0 package_name"
    echo ""
    echo "Runs the pana tool on a package to check its pub.dev readiness."
    echo ""
    echo "Arguments:"
    echo "  package_name    Name of the package in the packages/ directory"
    echo ""
    echo "Options:"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Available packages:"
    if [ -d "packages" ]; then
        ls -1 packages/ 2>/dev/null | sed 's/^/  - /'
    fi
    echo ""
    echo "Example:"
    echo "  $0 puer"
}

# Function to cleanup temporary files
cleanup() {
    if [ -n "${tmp_dir:-}" ] && [ -d "$tmp_dir" ]; then
        echo "Cleaning up temporary files..."
        rm -rf "$tmp_dir"
    fi
}

# Set up trap to cleanup on exit (success, error, or interruption)
trap cleanup EXIT INT TERM

# Check for help flag
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Get the package name from the argument
package_name="$1"
package_path="packages/$package_name"

# Check if the packages directory exists
if [ ! -d "packages" ]; then
    echo "Error: packages/ directory not found"
    echo "Make sure you run this script from the project root"
    exit 1
fi

# Check if the package folder exists
if [ ! -d "$package_path" ]; then
    echo "Error: Package '$package_name' does not exist in packages/"
    echo ""
    echo "Available packages:"
    ls -1 packages/ 2>/dev/null | sed 's/^/  - /'
    exit 1
fi

echo "Checking package: $package_name"
echo ""

# Create a unique temporary folder
tmp_dir=$(mktemp -d)
tmp_package_dir="$tmp_dir/$package_name"

# Copy the package files to temporary directory
echo "Copying package to temporary directory..."
mkdir -p "$tmp_package_dir"
cp -r "$package_path"/* "$tmp_package_dir/" || {
    echo "Error: Failed to copy package files"
    exit 1
}

# Activate pana if needed
echo "Ensuring pana is activated..."
fvm dart pub global activate pana || {
    echo "Error: Failed to activate pana"
    exit 1
}

echo ""
echo "Running pana analysis..."
echo "----------------------------------------"

# Run pana on the temporary package
fvm dart pub global run pana "$tmp_package_dir"

echo "----------------------------------------"
echo "Analysis complete!"
