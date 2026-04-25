# 系統架構說明 (ARCHITECTURE.md)

本文件描述 Marble Table 的核心設計決策與物件連結方式，供 AI 快速理解「房子是怎麼蓋的」。

## 1. 核心技術棧
- **物理引擎:** `Box2D` (專為解決高速穿隧道問題導入)。
- **開發頻率:** `60Hz`。
- **CCD (連續碰撞偵測):** 全面開啟。

## 2. 物件組成 (Composition)
專案不使用動態生成，所有物件皆為編輯器手動擺放的 `PackedScene`。

- **`MarbleTable` (場景核心):** 負責物理物件容器（Pegs, Slots）與彈珠發射流程中的槽位擊中偵測。
- **`CombatManager` (邏輯核心):** 負責戰鬥數值計算、牌堆循環 (Hand/Deck) 與怪物 CD 管理。
- **`CombatUI` (顯示核心):** 負責玩家/怪物血條、卡牌圖選取與傷害視覺整合。
- **`ScoreZone` (槽位):** 使用 `Area2D`。打中後發出 `slot_hit` 信號帶出索引，交由 `Main.gd` 轉交 `CombatManager` 結算。

## 3. 戰鬥與卡牌循環 (Combat & Deck System)
- **佈局配置:** 
    - **手牌區域:** 位於畫面左側，採用 `VBoxContainer` 垂直堆疊。
    - **卡牌型態:** 橫向長條狀 (Horizontal Bar)，支援兩排技能標籤顯示。
- **觸發機制:** 每當彈珠掉入槽位 $i$，`CombatManager` 讀取當前卡牌的 `slot_map[i]` 來決定觸發技能 A 或 B。
- **技能類型 (五色標示):**
    - **灰色 (Grey):** 一般傷害 A。
    - **黃色 (Yellow):** 強力傷害 B。
    - **綠色 (Green):** 回復 HP (Wolf 專屬)。
    - **藍色 (Blue):** 延緩敵方 CD (Owl 專屬)。
    - **紫色 (Purple):** 蓄力加倍 Buff (Dragon 專屬)。
- **疊加與大招 (Ultimate):** 同一軌道進入第 5 顆彈珠時，效果翻倍並觸發「軌道清理」。
- **循環模式:** 卡牌觸發後進入牌庫底，並從牌庫頂補充。

## 4. 多怪物與目標選取 (Multi-Monster & Targeting)
- **實作方式:** `CombatManager` 使用陣列管理多個怪物物件，且擁有一個全域的 `target_idx`。
- **選取機制:** 玩家可透過點擊怪物組件切換目標，選中者顯示**紅色選取框**。
- **死亡處理:** 血量歸 0 的怪物會停止冷卻計時並覆蓋灰色遮罩，攻擊邏輯自動跳過死亡對象。
- **對象判定:** 
    - 傷害性技能對準 `target_idx` 發動。
    - 回復性技能固定作用於玩家。

## 5. 物理動態調整與穩定性 (Physics Stability)
- **Box2D 限制:** 必須使用凸多邊形 (Convex)，頂點數上限為 8。
- **繞線方向:** 所有 `CollisionPolygon2D` 強制使用逆時針 (CCW) 排序。
- **轉角優化:** 複雜弧形改用多個簡單三角形/四邊形拼接，避免 `invalid_shape_handle` 報錯。
