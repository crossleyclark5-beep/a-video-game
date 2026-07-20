# START HERE — Cooper Game

## FINAL project (only this one)

Workspace:

`C:/Users/Martin/Downloads/cooper.cursor/cooper`

Godot project file:

`C:/Users/Martin/Downloads/cooper.cursor/cooper/digital-frontier/project.godot`

(If `project.godot` is directly under `cooper`, open that instead.)

Ignore older copies under OneDrive / Downloads ZIPs / `a-video-game-master`.

---

## Open the game (3 steps)

1. Start **Godot 4.7.1**
2. **Edit** the existing project at the path above (do not Import a new one)
3. Press **F5**

---

## If Godot shows two projects

You opened a ZIP extract as a second folder. Delete/ignore the extra folder. Keep only:

`C:/Users/Martin/Downloads/cooper.cursor/cooper`

---

## This is a handheld game

Digital Frontier is designed for a **custom handheld** (physical buttons, small screen).  
Keyboard in the editor is only a fallback so you can test without the device.

Full map: `docs/HANDHELD_FIRST.md`

### Controls (pad labels)

| Button | Action |
|--------|--------|
| Stick / D-pad | Move · menu focus |
| **A** | Interact / confirm |
| **B** | Cancel / close |
| **X** | Cycle Field Unit tabs |
| **Y** | Creature (pet at Home) |
| **Start** | Field Unit · Adventure from Home |
| **Select** | Pause · Select+B = Home |
| **L** | Run (hold) |
| **R** | Map peek |

Editor fallbacks: WASD, E/Space=A, Esc=B, Tab=Start, Q=X, C=Y, M=R, Shift=L, H=Home

---

## Core loop

**Home** → care for Sparkbit (D-pad + A) → **Start** Adventure → explore **with your creature** → discover / chests / quests → **Select+B** or **H** Home → Collection → again.

Autosave on scene change (including world position).

In Adventure your companion **Emberling** follows you, notices secrets (**Y** to ask them), and grows friendship from exploring together. Care + bond can evolve them into **Emberaptor**, then **Emberion**.

---

## Docs

- `docs/CREATURE_ADVENTURE.md` — partner follow / sense / abilities  
- `docs/HANDHELD_FIRST.md` — button map + philosophy  
- `docs/ADVENTURE_FOUNDATION.md` — exploration systems  
- `docs/CREATURE_COMPANION.md` — companion care  

---

## Getting updates

1. Download **master** ZIP:  
   https://github.com/crossleyclark5-beep/a-video-game/archive/refs/heads/master.zip
2. Copy/overwrite into **`C:/Users/Martin/Downloads/cooper.cursor/cooper`** (not a new folder)
3. Open the **same** `project.godot` again in Godot
