#!/bin/bash
#
# apply.sh — One-click apply for AcreetionOS GDM + ES1000 patches
#
# This script applies all configuration changes needed to make the
# GDM login screen usable on AMD/ATI ES1000 (R100) GPUs.
#
# Features:
#   - Idempotent: safe to run multiple times; detects existing changes
#   - Dry-run: use --dry-run to preview without making changes
#   - Verbose: use --verbose to see detailed output
#
# Usage:
#   sudo ./scripts/apply.sh             # Apply all patches
#   sudo ./scripts/apply.sh --dry-run   # Preview only
#   sudo ./scripts/apply.sh --force     # Re-apply even if already applied
#   sudo ./scripts/apply.sh --verbose   # Detailed output
#   sudo ./scripts/apply.sh --help      # Show help
#
# Run with sudo. It modifies system configuration files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PATCH_DIR="$SCRIPT_DIR/patches"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry()   { echo -e "${BLUE}[DRY-RUN]${NC} $1"; }

# Parse arguments
DRY_RUN=false
FORCE=false
VERBOSE=false

show_help() {
    cat <<EOF
Usage: sudo $0 [OPTIONS]

Apply GDM + ES1000 patches to make the login screen usable on
AMD/ATI ES1000 (R100) GPUs.

Options:
  --dry-run     Show what would be done without making changes
  --force       Re-apply patches even if already applied
  --verbose     Show detailed output
  --help        Show this help message

Examples:
  sudo $0                # Apply all patches
  sudo $0 --dry-run      # Preview changes
  sudo $0 --force        # Re-apply everything
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)   DRY_RUN=true; shift ;;
        --force)     FORCE=true; shift ;;
        --verbose)   VERBOSE=true; shift ;;
        --help)      show_help ;;
        *)           log_error "Unknown option: $1"; show_help ;;
    esac
done

# Must be root
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root (sudo)."
    exit 1
fi

# Apply or dry-run a file copy
# Usage: safe_copy <source> <dest> [description]
safe_copy() {
    local src="$1"
    local dest="$2"
    local desc="${3:-$(basename "$src")}"

    if [ ! -f "$src" ]; then
        log_warn "Source file not found: $src"
        return 1
    fi

    if [ -f "$dest" ]; then
        if diff -q "$src" "$dest" >/dev/null 2>&1; then
            $VERBOSE && log_info "  ✓ $dest already up-to-date"
            if $FORCE; then
                $VERBOSE && log_info "  → Forcing re-apply of $dest"
            else
                return 0
            fi
        fi
    fi

    if $DRY_RUN; then
        log_dry "Would copy: $src → $dest ($desc)"
        return 0
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"

    # Backup existing file if it's not a symlink and differs
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        if ! diff -q "$src" "$dest" >/dev/null 2>&1; then
            local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
            cp "$dest" "$backup"
            log_info "  → Backed up $dest → $backup"
        fi
    fi

    cp "$src" "$dest"
    log_info "  → $dest"
}

# Apply or dry-run a mv operation (file blocking)
# Usage: safe_block <target> [description]
safe_block() {
    local target="$1"
    local desc="${2:-$(basename "$target")}"

    if [ ! -f "$target" ] && [ ! -f "${target}.bak" ]; then
        log_warn "  → $target not found (already blocked?)"
        return 0
    fi

    if [ -f "${target}.bak" ]; then
        $VERBOSE && log_info "  ✓ ${target} already blocked"
        if $FORCE; then
            $VERBOSE && log_info "  → Forcing re-block of $target"
        else
            return 0
        fi
    fi

    if [ ! -f "$target" ]; then
        return 0
    fi

    if $DRY_RUN; then
        log_dry "Would block: $target → ${target}.bak ($desc)"
        return 0
    fi

    mv "$target" "${target}.bak"
    log_info "  → $target → .bak"
}

echo "============================================="
echo " AcreetionOS GDM + ES1000 Patches — Apply"
echo "============================================="
$DRY_RUN && echo "  *** DRY RUN MODE — No changes will be made ***"
echo ""

# Track if any changes were actually made
CHANGES_MADE=false

# 1. Xorg configuration
log_info "Installing Xorg radeon EXA config..."
safe_copy "$PATCH_DIR/xorg/10-radeon.conf" "/etc/X11/xorg.conf.d/10-radeon.conf" "Xorg radeon EXA config" && CHANGES_MADE=true

# 2. GDM daemon config
log_info "Installing GDM custom.conf..."
safe_copy "$PATCH_DIR/gdm/custom.conf" "/etc/gdm/custom.conf" "GDM daemon config" && CHANGES_MADE=true

# 3. GDM greeter dconf performance settings
log_info "Installing GDM greeter dconf performance profile..."
safe_copy "$PATCH_DIR/gdm/greeter-dconf-performance" "/etc/dconf/db/gdm.d/99-es1000-performance" "GDM greeter dconf profile" && CHANGES_MADE=true

