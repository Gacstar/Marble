# 系統架構說明 (ARCHITECTURE.md)

本文件描述 Marble Table 的核心設計決策與物件連結方式，供 AI 快速理解「房子是怎麼蓋的」。

## 1. 核心技術棧 (3D 轉型)
- **渲染模式:** 混合 2D/3D。UI 保持 2D，遊戲桌面採用 **Native 3D**。
- **物理引擎:** `Godot Physics 3D`。
- **視覺風格:** 3D Toon Shader (卡通渲染)。使用 `next_pass` 頂點擴張法實作像素邊線。
- **解析度/比例:** 3D 空間與 2D 座標採 `1:100` 換算 (PIXELS_PER_UNIT = 100)。

## 2. 物件組成 (Composition)
專案已從純 2D 遷移至「視口嵌入式 3D」架構：

- **`MarblePerspectiveView` (視窗容器):** 使用 `SubViewportContainer` 承載 3D 世界。
- **`SubViewport`:** 開啟 `physics_object_picking` 以支援滑鼠與 3D 物件互動。
- **`MarbleTable3D` (3D 實體):** 取代舊版 2D Table。包含實體化的牆壁、釘子、拉桿與得分區。
- **`CombatManager` (邏輯核心):** 保持不變，接收來自 3D 得分區的 `slot_hit` 信號。
- **`Plunger3D`:** 3D 物理拉桿，支援滑鼠拖拽與彈性回彈。
- **`ScoreZone3D`:** 3D 得分區偵測，進入後觸發技能並銷毀彈珠。

## 3. 2D/3D 橋接機制 (The Bridge)
- **輸入橋接:** `ViewportInputHandler.gd` 負責將 2D 螢幕座標透過 Raycast 轉換為 3D 互動，或透過 `physics_object_picking` 直接與 3D 碰撞體互動。
- **信號橋接:** `Main.gd` 持有 `MarbleTable3D` 的引用，維持舊有的信號連接邏輯（如 `slot_hit`），確保 2D UI 與 3D 物理同步。

## 4. 卡通美學實作 (Toon Aesthetic)
- **AdvancedToonShader:** 
    - **Pass 1:** 自定義 `Light` 函數實作階梯光影 (Toon Shading)。
    - **Pass 2 (Outline):** 使用 `next_pass` 配合 `cull_front` 實作可調寬度的物件邊線。

## 5. 物理動態調整與穩定性
- **邊界保護:** 設有隱形的「正面玻璃 (Front Glass)」防止彈珠在碰撞中彈出 Z 軸平面。
- **軸向鎖定:** 彈珠 (`RigidBody3D`) 鎖定 Z 軸線性位移，確保其保持在 XY 平面運動。
