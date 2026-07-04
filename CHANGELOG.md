# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-07-03

### Added

- Initial release of the standardized repository
- MIT License file
- CONTRIBUTING.md with contribution guidelines
- .editorconfig for consistent formatting
- Issue templates (bug report, feature request)
- Pull request template
- Makefile with convenience targets (apply, verify, dry-run, clean, format)
- CHANGELOG.md (this file)

### Changed

- **apply.sh**: Added `--dry-run` mode for previewing changes
- **apply.sh**: Added `--force` flag for re-applying already-applied patches
- **apply.sh**: Added `--verbose` mode for detailed output
- **apply.sh**: Added `--help` flag
- **apply.sh**: Files are now idempotent — safe to run multiple times
- **apply.sh**: Automatic backup of existing files before overwriting
- **apply.sh**: Source file existence checks to prevent silent failures

### Fixed

- apply.sh now checks if dconf is installed before attempting recompile
- Various edge cases in file state detection

## [0.1.0] — 2026-06-XX

### Added

- Initial patch set for GDM + GNOME on AMD/ATI ES1000 GPUs
- Xorg radeon EXA configuration
- GDM daemon custom.conf
- GDM greeter dconf performance profile
- GDM environment variables (LP_NUM_THREADS, MESA_GL_VERSION_OVERRIDE, etc.)
- Systemd tmpfiles entry for GDM X11
- User profile environment variables
- Wayland GNOME session blocking
- Pacman hook for persistence across GDM/gnome-shell updates
- AccountsService configuration
- apply.sh and verify.sh scripts
- Documentation (WHY.md, HOWTO.md, gdm-gnome-smoothness-es1000.md)
