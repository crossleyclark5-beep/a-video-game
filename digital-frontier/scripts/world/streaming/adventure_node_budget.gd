class_name AdventureNodeBudget
extends RefCounted
## Adventure world node / activation budget — density stays high; active cost stays bounded.
##
## Authored content may be large (MultiMesh forests, full region geometry).
## Runtime cost is managed by WorldStreamController + LivingWorldController.
## See docs/WORLD_STREAMING.md.


## Hard gate used by adventure_stability_probe (authored scene under GameWorld).
const AUTHORED_NODE_GATE := 11500

## Soft warning thresholds for the perf HUD (active processing cost).
const ACTIVE_NODE_WARN := 7500
const ACTIVE_NODE_CRITICAL := 9500

## Living population caps (mirrors LivingWorldController — single source of truth).
const WILDLIFE_CAP := 14
const HOSTILE_CAP := 6
const NPC_CAP := 5
const AQUATIC_CAP := 10

## Stream tick — keep light on handheld.
const STREAM_TICK_SEC := 0.35

## Ground focus rings (meters, XZ). Hysteresis via enter/exit pairs.
const GROUND_NEAR_ENTER := 140.0
const GROUND_NEAR_EXIT := 175.0
const GROUND_MEDIUM_ENTER := 380.0
const GROUND_MEDIUM_EXIT := 460.0
const GROUND_FAR_ENTER := 980.0
const GROUND_FAR_EXIT := 1180.0

## Aircraft / aerial inspect rings — large view, still streams VERY_FAR.
const AIR_NEAR_ENTER := 280.0
const AIR_NEAR_EXIT := 360.0
const AIR_MEDIUM_ENTER := 900.0
const AIR_MEDIUM_EXIT := 1100.0
const AIR_FAR_ENTER := 2800.0
const AIR_FAR_EXIT := 3400.0

## Vegetation visibility (ground). Air mode multiplies these (WorldLodPolicy).
const LOD_TREE_END := 420.0
const LOD_BUSH_END := 260.0
const LOD_ROCK_END := 300.0
const LOD_GRASS_END := 280.0
const LOD_MUSHROOM_END := 180.0
const LOD_AIR_MULT := 3.5

## Guidelines for designers / future biomes (documentation as data).
const GUIDELINES: Dictionary = {
	&"near": "Full AI, collisions, interactables, detailed vegetation, interiors when entered.",
	&"medium": "Visible shells, reduced AI tick, collisions on walkables, no far interiors.",
	&"far": "Visual only — terrain, low-cost vegetation, landmark silhouettes.",
	&"very_far": "Inactive — hidden + process disabled + collision off until player approaches.",
	&"interiors": "Load on enter, unload on exit (BuildingInteriorController).",
	&"living": "Spawn near focus, despawn beyond radius; pause AI when stream band >= FAR.",
	&"vegetation": "Prefer MultiMesh; never thin forests for FPS — stream + LOD instead.",
	&"aircraft": "Use AIR_* rings + LOD_AIR_MULT so cities/forests remain readable from altitude.",
}


enum Band {
	NEAR,
	MEDIUM,
	FAR,
	VERY_FAR,
}


static func band_name(band: Band) -> String:
	match band:
		Band.NEAR: return "NEAR"
		Band.MEDIUM: return "MEDIUM"
		Band.FAR: return "FAR"
		_: return "VERY_FAR"


static func guideline(key: StringName) -> String:
	return String(GUIDELINES.get(key, ""))
