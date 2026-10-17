# TokenVault for iOS

The vault in your pocket. Same encryption, same file format, same taxonomy as the macOS build —
rebuilt for a phone instead of stretched into one.

```
iOS/
├── TokenVault.xcodeproj          # one app target + one UI-test target, no dependencies
├── TokenVault/
│   ├── App/                      # entry point, AppState (lock + scene phase), root view
│   ├── Design/                   # Theme tokens, card/badge/control components
│   ├── Models/                   # iOS-only bits (provider glyphs, masking)
│   ├── Services/                 # VaultStore, settings, clipboard, auth, JWT, toasts
│   ├── Views/                    # vault, detail, editor, tools, log, trash, settings, import
│   └── Resources/Assets.xcassets # generated icon + accent colour
├── TokenVaultUITests/            # acceptance suite (XCUITest)
├── build.sh                      # build → install → launch on a simulator
├── verify.sh                     # build-for-testing + run the suite, verdict from the log
└── scripts/device.sh             # build → install → launch on a real iPhone
```

The models and the platform-neutral services (`TokenItem`, taxonomy, audit log, AES-GCM,
Keychain, import/export parsers, health checks, reminders) are **shared with the macOS build** —
they live in `../Sources/Core` and are compiled into both apps through a file-system synchronized
group. One copy of the crypto, not two.

## Build

```bash
./build.sh              # iPhone 18 Pro simulator, installed and launched
./build.sh --clean      # wipe the vault first
./verify.sh             # acceptance suite (~4 min); screenshots land in the xcresult
./scripts/device.sh     # a connected iPhone, signed with the free Apple ID in Xcode
```

The icon is generated, never hand-edited:

```bash
swift ../scripts/make-icon.swift ios      # 1024 full-bleed PNG for iOS
swift ../scripts/make-icon.swift macos    # macOS PNGs + .icns, same artwork in a Big Sur frame
```

## What is on the phone

| Screen | What it does |
|---|---|
| **保險庫** | Search (`tag:` `provider:` `cat:` `fav:true` `expired:true`), filter chips by category, favorites first, swipe to copy or delete, long-press menu |
| **Token 詳情** | Masked value with reveal, one-tap copy with clipboard auto-clear, metadata, provider console link, JWT decode, grouped actions |
| **新增 / 編輯** | Auto-detected provider from name or value, environment segmented control, category, format, group, tags, expiry, notes |
| **工具** | Key generator (API key / password / hex), JWT decoder, live token health checks (GitHub · OpenAI · Cloudflare), duplicate scan |
| **日誌** | Local audit trail — copies, edits, imports, exports, locks — capped at 500 entries |
| **設定** | Appearance, biometric lock, auto-lock window, clipboard clear window, expiry reminders, import/export, trash, lock now |
| **鎖定** | Face ID / Touch ID with passcode fallback; the app switcher sees a cover, never the vault |

## Security

- Every token value is **AES-256-GCM** sealed before it touches disk; the 256-bit master key lives
  in the Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) and never leaves the device.
- The vault file is `Documents/Vault/tokens.json` — the same schema the macOS build writes. File
  sharing is on, so it is reachable from the Files app and Finder.
- Clipboard copies are wiped after a configurable window, and only if nothing else replaced them.
- The UI is covered the moment the app leaves the foreground.
- No network access except the health checks you explicitly start.

### Moving tokens between Mac and iPhone

The master key is device-bound, so an encrypted JSON backup is only readable on the device that
wrote it. To move secrets:

1. On the Mac: **Export → .env** or **CSV**.
2. On the iPhone: **保險庫 → ⋯ → 匯入備份**, pick the file.

Importing a JSON backup from another device is handled honestly: rows whose ciphertext cannot be
decrypted are counted and skipped rather than imported with an empty value.

## Tests

`TokenVaultUITests` drives the real app on a simulator, unlocked and seeded
(`-uiTestReset -uiTestUnlocked -uiTestSeed`):

- the seeded vault lists its tokens
- search narrows the list
- the detail sheet starts masked, reveals on demand, and confirms a copy with a toast
- a newly added token appears in the list
- the generator produces the requested length
- the JWT decoder reads a claim
- settings shows security and about
- locking from the vault returns to the lock screen
- screenshot tour: vault, detail, editor, tools, settings, log
