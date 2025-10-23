# 🌌 Serv00 Galactic Reset

A lightweight, high-velocity script to reset your VPS, preserving your digital empire.

<div align="center" style="margin-bottom: 24px;">
  <img src="https://img.shields.io/badge/Serv00-Reset-00DDEB?style=flat-square&logo=server" alt="Serv00 Reset" />
  <img src="https://img.shields.io/badge/License-MIT-1E90FF?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/Platform-Linux/FreeBSD-D91414?style=flat-square&logo=linux" alt="Platform" />
</div>

---

## Overview

**Serv00 Galactic Reset** is your warp-speed solution for initializing VPS environments via SSH. Built for Serv00 and beyond, it clears clutter while safeguarding website directories (e.g., Typecho, Memos) and critical configs. Embrace the future of server management with precision and style.

---

## Quick Start

Launch into action with a single command:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/serv00-reset.sh
chmod +x serv00-reset.sh
./serv00-reset.sh
```

---

## Features

- **Futuristic CLI**: Neon-colored interface for a stellar user experience.
- **Website Protection**: Preserves `~/domains` for Typecho/Memos by default.
- **Safeguards**: Multi-step confirmations to prevent data loss.
- **Cleanup Tasks**:
  - Vaporize cron jobs.
  - Terminate rogue user processes.
  - Clear home directory, sparing websites and configs.

---

## Installation

For seamless access, integrate into your system:

```bash
sudo mv serv00-reset.sh /usr/local/bin/serv00-reset
```

Or add a cosmic alias:

```bash
echo "alias serv00-reset='~/serv00-reset.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## Caution

⚠️ This script deletes non-essential data. Backup critical files before engaging warp drive.

---

## Contributing

Join the mission! Fork this repo, submit pull requests, or share feedback on [X](https://x.com/SamueruTokeisou). Let’s build a cleaner universe together.

<footer align="center">
  <sub>© 2025 Tokeisou Samueru · Reset the stars, conquer the void.</sub>
</footer>
