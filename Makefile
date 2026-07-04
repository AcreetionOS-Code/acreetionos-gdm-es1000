# Makefile — AcreetionOS GDM + ES1000 Patches
#
# Convenience targets for common operations.
# The real work is done by the scripts in scripts/.
#
# Default target
.PHONY: help
help:
	@echo "AcreetionOS GDM + ES1000 Patches — available targets"
	@echo ""
	@echo "  help      Show this help message"
	@echo "  apply     Apply all patches (requires sudo)"
	@echo "  verify    Verify all patches are applied (requires sudo)"
	@echo "  dry-run   Show what would be applied (requires sudo)"
	@echo "  clean     Remove backup files from the system"
	@echo "  format    Check shell script formatting"
	@echo ""

.PHONY: apply
apply:
	@echo "==> Applying GDM + ES1000 patches..."
	sudo ./scripts/apply.sh

.PHONY: verify
verify:
	@echo "==> Verifying patches..."
	sudo ./scripts/verify.sh

.PHONY: dry-run
dry-run:
	@echo "==> Dry-run: showing what would be applied..."
	sudo ./scripts/apply.sh --dry-run

.PHONY: clean
clean:
	@echo "==> Removing backup files..."
	sudo find /etc /usr/share -name '*.bak' -delete 2>/dev/null || true
	@echo "Done."

.PHONY: format
format:
	@echo "==> Checking shell script formatting..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh; \
	else \
		echo "shellcheck not installed. Install it with: sudo pacman -S shellcheck"; \
	fi
