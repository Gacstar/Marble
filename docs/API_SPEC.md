# 技術參考手冊 (API_SPEC.md)

## CombatManager.gd (核心戰鬥與卡牌管理)
### 屬性 (Properties)
- `player_hp / player_max_hp`: 玩家生命值狀態。
- `monsters`: Array[Dictionary]，當前場上怪物的資料列表。
    - 內容物格式: `{ "name", "hp", "max_hp", "cd", "cd_default", "damage_range" }`
- `target_monster_idx`: 當前選中的目標怪物索引。
- `next_damage_multiplier`: 全域傷害倍率 (預設為 1，發動龍卡蓄力後變為 2)。

### 信號 (Signals)
- `combat_updated(p_hp, p_max, m_data, t_idx, mult)`: 同步全場戰鬥數據。
- `monster_attacked(m_name, dmg)`: 怪物發動攻擊。
- `monster_defeated(m_name)`: 怪物死亡。
- `monster_selection_changed(idx)`: 目標切換。

### 函式 (Methods)
- `select_monster(idx: int)`: 手動切換攻擊對象。
- `trigger_skill_from_slot(slot_index: int)`: 觸發卡牌技能，計算傷害(含倍率/CD延緩/補血)並洗牌。

## CardResource.gd (卡牌資料資源)
### 屬性 (Properties)
- `skill_b_is_heal`: 是否為生命恢復技能。
- `skill_b_is_delay_cd`: 是否為延緩敵方 CD 技能 (Owl)。
- `skill_b_is_damage_buff`: 是否為下回合雙倍傷害技能 (Dragon)。

## MarbleTable.gd
### 信號 (Signals)
- `slot_hit(index: int)`: 當彈珠進入第 index 個槽位時發出。

### 函式 (Methods)
- `update_slot_indicators(slot_map: Array[int])`: 同步槽位的指示燈顏色。

## CombatUI.gd
### 函式 (Methods)
- `update_ui(p_hp, p_max, m_data, t_idx, mult)`: 驅動全場 UI 刷新，含怪獸列表動態生成與卡牌倍率文字變色。
- `show_damage_effect(target_name, amount)`: 顯示傷害日誌。

## ScoreZone.gd
### 函式 (Methods)
- `set_indicator_color(color: Color)`: 根據卡牌技能類型直接變更洞口指示燈顏色。
