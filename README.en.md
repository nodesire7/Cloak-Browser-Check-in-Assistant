# Cloak Browser Check-in Assistant

> **中文 → [README.md](README.md)**

Automated daily check-in for PT sites using [Cloak Browser](https://cloakbrowser.dev) to bypass Cloudflare challenges.

**Built-in site templates:** ourbits.club · audiences.me · and any NexusPHP site

---

## Quick Start

### Linux / macOS

```bash
chmod +x run.sh
./run.sh
```

### Windows

Double-click `run.bat`

**On first run, the script automatically:**

1. Verifies Python 3.8+ (shows install instructions if missing)
2. Installs `cloakbrowser` automatically
3. Opens the **setup wizard** to add sites and enter credentials
4. Runs the check-in

Subsequent runs skip setup and go straight to check-in.

---

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Auto-setup on first run, then check in all sites |
| `./run.sh --setup` | Open setup wizard (add/edit/remove sites) |
| `./run.sh --login` | Clear cookies and force re-login |
| `./run.sh ourbits` | Check in for one site only |

Windows: replace `./run.sh` with `run.bat`.

---

## Setup Wizard

Run `./run.sh --setup` to open the interactive setup wizard:

```
Current sites:
  1. ourbits — https://ourbits.club  [enabled]
  2. audiences — https://audiences.me  [enabled]

Menu:
  1) Add site
  2) Edit site (username / password / enable)
  3) Remove site
  4) Clear cookies (force re-login)
  5) Save and exit
  0) Exit without saving
```

Choose from built-in templates or enter any NexusPHP site's URL manually.

---

## Requirements

- Python 3.8+
- A valid account on each PT site

## Notes

- `config.json` stores site configuration and credentials locally, excluded from git via `.gitignore`.
- Browser profiles (`profile_*/`) and cookies (`cookies_*.json`) are also gitignored.
- Sites with image CAPTCHA will prompt you to enter the code manually on first login.
- After a successful login, cookies persist until the session expires.
