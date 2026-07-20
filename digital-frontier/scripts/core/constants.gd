class_name GameConstants
extends RefCounted
## Project-wide constants. Prefer data files for content; use this for engine-level values only.

const PROJECT_NAME := &"Cooper Game"
const SAVE_FILE_EXTENSION := &".sav"
const SAVE_SLOT_COUNT := 3

## Hex grid defaults (overridden per-region via RegionData).
const DEFAULT_HEX_SIZE := 1.0
const DEFAULT_HEX_ORIENTATION := &"pointy"

## Scene paths — single source of truth for programmatic loading.
const SCENE_BOOT := &"res://scenes/bootstrap/boot.tscn"
const SCENE_MAIN := &"res://scenes/main/main.tscn"
const SCENE_HOME := &"res://scenes/home/home_habitat.tscn"
const SCENE_GAME_WORLD := &"res://scenes/world/game_world.tscn"
const SCENE_LOADING := &"res://scenes/bootstrap/loading_screen.tscn"

## Data directory roots for ResourceRegistry scanning.
const DATA_ROOT := &"res://data/"
const DATA_REGIONS := &"res://data/regions/"
const DATA_CREATURES := &"res://data/creatures/"
const DATA_ITEMS := &"res://data/items/"
const DATA_QUESTS := &"res://data/quests/"
const DATA_BUILDINGS := &"res://data/buildings/"
const DATA_NPCS := &"res://data/npcs/"
const DATA_VEHICLES := &"res://data/vehicles/"
const DATA_BOSSES := &"res://data/bosses/"
const DATA_TABLES := &"res://data/tables/"
const DATA_LOOT := &"res://data/tables/loot/"
const DATA_DISCOVERABLES := &"res://data/discoverables/"
const DATA_ACHIEVEMENTS := &"res://data/achievements/"

## Default save slot used by autosave.
const AUTOSAVE_SLOT := 0

## Physics layer indices (must match project.godot layer_names).
enum PhysicsLayer {
	WORLD_STATIC = 1,
	WORLD_DYNAMIC = 2,
	PLAYER = 3,
	ENTITIES = 4,
	INTERACTABLES = 5,
	VEHICLES = 6,
	PROJECTILES = 7,
	TRIGGERS = 8,
}

## Groups used across scenes for discovery without hard references.
const GROUP_PLAYER := &"player"
const GROUP_CREATURES := &"creatures"
const GROUP_NPCS := &"npcs"
const GROUP_INTERACTABLES := &"interactables"
const GROUP_VEHICLES := &"vehicles"
const GROUP_SAVEABLE := &"saveable"
