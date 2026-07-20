class_name WorldPalette
extends RefCounted
## Shared limited color set for the modern pixel-art 2.5D world.
## Keep the whole game on one handcrafted palette so nothing feels AAA-generic.

## Terrain
const GRASS := Color(0.30, 0.62, 0.28)
const GRASS_DARK := Color(0.22, 0.48, 0.22)
const GRASS_LIGHT := Color(0.40, 0.72, 0.34)
const DIRT := Color(0.55, 0.38, 0.22)
const SAND := Color(0.78, 0.68, 0.42)
const ROAD := Color(0.22, 0.22, 0.26)
const ROAD_EDGE := Color(0.16, 0.16, 0.18)
const ROAD_LINE := Color(0.92, 0.88, 0.55)
const SIDEWALK := Color(0.62, 0.62, 0.58)
const CURB := Color(0.52, 0.52, 0.48)
const PATH := Color(0.68, 0.55, 0.36)
const WATER := Color(0.28, 0.55, 0.78)
const WATER_DEEP := Color(0.18, 0.38, 0.62)

## Buildings
const BRICK := Color(0.72, 0.32, 0.26)
const WOOD := Color(0.55, 0.36, 0.20)
const ROOF := Color(0.28, 0.30, 0.42)
const ROOF_RED := Color(0.62, 0.22, 0.18)
const WALL_CREAM := Color(0.88, 0.84, 0.72)
const WINDOW := Color(0.35, 0.55, 0.72)
const METAL := Color(0.45, 0.48, 0.52)
const FENCE := Color(0.70, 0.70, 0.64)
const ROCK := Color(0.50, 0.48, 0.44)
const LAMP_GLOW := Color(1.0, 0.92, 0.65)

## Nature
const TRUNK := Color(0.42, 0.28, 0.16)
const LEAF := Color(0.22, 0.55, 0.24)
const LEAF_DARK := Color(0.14, 0.38, 0.18)
const LEAF_LIT := Color(0.32, 0.68, 0.30)
const BUSH := Color(0.18, 0.48, 0.22)
const FLOWER := Color(0.92, 0.35, 0.45)
const FLOWER_Y := Color(0.95, 0.78, 0.22)

## Sky / light (discrete steps — no pastel mush)
const SKY_DAY := Color(0.42, 0.68, 0.95)
const SKY_MORNING := Color(0.95, 0.75, 0.55)
const SKY_EVENING := Color(0.85, 0.42, 0.35)
const SUN_DAY := Color(1.0, 0.95, 0.82)
const AMBIENT_DAY := Color(0.55, 0.62, 0.72)

## UI — Digital Frontier Field Unit brand (early-2000s digi-device energy)
const UI_INK := Color(0.07, 0.09, 0.14)
const UI_PAPER := Color(0.94, 0.91, 0.82)
const UI_ACCENT := Color(1.0, 0.48, 0.18) ## Electric orange CTA
const UI_BORDER := Color(0.14, 0.16, 0.22)
const UI_NAVY := Color(0.10, 0.14, 0.28) ## Device shell / deep panels
const UI_CYAN := Color(0.25, 0.85, 0.95) ## Digital LCD accent
const UI_LIME := Color(0.45, 0.95, 0.35) ## Success / ready
const UI_PURPLE := Color(0.55, 0.35, 0.85) ## Tab / secondary
const UI_GOLD := Color(0.98, 0.82, 0.28) ## Bits / rewards
const UI_DANGER := Color(0.95, 0.32, 0.28)
const UI_MUTED := Color(0.45, 0.48, 0.55)
const UI_SHEET := Color(0.12, 0.16, 0.32) ## Sheet body on navy chrome
const UI_SHEET_TEXT := Color(0.94, 0.95, 0.92)


static func quantize(color: Color, steps: int = 6) -> Color:
	## Snap to a coarse ramp so lighting can't create infinite soft gradients.
	var s := float(maxi(2, steps))
	return Color(
		roundf(color.r * s) / s,
		roundf(color.g * s) / s,
		roundf(color.b * s) / s,
		color.a,
	)
