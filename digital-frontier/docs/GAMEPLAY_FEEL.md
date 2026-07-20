# Gameplay Feel — Buildings, Chests, Companion

## Why it felt broken

| System | Root cause |
|--------|------------|
| Houses | Solid `Body` box hid the player; door disabled while “inside” so Exit never worked; GreenHouse had no interior |
| Chests | Door Area swallowed Chest_1; felt like a scene kick when Enter fired instead of Open |
| Companion | Grounded physics + world collision stuck them; no snap on house enter |

## Fixes

1. **Buildings** — Open-top wall shells, roof/peak fade, shell cutaway, door stays enabled for Exit, soft step-in tween, interior camera mode, both enterable houses load interior scene, companion warps with you.
2. **Chests** — Explicit Closed / Opening / Opened states; open in place (no scene change); tighter door volumes; Chest_1 moved off the porch; focus prefers chests over doors.
3. **Companion** — Floating motion, no world grind, faster catch-up, stuck snap, warp on building enter/exit, softer notice idle.

## Handheld feel

Player always stays in the adventure scene. Enter / Exit / Open are A-button prompts. Home remains Select+B or H only.
