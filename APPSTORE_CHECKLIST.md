# App Store 上架最終檢查清單 ✅

## 自動化驗證 (已通過)

| 項目 | 狀態 | 說明 |
|------|------|------|
| 編譯 (swiftc -O) | ✅ | 0 error, 1 warning (無害) |
| 資產編譯 (actool) | ✅ | AppIcon + Assets.car |
| 代碼簽名 (Hardened Runtime) | ✅ | `--options runtime --timestamp` |
| ad-hoc 簽名 | ✅ | 開發測試用 |
| 崩潰風險 | ✅ | 所有 force-unwrap 已審查 |

## Info.plist ✅

| 鍵 | 值 |
|----|-----|
| CFBundleIdentifier | org.wahsun.tokenvault |
| CFBundleVersion / ShortVersion | 1 / 1.0 |
| LSMinimumSystemVersion | 14.0 (arm64) |
| LSApplicationCategoryType | public.app-category.developer-tools |
| NSFaceIDUsageDescription | ✅ 完整說明 |
| NSHumanReadableCopyright | © 2026 WAHSUN |
| ITSAppUsesNonExemptEncryption | false |
| CFBundleSpokenName | Token Vault |
| CFBundleDocumentTypes | JSON 備份關聯 |

## Entitlements ✅

| 權限 | 用途 |
|------|------|
| com.apple.security.app-sandbox | App Store 必須 |
| files.user-selected.read-write | 導入/匯出 |
| network.client | GitHub 同步 |

## 上架前準備事項

1. **Apple Developer 帳號** ($99/年)
2. **建立 Distribution 憑證** (Xcode → Settings → Accounts)
3. **App Store Connect 建立 App**:
   - Bundle ID: `org.wahsun.tokenvault`
   - 分類: Developer Tools
   - 定價: 免費
4. **簽名改為 Developer ID**:
   ```bash
   codesign --force --deep --sign "Developer ID Application: WAHSUN (TEAMID)" \
     --options runtime --entitlements Resources/TokenVault.entitlements \
     --timestamp .build/TokenVault.app
   ```
5. **上傳到 App Store**:
   ```bash
   xcrun altool --upload-app -f TokenVault.pkg \
     -t macos -u apple@id.com -p @keychain:AC_PASSWORD
   ```
6. **App Store 截圖** (至少 3 張, 1280x800 或 1440x900):
   - 主畫面 (側欄+Token列表)
   - 新增 Token 畫面
   - Token 工具箱 (產生器)
7. **App 描述** (繁體中文 + 英文):
   - 零知識 API Token 管理
   - AES-256-GCM 加密
   - 開發者環境 (dev/staging/prod)

## 隱私權政策

App 不上傳任何數據到第三方伺服器。所有 Token 經 AES-256-GCM 加密後儲存在 iCloud Drive。開發者無法存取用戶數據。
