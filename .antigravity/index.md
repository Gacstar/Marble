# 專案技能索引庫 (Antigravity Skills Index)

本專案採用結構化的「上下文工程」機制。當執行以下情境時，請務必加載對應的技能模組。

## 技能觸發清單 (Trigger Matrix)

| 意圖 / 情境 (Trigger Context) | 對應技能模組 (Assigned Skill) | 核心目標 (Core Objective) |
| :--- | :--- | :--- |
| **下班、交接、同步、維護文檔** | `[Handover Protocol](skills/handover-protocol/SKILL.md)` | 確保知識持續化，更新 /docs 資料夾。 |
| **新助手進入、了解專案、執行規範** | `[Onboarding Mastery](skills/onboarding-mastery/SKILL.md)` | 快速對接專案大腦，確保 SOP 執行。 |
| **彈珠台、物理碰撞、Box2D、頂點排序** | `[Physics Defense](skills/physics-defense/SKILL.md)` | 遵循 Godot 物理穩健規範，避免閃退。 |
| **開始新功能、需求不明確** | `[Spec-Driven Development](skills/core/spec-driven-development/SKILL.md)` | 先寫規格再寫程式，避免無謂重工。 |
| **大型任務、需要拆解** | `[Planning & Breakdown](skills/core/planning-and-task-breakdown/SKILL.md)` | 將大任務切成垂直切片，有序實作。 |
| **實作功能、撰寫程式碼** | `[Incremental Implementation](skills/core/incremental-implementation/SKILL.md)` | 遵循範疇紀律，一次只做一個小切片。 |
| **提交變更、Git 存檔** | `[Git Workflow](skills/core/git-workflow-and-versioning/SKILL.md)` | 確保原子提交與高品質的歷史紀錄。 |
| **做架構決策、寫文件** | `[Documentation & ADRs](skills/core/documentation-and-adrs/SKILL.md)` | 記錄決策的「為什麼」，維護專案大腦。 |
| **優化、重構、測試、發布** | `skills/core/` 目錄下的其餘 15 個技能 | 涵蓋 CI/CD、效能優化、測試驅動等通用工程。 |

## 外部文檔強連結 (Mandatory Technical Context)
在執行任何技能前，AI **必須**先檢查以下技術真相來源：
- **API 規格書**: `[docs/API_SPEC.md](file:///d:/GodotProject/Marble/docs/API_SPEC.md)`
- **架構設計**: `[docs/ARCHITECTURE.md](file:///d:/GodotProject/Marble/docs/ARCHITECTURE.md)`
- **新人導航**: `[MASTER_ONBOARDING.md](file:///d:/GodotProject/Marble/MASTER_ONBOARDING.md)`

---
> [!NOTE]
> 每個技能模組內部都包含更詳細的 `Gotchas` 與 `Execution Protocols`。
