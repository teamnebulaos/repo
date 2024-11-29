#!/bin/bash

# Configuration
REPO_NAME="nebulaos"
REPO_DIR="x86_64"
PACKAGES=(
    "nebula-software"
)

# Create repo directory
mkdir -p "$REPO_DIR"

# Function to build a package
build_package() {
    local pkg=$1
    echo "Building $pkg..."
    
    # Clone package repository
    git clone "https://github.com/teamnebulaos/$pkg.git" build/$pkg
    
    # Build package
    cd build/$pkg
    makepkg -s --noconfirm
    
    # Move package to repo
    mv *.pkg.tar.zst ../../"$REPO_DIR"/
    cd ../..
}

# Create build directory
mkdir -p build

# Build all packages
for pkg in "${PACKAGES[@]}"; do
    build_package "$pkg"
done

# Create repo database
cd "$REPO_DIR"
repo-add "$REPO_NAME.db.tar.gz" *.pkg.tar.zst

# Clean up
cd ..
rm -rf build
