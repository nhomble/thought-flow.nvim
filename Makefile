.PHONY: help lint format check install-tools

help:
	@echo "Available targets:"
	@echo "  make lint          - Run luacheck linter"
	@echo "  make format        - Format code with stylua"
	@echo "  make check         - Run lint + format check"
	@echo "  make install-tools - Install luacheck and stylua via Homebrew"

# Install tools locally via Homebrew
install-tools:
	@command -v luacheck >/dev/null 2>&1 || { echo "Installing luacheck..."; brew install luacheck; }
	@command -v stylua >/dev/null 2>&1 || { echo "Installing stylua..."; brew install stylua; }
	@echo "All tools installed"

# Run luacheck linter
lint:
	@command -v luacheck >/dev/null 2>&1 || { echo "Error: luacheck not found. Run 'make install-tools'"; exit 1; }
	luacheck lua/

# Format code with stylua (modifies files)
format:
	@command -v stylua >/dev/null 2>&1 || { echo "Error: stylua not found. Run 'make install-tools'"; exit 1; }
	stylua lua/

# Check formatting without modifying (CI mode)
format-check:
	@command -v stylua >/dev/null 2>&1 || { echo "Error: stylua not found. Run 'make install-tools'"; exit 1; }
	stylua --check lua/

# Run all checks (lint + format check)
check: lint format-check
	@echo "All checks passed"
