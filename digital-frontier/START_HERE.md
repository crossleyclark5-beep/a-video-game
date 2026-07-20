# START HERE — Cooper Game

Your game folder on this PC:

`C:/Users/Martin/OneDrive/Dokumenty/a-video-game-master`

---

## Open the game (3 steps)

1. Start **Godot 4.7.1**
2. **Import** this file:

   `C:/Users/Martin/OneDrive/Dokumenty/a-video-game-master/digital-frontier/project.godot`

3. Press **F5**

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

**Home** → care for Sparkbit (D-pad + A) → **Start** Adventure → explore → discover / chests / quests → **Select+B** or **H** Home → Collection → again.

Autosave on scene change (including world position).

---

## Docs

- `docs/HANDHELD_FIRST.md` — button map + philosophy  
- `docs/ADVENTURE_FOUNDATION.md` — exploration systems  
- `docs/CREATURE_COMPANION.md` — companion care  

---

## Getting updates

1. Download a fresh ZIP from https://github.com/crossleyclark5-beep/a-video-game
2. Replace your `a-video-game-master` folder
3. Open `digital-frontier/project.godot` again
