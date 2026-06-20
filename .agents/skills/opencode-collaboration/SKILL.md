---
name: opencode-collaboration
description: OpenCode 協同作業與本地模型自動化。指導 AI 代理如何穩定地呼叫本地端的 OpenCode 進行多代理人協作開發。當使用者說「外包給 OpenCode」、「使用本地模型修改檔案」時觸發。
---

# Skill: OpenCode 協同作業與本地模型自動化 (OpenCode Collaboration & Automation)

| Metadata | Value |
| :--- | :--- |
| **Name** | OpenCode Collaboration |
| **Description** | 指導 AI 代理如何穩定地呼叫本地端的 OpenCode 進行多代理人（Multi-Agent）協作開發與檔案修改。 |
| **Category** | Tools / Multi-Agent |
| **Triggers** | 「外包給 OpenCode」、「使用本地模型修改檔案」、「呼叫 OpenCode 執行」。 |

## 1. 啟動前提 (Context Requirements)
在嘗試發送指令給 OpenCode 前，必須確認：
1. **環境狀態**：使用者不能在同一個終端機中開啟著互動介面 (TUI)，否則背景指令會因為資源或 Port 被佔用而卡死。
2. **設定檔格式**：確保 `opencode.json` 中的 provider 與 model 區塊皆包含 mandatory 的 `"name"` 屬性，否則會報錯 `Model is not valid`。

### 標準 opencode.json 範例 (Ollama)
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3.5:9b-16k",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3.5:9b-16k": {
          "name": "Qwen 3.5 9B (16k Context)"
        }
      }
    }
  }
}
```

## 2. 執行流程 (Execution Protocols)

### 方案 A：手動 TUI 模式 (適合人類操作)
- **指令**: `opencode` 或 `opencode --model ollama/<model-name>`
- **特性**: 具備快取與信任記憶功能。讀取檔案無需確認，寫入檔案時會要求 `y` 授權，但有機會在同對話中記憶權限。

### 方案 B：無頭自動化模式 (Headless Automation - AI 呼叫專用)
為了讓 OpenCode 能夠一路執行完畢而不被 `y/N` 的提示卡死，必須在 PowerShell 環境中使用陣列管線強制注入多個 `y`。

- **正確的自動化指令範例**:
  ```powershell
  & { "y"; "y"; "y"; "y"; "y" } | opencode --model ollama/qwen3.5:9b-16k run "請覆寫 d:\path\to\file.txt，內容為 XXX"
  ```
- **注意**：必須預留足夠的執行時間（至少 30-60 秒），以容忍本地 9B 以上模型的推論延遲。

## 3. 常見坑洞 (Gotchas & Pitfalls)

> [!WARNING]
> **絕對禁止在路徑中使用 `%USERPROFILE%` 變數！**
> 在 PowerShell 中呼叫 `opencode` 時，如果路徑字串中包含 `%USERPROFILE%`，它不會被解析為環境變數，而是會直接在專案根目錄建立一個名為 `%USERPROFILE%` 的實體資料夾！
> **解決方案**：請一律使用絕對路徑（如 `C:\Users\gacst\...`）或是正確的 PowerShell 變數 `$env:USERPROFILE`。

- **亂碼問題**: OpenCode 在自動建立檔案時可能會以 UTF-8 寫入，若使用 `Get-Content -Encoding Unicode` 讀取會出現亂碼（如 `裦鮄雥떖`）。建議讀取時使用 `-Encoding UTF8`。
- **無反應/卡死**: 如果指令持續 `RUNNING` 且無日誌輸出，極大概率是 TUI 與背景發生衝突，請提醒使用者關閉前台的 OpenCode。
- **PATH 環境變數未載入**: 全域安裝 (`npm install -g opencode-ai`) 後若出現「找不到 opencode 指令」，通常是因為 `AppData\Roaming\npm` 尚未套用至當前終端機的 PATH。**解法**：重新啟動終端機，或直接使用絕對路徑執行 `C:\Users\<使用者>\AppData\Roaming\npm\opencode.cmd`。
