SHELL := /bin/bash
.PHONY: init link unlink update-ecc setup-shell

init:
	git submodule update --init --recursive
	@[[ -f .env ]] || cp -v .env.example .env
	@echo "🏛️  Athena submodules and .env initialized."

setup-shell:
	@if ! grep -q "Athena/bin" ~/.zshrc 2>/dev/null; then \
		echo "" >> ~/.zshrc; \
		echo "# Athena Agent Framework" >> ~/.zshrc; \
		echo 'export PATH="$$HOME/Athena/bin:$$PATH"' >> ~/.zshrc; \
		echo '[[ -f "$$HOME/Athena/.env" ]] && set -a && source "$$HOME/Athena/.env" && set +a' >> ~/.zshrc; \
		echo 'which athena-ctl >/dev/null 2>&1 && eval "$$(athena-ctl completion zsh)"' >> ~/.zshrc; \
		echo "✅ Athena environment added to ~/.zshrc"; \
	fi

link: setup-shell
	mkdir -p ~/.config/opencode ~/.config/zed
	@[[ -f ~/.config/zed/settings.json && ! -L ~/.config/zed/settings.json ]] && mv -v ~/.config/zed/settings.json ~/.config/zed/settings.json.bak || true
	@[[ -f ~/.config/opencode/opencode.jsonc && ! -L ~/.config/opencode/opencode.jsonc ]] && mv -v ~/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc.bak || true
	@[[ -f ~/.config/opencode/SYSTEM.md && ! -L ~/.config/opencode/SYSTEM.md ]] && mv -v ~/.config/opencode/SYSTEM.md ~/.config/opencode/SYSTEM.md.bak || true
	stow -v -R -t ~ opencode
	stow -v -R -t ~ zed
	@echo "✅ Symlinks active. Reload your shell with: source ~/.zshrc"

unlink:
	stow -v -D -t ~ opencode
	stow -v -D -t ~ zed

update-ecc:
	git submodule update --remote --merge catalog/upstream-ecc
