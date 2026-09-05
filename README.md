# TokenVault

### Open-source API token manager — built for developers

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="TokenVault" width="128" />
</p>

TokenVault is an **API secret manager designed for developers**. Unlike a general-purpose password manager, TokenVault is built around what developers actually need: environment labels (dev / staging / prod), automatic provider detection, a built-in JWT decoder, one-click token generation, and menu-bar quick copy — all protected with **AES-256-GCM encryption**.

This is **open-source software** under the MIT license. Contributions and forks are welcome.

---

## Requirements

- **Platform:** macOS 14.0 (Sonoma) or later
- **Architecture:** Apple Silicon (arm64)
- **Unlock:** Face ID / Touch ID (or device password)

---

## Highlights

### 🔐 Security architecture

- Every token value is encrypted with **AES-256-GCM**
- The master encryption key lives in the **macOS Keychain (Secure Enclave)**
- Keys never leave your device
- **Face ID / Touch ID** biometric unlock
- **Auto-lock on idle** — protects against shoulder surfing
- **Clipboard auto-clear** — wipes copied tokens automatically

### 🧠 Built for developers

- **Automatic detection of 21 providers** — OpenAI, GitHub, AWS, Azure, Google Cloud, Claude, Gemini, DeepSeek, Vercel, Supabase and more
- **10 token categories** — AI, cloud, database, community, payments, SSH, JWT, certificates, servers, other
- **10 credential formats** — API keys, OAuth tokens, SSH private keys, JWT, cookies, authorization headers, webhooks and more
- **Environment labels** — Development / Staging / Production
- **Built-in JWT decoder** — one-click decode of header + payload
- **Token generator** — custom length and character sets for secure keys
- **Token health checks** — validates GitHub / OpenAI / Cloudflare tokens automatically

### ⚡ Fast workflows

- **Menu-bar popover** — search and copy any token from the menu bar
- **Global shortcut ⌘⇧T** — paste your most-used token inside any app
- **⌘K Spotlight search** — find tokens instantly
- **Keyboard-shortcut HUD** — hold ⌘ for 1.5 s to see every shortcut

### 🔄 Flexible sync & backup

- **iCloud Drive sync** — automatic across Macs (optional)
- **GitHub private-repo backup** — encrypted backup to your own private repo (optional)
- **Multi-format import** — `.env`, CSV, JSON backups, manual paste, drag & drop
- **Multi-format export** — encrypted JSON backups, `.env`, CSV

### 🎨 Native macOS experience

- **Native SwiftUI interface** — smooth and light, no Electron shell
- **Dark mode** — system / dark / light
- **macOS 26 Liquid Glass** — frosted materials, dynamic refraction
- **SF Symbols animations** — bounce, pulse, replace and other native effects

---

## Installation

### Build from source

```bash
git clone https://github.com/C92D58/TokenVault.git
cd TokenVault
bash build.sh
```

The built `TokenVault.app` is placed in `.build/`.

### Install from DMG

1. Download the latest `TokenVault-1.0.dmg` from the [Releases](https://github.com/C92D58/TokenVault/releases) page
2. Open the DMG and drag `TokenVault.app` into `Applications`
3. On first launch macOS may warn "cannot verify developer":
   - Go to **System Settings → Privacy & Security** → click "Open Anyway"

---

## Quick start

### Add your first token

1. Click the **＋** button in the top-right of the main window (or press `⌘N`)
2. Enter a name and value (masked with `SecureField`)
3. Choose an environment (dev / staging / prod) and a provider (auto-detected)
4. Optional: expiry date, group, notes
5. Click **Save** — the token is encrypted with AES-256-GCM and written to disk immediately

### Quick copy

- **Menu bar:** click the 🔑 icon → search → click to copy
- **Shortcut:** `⌘⇧T` pastes your most-used token directly
- **Main window:** click the copy icon next to a token card (or double-click the card)

### Import existing tokens

- Drag `.env` / `.csv` / `.json` backup files onto the main window
- Or click **Import** → choose a file → preview → confirm

---

## Shortcut Reference

| Shortcut | Action |
|----------|--------|
| `⌘⇧T` | paste most-used token globally |
| `⌘N` | new token |
| `⇧⌘N` | new group |
| `⌘K` | Spotlight search |
| `⌘L` | lock TokenVault |
| `⌘,` | open settings |
| `⌘E` | export backup |
| `⌘I` | import backup |
| `⌘W` | close window |
| `⌘Q` | quit TokenVault |
| hold `⌘` for 1.5 s | show shortcut HUD |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Language** | Swift |
| **UI** | SwiftUI + AppKit |
| **Crypto** | CryptoKit (AES-256-GCM) |
| **Key storage** | Security Framework (Keychain Services) |
| **Biometrics** | LocalAuthentication |
| **Persistence** | Codable + JSON (iCloud Drive / local) |
| **Third-party libraries** | none (zero dependencies) |

---

## Project Structure

```
TokenVault/
├── Sources/
│   ├── App/              # app entry + AppDelegate
│   ├── DesignSystem/     # design system (tokens, materials, effects)
│   ├── Models/           # data models (token, category, security record)
│   ├── Services/         # service layer (crypto, storage, health checks, etc.)
│   └── Views/            # view layer (main screen, editor, settings, etc.)
├── Assets.xcassets/      # app icons & color assets
├── Resources/            # Info.plist, entitlements
├── build.sh              # build script
└── package.sh            # DMG packaging script
```

---

## Security Notes

TokenVault's encryption architecture:

1. Every token value is encrypted with **AES-256-GCM** before being written to disk
2. The encryption key lives in the **macOS Keychain**, protected by Secure Enclave
3. Keys **never** leave your device
4. iCloud sync carries encrypted ciphertext only
5. Biometrics (Face ID / Touch ID) unlock the app itself

> TokenVault **does not** use any remote server, analytics or third-party network service. Your data exists only on your device.

---

## License

MIT License

© 2026 WAHSUN

This software is provided "as is", without warranty of any kind, express or implied. See the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>🔐 Security is no small matter</sub>
</p>
