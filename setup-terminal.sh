#!/bin/bash
# Terminal Setup Script for Chinese Input Method (fcitx5)

set -e

echo "=== Terminal Setup for Chinese Input ==="
echo ""

# Check if fcitx5 is installed
if ! command -v fcitx5 &> /dev/null; then
    echo "Error: fcitx5 is not installed"
    echo "Please install it with: sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-qt fcitx5-gtk fcitx5-configtool"
    exit 1
fi

# Set environment variables
echo "Setting up environment variables..."

# Create or update environment file
ENV_FILE="$HOME/.config/environment.d/fcitx5.conf"
mkdir -p "$HOME/.config/environment.d"

cat > "$ENV_FILE" << 'EOF'
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
EOF

echo "Environment variables configured in: $ENV_FILE"

# Add to .bashrc if not already present
if ! grep -q "GTK_IM_MODULE=fcitx5" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# fcitx5 input method" >> "$HOME/.bashrc"
    echo "export GTK_IM_MODULE=fcitx5" >> "$HOME/.bashrc"
    echo "export QT_IM_MODULE=fcitx5" >> "$HOME/.bashrc"
    echo "export XMODIFIERS=@im=fcitx5" >> "$HOME/.bashrc"
    echo "Added to .bashrc"
fi

# Add to .xprofile if exists or create it
XPROFILE="$HOME/.xprofile"
if [ ! -f "$XPROFILE" ] || ! grep -q "fcitx5" "$XPROFILE" 2>/dev/null; then
    cat >> "$XPROFILE" << 'EOF'

# Start fcitx5 automatically
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
fcitx5 -d &
EOF
    echo "Added to .xprofile"
fi

# Check if fcitx5 is running
if pgrep -x fcitx5 > /dev/null; then
    echo "fcitx5 is running, restarting..."
    fcitx5 -r
else
    echo "Starting fcitx5..."
    fcitx5 -d
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Configuration:"
echo "  - Environment variables: $ENV_FILE"
echo "  - Shell config: ~/.bashrc"
echo "  - X11 config: ~/.xprofile"
echo ""
echo "Usage:"
echo "  - Press Ctrl+Space to toggle input method"
echo "  - Run 'fcitx5-config-qt' to configure input methods"
echo "  - Run 'fcitx5-diagnose' to troubleshoot issues"
echo ""
echo "Note: You may need to log out and log back in for all changes to take effect"
