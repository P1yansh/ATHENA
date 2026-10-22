# 🏛️ Athena

A modular, hardware-scalable AI Agent workflow for Arch Linux combining **Zed**, **OpenCode**, **Everything Claude Code (ECC)**, and **llama.cpp**.

## Directory Topology
- `bin/`: Contains `llama-launch` (profile-driven inference launcher) and `athena-ctl` (skill/agent/project manager).
- `hardware-profiles/`: Decoupled hardware flags (`low-vram-6gb.conf`, `mid-vram-16gb.conf`).
- `catalog/`: Houses `upstream-ecc` (Git submodule) and your `custom-agents/` & `custom-skills/`.
- `opencode/` & `zed/`: GNU Stow packages mapping cleanly into `~/.config/`.
- `projects/`: Git-ignored workspace directory where all individual coding repositories and GSoC projects live.

## Quickstart on Arch Linux
```bash
sudo pacman -S --needed zed opencode llama-cpp ggml-cuda stow jq curl git wl-clipboard
git clone --recurse-submodules git@github.com:P1yansh/Athena.git ~/Athena
cd ~/Athena && make init link
```
