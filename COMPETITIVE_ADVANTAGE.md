# TokenVault 競爭優勢分析

## 為什麼選擇 TokenVault？

| | TokenVault | 1Password | Bitwarden | Apple Keychain | .env 檔案 |
|---|---|---|---|---|---|
| **價格** | 個人自用（不對外） | $2.99/月 | $10/年 | 免費 | 免費 |
| **零知識加密** | ✅ AES-256-GCM | ✅ | ✅ | ✅ | ❌ |
| **開發者環境** | ✅ dev/staging/prod | ❌ | ❌ | ❌ | ❌ |
| **Token 類型檢測** | ✅ 自動識別 10 種 | ❌ | ❌ | ❌ | ❌ |
| **21 種服務商** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **JWT 解碼** | ✅ 內建 | ❌ | ❌ | ❌ | ❌ |
| **Token 產生器** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **健康檢查** | ✅ GitHub/OpenAI/CF | ❌ | ❌ | ❌ | ❌ |
| **iCloud 同步** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **離線可用** | ✅ | ✅ | ✅ | 部分 | ✅ |
| **原生 macOS** | ✅ SwiftUI | ❌ Electron | ❌ Electron | ✅ | — |
| **剪貼板保護** | ✅ 自動清空 | ✅ | ✅ | ❌ | ❌ |
| **導入 .env/CSV** | ✅ | ✅ | ✅ | ❌ | — |
| **Face ID** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **選單列快速複製** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **全域快捷鍵 ⌘⇧T** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Spotlight 搜尋** | ✅ ⌘K | ❌ | ❌ | ❌ | ❌ |

## 核心差異化

### 1. 為開發者而生
TokenVault 是唯一一個**從頭為開發者設計**的密鑰管理工具：
- 自動識別 GitHub/AWS/OpenAI/Cloudflare 等 10 種 Token 類型
- 21 種服務提供商自動檢測（OpenAI、Claude、Gemini、DeepSeek 等）
- 環境標記（開發/預發/正式）對應真實開發流程
- 內建 JWT 解碼器 — 不用另外開 jwt.io
- Token 產生器 — 一鍵產生安全密鑰
- Token 健康檢查 — 驗證 GitHub/OpenAI/Cloudflare 有效性

### 2. 個人專屬
私有專案，不對外發布、不授權他人使用。每個設計決定只服務我自己的工作流程。

### 3. 安全架構
AES-256-GCM 加密，主密鑰在 Secure Enclave，不上傳任何伺服器。

### 4. 原生 macOS 體驗
SwiftUI 原生構建，不是 Electron 殼。啟動快、記憶體省、動畫流暢。支援 macOS 26 Liquid Glass 設計語言。

### 5. 開發者工作流整合
- ⌘⇧T 全域快捷鍵：任何 App 中一鍵貼上最常用 Token
- ⌘K Spotlight 搜尋
- 選單列快速複製：無需打開主視窗
- 導入 .env / CSV：從現有專案一鍵遷移

## 目標用戶

- 全端/後端開發者（管理多個 API Key）
- DevOps/SRE（管理雲服務憑證）
- 自由職業者（管理客戶專案 Token）
- 小型團隊（需要簡單安全的密鑰共享）

## 發展路線

- [ ] iOS/iPadOS 版本
- [ ] 團隊共享（iCloud Shared Database）
- [ ] CLI 工具（終端機直接操作）
- [ ] Raycast 擴展
- [x] 安全稽核日誌
- [x] Token 健康檢查
