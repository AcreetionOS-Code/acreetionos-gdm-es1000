#!/bin/bash
#
# verify.sh — Verify that all patches are correctly applied
#
# Usage:
#   sudo ./scripts/verify.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "  ${GREEN}[PASS]${NC} $desc"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}[FAIL]${NC} $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================="
echo " AcreetionOS GDM + ES1000 — Verification"
echo "============================================="
echo ""

echo "--- Configuration Files ---"
check "Xorg radeon EXA config" \
    "grep -q 'Driver.*radeon' /etc/X11/xorg.conf.d/10-radeon.conf 2>/dev/null && \
     grep -q 'AccelMethod.*EXA' /etc/X11/xorg.conf.d/10-radeon.conf 2>/dev/null"

check "GDM custom.conf exists" \
    "test -f /etc/gdm/custom.conf"

check "GDM dconf performance profile" \
    "test -f /etc/dconf/db/gdm.d/99-es1000-performance"

check "GDM dconf database compiled" \
    "test -f /etc/dconf/db/gdm"

check "GDM greeter environment" \
    "test -f /etc/environment.d/90-gdm-greeter-performance.conf && \
     grep -q 'LP_NUM_THREADS' /etc/environment.d/90-gdm-greeter-performance.conf"

check "Systemd tmpfiles entry" \
    "test -f /etc/tmpfiles.d/gdm-x11.conf"

check "User profile environment" \
    "test -f /etc/profile.d/99-es1000-performance.sh"

echo ""
echo "--- Wayland Blockade ---"
check "Wayland GNOME session blocked" \
    "test ! -f /usr/share/wayland-sessions/gnome.desktop"

check "Pacman hook installed" \
    "test -f /etc/pacman.d/hooks/gdm-wayland-block.hook"

echo ""
echo "--- Runtime Status ---"
check "GDM is running" \
    "systemctl is-active --quiet gdm"

if command -v loginctl &>/dev/null; then
    SESSION_TYPE=$(loginctl show-session "$(loginctl | grep "$(whoami)" | awk '{print $1}')" -p Type 2>/dev/null | cut -d= -f2 || echo "")
    if [ -n "$SESSION_TYPE" ]; then
        check "Current session type" "test '$SESSION_TYPE' = 'x11'"
    fi
fi

echo ""
echo "============================================="
echo -e " Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "============================================="

exit $FAIL
