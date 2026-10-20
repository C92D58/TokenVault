# App Store 上架清單 — TokenVault（macOS + iOS）

更新於 2026-10-20。每一項標「已具備 ✅」或「待做」。

## 一、程式與 bundle

| 項目 | iOS | macOS |
|---|---|---|
| Bundle ID | `dev.wahsun.tokenvault` | `org.wahsun.tokenvault` ⚠️ 見決策 |
| 版本 / build | 1.0 (1) | 1.0 (1) |
| 最低系統 | iOS 18.0 | macOS 14.0 (arm64) |
| 分類 | developer-tools | developer-tools |
| Face ID 用途說明 | ✅ | ✅ |
| 加密出口合規 | ✅ `ITSAppUsesNonExemptEncryption=false`（僅標準 AES，屬豁免） | ✅ |
| App Sandbox | 不適用 | ✅ sandbox + user-selected files + network.client |
| Hardened Runtime | 不適用 | ✅ `--options runtime` |
| 第三方依賴 | 0 | 0 |
| 隱私清單 `PrivacyInfo.xcprivacy` | ✅ 已進 bundle | ✅ 已進 `Contents/Resources` |
| 追蹤 / 收集資料 | ✅ 無 | ✅ 無 |
| 網路 | 僅在使用者按下時連健康檢查 API | 同 + GitHub 備份 |
| 帳號系統 | 無 | 無 |

驗證指令：

```bash
codesign -dvvv --entitlements - .build/TokenVault.app   # macOS
codesign -dv --verbose=2 <iOS device build>/TokenVault.app
ls TokenVault.app/PrivacyInfo.xcprivacy                 # 必須存在
```

## 二、本次審計修掉的問題

| # | 問題 | 嚴重度 | 處理 |
|---|---|---|---|
| 1 | 兩端都缺 `PrivacyInfo.xcprivacy` → 上傳會被拒（ITMS-91053） | 🔴 阻擋上架 | 已補並確認進 bundle |
| 2 | macOS「iCloud 同步」是假功能：沙盒下不是真的 iCloud Drive，`useICloud` 只改標籤文字 | 🔴 功能誤導 | 移除開關，改本機儲存 + 匯出/匯入，README 更正 |
| 3 | 到期提醒預設開，但只有手動撥動才請求通知權限 → 提醒永遠不出現 | 🟠 功能失效 | 解鎖後主動請求一次 |
| 4 | `EncryptionService.reEncrypt` 死碼含 3 個強制解包（舊明文資料會 crash） | 🟠 崩潰風險 | 刪除（無呼叫點） |
| 5 | macOS「儲存位置」跟著假開關顯示 iCloud Drive | 🟡 文案 | 改「本機」 |
| 6 | 兩端都沒有隱私政策入口 | 🟡 審查觀感 | 兩端都加 `privacy.wahsun.org` |

## 三、上架前還要做的

### 1. 決定 Bundle ID（上架前唯一一次機會）

iOS `dev.` / macOS `org.` → App Store Connect 會是兩筆獨立 App，無法通用購買。

- 要「一次購買、iPhone + Mac 都能用」→ 兩端同 bundle id（建議 `dev.wahsun.tokenvault`），macOS 專案必須先改名再提交。
- 要兩個獨立 App → 現狀可用，但前綴不一致，看起來像兩個團隊。

要改就是現在改：首次上架前沒有舊版升級成本。

### 2. macOS 截圖（尚未做）

需要 `1280×800`、`1440×900`、`2880×1800`（交 2880×1800 一組即可）。iOS 的 6 張 `1320×2868` 已完成，在 `~/Desktop/TokenVault-AppStore/`。

建議畫面：主視窗（側欄＋Token 列表）、新增 Token、工具箱、設定、關於面板。

### 3. App Store Connect 建檔

- 名稱：TokenVault（被佔用時 `TokenVault — API 密鑰保險庫`）
- 副標題：`開發者的 API 密鑰保險庫`
- 分類：Developer Tools（主）、Utilities（次）
- 價格：免費、無內購
- 年齡分級：4+
- 隱私政策：<https://privacy.wahsun.org/>
- 支援：<https://wahsun.org>
- 版權：WAHSUN
- 關鍵字：api key manager, developer tools, secrets, token, aes, face id, jwt, 密鑰
- 審查備註：不需帳號；資料只存本機並以 AES-256-GCM 加密；健康檢查僅在使用者按下時連線，只帶使用者自己的 token。

### 4. 功能宣稱要與程式一致

已不再宣稱 iCloud 同步。建議描述：

> 每個值以 AES-256-GCM 加密後才寫入磁碟，金鑰存放於裝置鑰匙圈，不上傳任何資料。支援 20 種服務商自動辨識、環境標籤、JWT 解碼、金鑰產生器、Token 健康檢查、重複密鑰掃描，以及本機稽核日誌。

### 5. 每次發版自檢

```bash
bash build.sh                            # macOS
cd iOS && ./verify.sh                    # 10 個 XCUITest 全綠
cd iOS && ./build.sh                     # 模擬器
cd iOS && ./scripts/install-device.sh    # 真機（usbmuxd 備援）
```

首次上架維持 1.0；之後每次提交 `CFBundleVersion` 必須遞增。

## 四、簽名的坑（已解決，留紀錄）

1. **憑證不可帶自訂信任設定**，否則 xcodebuild 直接拒絕：
   `Invalid trust settings. Restore system default trust settings …`
   檢查 `security dump-trust-settings | grep -E '^Cert'`；
   清除 `security find-certificate -c "<憑證名>" -p login.keychain-db > /tmp/leaf.pem && security remove-trusted-cert /tmp/leaf.pem`
2. **團隊必須是 Xcode 已登入的那個**（本機 `MAA6W8AG5P`），腳本自動讀取。
3. **CoreDevice tunnel 可能壞掉**（`RemotePairingError 4`）而 usbmuxd 正常 → 用 `iOS/scripts/install-device.sh` 的 `ideviceinstaller` 備援。

## 五、隱私權政策

App 不對外傳送任何資料。Token 值以 AES-256-GCM 加密後存放在 App 自己的 Application Support 目錄，金鑰在裝置鑰匙圈。開發者無法存取使用者資料。完整條文：<https://privacy.wahsun.org/>
