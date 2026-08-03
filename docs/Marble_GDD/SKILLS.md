# 技能系統與效果說明 (SKILLS.md)

本文件詳細記錄了 Marble Table 目前已實作的所有卡牌與技能效果（實作於 `gameplay/combat/skills/`）。

---

## 目前已實作的技能效果

### 1. 普通攻擊 (SkillDamage)
- **實作檔案**：[SkillDamage.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/combat/skills/SkillDamage.gd)
- **實際作用**：對當前活躍敵人造成 `技能數值 * 全域傷害倍率` 的傷害。造成傷害後，全域傷害倍率會重置為 1。

### 2. 治癒 (SkillHeal)
- **實作檔案**：[SkillHeal.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/combat/skills/SkillHeal.gd)
- **實際作用**：回復我方（老奶奶）生命值，回復量為 `技能數值`，最高不超過最大生命值限制。

### 3. 蓄力/傷害加成 (SkillDamageBuff)
- **實作檔案**：[SkillDamageBuff.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/combat/skills/SkillDamageBuff.gd)
- **實際作用**：將全域傷害倍率（`next_damage_multiplier`）設定為 2。在此效果中，傳入的技能數值無實際用途（固定為 2 倍）。

### 4. 冰凍/封鎖道具 (SkillDelayCD)
- **實作檔案**：[SkillDelayCD.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/combat/skills/SkillDelayCD.gd)
- **實際作用**：對當前選中的敵人道具卡施加冰凍狀態。技能數值代表冰凍的回合數（`lock_turns` 增加該數值）。在冰凍期間，該道具卡 CD 不會減少且無法發動攻擊。

### 5. 中毒 (SkillPoison)
- **實作檔案**：[SkillPoison.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/combat/skills/SkillPoison.gd)
- **實際作用**：使目標進入中毒狀態，固定持續 3 回合，每回合扣除該技能數值的血量。
  - **發動當回合**：施加中毒狀態，當回合先不扣血（對方的中毒剩餘回合在當回合結束時顯示為 3）。
  - **後續回合**：從下一回合開始，於回合開頭結算中毒傷害並扣血，中毒剩餘回合數減 1，直至歸零。
  - **雙向適用**：我方（如「臭豆腐」技能 B）與敵方（如「衛生紙」道具）均可觸發此中毒狀態。
