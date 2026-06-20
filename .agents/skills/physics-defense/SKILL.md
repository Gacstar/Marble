---
name: physics-defense
description: 物理避坑與穩健性規範。確保彈珠台物理計算的絕對穩定性，避免閃退與穿牆。當使用者說「修改碰撞體」、「調整 MarbleTable」、「處理物理材質」時觸發。
---

# Skill: 物理避坑與穩健性規範 (Physics Defense)

| Metadata | Value |
| :--- | :--- |
| **Name** | Physics Defense |
| **Description** | 確保彈珠台物理計算的絕對穩定性，避免閃退與穿牆。 |
| **Category** | Technical / Quality |
| **Triggers** | 「修改碰撞體」、「調整 MarbleTable」、「處理物理材質」。 |

## 1. 觸發情境 (Triggers)
- 當編輯或新增 `.tscn` 中的 `CollisionPolygon2D` 時。
- 當涉及 `Box2D` 插件的參數調整。
- 當涉及槽位偵測 (ScoreZone) 與彈珠計數邏輯。

## 2. 強制性上下文連結 (Context Requirements)
- **物理架構**: `[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md)` (參閱第 5 節)。

## 3. 執行守則 (Execution Protocols)
- **頂點檢查**: 修改任何碰撞體前，必須手動計算頂點數，嚴格限制在 8 以內。
- **繞向檢查**: 確保頂點數列符合 **Counter-Clockwise (CCW)**。
- **類型檢查**: 強制使用凸多邊形 (Convex)，不穩定形狀必須拆解。

## 4. 常見坑洞 (Gotchas)
- **核心指南**: 詳見 `[docs/PITFALLS.md](../../docs/PITFALLS.md#1-物理系統)`。
- **後果**: 違反頂點限制會導致 `invalid_shape_handle` 或遊戲閃退。
