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

**Canonical folder on Martin’s PC:**

`C:/Users/Martin/Downloads/cooper.cursor/cooper`

1. Launch Godot 4.7.1
2. **Edit** (do not Import a second copy) this file:
   ```
   C:/Users/Martin/Downloads/cooper.cursor/cooper/digital-frontier/project.godot
   ```
   If `project.godot` is at the root of `cooper`, open that instead.
3. Press **F5**

You should boot: `boot.tscn` → `main.tscn` → Home habitat (then Adventure).

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
