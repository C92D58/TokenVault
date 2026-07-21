# App Store 上架檢查清單

## 已就緒 ✅

| 項目 | 狀態 |
|------|------|
| App Sandbox 權限 | ✅ `TokenVault.entitlements` |
| 隱私說明 (Face ID) | ✅ `NSFaceIDUsageDescription` |
| 應用分類 | ✅ `public.app-category.developer-tools` |
| App Icon (10 種解析度) | ✅ `Assets.xcassets/AppIcon` |
| 最低系統版本 | ✅ macOS 14.0 |
| Bundle ID | ✅ `org.wahsun.tokenvault` |
| 版權宣告 | ✅ `NSHumanReadableCopyright` |
| 自動終止關閉 | ✅ `NSSupportsAutomaticTermination = false` |
| 高分支援 | ✅ `NSHighResolutionCapable = true` |
| 文件類型關聯 | ✅ 支援 .json 備份 |

## 使用者部署前需要 ⚠️

| 項目 | 說明 |
|------|------|
| **Apple Developer 帳號** | $99/年，需在 developer.apple.com 註冊 |
| **分發憑證** | Xcode → Preferences → Accounts → Manage Certificates |
| **App Store Connect** | 建立 App 條目，填寫描述、截圖、關鍵字 |
| **代碼簽名** | 將 `codesign -s "Developer ID"` 替代 ad-hoc `-` |
| **Notarization** | 直接上架 App Store 則 Apple 處理；獨立分發需 `xcrun notarytool` |
| **沙箱測試** | 在 Xcode 中用 Sandbox 開啟測試匯入/匯出文件流程 |

## App Store 審核重點

| 檢查項 | 要求 |
|--------|------|
| **崩潰/凍結** | 啟動後 1 分鐘內不崩潰 |
| **私密 API** | Carbon `RegisterEventHotKey` 是公開 API ✅ |
| **最低 OS** | 需在 macOS 14 上測試 |
| **UI 完整性** | 所有按鈕有功能，無死連結 |
| **隱私** | 所有權限請求有說明文字 |
| **版權** | 不含未授權的第三方 IP |
| **內容** | 不包含色情/暴力/賭博 |

## CI/CD 建議

```bash
# 提交前驗證
./build.sh                      # 本地編譯
open .build/TokenVault.app       # 測試啟動

# App Store 構建 (需 Xcode 開發者憑證)
xcodebuild -project TokenVault.xcodeproj \
  -scheme TokenVault \
  -configuration Release \
  -destination 'platform=macOS' \
  archive -archivePath ./build/TokenVault.xcarchive
```
