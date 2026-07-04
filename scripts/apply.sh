#!/bin/bash
#
# apply.sh — One-click apply for AcreetionOS GDM + ES1000 patches
#
# This script applies all configuration changes needed to make the
# GDM login screen usable on AMD/ATI ES1000 (R100) GPUs.
#
# Usage:
#   sudo ./scripts/apply.sh
#
# Run with sudo. It modifies system configuration files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PATCH_DIR="$SCRIPT_DIR/patches"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Must be root
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root (sudo)."
    exit 1
fi

echo "============================================="
echo " AcreetionOS GDM + ES1000 Patches — Apply"
echo "============================================="
echo ""

# 1. Xorg configuration
log_info "Installing Xorg radeon EXA config..."
mkdir -p /etc/X11/xorg.conf.d
cp "$PATCH_DIR/xorg/10-radeon.conf" /etc/X11/xorg.conf.d/
log_info "  → /etc/X11/xorg.conf.d/10-radeon.conf"

# 2. GDM daemon config
log_info "Installing GDM custom.conf..."
cp "$PATCH_DIR/gdm/custom.conf" /etc/gdm/
log_info "  → /etc/gdm/custom.conf"

# 3. GDM greeter dconf performance settings
log_info "Installing GDM greeter dconf performance profile..."
mkdir -p /etc/dconf/db/gdm.d
cp "$PATCH_DIR/gdm/greeter-dconf-performance" /etc/dconf/db/gdm.d/99-es1000-performance
log_info "  → /etc/dconf/db/gdm.d/99-es1000-performance"

# 4. GDM dconf profile
if [ -f "$PATCH_DIR/gdm/gdm" ]; then
    mkdir -p /etc/dconf/profile
    cp "$PATCH_DIR/gdm/gdm" /etc/dconf/profile/gdm
    log_info "  → /etc/dconf/profile/gdm"
fi

# Recompile dconf
dconf update && log_info "  → dconf database recompiled"

# 5. Environment variables for GDM greeter
log_info "Installing GDM greeter environment..."
mkdir -p /etc/environment.d
cp "$PATCH_DIR/gdm/90-gdm-greeter-performance.conf" /etc/environment.d/
log_info "  → /etc/environment.d/90-gdm-greeter-performance.conf"

# 6. Systemd tmpfiles entry
log_info "Installing systemd tmpfiles entry..."
cp "$PATCH_DIR/gdm/gdm-x11.conf" /etc/tmpfiles.d/
log_info "  → /etc/tmpfiles.d/gdm-x11.conf"

# 7. Profile environment for user session
log_info "Installing user profile environment..."
cp "$PATCH_DIR/profile/99-es1000-performance.sh" /etc/profile.d/
log_info "  → /etc/profile.d/99-es1000-performance.sh"

# 8. Block Wayland user session
log_info "Blocking Wayland GNOME session..."
if [ -f /usr/share/wayland-sessions/gnome.desktop ]; then
    mv /usr/share/wayland-sessions/gnome.desktop /usr/share/wayland-sessions/gnome.desktop.bak
    log_info "  → /usr/share/wayland-sessions/gnome.desktop → .bak"
else
    log_warn "  → Wayland GNOME session already blocked (or not found)"
fi

# 9. Install pacman hook
log_info "Installing pacman hook..."
mkdir -p /etc/pacman.d/hooks
cp "$PATCH_DIR/session/gdm-wayland-block.hook" /etc/pacman.d/hooks/
log_info "  → /etc/pacman.d/hooks/gdm-wayland-block.hook"

# 10. Set user session configuration
CURRENT_USER="${SUDO_USER:-$(who am i | awk '{print $1}')}"
if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    log_info "Configuring session for user '$CURRENT_USER'..."

    # AccountsService
    mkdir -p /var/lib/AccountsService/users
    if [ -f "$PATCH_DIR/session/accounts-service-natalie" ]; then
        cp "$PATCH_DIR/session/accounts-service-natalie" "/var/lib/AccountsService/users/$CURRENT_USER"
        sed -i "s/^\[User\]/[User]/" "/var/lib/AccountsService/users/$CURRENT_USER"
        log_info "  → /var/lib/AccountsService/users/$CURRENT_USER"
    fi

    # .dmrc
    if [ -f "$PATCH_DIR/session/.dmrc" ]; then
        cp "$PATCH_DIR/session/.dmrc" "/home/$CURRENT_USER/.dmrc"
        chown "$CURRENT_USER:$CURRENT_USER" "/home/$CURRENT_USER/.dmrc"
        log_info "  → /home/$CURRENT_USER/.dmrc"
    fi
fi

# 11. Set proper permissions on Xauthority for GDM
log_info "Setting up GDM Xauthority permissions..."
if [ -f /etc/gdm/Xsession ]; then
    chmod 755 /etc/gdm/Xsession
fi

echo ""
echo "============================================="
log_info "All patches applied successfully!"
echo ""
echo "  Next steps:"
echo "    1. Reboot the system:  sudo systemctl reboot"
echo "    2. After login, verify:  echo \$XDG_SESSION_TYPE"
echo "       (should output: x11)"
echo "============================================="
