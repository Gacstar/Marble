---
tags: [type/architecture, module/shader-perspective, module/combat-system, module/viewport-input]
---
# 系統架構說明 (ARCHITECTURE.md)

本文件描述 Marble Table 的核心設計決策與物件連結方式，供 AI 快速理解「房子是怎麼蓋的」。

## 1. 核心技術棧 (著色器 2D 形變透視)
- **渲染模式:** 混合 2D/透視投影。UI 保持純 2D 渲染，遊戲桌面採用 **SubViewport 2D 渲染 + Shader 形變透視**。
- **物理引擎:** `Godot Box2D 2D 物理`，確保彈珠運動絕對扁平且穩定。
- **視覺風格:** 透過 `perspective_warp.gdshader` 進行 3D 卡通效果的形變拉伸，讓 2D 平面在 2D TextureRect 上呈現出精美的 3D 透視斜面感。
- **解析度/比例:** 桌面的解析度被嚴格封裝在 `457 x 854` 像素的 `TableViewport` 中，以保證座標系完全一致。

## 2. 物件組成 (Composition)
專案採用「視口著色器變形」與「對稱卡牌」雙重核心架構：

- **`MarbleShaderPerspectiveView` (透視組件):** 
    - 使用 `SubViewport` 承載與封裝 `MarbleTable`。
    - 透過底層的 `TableScreen` (TextureRect) 讀取視口貼圖，並加載四角點形變 Shader 將畫面拉伸投影。
- **`ViewportInputHandler` / `MarbleShaderPerspectiveView.gd` (輸入投影橋接):**
    - 負責精確逆算滑鼠在形變畫面的 UV，並將其轉回 `0~1` 內部座標，進而精確推算傳遞給 SubViewport 中的彈珠台。
- **`CombatUI` (左右對稱介面):**
    - **左側 我方老奶奶 (`PlayerSide`)**：渲染大頭像、總血條與縱向手牌（`CardHand`）。
    - **右側 奧客敵方 (`EnemySide`)**：幾何鏡像渲染大頭像、總血條與縱向道具卡（`ItemCardContainer`）。
- **`CombatManager` (邏輯核心):** 管理雙向 HP 狀態與卡牌 CD/凍結。接收來自彈珠台的 `slot_hit` 得分信號，進行即時戰鬥演算，並產生包含完整生命與傷害轉變資訊的戰鬥收據。
- **`SkillDirector` (演出與時序導演):** 掛載於 `CombatUI` 下的非同步動畫管理模組。透過協程（`await`）調度投擲物飛行、角色受擊抖動與閃紅、浮動數字飄字，以及血條平滑的 Tween 緩動，實現狀態結算與時序表演的優雅解耦。

## 3. 2D 物理動態與槽位發光
- **槽位指示發光**: 在 `ScoreZone.tscn` 槽位底部配置了 `Indicator`，其 Y 座標已從 Y=864 上移至 **Y=834**，以確保不會被 `SubViewport` 高度限制 (854px) 裁切。
- **燈號顏色更新**: `Main.gd` 接取選牌變更後，會通過 `MarbleTable.update_slot_indicators(card)` 來動態調整這 8 個發光槽的顏色。

## 4. 開發輔助工具 (Development Tools)
- **卡牌與技能編輯器 (Card & Skill Editor):**
    - **資料定位**: 遊戲卡牌、技能、敵人及敵方道具的 CSV 設定表已統一集中於 [data/](file:///d:/GodotProject/Marble/MarbleGame/data/) 資料夾下，並分別由 [CardDataLoader.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/cards/food/CardDataLoader.gd) 與 [EnemyDataLoader.gd](file:///d:/GodotProject/Marble/MarbleGame/gameplay/combat/EnemyDataLoader.gd) 靜態載入。
    - **本地網頁工具**: 位於 [card_editor.html](file:///d:/GodotProject/Marble/tools/card_editor.html)，整合了卡牌即時預覽、中文技能下拉選單、PS 拾色器連動與 8-Slots 點亮編輯等進階 UI。
    - **快捷背景啟動與自我銷毀**:
        - 使用者在 Windows 檔案總管中雙擊根目錄的 [啟動卡牌編輯器.bat](file:///d:/GodotProject/Marble/啟動卡牌編輯器.bat) 便可在背景無感啟動一個 Python API 伺服器，自動彈出網頁，且完全不佔用 IDE 的 AI 代理人通道。
        - **自銷毀機制**: 網頁在關閉（分頁關閉、視窗關閉或重載）時會自動向後端發送 `/api/shutdown` 請求，使背景 Python 伺服器在 0.5 秒內自我退出，不佔用任何系統與背景資源。

