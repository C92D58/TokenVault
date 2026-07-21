# TokenVault

### 零知識 API Token 管理器 — 為開發者而生

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="TokenVault" width="128" />
</p>

TokenVault 是一款專為開發者設計的 **API 密鑰管理工具**。不同於一般密碼管理器，TokenVault 從頭建構了開發者真正需要的功能：環境標記（開發／預發／正式）、Token 類型自動識別、內建 JWT 解碼器、一鍵 Token 產生器，以及選單列快速複製 —— 全部以 **AES-256-GCM 零知識加密**保護。

---

## 定價

| 方案 | 價格 | 說明 |
|------|------|------|
| **永久買斷** | **$19.99** | 一次性付費，終身使用，無訂閱、無隱藏費用 |

> TokenVault 是 **私人付費軟體**，原始碼未開放。你購買的是編譯好的 macOS 應用程式，包含未來所有小版本更新。

---

## 系統需求

- **平台：** macOS 14.0（Sonoma）或更新版本
- **架構：** Apple Silicon（arm64）
- **授權：** Face ID / Touch ID（或裝置密碼）

---

## 功能亮點

### 🔐 零知識安全架構

- **AES-256-GCM** 加密每個 Token 值
- 主加密金鑰存放於 **macOS 安全鑰匙圈（Secure Enclave）**
- 金鑰永不出境 — 開發者無法存取你的資料
- **Face ID / Touch ID** 生物辨識解鎖
- **閒置自動鎖定** — 防止離開座位時被偷看
- **剪貼簿自動清空** — 複製 Token 後 15/30/45 秒自動清除

### 🧠 為開發者打造

- **9 種 Token 類型自動識別** — GitHub、GitLab、AWS、OpenAI、Cloudflare、Slack、Stripe、Tailscale、自訂
- **環境標記** — 開發（Development）、預發（Staging）、正式（Production），對應真實開發流程
- **內建 JWT 解碼器** — 一鍵解碼 Header + Payload，不用另外開 jwt.io
- **Token 產生器** — 自訂長度、字元集，一鍵產生安全密鑰
- **安全分數儀表板** — 過期 Token 提醒、使用統計、健康分數

### ⚡ 極速工作流

- **選單列 Popover** — 一鍵從選單列搜尋並複製 Token
- **全域快捷鍵 ⌘⇧T** — 在任何 App 中直接貼上最常用 Token
- **鍵盤快捷鍵提示 HUD** — 長按 ⌘ 1.5 秒顯示所有快捷鍵

### 🔄 靈活同步與備份

- **iCloud Drive 同步** — 跨 Mac 自動同步（可選）
- **GitHub 私有倉庫備份** — 加密備份推送到你的私有 Repo（可選）
- **多格式導入** — 支援 `.env`、CSV、JSON 備份、手動貼上
- **多格式匯出** — 加密 JSON 備份、`.env`、CSV

### 🎨 原生 macOS 體驗

- **SwiftUI 原生介面** — 流暢、輕量，非 Electron 包殼
- **深色模式** — 系統／深色／淺色 自由切換
- **最小化資源佔用** — 僅 2.8 MB，零第三方依賴

---

## 安裝

1. 從 [wahsun.org](https://wahsun.org) 下載最新版 `TokenVault.app`
2. 將 `TokenVault.app` 拖入 `Applications` 資料夾
3. 首次開啟時，macOS 可能會提示「無法驗證開發者」：
   - 前往 **系統設定 → 隱私權與安全性**
   - 點擊「強制打開」
4. 設定你的 Face ID / Touch ID 授權
5. 開始管理你的 Token！

---

## 快速開始

### 新增第一個 Token

1. 點擊主視窗右上角的 **＋** 按鈕
2. 輸入 Token 名稱與值（支援 `SecureField` 遮罩顯示）
3. 選擇環境（開發／預發／正式）與類型（如 GitHub、AWS）
4. 可選：設定到期日、加入群組
5. 點擊「儲存」— Token 即時以 AES-256-GCM 加密寫入磁碟

### 快速複製

- **選單列**：點擊選單列 🔑 圖示 → 搜尋 Token → 點擊複製
- **快捷鍵**：`⌘⇧T` 直接貼上最常用 Token
- **主視窗**：點擊 Token 卡片旁的複製圖示

### 導入現有 Token

- 拖曳 `.env` / `.csv` / `.json` 備份檔案到主視窗
- 或點擊「導入」按鈕 → 選擇檔案 → 預覽 → 確認導入

---

## 快捷鍵速查

| 快捷鍵 | 功能 |
|--------|------|
| `⌘⇧T` | 全域貼上最常用 Token |
| `⌘N` | 新增 Token |
| `⌘F` | 搜尋 Token |
| `⌘,` | 開啟設定 |
| `⌘W` | 關閉視窗 |
| `⌘Q` | 退出 TokenVault |
| 長按 `⌘` 1.5 秒 | 顯示快捷鍵 HUD |

---

## 安全性說明

TokenVault 採用 **零知識架構**：

1. 所有 Token 值在寫入磁碟前以 **AES-256-GCM** 加密
2. 加密金鑰存放於 **macOS 鑰匙圈**，受 Secure Enclave 保護
3. 金鑰**永遠不會**離開你的裝置
4. 開發者**無法**存取你的任何 Token 資料
5. iCloud 同步的僅是經過加密的密文
6. 生物辨識（Face ID / Touch ID）用於解鎖應用程式本身

> TokenVault **不使用**任何遠端伺服器、分析追蹤或第三方網路服務。你的資料只存在你的裝置上。

---

## 比較

| | TokenVault | 1Password | Bitwarden | .env 檔案 |
|---|---|---|---|---|
| **價格** | $19.99 買斷 | $2.99/月 | $10/年 | 免費 |
| **開發者環境** | ✅ dev/staging/prod | ❌ | ❌ | ❌ |
| **Token 類型檢測** | ✅ 9 種 | ❌ | ❌ | ❌ |
| **JWT 解碼** | ✅ 內建 | ❌ | ❌ | ❌ |
| **Token 產生器** | ✅ | ❌ | ❌ | ❌ |
| **全域快捷鍵** | ✅ ⌘⇧T | ❌ | ❌ | ❌ |
| **原生輕量** | ✅ SwiftUI 2.8MB | ❌ Electron | ❌ Electron | ✅ |
| **零知識加密** | ✅ AES-256-GCM | ✅ | ✅ | ❌ |

---

## 技術棧

| 層面 | 技術 |
|------|------|
| **語言** | Swift |
| **UI** | SwiftUI + AppKit |
| **加密** | CryptoKit（AES-256-GCM） |
| **金鑰存儲** | Security Framework（Keychain Services） |
| **生物辨識** | LocalAuthentication |
| **資料持久化** | Codable + JSON（iCloud Drive / 本地） |
| **第三方程式庫** | 無（零依賴） |

---

## 關於 WAHSUN

TokenVault 由 **WAHSUN** 獨立開發並維護。我們專注於打造開發者真正需要的工具 —— 簡潔、安全、買斷制。

- 🌐 [wahsun.org](https://wahsun.org)
- 📧 [x@wahsun.org](mailto:x@wahsun.org)

---

## 授權條款

© 2026 WAHSUN。保留所有權利。

本軟體為 **商業授權軟體**，原始碼未開放。禁止未經授權的複製、散佈、反編譯或逆向工程。購買一份授權限於個人使用。

---

<p align="center">
  <sub>🔐 安全無小事</sub>
</p>
