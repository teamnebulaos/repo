#!/bin/bash

# Configuration
WORK_DIR="/tmp/archiso-work"
OUT_DIR="/tmp/archiso-out"
PROFILE_DIR="/usr/share/archiso/configs/releng"
CUSTOM_PROFILE="nebulaos"
REPO_URL="https://github.com/teamnebulaos/repo"
ISO_NAME="nebulaos"

# Create working directory
cleanup() {
    echo "Cleaning up..."
    sudo rm -rf "$WORK_DIR"
    sudo rm -rf "$OUT_DIR"
}

trap cleanup EXIT

# Function to get latest version from GitHub
get_latest_version() {
    curl -s "https://api.github.com/repos/teamnebulaos/repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Create custom profile
setup_profile() {
    echo "Setting up custom profile..."
    cp -r "$PROFILE_DIR" "$CUSTOM_PROFILE"
    
    # Add custom repository
    echo "[nebulaos]" >> "$CUSTOM_PROFILE/pacman.conf"
    echo "SigLevel = Optional TrustAll" >> "$CUSTOM_PROFILE/pacman.conf"
    echo "Server = https://raw.githubusercontent.com/teamnebulaos/repo/main/\$arch" >> "$CUSTOM_PROFILE/pacman.conf"
    
    # Add custom packages
    echo "nebula-software" >> "$CUSTOM_PROFILE/packages.x86_64"
    echo "nebula-theme" >> "$CUSTOM_PROFILE/packages.x86_64"
    echo "nebula-stage-manager" >> "$CUSTOM_PROFILE/packages.x86_64"
    echo "gnome" >> "$CUSTOM_PROFILE/packages.x86_64"
}

# Download and integrate updates
integrate_updates() {
    local version=$(get_latest_version)
    echo "Integrating updates from version $version..."
    
    # Create temporary directory for updates
    mkdir -p "$WORK_DIR/updates"
    cd "$WORK_DIR/updates"
    
    # Download update manifest
    curl -L -o manifest.json "https://raw.githubusercontent.com/teamnebulaos/repo/$version/update_manifest.json"
    
    # Process manifest
    if [ -f manifest.json ]; then
        # Download all update files
        for file in $(jq -r '.update_files[].path' manifest.json); do
            dir=$(dirname "$file")
            mkdir -p "$CUSTOM_PROFILE/airootfs$dir"
            curl -L -o "$CUSTOM_PROFILE/airootfs$file" "https://raw.githubusercontent.com/teamnebulaos/repo/$version/files$file"
        done
        
        # Add packages to be installed
        jq -r '.package_updates[] | select(.action == "install" or .action == "update") | .name' manifest.json >> "$CUSTOM_PROFILE/packages.x86_64"
    fi
}

# Configure GNOME settings
configure_gnome() {
    echo "Configuring GNOME settings..."
    mkdir -p "$CUSTOM_PROFILE/airootfs/etc/dconf/db/local.d"
    
    # Create GNOME configuration
    cat > "$CUSTOM_PROFILE/airootfs/etc/dconf/db/local.d/01-nebulaos" << EOF
[org/gnome/shell]
enabled-extensions=['stage-manager@nebulaos.org']
favorite-apps=['org.gnome.Settings.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.nebula.Software.desktop']

[org/gnome/desktop/interface]
gtk-theme='Nebula'
icon-theme='Nebula'
cursor-theme='Nebula'

[org/gnome/shell/extensions/stage-manager]
enabled=true
animation-speed=200
EOF

    # Create dconf profile
    mkdir -p "$CUSTOM_PROFILE/airootfs/etc/dconf/profile"
    echo "user-db:user" > "$CUSTOM_PROFILE/airootfs/etc/dconf/profile/user"
    echo "system-db:local" >> "$CUSTOM_PROFILE/airootfs/etc/dconf/profile/user"
}

# Add custom wallpapers
add_wallpapers() {
    echo "Adding wallpapers..."
    mkdir -p "$CUSTOM_PROFILE/airootfs/usr/share/backgrounds/nebulaos"
    
    # Download wallpapers from repo
    curl -L -o "$CUSTOM_PROFILE/airootfs/usr/share/backgrounds/nebulaos/wallpapers.tar.gz" \
        "$REPO_URL/raw/main/wallpapers/wallpapers.tar.gz"
    
    cd "$CUSTOM_PROFILE/airootfs/usr/share/backgrounds/nebulaos"
    tar xzf wallpapers.tar.gz
    rm wallpapers.tar.gz
}

# Main build process
main() {
    echo "Starting NebulaOS ISO build process..."
    
    # Initial setup
    setup_profile
    
    # Integrate latest updates
    integrate_updates
    
    # Configure GNOME and add wallpapers
    configure_gnome
    add_wallpapers
    
    # Build ISO
    echo "Building ISO..."
    sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$CUSTOM_PROFILE"
    
    # Rename ISO
    version=$(get_latest_version)
    mv "$OUT_DIR"/*.iso "$OUT_DIR/${ISO_NAME}-${version}.iso"
    
    echo "ISO build complete! File is located at: $OUT_DIR/${ISO_NAME}-${version}.iso"
}

# Run the build process
main
