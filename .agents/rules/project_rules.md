# Antigravity Workspace Rules (Marble Project)

## CORE PROTOCOL
Upon session initialization, the Agent MUST:
1.  **Read** `MASTER_ONBOARDING.md` to understand the project brain MOC.
2.  **Read** `.agents/index.md` to identify valid skills.
3.  **Cross-reference** `docs/API_SPEC.md` before ANY code generation.
4.  **Consult** `docs/PITFALLS.md` immediately if errors occur, code fails to run, or behavior is unexpected.

## SKILL TRIGGERS
- If the user says "打交接文件", execute `skills/handover-protocol/SKILL.md`.
- If the user says "修改碰撞體", execute `skills/physics-defense/SKILL.md`.

## ANTI-PATTERNS
- DO NOT ignore the Box2D 8-vertex limit.
- DO NOT skip technical document synchronization.
