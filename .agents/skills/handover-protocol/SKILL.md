---
name: handover-protocol
description: 交接協定與知識持久化。確保 AI 開發過程中的短期負載轉化為專案的長期技術資產。當使用者說「寫交接文件」、「下班」、「對接」、「同步資料」時觸發。
---

# Skill: 交接協定與知識持久化 (Handover & Knowledge Persistence)

| Metadata | Value |
| :--- | :--- |
| **Name** | Handover Protocol |
| **Description** | 確保 AI 開發過程中的短期負載轉化為專案的長期技術資產，並動態維護與「自我演化」專案標籤知識圖譜。 |
| **Category** | Maintenance / Process |
| **Triggers** | 「寫交接文件」、「下班」、「對接」、「同步資料」。 |

## 1. 當前內容規範 (Triggers)
當偵測到以下意圖時，**必須**啟動此協定：
- 準備結束當前會話 (End of Session)。
- 使用者明確要求紀錄今天的開發成果。
- 專案發生了重大的 API、架構、或效能配置變動。

## 2. 強制性上下文連結 (Context Requirements)
在執行此技能前，必須確保已讀取：
- **API 規格**: `[docs/API_SPEC.md](../../docs/API_SPEC.md)`
- **架構定義**: `[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md)`
- **標籤字典**: `[docs/TAG_INDEX.md](../../docs/TAG_INDEX.md)`

## 3. 執行流程 (Execution Protocols)
1.  **掃描變更**: 比對今日實作的程式碼與現有的 `API_SPEC.md` 是否一致。
2.  **更新 Source of Truth**:
    - **【三方一致性檢驗 (Triple Alignment Rule)】**：必須確認「設計文件 (GDD)」、「API 規格書 (API_SPEC.md)」與「實作代碼 (Code)」三者關於數值、機制和簽章的描述完全一致。若在實作中調整了參數或規則（例如將 5 珠改為 3 珠），必須在交接流程中一併將設計文件與規格書同步更新，杜絕文件脫節。
    - 如果新增了信號或方法，立即更新 `@/docs/API_SPEC.md`。
    - 如果調整了 UI 佈局，立即更新 `@/docs/ARCHITECTURE.md`。
    - **【大腦演化 ➔ Bug強制回饋】**：若本次開發遇到重大技術障礙或踩雷（如型別陣列失效、UID快取脫節、Box2D頂點問題），**必須強制將避坑對策寫入 `@/docs/PITFALLS.md`**，防止未來的 AI 重蹈覆轍，無謂消耗偵錯 Token。
3.  **生成日誌與標籤維護**: 
    - 在 `@/docs/logs/` 記錄具體的 commit 級別變更摘要。
    - **標籤規範**：所有新增、修改的分子化技術文檔或交接日誌，必須在頂部放置標準 YAML Frontmatter，以陣列格式宣告層級標籤（例如 `tags: [handover-notes, module/physics-box2d]`）。
    - **標籤追加靈活性**：AI 代理人在撰寫交接日誌時，**被強烈鼓勵**依據今日的開發成果，在 `docs/TAG_INDEX.md` 的基礎上自訂並追加任何合理的標籤（例如 `module/physics-box2d/polygon-sort-bug`），維持標籤大腦的活性。
4.  **【大腦演化 ➔ 元評估交接 (Meta-Evaluation Handover)】**：
    - AI 在寫完交接報告或日誌後，必須進行自我審查：「*我寫的這份文件，是否能讓下一輪開啟新對話、零記憶的我，在 **30 秒內**完全接軌？是否有冗餘廢話？*」
    - 若文字流於囉唆，**強制精簡 30%**，以極致的高資訊密度節省未來的 Token。
5.  **【大腦演化 ➔ 細胞分裂機制 (Atomic Splitting)】**：
    - 檢查 `/docs` 下的核心文件（如 `API_SPEC.md` 或 `ARCHITECTURE.md`）。若其長度**超過 200 行**，AI 必須在交接時主動執行「細胞分裂」——將其拆分為更小的子模組文件，並在 `MASTER_ONBOARDING.md` 中更新路由，實現 Token 的極致節約。
6.  **【大腦演化 ➔ 技能自我重構 (Skill Refactoring)】**：
    - AI 應評估現行工作流（如 `.agents/skills/` 下的各個技能定義）。若技能中的 SOP 或 gotchas 出現不合時宜、或是太冗長的部分，AI 應主動在交接時修改對應的 `SKILL.md`，使思考指示模板保持最精簡、最有效率的狀態。

## 4. 常見坑洞 (Gotchas)
- **核心指南**: 詳見 `[docs/PITFALLS.md](../../docs/PITFALLS.md#2-ui-佈局與信號)`。
- **規範**: 必須使用相對路徑連結，且同步更新 API_SPEC 以免信號報錯。
- **層級標籤語法**：新自訂的標籤建議使用 `大類/子類`（如 `module/card-hand/cd-freeze`）的結構，以便於 Obsidian 等工具自動生成精美層級的標籤樹形導航。

## 5. 交接日誌標準模板 (Handover Log Template)
每次撰寫交接日誌時，請遵循此高密度格式，並存檔於 `docs/logs/H_YYYYMMDD.md`：
```markdown
---
tags: [handover-notes, module/your-module]
---
# 交接日誌 (YYYY/MM/DD)

## 📌 Meta 極速交接 (30秒接軌摘要)
- **核心狀態**：[一句話說明目前的開發進度/卡關點]
- **下一代 AI 任務**：[明確的下一步行動指令]

## 🛠️ 變更紀錄與連結
- [x] [修改/新增的項目說明] ➔ 實作檔案：[Filename](file:///path/to/file)
- [x] 規格與文件更新：已對齊 [API_SPEC.md](file:///path/to/docs/API_SPEC.md) 與 [GDD](file:///path/to/docs/Marble_GDD/MOC_GDD.md)

## ⚠️ 踩雷與防禦 (Pitfalls)
- **問題**：[遇到的問題或 Bug 描述]
- **對策**：[如何解決，以及如何避免重複踩坑]

## 📅 下一步規劃 (TODO)
- [ ] [待辦事項]
```
