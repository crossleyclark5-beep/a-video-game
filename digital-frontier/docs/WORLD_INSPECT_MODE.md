# World Inspection Mode (Developer Tool)

Temporary free-camera + overlay suite for reviewing Digital Frontier as a **true 3D world**.

**Not a player feature.** Gated by `GameConfig.enable_cheats` (on in debug builds).

## Toggle

| Action | Binding |
| --- | --- |
| Enter / exit inspect | **F3** (`inspect_toggle`) |
| Exit | **Esc** / F3 |

Starts from the current ortho gameplay camera; swaps to a perspective free-cam. Restores the 2.5D rig on exit. Input context becomes `WORLD_INSPECT` so the player/vehicles stop.

## Camera controls

| Input | Action |
| --- | --- |
| WASD | Fly horizontally |
| Q / Ctrl | Down |
| E / Space | Up |
| RMB + mouse | Look |
| Arrow keys | Look (no mouse) |
| Shift | 4× speed |
| Alt | Slow precision |
| Mouse wheel | FOV zoom |
| C | Snap above player |
| Home | Jump to Park aerial |

## Overlays

| Key | Overlay |
| --- | --- |
| **1** | Grid — world spacing |
| **2** | Height — elevation pillars from `GrasslandHeightField` |
| **3** | Object info — name, type, coords, Δ vs ground (default on) |
| **4** | Collision — transparent proxies for nearby `CollisionShape3D` (Godot 4.7 has no viewport collision debug draw) |
| **5** | Scale — AABB dimensions of aimed object |
| **6** / **F4** | Placement scan — floating / buried / overlap / scale / rotation |

Placement highlights problem markers near the camera (radius ~180m).

## Integration

- `WorldInspectController` spawned from `GameWorld` when cheats enabled
- `CameraRig.set_inspect_paused(true)` freezes ortho follow + occlusion fader
- Scripts: `scripts/devtools/world_inspect/`

## Quality checklist (use while flying)

**Terrain** — hills/mountains believable? elevation natural from air?  
**Vegetation** — forests dense? placement organic?  
**Buildings** — grounded? interiors aligned?  
**Roads** — connections + driveways?  
**Objects** — scale, clipping, floating?  
**Aerial** — cities readable, landmarks visible, no empty voids?

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/world_inspect_smoke.tscn
```
