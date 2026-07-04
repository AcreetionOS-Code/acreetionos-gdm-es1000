# How to Apply These Patches

## Prerequisites

- Arch Linux (or derivative with systemd, GDM, GNOME)
- AMD/ATI ES1000 or similar R100-class GPU
- `sudo` access
- `gh` and `git` (if cloning from GitHub)

## Quick Method: One-Click Apply

```bash
# Clone and apply
git clone https://github.com/spivanatalie64/acreetionos-gdm-es1000.git
cd acreetionos-gdm-es1000
sudo ./scripts/apply.sh
```

## Manual Method: Apply Piece by Piece

### 1. Xorg Configuration

Place the radeon EXA config to enable hardware-accelerated 2D:

```bash
sudo cp patches/xorg/10-radeon.conf /etc/X11/xorg.conf.d/
```

This enables:
- EXA 2D acceleration for the radeon driver
- TearFree page-flipping
- SWCursor (avoids 3D cursor)
- EXAPixmaps for efficient VRAM pixmap management

### 2. GDM Daemon Configuration

```bash
sudo cp patches/gdm/custom.conf /etc/gdm/
```

Adds `WaylandEnable=false` in the `[daemon]` section. Note: this has no effect
on GDM 50.x's display server selection (it always adds "wayland" to supported
session types), but it serves as documentation of intent and may affect older
versions.

### 3. GDM Greeter Performance (dconf)

```bash
sudo mkdir -p /etc/dconf/db/gdm.d
sudo cp patches/gdm/greeter-dconf-performance /etc/dconf/db/gdm.d/99-es1000-performance
sudo cp patches/gdm/gdm /etc/dconf/profile/gdm
sudo dconf update
```

Applies the following to the GDM greeter:
- Disables animations, hot corners, dynamic workspaces, edge tiling
- Sets solid black background (no wallpaper)
- Reduces font sizes to 10pt
- Disables screen blanking during login

### 4. GDM Greeter Environment Variables

```bash
sudo cp patches/gdm/90-gdm-greeter-performance.conf /etc/environment.d/
```

Sets for the greeter process:
- `MESA_GL_VERSION_OVERRIDE=3.3` — skip GL version negotiation
- `MESA_NO_ERROR=1` — skip GL error checking
- `LP_NUM_THREADS=1` — llvmpipe: single thread (matches single-core CPU)
- `vblank_mode=0` — disable vsync

### 5. Systemd tmpfiles (Runtime Config Persistence)

```bash
sudo cp patches/gdm/gdm-x11.conf /etc/tmpfiles.d/
```

Ensures `/run/gdm/custom.conf` is recreated on every boot with
`WaylandEnable=false`.

### 6. User Session Environment

```bash
sudo cp patches/profile/99-es1000-performance.sh /etc/profile.d/
```

Sets the same performance environment variables for user sessions.

### 7. Block Wayland User Sessions

```bash
# Remove the Wayland GNOME session
sudo mv /usr/share/wayland-sessions/gnome.desktop /usr/share/wayland-sessions/gnome.desktop.bak

# Install the pacman hook to keep it blocked after updates
sudo cp patches/session/gdm-wayland-block.hook /etc/pacman.d/hooks/
```

### 8. Configure User for X11 Session

```bash
# Set AccountsService
sudo cp patches/session/accounts-service-natalie /var/lib/AccountsService/users/$(whoami)

# Set .dmrc
cp patches/session/.dmrc ~/
```

### 9. Reboot

```bash
sudo systemctl reboot
```

## Verification

After applying and rebooting:

```bash
# Check that GDM uses Wayland (it should — the greeter needs it)
ps aux | grep gdm-wayland-session

# Check that gnome-shell is running as the GDM greeter
ps aux | grep "gnome-shell.*gdm"

# Check that Xwayland is present
ps aux | grep Xwayland

# After logging in, check you're on X11
echo $XDG_SESSION_TYPE
# Should output: x11
```

## Troubleshooting

### GDM fails to start
```bash
sudo journalctl -u gdm -n 50
```

### Greeter is blank/not showing
```bash
# Restart GDM
sudo systemctl restart gdm
```

### Xorg crashes with SIGABRT
This was caused by `AccelDFS=on` with missing `radeon_dri.so`.
The config in this repo has `AccelDFS` removed. If you still see crashes:
```bash
# Check Xorg log
cat /var/log/Xorg.0.log | grep EE
```

### Wayland session reappeared after update
The pacman hook should handle this. To manually re-apply:
```bash
sudo mv /usr/share/wayland-sessions/gnome.desktop /usr/share/wayland-sessions/gnome.desktop.bak
```
