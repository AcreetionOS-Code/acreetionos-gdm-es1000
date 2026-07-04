---
name: Bug Report
about: Report a bug or unexpected behavior
title: ''
labels: bug
assignees: ''

---

## Describe the Bug

A clear and concise description of what the bug is.

## To Reproduce

Steps to reproduce the behavior:

1. Run `sudo ./scripts/apply.sh`
2. See error ...

## Expected Behavior

A clear and concise description of what you expected to happen.

## System Information

- **OS**: [e.g. Arch Linux]
- **Kernel**: `uname -a`
- **GPU**: `lspci -nn | grep -i vga`
- **GNOME Shell**: `gnome-shell --version`
- **GDM**: `gdm --version`
- **Mesa**: `glxinfo | grep "OpenGL version"`

## Verification Output

```
# Paste the output of: sudo ./scripts/verify.sh
```

## Additional Context

Add any other context about the problem here.
