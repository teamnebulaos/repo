#!/bin/bash

# Configuration
REPO_NAME="nebulaos"
REPO_DIR="x86_64"

# Update repository
cd "$REPO_DIR"
repo-add "$REPO_NAME.db.tar.gz" *.pkg.tar.zst

# Create symbolic links
ln -sf "$REPO_NAME.db.tar.gz" "$REPO_NAME.db"
ln -sf "$REPO_NAME.files.tar.gz" "$REPO_NAME.files"

# Optional: Sign packages
# repo-add --sign "$REPO_NAME.db.tar.gz" *.pkg.tar.zst
