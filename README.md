# AcreetionOS GDM + ES1000 GPU Patches

**Making GNOME's login screen usable on hardware older than your average sysadmin.**

This repository contains the complete set of configuration changes and patches
required to get the GDM (GNOME Display Manager) login screen working smoothly
on systems with an **AMD/ATI ES1000** (RV100/Radeon 7000-class) GPU — a chip
so old that Mesa 26.x dropped its DRI driver entirely.

## The Problem

| Component | Issue |
|-----------|-------|
| **GPU** | AMD ES1000 — no hardware 3D acceleration since Mesa 24+ |
| **GNOME Shell** | Requires OpenGL 3.3+; falls back to `llvmpipe` software rendering |
| **GDM Greeter** | GNOME Shell's `--mode=gdm` refuses to run outside Wayland (`AssertEnvironment=XDG_SESSION_TYPE=wayland`) |
| **Result** | Login screen renders at ~2 FPS, feels like 1999 |

## Solution Overview

Three layers of fixes:

### 1. GDM Greeter Optimizations (Wayland stays, but optimized)
The greeter has to stay on Wayland (gnome-shell asserts it), but we make it
fast by:
- Disabling all animations, hot corners, dynamic workspaces
- Solid black background (no wallpaper rendering cost)
- Reducing font sizes
- Limiting `llvmpipe` to 1 thread (matches single-core CPU)
- Forcing GL version override to skip compat checks
- Disabling vsync (vblank_mode=0)

### 2. User Session Forced to X11
After login, the user's GNOME session runs on X11 with the **radeon EXA**
driver for hardware-accelerated 2D rendering:
- Wayland GNOME session file removed (`gnome.desktop` → `.bak`)
- AccountsService configured for X11 session
- `.dmrc` set to `Session=gnome`
- Xorg configured with EXA acceleration, TearFree, PageFlip

### 3. Wayland Permanently Locked for User Sessions
- Pacman hook re-applies the Wayland block on every `gdm`/`gnome-shell` update
- Systemd-tmpfiles entry ensures runtime config persists across boots

## Repository Structure

```
├── README.md                          # This file
├── patches/
│   ├── xorg/
│   │   └── 10-radeon.conf            # Xorg radeon EXA config
│   ├── gdm/
│   │   ├── custom.conf               # GDM daemon config
│   │   ├── greeter-dconf-performance  # dconf greeter optimizations
│   │   ├── 90-gdm-greeter-performance.conf  # Environment vars for greeter
│   │   ├── gdm                       # dconf profile
│   │   └── gdm-x11.conf              # systemd-tmpfiles entry
│   ├── session/
│   │   ├── accounts-service-natalie  # AccountsService user config
│   │   ├── .dmrc                     # User session preference
│   │   └── gdm-wayland-block.hook    # Pacman hook
│   └── profile/
│       └── 99-es1000-performance.sh  # Profile env vars
├── scripts/
│   ├── apply.sh                      # One-click apply
│   └── verify.sh                     # Verify patches are applied
├── docs/
│   ├── WHY.md                        # Technical rationale
│   └── HOWTO.md                      # How to apply
└── .gitignore
```

## Quick Apply

```bash
sudo ./scripts/apply.sh
```

## Tested On

- **OS:** Arch Linux (rolling)
- **GPU:** AMD/ATI ES1000 (RV100) @ PCI 01:03.0
- **CPU:** Intel Xeon E5649 @ 2.53GHz (single-core)
- **RAM:** 62GB
- **Mesa:** 26.1.3 (no `radeon_dri.so` — software GL only)
- **GNOME Shell:** 50.3
- **GDM:** 50.1
- **Kernel:** 7.0.14-zen1-1-zen
- **Display:** 1920×1080 on VGA

## License

Do whatever you want. This is configuration, not code. If it burns your house
down, you get to keep the insurance money.
