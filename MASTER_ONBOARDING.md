# Marble Table: 專案大腦 MOC (MASTER_INDEX)

本專案遵循「AI-to-AI 交接規範」，任何接手的 AI 應該優先閱讀此 MOC 進入狀況。

---

## 🏗️ 核心架構 (Architecture)
房子是怎麼蓋的？物理引擎為何選用 Box2D？
**[📂 docs/ARCHITECTURE.md](file:///d:/GodotProject/Marble/docs/ARCHITECTURE.md)**

## 📖 技術字典 (API Reference)
有哪些函數？重要變數叫什麼？檔案去哪找？
**[📂 docs/API_SPEC.md](file:///d:/GodotProject/Marble/docs/API_SPEC.md)**

## 📅 進度與待辦 (Status & TODO)
目前開發到哪裡？下一步該做什麼？
**[📂 docs/TODO.md](file:///d:/GodotProject/Marble/docs/TODO.md)**

## 📜 歷史交接紀錄 (Logs)
具體的開發時間線與歷史修改日誌。
**[📂 docs/logs/](file:///d:/GodotProject/Marble/docs/logs/)**

## 📜 核心開發技能 (Modular Agent Skills)
專案專屬的開發規範、物理避坑守則與交接協定。**所有 AI 必須優先載入此索引。**
**[📂 .antigravity/index.md](file:///d:/GodotProject/Marble/.antigravity/index.md)**

---
> [!IMPORTANT]
> **AI 運作核心規範 (Systemic Protocols):**
> 1. **技能驅動**: 在執行任務前，請先掃描 `.antigravity/index.md` 並啟動對應情境的技能模組。
> 2. **雙軌同步**: 所有的技術開發必須同時更新 `docs/API_SPEC.md` 與 `docs/ARCHITECTURE.md`，詳見 `handover-protocol`。
> 3. **物理防禦**: 若涉及 MarbleTable 修改，強制激活 `physics-defense` 技能。
> 4. **導航優先**: 加入專案的第一個動作，必須閱讀此 MOC 檔案。