# 4. GDM dconf profile
if [ -f "$PATCH_DIR/gdm/gdm" ]; then
    log_info "Installing GDM dconf profile..."
    safe_copy "$PATCH_DIR/gdm/gdm" "/etc/dconf/profile/gdm" "GDM dconf profile" && CHANGES_MADE=true
fi

# Recompile dconf (only if we're not in dry-run)
if ! $DRY_RUN; then
    if command -v dconf >/dev/null 2>&1; then
        dconf update && log_info "  → dconf database recompiled"
    else
        log_warn "  → dconf not found; recompile skipped"
    fi
fi

# 5. Environment variables for GDM greeter
log_info "Installing GDM greeter environment..."
safe_copy "$PATCH_DIR/gdm/90-gdm-greeter-performance.conf" "/etc/environment.d/90-gdm-greeter-performance.conf" "GDM greeter env vars" && CHANGES_MADE=true

# 6. Systemd tmpfiles entry
log_info "Installing systemd tmpfiles entry..."
safe_copy "$PATCH_DIR/gdm/gdm-x11.conf" "/etc/tmpfiles.d/gdm-x11.conf" "Systemd tmpfiles entry" && CHANGES_MADE=true

# 7. Profile environment for user session
log_info "Installing user profile environment..."
safe_copy "$PATCH_DIR/profile/99-es1000-performance.sh" "/etc/profile.d/99-es1000-performance.sh" "User profile env vars" && CHANGES_MADE=true

# 8. Block Wayland user session
log_info "Blocking Wayland GNOME session..."
safe_block "/usr/share/wayland-sessions/gnome.desktop" "Wayland GNOME session" && CHANGES_MADE=true

# 9. Install pacman hook
log_info "Installing pacman hook..."
safe_copy "$PATCH_DIR/session/gdm-wayland-block.hook" "/etc/pacman.d/hooks/gdm-wayland-block.hook" "Pacman hook" && CHANGES_MADE=true

# 10. Set user session configuration
CURRENT_USER="${SUDO_USER:-$(who am i | awk '{print $1}')}"
if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    log_info "Configuring session for user '$CURRENT_USER'..."

    # AccountsService
    if [ -f "$PATCH_DIR/session/accounts-service-natalie" ]; then
        local acct_dest="/var/lib/AccountsService/users/$CURRENT_USER"
        if $DRY_RUN; then
            log_dry "Would install AccountsService config: → $acct_dest"
        elif [ -f "$acct_dest" ] && diff -q "$PATCH_DIR/session/accounts-service-natalie" "$acct_dest" >/dev/null 2>&1 && ! $FORCE; then
            $VERBOSE && log_info "  ✓ $acct_dest already up-to-date"
        else
            mkdir -p /var/lib/AccountsService/users
            cp "$PATCH_DIR/session/accounts-service-natalie" "$acct_dest"
            log_info "  → $acct_dest"
            CHANGES_MADE=true
        fi
    fi

    # .dmrc
    if [ -f "$PATCH_DIR/session/.dmrc" ]; then
        local dmrc_dest="/home/$CURRENT_USER/.dmrc"
        if $DRY_RUN; then
            log_dry "Would install .dmrc: → $dmrc_dest"
        elif [ -f "$dmrc_dest" ] && diff -q "$PATCH_DIR/session/.dmrc" "$dmrc_dest" >/dev/null 2>&1 && ! $FORCE; then
            $VERBOSE && log_info "  ✓ $dmrc_dest already up-to-date"
        else
            cp "$PATCH_DIR/session/.dmrc" "$dmrc_dest"
            chown "$CURRENT_USER:$CURRENT_USER" "$dmrc_dest"
            log_info "  → $dmrc_dest"
            CHANGES_MADE=true
        fi
    fi
fi

# 11. Set proper permissions on Xauthority for GDM
log_info "Setting up GDM Xauthority permissions..."
if ! $DRY_RUN; then
    if [ -f /etc/gdm/Xsession ]; then
        chmod 755 /etc/gdm/Xsession
        log_info "  → /etc/gdm/Xsession permissions set"
    fi
fi

echo ""
echo "============================================="
if $DRY_RUN; then
    log_info "Dry-run complete. No changes were made."
    echo ""
    echo "  Run without --dry-run to apply these changes."
elif $CHANGES_MADE; then
    log_info "All patches applied successfully!"
    echo ""
    echo "  Next steps:"
    echo "    1. Reboot the system:  sudo systemctl reboot"
    echo "    2. After login, verify:  echo \$XDG_SESSION_TYPE"
    echo "       (should output: x11)"
else
    log_info "All patches already applied (no changes needed)."
    echo ""
    echo "  Run with --force to re-apply all patches."
fi
echo "============================================="
