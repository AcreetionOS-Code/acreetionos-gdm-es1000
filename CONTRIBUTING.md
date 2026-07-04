# Contributing to AcreetionOS GDM + ES1000 Patches

Thanks for your interest in contributing! This is a small, focused project
that patches GDM/GNOME for legacy ES1000 hardware. Here's how to help.

## Reporting Issues

Before filing an issue:

- Check that you're running a supported OS (Arch Linux or derivative)
- Verify your GPU is an AMD/ATI ES1000 (RV100/RV280)
- Run `sudo ./scripts/verify.sh` and include the output

When reporting, include:

- Your OS version (`cat /etc/os-release`)
- Your kernel version (`uname -a`)
- Your GPU model (`lspci -nn | grep -i vga`)
- Your GNOME Shell version (`gnome-shell --version`)
- Your GDM version (`gdm --version`)

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-change`)
3. Make your changes
4. Test them on actual ES1000 hardware (or a VM)
5. Commit with a clear message describing the change
6. Push and open a Pull Request

## Coding Standards

- **Scripts**: Shell scripts must use `bash` with `set -euo pipefail`
- **Formatting**: 4-space indentation, no tabs in shell scripts
- **Idempotency**: All scripts must be safe to run multiple times
- **Dry-run support**: Add `--dry-run` to any destructive operation

## Commit Messages

Follow conventional commits:

```
feat: add support for [feature]
fix: correct [issue]
docs: update [documentation]
refactor: improve [component]
```

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
