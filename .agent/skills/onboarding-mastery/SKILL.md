# Skill: 專案導航與新人引導 (Onboarding Mastery)

| Metadata | Value |
| :--- | :--- |
| **Name** | Onboarding Mastery |
| **Description** | 確保新助手能快速掌握專案全貌並遵循現有規範。 |
| **Category** | Onboarding / Governance |
| **Triggers** | 「剛接手專案」、「讀取導航」、「了解開發規範」。 |

## 1. 觸發情境 (Triggers)
- 當 AI 第一次載入此專案時。
- 使用者要求解釋專案結構。
- 當發生跨會話（Cross-session）交接時。

## 2. 核心路徑 (Mandatory Flow)
AI 必須遵循以下順序載入知識：
1.  **第一站**: `@/MASTER_ONBOARDING.md` (了解專案大腦 MOC)。
2.  **第二站**: `@/.antigravity/index.md` (掃描可用技能矩陣)。
3.  **第三站**: `@/docs/ARCHITECTURE.md` 與 `API_SPEC.md`。

## 3. 執行協定 (Instructions)
- 在執行任何修改前，必須向使用者確認當前的任務目標是否與 `docs/TODO.md` 一致。
- 嚴格遵守「更新文檔優先於寫 Code」的原則。

## 4. 故障預防 (Gotchas)
- **避免資訊碎片化**: 不要建立新的冗餘文檔，應優先更新現有的 MOC。
