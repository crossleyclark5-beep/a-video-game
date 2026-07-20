# Agent notes — Cooper / Digital Frontier

## Canonical local project (user machine)

**All updates must target this folder. Do not tell the user to use any other path.**

```
C:/Users/Martin/Downloads/cooper.cursor/cooper
```

Godot entry (preferred):

```
C:/Users/Martin/Downloads/cooper.cursor/cooper/digital-frontier/project.godot
```

Fallback if the Godot project is the workspace root:

```
C:/Users/Martin/Downloads/cooper.cursor/cooper/project.godot
```

Deprecated / do not use in instructions:

- `C:/Users/Martin/OneDrive/Dokumenty/a-video-game-master/...`
- Branch ZIP extract folders (`a-video-game-cursor-…`)
- Any second Godot Import

## How updates reach that folder

This cloud workspace pushes to GitHub `master`. The user applies updates by overwriting  
`C:/Users/Martin/Downloads/cooper.cursor/cooper` from the master ZIP, or by `git pull` if that folder is a clone.

Always say: update **into** that `cooper` folder — never Import a new Godot project.

## Game project in this repo

Godot project lives under `digital-frontier/` (`project.godot`, Godot 4.7.1).
