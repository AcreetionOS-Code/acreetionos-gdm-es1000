# Why This Exists — The Full Technical Rationale

## The ES1000 Problem

The AMD/ATI ES1000 is a **R100-family** GPU from the early 2000s. It was
commonly used as a server BMC/serial-over-LAN chip. It has:

- **No hardware T&L** (Transform & Lighting)
- **No unified shader architecture** (it's a fixed-function pipeline)
- **Maximum OpenGL support: ~1.3** (in hardware)
- **DRI driver: `radeon_dri.so` for r100** — removed from Mesa 24+

Mesa 26.x (shipped on Arch Linux in 2026) **does not include the classic r100
DRI driver**. The file `/usr/lib/dri/radeon_dri.so` simply does not exist.

## GNOME Shell's 3D Requirement

GNOME Shell uses OpenGL 3.3+ for compositing. When no hardware GL is available:

- **On Wayland:** gnome-shell acts as the Wayland compositor AND the display
  server. It falls back to `llvmpipe` (Mesa's software rasterizer) for all
  GL operations. This is functional but **extremely slow** on single-core CPUs.

- **On X11:** gnome-shell becomes a regular X11 client using Clutter/Mutter.
  It ALSO needs OpenGL, so it ALSO falls back to `llvmpipe`. However, the
  underlying 2D rendering goes through Xorg's **EXA acceleration** (via the
  radeon kernel driver), which IS hardware-accelerated.

## Why We Can't Just Switch GDM to X11

The GDM greeter runs `gnome-shell --mode=gdm`. In GNOME 45+, this is a systemd
user service with the following assertion:

```
AssertEnvironment=XDG_SESSION_TYPE=wayland
```

This is in `/usr/lib/systemd/user/org.gnome.Shell@.service`. systemd's
`AssertEnvironment` is **not overridable** via drop-ins — drop-ins add
additional assertions (AND logic), they don't replace.

So the GDM greeter **must** run on Wayland. Full stop.

## The Greeter Performance Problem

On Wayland with `llvmpipe` on a 2.53GHz single-core CPU:

- Each frame requires a full GL compatibility check
- Animations burn CPU cycles that don't exist
- Background images add texture upload overhead
- Multiple threads in llvmpipe cause lock contention
- vsync synchronization blocks the render loop

## The Three-Layer Fix

### Layer 1: GDM Greeter Performance (Wayland)

Reduce the greeter's rendering load to the absolute minimum:

- **Disable animations**: No transitions, no sliding, no fading
- **Disable hot corners**: No overlay trigger polling
- **Solid black background**: No wallpaper texture uploads
- **Limit llvmpipe to 1 thread**: Single-core CPU can't benefit from threads
- **Force GL version override**: Skip version negotiation on every context
- **Disable GL error checking**: `MESA_NO_ERROR=1` saves validation overhead
- **Disable vsync**: `vblank_mode=0` prevents blocking on display refresh

### Layer 2: User Session on X11

After login, the user runs GNOME on X11. Xorg's radeon EXA driver provides
hardware-accelerated 2D:

- **EXA acceleration**: 2D operations go through the GPU
- **TearFree**: Page-flipping without tearing
- **EXAPixmaps**: Efficient pixmap management in VRAM
- **SWCursor**: Skip 3D cursor rendering

The ES1000 can't do 3D, but **2D desktop operations** (window moves, text
rendering, image display) become smooth.

### Layer 3: Lock Wayland for User Sessions

The Wayland GNOME desktop file is removed (`.bak`). The user's session is
configured for X11 via AccountsService and `.dmrc`. A pacman hook ensures
this survives package updates:

```
Trigger: gdm OR gnome-shell
Action:  If Wayland GNOME session reappears, hide it
```

## Why Not mesa-amber?

`mesa-amber` provides the classic r100 DRI driver (OpenGL 1.3-2.1 hardware
acceleration). However:

- **mesa-amber 21.3.9 conflicts with mesa 26.1.3**
- Replacing mesa with mesa-amber would break every modern GL application
- The ES1000's hardware GL is too limited for GNOME Shell anyway
- llvmpipe gives better GL 3.3 compatibility than the old r100 hardware

## The Xorg Crash Bug

During development, we discovered that the radeon EXA driver **crashes with
SIGABRT** when AIGLX fails to find `radeon_dri.so`. The crash backtrace:

```
#0  __assert_fail (libc.so.6)
#10 libexa.so (EXA assertion failure)
#13 radeon_drv.so (EXA + DRI init)
```

The fix: AIGLX falls back to `DRISWRAST` (software GL) when the DRI driver
is missing. With default Xorg settings, this fallback works correctly. The
crash only occurred when specific DRI-related options were set (`AccelDFS on`,
`DRI 2`, etc.) that prevented the graceful fallback.

The current configuration uses safe defaults for the radeon driver:
- `AccelMethod EXA` for 2D acceleration
- `EnablePageFlip on` for smooth compositing
- No `AccelDFS` — this prevents the DRI assertion crash
- AIGLX falls through to `swrast_dri.so` automatically

## Future Considerations

- **Vulkan + Zink**: If the ES1000 ever gets a Vulkan driver (unlikely),
  `MESA_LOADER_DRIVER_OVERRIDE=zink` could provide GL via Vulkan
- **Mesa-amber split**: If mesa-amber becomes installable alongside mesa
  (not conflicting), the radeon DRI driver would provide hardware GL 1.3
- **A different DM**: LightDM or SDDM with a lighter greeter would eliminate
  the Wayland requirement entirely
