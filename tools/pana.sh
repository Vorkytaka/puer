#!/bin/bash

# This script runs the pana tool on a package
# Usage: ./tools/pana.sh package_name

# Check if the package name is provided
if [ $# -eq 0 ]; then
    echo "Error: Package name not provided"
    echo "Usage: $0 package_name"
    exit 1
fi

# Get the package name from the argument
package_name=$1
package_path="packages/$package_name"

# Check if the folder exists
if [ ! -d "$package_path" ]; then
    echo "Error: Folder $package_path does not exist"
    exit 1
fi

# Create a temporary folder and copy the package files
mkdir .tmp
mkdir ".tmp/$package_name"
cp -r "$package_path"/* ".tmp/$package_name"

dart pub global activate pana
dart pub global run pana ".tmp/$package_name"

rm -rf .tmp
