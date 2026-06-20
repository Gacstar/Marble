# 專案標籤字典 (TAG_INDEX.md)

本文件定義了 Marble Table 專案所採用的標準標籤體系（Tag Taxonomy），用於協助 AI 與人類開發者在 Obsidian 或大腦日誌中快速檢索與過濾資訊。

## 1. 類型標籤 (Type Tags)
定義檔案的文檔類型與結構層級：
- `type/moc`：地圖索引目錄（如 MASTER_ONBOARDING.md, MOC_GDD.md）
- `type/adr`：系統架構決策紀錄（如 ADR-001.md 等）
- `type/api-spec`：技術字典、介面與信號規格書
- `type/architecture`：系統架構、物件組成與渲染原理說明書
- `type/todo`：專案進度與待辦清單
- `type/handover-notes`：交接日誌與歷史日誌檔案

## 2. 模組標籤 (Module Tags)
標示檔案涉及的遊戲核心技術與功能板塊：
- `module/physics-box2d`：Godot Box2D 2D 物理碰撞、剛體、材質與多邊形頂點排序
- `module/shader-perspective`：SubViewport 渲染與透視拉伸著色器 (Perspective Warp Shader)
- `module/combat-system`：雙向 HP 管理、戰鬥邏輯、CombatManager 與計分槽得分判定
- `module/card-hand`：手牌/道具卡 CD 計算、滑動凍結與卡牌行為機制
- `module/viewport-input`：形變畫面的滑鼠點擊 UV 投影逆算處理 (ViewportInputHandler)

## 3. 狀態與輔助標籤 (Status Tags)
標示檔案記錄的特別工程狀態：
- `status/perf-bottleneck`：涉及效能瓶頸、效能優化與硬體環境（如 RTX 3060 基準效能）的技術文件
- `status/bug-fixed`：記錄歷史避雷、採坑記錄與解決指引（如 PITFALLS.md）
- `status/legacy-ref`：舊版系統設計、歷史對話交接等參考資料

---

## 4. 標籤寫作規範
1. **宣告位置**：每個核心 Markdown 檔案最頂部，必須以 YAML 格式宣告標籤。
2. **命名語法**：標籤採用 `大類/小類` 的層級結構（例如 `module/physics-box2d`），這樣在 Obsidian 中會自動生成層級標籤樹，極易檢索。
3. **交接靈活性**：AI 代理人在執行交接或新增文檔時，**被允許且被鼓勵**依據開發成果追加更細緻的標籤（例如 `module/combat-system/visual-effect`），但主幹應遵循本大綱。
