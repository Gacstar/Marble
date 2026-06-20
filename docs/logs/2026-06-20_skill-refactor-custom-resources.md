---
tags: [type/handover-notes, module/combat-system, module/card-hand]
---
# 技能系統重構日誌 (自訂資源 B 架構) - 2026-06-20

## 1. 變更背景與成就
原本在 `CombatManager.gd` 中以 `if-elif` 寫死技能類型的做法已在今日被徹底拋棄。為了解決技能未來擴展到數百招時的維護性危機，我們採用了 **自訂資源 (Strategy Pattern/策略模式)** 將技能邏輯與戰鬥控制中心解耦，並完成了技能 A/B 槽位顏色讀表的拆分。

## 2. 新架構運作原理 (30秒接軌)
- **技能配置表 (skills.csv)**：將原 `color` 欄位拆分為 `color_a` 與 `color_b`，用以設定技能擺在卡牌 A 或 B 插槽時的顏色。移除爆擊，ID 還原為：1-攻擊、2-回復、3-延緩、4-蓄力。
- **技能資源腳本 (`res://gameplay/combat/skills/`)**：
  - `BaseSkillEffect.gd` 定義了 `apply_effect(combat_manager, value)`。
  - 各個衍生類別實體（`SkillDamage`, `SkillHeal`, `SkillDelayCD`, `SkillDamageBuff`）各自實作內部效果。
- **自動配對流程**：
  1. `CardDataLoader.gd` 讀取技能表，根據技能類型字串實例化對應的腳本物件 (`.new()`)，綁定到 `CardResource`。
  2. 當彈珠擊中桌台槽位時，`CombatManager.gd` 只要呼叫：
     `card.get_skill_effect(slot_index).apply_effect(self, value)`
     即自動執行正確的技能邏輯。
  3. UI 燈號與桌台燈號統一呼叫 `card.get_skill_color(slot_idx)`，能完美展現 A 與 B 雙色配置。

## 3. 下一班 AI 接班提示 (Next Tasks & Pitfalls)
- **敵方技能共用**：將來若要幫奧客道具卡加入更多獨特技能，可以直接利用 `BaseSkillEffect` 衍生新的腳本，傳入 `CombatManager` 做邏輯運算。
- **不要直接修改 CombatManager 來加技能**：如需新增任何招式，請直接在 `res://gameplay/combat/skills/` 建立新的 `BaseSkillEffect` 腳本，並在 `CardDataLoader._create_skill_effect()` 加入對應配對行即可。
