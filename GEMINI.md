# Antigravity Workspace Rules (Marble Project)

## CORE PROTOCOL
Upon session initialization, the Agent MUST:
1.  **Read** `MASTER_ONBOARDING.md` to understand the project brain MOC.
2.  **Read** `.agents/index.md` to identify valid skills.
3.  **Cross-reference** `docs/API_SPEC.md` before ANY code generation.
4.  **Consult** `docs/PITFALLS.md` immediately if errors occur, code fails to run, or behavior is unexpected.

## TROUBLESHOOTING & RETRIEVAL PROTOCOL
當遇到非預期錯誤、GDScript 編譯失敗、物理碰撞體穿牆、或是在排查 Bug 卡住時，Agent **必須**執行以下防呆檢索：
1.  **強制查閱避雷指南 (Mandatory Pitfall Check)**：在嘗試 any 隨機修改前，**必須第一秒鐘讀取 `docs/PITFALLS.md`**。對照是否觸發了已知地雷（如 Box2D 逆時針排序、8頂點上限、Godot 4 UID快取脫節等）。
2.  **檢索架構決策背景 (ADR Retrieval)**：若 Bug 涉及核心技術棧（如透視 Shader、對稱 UI 介面、老奶奶/奧客資料流），前往 `docs/decisions/` 查閱 ADR 快照，理解原始設計約束與「為什麼要這樣寫」。
3.  **強制對齊技術字典 (API Spec Sync)**：若信號簽章、變數或函式名稱發生變動，強制將目前程式碼與 `docs/API_SPEC.md` 進行逐一比對驗證，杜絕不同步 Bug。

## SKILL TRIGGERS
- If the user says "打交接文件" or "寫交接文件" or "下班", execute `.agents/skills/handover-protocol/SKILL.md`.
- If the user says "修改碰撞體" or "調整 MarbleTable" or "處理物理材質", execute `.agents/skills/physics-defense/SKILL.md`.
- If the user says "剛接手專案" or "讀取導航" or "了解開發規範", execute `.agents/skills/onboarding-mastery/SKILL.md`.
- If the user says "外包給 OpenCode" or "使用本地模型修改檔案", execute `.agents/skills/opencode-collaboration/SKILL.md`.

## ANTI-PATTERNS
- DO NOT ignore the Box2D 8-vertex limit.
- DO NOT skip technical document synchronization.
- DO NOT overwrite files without checking if they belong to a previous session.

## BEHAVIORAL CODING GUIDELINES
Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

Tradeoff: These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First
Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes
Touch only what you must. Clean up only your own mess.

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.
- The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution
Define success criteria. Loop until verified.

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

These guidelines are working if: fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
