# START HERE — Cooper Game

**Your working project on this PC:**

`C:/Users/Martin/OneDrive/Dokumenty/a-video-game-master/digital-frontier/project.godot`

Keep that folder. Spelling is `digital-frontier` (not `digital-fronteir`).

---

## Open the game (3 steps)

1. Start **Godot 4.7.1**
2. Open the **existing** project (Edit), not a new Import — the path above
3. Press **F5**

There is only **one** Godot project: `digital-frontier/project.godot`.

---

## If Godot shows two projects

You downloaded a ZIP that extracted into a **new folder** next to the old one. Godot treats every folder with its own `project.godot` as a separate project.

**Fix:**

1. Close Godot.
2. Download master ZIP:  
   https://github.com/crossleyclark5-beep/a-video-game/archive/refs/heads/master.zip
3. Delete or rename the old `a-video-game-master` folder.
4. Put the new extract in the same place, named `a-video-game-master`.
5. Delete any extra folders like `a-video-game-cursor-…` if you do not need them.
6. Open Godot → Edit the original project path only.

Do **not** Import the new folder as a second project.

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

In Adventure your companion **follows you**, notices secrets (**Y** to ask them), and grows friendship from exploring together.

---

## Docs

- `docs/CREATURE_ADVENTURE.md` — partner follow / sense / abilities  
- `docs/HANDHELD_FIRST.md` — button map + philosophy  
- `docs/ADVENTURE_FOUNDATION.md` — exploration systems  
- `docs/CREATURE_COMPANION.md` — companion care  

---

## Getting updates

1. Download **master** ZIP only:  
   https://github.com/crossleyclark5-beep/a-video-game/archive/refs/heads/master.zip
2. Replace your `a-video-game-master` folder (same name, same place).
3. Open the **same** `digital-frontier/project.godot` again in Godot.
