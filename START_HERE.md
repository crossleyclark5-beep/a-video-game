# Open the game (one project only)

**Your working project (this is the one that works):**

`C:/Users/Martin/OneDrive/Dokumenty/a-video-game-master/digital-frontier/project.godot`

In Godot, open **Edit** on that same project — do not Import a second copy. Then press **F5**.

Folder spelling is `digital-frontier` (with an **i** before the last **e**).

---

## Getting updates — keep ONE Godot project

Branch ZIP downloads make a **new folder** (e.g. `a-video-game-cursor-…`). Godot then shows a **separate project**. That is expected — and not what you want.

**Do this instead:**

1. Download **master** only:  
   https://github.com/crossleyclark5-beep/a-video-game/archive/refs/heads/master.zip
2. Extract the ZIP (it becomes something like `a-video-game-master` again).
3. **Replace** your old folder: delete or rename the old `a-video-game-master`, then put the new one in the same place with the **same name**.
4. In Godot Project Manager: open the **existing** entry for  
   `…/a-video-game-master/digital-frontier/project.godot`  
   Do **not** click Import on a second folder.

More detail: [`digital-frontier/START_HERE.md`](digital-frontier/START_HERE.md)
