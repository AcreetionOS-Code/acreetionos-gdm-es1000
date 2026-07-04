# GDM + GNOME Smoothness Optimizations for ES1000
## Date: 2026-06-29

## System Context
- GPU: AMD/ATI ES1000 (RV100/Radeon 7000 class) — NO hardware 3D acceleration in Mesa 26+
- CPU: Single-core Intel Xeon E5649 @ 2.53GHz
- RAM: 62GB
- Display: 1920x1080 on X11 (Wayland unsupported on this GPU)
- GNOME Shell: 50.2
- Kernel: 7.0.14-zen1-1-zen
- Mesa: 26.1.3 (no radeon_dri.so for r100 chips — software rendering only)

## Key Bottleneck
The ES1000 has no OpenGL driver in Mesa 26.x. The old classic `radeon` DRI driver for r100 chips was removed from Mesa years ago. GNOME Shell falls back to llvmpipe (software rendering) for all OpenGL operations. 2D acceleration works via the Xorg radeon EXA driver.

## Changes Applied

### 1. Xorg Configuration (/etc/X11/xorg.conf.d/10-radeon.conf)
- EXA acceleration (hardware 2D) enabled
- TearFree: on (prevents screen tearing via page flipping)
- SwapbuffersWait: off (don't wait for vsync)
- EnablePageFlip: on
- EXAPixmaps: on (more efficient pixmap management)
- DRI: 2 (explicitly set, DRI3 not supported)
- SWCursor: on (avoids 3D cursor rendering)

### 2. GNOME Shell / Mutter Settings
- Animations disabled
- Hot corners disabled
- Dynamic workspaces disabled (fixed workspace count)
- Edge tiling disabled
- Attach modal dialogs disabled
- Experimental feature: scale-monitor-framebuffer
- Solid dark background (no wallpaper rendering costs)
- Screen idle activation disabled
- Font sizes reduced to 10pt (less rendering)
- Overlay scrolling disabled

### 3. GDM Configuration (/etc/gdm/custom.conf)
- Wayland disabled (X11 only)
- Debug logging disabled
- GDM dconf: animations disabled for the greeter too

### 4. Environment Variables (/etc/environment.d/90-gl-performance.conf + ~/.profile)
- MESA_GL_VERSION_OVERRIDE=3.3 (force sufficient GL version)
- MESA_GLSL_VERSION_OVERRIDE=330
- MESA_NO_ERROR=1 (skip GL error checking)
- mesa_glthread=false (single-core, threading adds overhead)
- LP_NUM_THREADS=1 (limit llvmpipe to 1 thread)
- vblank_mode=0 (don't sync to vertical blank)
- CLUTTER_BACKEND=x11 (explicit)
- __GLX_VENDOR_LIBRARY_NAME=mesa

### 5. Mesa drirc (~/.drirc)
- Per-application settings for gnome-shell
- vblank_mode=0, mesa_glthread=false

### 6. Kernel / Boot Changes
- sysctl: vm.swappiness=10, vm.vfs_cache_pressure=50, vm.dirty_ratio=40, vm.dirty_background_ratio=5, sched_autogroup_enabled=0
- GRUB cmdline: radeon.modeset=1 radeon.dpm=1 radeon.audio=0 radeon.disp_priority=2 radeon.msi=1
- /etc/modprobe.d/radeon-optimizations.conf: radeon module params

### 7. Sudo Configuration
- Passwordless sudo set up for natalie via /etc/sudoers.d/99-natalie-nopasswd

## TODO for Next Reboot
- GRUB changes (radeon kernel params) require a reboot
- New Xorg config takes effect on display server restart (GDM restart or reboot)
- The `WaylandEnable=false` setting takes effect on GDM restart
- Kernel sysctl file auto-loads on boot

## Potential Future Work
- Install `mesa-amber` from AUR (21.3.9) to get classic radeon DRI driver for hardware GL — BUT conflicts with current Mesa, not recommended
- Add a discrete GPU for hardware acceleration
- Consider lighter desktop (LXQt, MATE, Openbox) if GNOME remains too slow
