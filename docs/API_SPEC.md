---
tags: [type/api-spec, module/combat-system, module/card-hand, module/physics-box2d, module/viewport-input]
---
# 技術參考手冊 (API_SPEC.md)

## CombatManager.gd (核心戰鬥與卡牌管理)
### 屬性 (Properties)
- `player_hp / player_max_hp`: 玩家生命值狀態。
- `active_enemy`: Dictionary，當前活躍敵人的資料，包含 `{ "name", "icon", "hp", "max_hp" }`。
- `item_cards`: Array[ItemCardResource]，配置在奧客身上的道具卡列表，具有獨立 CD 與被封鎖的 `lock_turns` 回合數。
- `target_item_idx`: 當前選中的目標道具卡索引。
- `next_damage_multiplier`: 全域傷害倍率 (預設為 1，發動龍卡蓄力後變為 2)。

### 信號 (Signals)
- `combat_updated(player_hp, player_max_hp, active_enemy, item_cards, target_item_idx, next_damage_multiplier)`: 同步對稱戰鬥數據。
- `enemy_attacked(enemy_name, damage)`: 奧客道具卡發動攻擊。
- `enemy_defeated(enemy_name)`: 奧客被擊敗死亡。
- `enemy_selection_changed(idx)`: 目標道具卡切換。

### 函式 (Methods)
- `select_enemy(idx: int)`: 手動選中目標道具卡，作為封鎖/冰凍技能的目標。
- `trigger_skill_from_slot(slot_index: int) -> Dictionary`: 觸發食物卡技能，計算傷害並更新狀態，返回內含我方行動、敵方反擊、新舊生命狀態轉變之「戰鬥收據（Receipt）」。

## SkillDirector.gd (技能演出與時序管理器)
### 屬性 (Properties)
- `projectile_scene`: PackedScene，投擲物預製場景。
- `damage_popup_scene`: PackedScene，飄字預製場景。

### 函式 (Methods)
- `play_card_zoom_animation(card_idx: int) -> void`: 播放指定索引之手牌卡片縮放兩下（放大至 1.22 倍後縮回）的發動動畫。
- `play_player_attack(card: CardResource, damage: int, from_enemy_hp: int, to_enemy_hp: int, max_enemy_hp: int) -> void`: 播放老奶奶向敵人投擲食物球、敵人抖動閃紅、受擊飄字與血條平滑扣減之非同步動畫。
- `play_enemy_attack(item_name: String, damage: int, from_player_hp: int, to_player_hp: int, max_player_hp: int) -> void`: 播放敵人朝老奶奶發射球體、老奶奶抖動閃紅、扣血飄字與血條平滑扣減之非同步動畫。
- `play_heal_effect(amount: int, from_player_hp: int, to_player_hp: int, max_player_hp: int) -> void`: 播放老奶奶治癒綠光、綠色補血飄字與血條平滑回彈之非同步動畫。


## CardResource.gd (卡牌資料資源)
### 屬性 (Properties)
- `skill_a_effect / skill_b_effect`: BaseSkillEffect，技能 A 與 B 的自訂技能資源實體。
- `skill_a_color_a / skill_a_color_b`: Color，技能 A 在 A 插槽與 B 插槽時的對應渲染顏色。
- `skill_b_color_a / skill_b_color_b`: Color，技能 B 在 A 插槽與 B 插槽時的對應渲染顏色。

### 函式 (Methods)
- `get_skill_color(slot_idx: int) -> Color`: 根據插槽索引（0-7）查出該位置應顯示的對應技能 A/B 的色碼。
- `get_skill_effect(slot_idx: int) -> BaseSkillEffect`: 根據插槽索引（0-7）查出該位置應執行的對應技能 Resource 實體。

## BaseSkillEffect.gd (自訂技能資源基底)
### 函式 (Methods)
- `apply_effect(combat_manager: Node, value: int) -> void`: 虛擬函式，衍生技能在此實作具體戰鬥效果邏輯。


## MarbleTable.gd (2D 彈珠台管理器)
### 信號 (Signals)
- `slot_hit(index: int)`: 當彈珠進入第 index 個得分區時發出。

### 函式 (Methods)
- `clear_slot_marbles(slot_idx: int)`: 清除特定槽位的累積物理彈珠效果。
- `update_slot_indicators(card: CardResource)`: 根據卡牌技能，動態變更 ScoreZone 的發光顏色（已解決 Viewport 裁切 Bug，燈號已成功上移）。
- `spawn_ball()`: 在拉桿位置生成一個物理彈珠。

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

## EnemyDataLoader.gd (敵人與道具卡資料載入器)
### 靜態函式 (Static Methods)
- `load_enemy(target_id: int) -> Dictionary`: 讀取 `enemies.csv`、`enemy_skills.csv` 與 `item_cards.csv`，將指定 ID 的敵人資料加載並組裝成一個 Dictionary，包含 `{ "display_name", "max_hp", "icon", "item_cards": Array[ItemCardResource] }`。
