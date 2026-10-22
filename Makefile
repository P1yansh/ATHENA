SHELL := /bin/bash
.PHONY: init link unlink update-ecc

init:
	git submodule update --init --recursive
	@[[ -f .env ]] || cp -v .env.example .env
	@echo "Athena submodules and .env initialized."

link:
	mkdir -p ~/.config/opencode ~/.config/zed
	@[[ -f ~/.config/zed/settings.json && ! -L ~/.config/zed/settings.json ]] && mv -v ~/.config/zed/settings.json ~/.config/zed/settings.json.bak || true
	@[[ -f ~/.config/opencode/opencode.jsonc && ! -L ~/.config/opencode/opencode.jsonc ]] && mv -v ~/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc.bak || true
	@[[ -f ~/.config/opencode/SYSTEM.md && ! -L ~/.config/opencode/SYSTEM.md ]] && mv -v ~/.config/opencode/SYSTEM.md ~/.config/opencode/SYSTEM.md.bak || true
	stow -v -R -t ~ opencode
	stow -v -R -t ~ zed
	@echo "Symlinks active."

unlink:
	stow -v -D -t ~ opencode
	stow -v -D -t ~ zed

update-ecc:
	git submodule update --remote --merge catalog/upstream-ecc
