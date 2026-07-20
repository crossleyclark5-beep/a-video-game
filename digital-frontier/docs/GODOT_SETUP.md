# Opening Digital Frontier in Godot 4.7.1

## Important: use the correct OS build

Your download path shows a **Linux** binary:

`Godot_v4.7.1-stable_linux.x86_64`

| If you use… | You need… |
|-------------|-----------|
| **Windows** (most common from a `c:\Users\...` path) | `Godot_v4.7.1-stable_win64.exe` |
| **Linux / WSL** | `Godot_v4.7.1-stable_linux.x86_64` (what you have) |
| **macOS** | `Godot_v4.7.1-stable_macos.universal.zip` |

Temp-folder extracts can disappear after a reboot. Move the binary somewhere permanent, e.g.:

- Windows: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Linux: `~/Godot/Godot_v4.7.1-stable_linux.x86_64`

Download page: https://godotengine.org/download

---

## Open this project

1. Clone / pull the repo and checkout the foundation branch if needed:
   ```bash
   git checkout cursor/godot-foundation-21cb
   ```
2. Launch Godot 4.7.1
3. **Import** → select:
   ```
   <repo>/digital-frontier/project.godot
   ```
4. Open the project → press **F5**

You should boot: `boot.tscn` → `main.tscn` → empty `game_world.tscn`.

---

## Verify version

In Godot: **Help → About** should show **4.7.1.stable**.

Or from a terminal (Linux/WSL):

```bash
chmod +x Godot_v4.7.1-stable_linux.x86_64
./Godot_v4.7.1-stable_linux.x86_64 --version
```

---

## This cloud agent

The Cursor cloud environment does **not** have your local Godot binary. Gameplay implementation and editor testing happen on your machine; the agent edits project files in the repo.
