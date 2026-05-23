# Marble 專案踩雷手札 (Technical Pitfalls & Gotchas)

本文件記錄了開發過程中發現的所有技術陷阱，旨在防止後續開發者（不論人或 AI）重複掉入相同的坑洞。

## 1. 物理系統 (Godot Box2D)
> 這是本專案最危險的區域，任何改動前必須查閱。

- **[陷阱] 頂點排序錯誤**: 
    - **現象**: 執行時報錯或碰撞體消失。
    -  **原因**: Godot 的座標系中，頂點必須按 **逆時針 (Counter-Clockwise)** 排序。
    - **對策**: 使用 `physics-defense` 技能進行自動檢查，或手動確認 `CollisionPolygon2D` 頂點順序。
- **[陷阱] 頂點過量 (Vertex Overflow)**:
    - **現象**: 出現 `invalid_shape_handle` 錯誤。
    - **原因**: 為追求形狀完美而使用了超過 8 個頂點。
    - **對策**: 嚴格拆解複雜形狀為多個簡單凸多邊形 (Convex)。

## 2. UI 佈局與信號 (UI & Signals)
- **[陷阱] 信號參數不匹配**:
    - **現象**: 點擊介面沒反應，控制台報錯 `signal signature mismatch`。
    - **原因**: 修改了核心信號（如 `combat_updated`）的參數數量，但忘記更新 `Main.gd`。
    - **對策**: 修改 API 時強制執行 `handover-protocol` 檢查 `docs/API_SPEC.md`。

## 3. GDScript 資源管理
- **[陷阱] 型別陣列賦值失效**:
    - **現象**: 在 Inspector 中設定了屬性但運行時數值錯誤。
    - **原因**: 直接對 `Array[int]` 使用 `=` 賦值有時會失效。
    - **對策**: 使用 `assign()` 函式或確保型別嚴格對齊。

## 4. Godot 4 資源與快取管理 (Resource & Cache Management)
- **[陷阱] 外部改名/移動檔案導致 UID 快取不同步 (Godot 4 UID Desync)**:
    - **現象**: 執行或編輯時出現 `Cannot load resource`，或者程式碼仍然參照舊路徑，甚至造成編輯器與運行時崩潰。
    - **原因**: Godot 4 使用內部 UID 快取機制（存放在 `.godot/` 內）。如果直接在作業系統或 AI 編輯器中對 `.gd`、`.tscn` 或 `.tres` 進行改名或搬移，Godot 無法在關閉狀態下同步更新 UID，導致再次開啟時索引脫節。
    - **對策**: 在外部大量搬移/改名檔案後，**必須先關閉 Godot 編輯器，徹底手動刪除專案根目錄下的 `.godot/` 資料夾，再重新啟動 Godot**。Godot 會在啟動時自動、無痛地重新生成所有正確的 UID 與資源映射快取。

---
> [!TIP]
> 發現新地雷時，請務必立即更新此文件！
