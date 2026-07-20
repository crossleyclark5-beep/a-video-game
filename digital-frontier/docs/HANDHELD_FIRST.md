# Handheld-First Design

Digital Frontier is built for a **custom handheld**, not a PC game with a pad bolted on.

## Hardware assumptions

- Physical buttons only (no touchscreen)
- Small display (design ~960×540 logical; large type)
- Analog stick **or** D-pad
- Face buttons A/B/X/Y
- Start + Select
- Shoulder L/R
- Optional: gyro, haptics, speaker, LED/RGB

## Recommended button map

| Physical | Action ID | Overworld | Menus / Home |
|----------|-----------|-----------|--------------|
| Stick / D-pad | `move_*` / `ui_*` | Move | Move focus |
| **A** | `interact` / `ui_confirm` | Interact, open, talk | Confirm / care |
| **B** | `ui_cancel` | Close sheet | Back / close |
| **X** | `device_cycle` | Cycle Field Unit tabs | Cycle tabs |
| **Y** | `creature_action` | Quick creature note | Pet / focus care |
| **Start** | `device_menu` | Open/close Field Unit | Same |
| **Select** | `pause_menu` | Pause / Settings | Settings |
| **L** (hold) | `run` | Run | — |
| **R** | `map_peek` | Jump to Map tab | — |
| **Select+B** or Hold Select | `go_home` | Return Home | — |
| **Start** on Home | `go_adventure` | — | Start Adventure |

Keyboard exists only as a **dev fallback** so Godot on PC can simulate the pad.

## Control philosophy

1. Few buttons, always reachable  
2. **A** does the verb in front of you (“Open”, “Talk”, “Feed”)  
3. **B** always backs out  
4. One **Start** sheet for Pack / Map / Quests / Log / Bits — never a PC window stack  
5. No mouse required; clicks are secondary if present  

## UI rules

- Large readable labels  
- One focused row at a time  
- D-pad + A/B only for menus  
- Prompt text: `A — Open chest` (not “Press E”)  
- Minimal depth: Home → one sheet, Adventure → one Field Unit  

## Device features (stubs now)

| Feature | Use later |
|---------|-----------|
| Haptics | Chest open, discovery, creature mood |
| Gyro | Vehicles, special look moments |
| Speaker | Creature / UI / ambience (AudioManager) |
| LED/RGB | Mood + notifications |

`DeviceService` exposes no-op / PC stubs so gameplay can call it today.

## Adaptation order

1. Central InputMap + glyphs ✅  
2. Prompts + Adventure Field Unit on actions ✅  
3. Home focus strip (buttons only) ✅  
4. DeviceService hooks on chests/discover/care ✅  
5. Camera fixed for small screen ✅ (wheel zoom editor-only)  
6. Settings / remap UI — next  

## Runtime checklist

- [x] Stick / D-pad move  
- [x] A interact with `A — verb` prompts  
- [x] Start Field Unit / Home Adventure  
- [x] X cycle tabs · R map · B close  
- [x] Home D-pad + A care strip  
- [x] DeviceService haptic / LED stubs  
- [ ] Settings remapping screen  
- [ ] Dialogue choice UI with A/B  
- [ ] Real firmware DeviceService backend  
