# Skill: 交接協定與知識持久化 (Handover & Knowledge Persistence)

| Metadata | Value |
| :--- | :--- |
| **Name** | Handover Protocol |
| **Description** | 確保 AI 開發過程中的短期負載轉化為專案的長期技術資產。 |
| **Category** | Maintenance / Process |
| **Triggers** | 「寫交接文件」、「下班」、「對接」、「同步資料」。 |

## 1. 當前內容規範 (Triggers)
當偵測到以下意圖時，**必須**啟動此協定：
- 準備結束當前會話 (End of Session)。
- 使用者明確要求紀錄今天的開發成果。
- 專案發生了重大的 API 或架構變動。

## 2. 強制性上下文連結 (Context Requirements)
在執行此技能前，必須確保已讀取：
- **API 規格**: `[docs/API_SPEC.md](../../docs/API_SPEC.md)`
- **架構定義**: `[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md)`

## 3. 執行流程 (Execution Protocols)
1.  **掃描變更**: 比對今日實作的程式碼與現有的 `API_SPEC.md` 是否一致。
2.  **更新 Source of Truth**:
    - 如果新增了信號或方法，立即更新 `@/docs/API_SPEC.md`。
    - 如果調整了 UI 佈局，立即更新 `@/docs/ARCHITECTURE.md`。
3.  **生成日誌**: 在 `@/docs/logs/` (若存在) 記錄具體的 commit 級別變更摘要。

## 4. 常見坑洞 (Gotchas)
- **核心指南**: 詳見 `[docs/PITFALLS.md](../../docs/PITFALLS.md#2-ui-佈局與信號)`。
- **規範**: 必須使用相對路徑連結，且同步更新 API_SPEC 以免信號報錯。
