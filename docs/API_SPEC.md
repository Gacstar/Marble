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

## MarbleTable3D.gd (3D 彈珠台管理器)
### 信號 (Signals)
- `slot_hit(index: int)`: 當彈珠進入第 index 個 3D 得分區時發出。

### 函式 (Methods)
- `clear_slot_marbles(slot_idx: int)`: [TODO] 清除 3D 空間中特定槽位的累積效果。
- `update_slot_indicators(card: Resource)`: [TODO] 根據卡牌技能，動態變更 3D ScoreZone 的發光顏色。
- `spawn_ball(force: float)`: 在拉桿位置生成一個具備衝量的 3D 彈珠。

## Plunger3D.gd (3D 拉桿)
### 信號 (Signals)
- `launched(force: float)`: 當玩家放開滑鼠時發出，帶出力道數值。

### 互動邏輯 (Interaction)
- **拖拽偵測**: 透過 `_on_input_event` 偵測滑鼠點擊，並在 `_process` 中計算垂直拖拽位移。
- **回彈動畫**: 使用 `Tween` 實作力道釋放後的彈性復位。

## ScoreZone3D.gd (3D 得分偵測區)
### 信號 (Signals)
- `ball_entered(idx: int)`: 偵測到 3D 彈珠進入，回傳該洞口的索引。

### 視覺狀態
- **指示燈**: 包含一個半透明的 `MeshInstance3D`，用於顯示當前技能對應的洞口。
