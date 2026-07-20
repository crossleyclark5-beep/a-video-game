class_name PixelCreatureSprite
extends Node2D
## Procedural 2D pixel companion for the Home Field Unit LCD.
## Supports idle / walk / sleep / eat / happy / sad — ready for skins & evolutions.

enum Anim {
	IDLE,
	WALK,
	SLEEP,
	EAT,
	HAPPY,
	SAD,
}

const SPRITE_SIZE := 32
const FRAME_TIME := 0.18

var anim: Anim = Anim.IDLE
var facing: int = 1  ## 1 = right, -1 = left
var body_color := Color(0.98, 0.55, 0.18)
var accent_color := Color(0.98, 0.78, 0.28)
var stage: int = 0

var _frame: int = 0
var _timer: float = 0.0
var _tex_cache: Dictionary = {}  ## "anim_frame_stage_facing" -> ImageTexture
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true
	add_child(_sprite)
	_rebuild_from_manager()
	_apply_frame()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= FRAME_TIME:
		_timer = 0.0
		_frame = (_frame + 1) % _frame_count()
		_apply_frame()


func set_anim(next: Anim) -> void:
	if anim == next:
		return
	anim = next
	_frame = 0
	_timer = 0.0
	_apply_frame()


func play_care(action: StringName) -> void:
	match action:
		&"feed", &"eat":
			set_anim(Anim.EAT)
		&"rest":
			set_anim(Anim.SLEEP)
		&"play", &"pet", &"train":
			set_anim(Anim.HAPPY)
		&"status":
			set_anim(Anim.IDLE)
		_:
			set_anim(Anim.HAPPY)


func refresh_palette() -> void:
	_tex_cache.clear()
	_rebuild_from_manager()
	_apply_frame()


func _rebuild_from_manager() -> void:
	var inst: CreatureInstance = CreatureManager.get_active_instance()
	if inst == null:
		return
	var data: CreatureData = inst.get_species()
	if data:
		body_color = data.body_color
		accent_color = data.accent_color
	stage = CreatureManager.get_level() / 5


func _frame_count() -> int:
	match anim:
		Anim.WALK, Anim.EAT, Anim.HAPPY:
			return 4
		Anim.SLEEP:
			return 2
		_:
			return 2


func _apply_frame() -> void:
	var key := "%d_%d_%d_%d" % [int(anim), _frame, stage, facing]
	if not _tex_cache.has(key):
		_tex_cache[key] = _bake_frame(anim, _frame)
	_sprite.texture = _tex_cache[key]
	_sprite.flip_h = facing < 0
	## Tiny bob for life.
	var bob := 0.0
	if anim == Anim.WALK:
		bob = -1.0 if (_frame % 2) == 0 else 0.0
	elif anim == Anim.HAPPY:
		bob = -2.0 if (_frame % 2) == 0 else 0.0
	_sprite.position.y = bob


func _bake_frame(a: Anim, frame: int) -> ImageTexture:
	var img := Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var scale_px := 1 + mini(stage, 2)
	var cx := SPRITE_SIZE / 2
	var cy := SPRITE_SIZE / 2 + 2
	var body := WorldPalette.quantize(body_color)
	var accent := WorldPalette.quantize(accent_color)
	var outline := Color(0.12, 0.1, 0.1)
	var eye := Color(0.08, 0.08, 0.1)
	var belly := body.lightened(0.25)

	## Body silhouette (blocky dino / blob).
	var bw := 10 + scale_px * 2
	var bh := 10 + scale_px * 2
	var by_off := 0
	match a:
		Anim.SLEEP:
			by_off = 3
			_fill_rect(img, cx - bw / 2, cy - bh / 2 + by_off, bw, bh - 2, body)
			_fill_rect(img, cx - bw / 2 + 2, cy - 1 + by_off, bw - 4, 4, belly)
			## Closed eyes
			_fill_rect(img, cx - 4, cy - 3 + by_off, 3, 1, outline)
			_fill_rect(img, cx + 1, cy - 3 + by_off, 3, 1, outline)
			## Zzz
			if frame == 1:
				_fill_rect(img, cx + 6, cy - 10, 2, 2, accent)
		Anim.WALK:
			var leg := 2 if (frame % 2) == 0 else 0
			_fill_rect(img, cx - bw / 2, cy - bh / 2, bw, bh, body)
			_fill_rect(img, cx - bw / 2 + 2, cy - 2, bw - 4, 5, belly)
			_fill_rect(img, cx - 5, cy + bh / 2 - 1, 3, 3 + leg, body)
			_fill_rect(img, cx + 2, cy + bh / 2 - 1, 3, 3 + (2 - leg), body)
			_draw_face(img, cx, cy - 2, eye, accent, false)
		Anim.EAT:
			_fill_rect(img, cx - bw / 2, cy - bh / 2, bw, bh, body)
			_fill_rect(img, cx - bw / 2 + 2, cy - 2, bw - 4, 5, belly)
			var mouth_h := 2 + (frame % 2)
			_fill_rect(img, cx - 2, cy + 1, 4, mouth_h, outline)
			## Food crumb
			_fill_rect(img, cx + 6, cy + 2 - frame, 2, 2, accent)
			_draw_face(img, cx, cy - 3, eye, accent, false)
		Anim.HAPPY:
			_fill_rect(img, cx - bw / 2, cy - bh / 2 - (frame % 2), bw, bh, body)
			_fill_rect(img, cx - bw / 2 + 2, cy - 2, bw - 4, 5, belly)
			_draw_face(img, cx, cy - 2, eye, accent, true)
			## Sparkles
			if frame % 2 == 0:
				_fill_rect(img, cx - 10, cy - 8, 2, 2, accent)
				_fill_rect(img, cx + 8, cy - 6, 2, 2, accent)
		Anim.SAD:
			_fill_rect(img, cx - bw / 2, cy - bh / 2 + 1, bw, bh, body)
			_fill_rect(img, cx - bw / 2 + 2, cy, bw - 4, 4, belly)
			_fill_rect(img, cx - 4, cy - 2, 2, 2, eye)
			_fill_rect(img, cx + 2, cy - 2, 2, 2, eye)
			_fill_rect(img, cx - 2, cy + 3, 4, 1, outline)
		_:
			## Idle bob via vertical offset in sprite position; draw standing.
			_fill_rect(img, cx - bw / 2, cy - bh / 2, bw, bh, body)
			_fill_rect(img, cx - bw / 2 + 2, cy - 2, bw - 4, 5, belly)
			_fill_rect(img, cx - 5, cy + bh / 2 - 1, 3, 3, body)
			_fill_rect(img, cx + 2, cy + bh / 2 - 1, 3, 3, body)
			_draw_face(img, cx, cy - 2, eye, accent, false)
			## Ear / crest
			_fill_rect(img, cx - 2, cy - bh / 2 - 3, 4, 3, accent)

	## Outline pass for crisp handheld read.
	_outline_silhouette(img, outline)
	return ImageTexture.create_from_image(img)


func _draw_face(img: Image, cx: int, cy: int, eye: Color, accent: Color, smile: bool) -> void:
	_fill_rect(img, cx - 4, cy - 1, 2, 2, eye)
	_fill_rect(img, cx + 2, cy - 1, 2, 2, eye)
	_fill_rect(img, cx - 3, cy - 1, 1, 1, Color.WHITE)
	_fill_rect(img, cx + 3, cy - 1, 1, 1, Color.WHITE)
	if smile:
		_fill_rect(img, cx - 2, cy + 3, 4, 1, accent)
		_fill_rect(img, cx - 3, cy + 2, 1, 1, accent)
		_fill_rect(img, cx + 2, cy + 2, 1, 1, accent)
	else:
		_fill_rect(img, cx - 1, cy + 3, 2, 1, accent)


func _fill_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and py >= 0 and px < SPRITE_SIZE and py < SPRITE_SIZE:
				img.set_pixel(px, py, c)


func _outline_silhouette(img: Image, outline: Color) -> void:
	var copy := img.duplicate()
	for y in SPRITE_SIZE:
		for x in SPRITE_SIZE:
			if copy.get_pixel(x, y).a < 0.1:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= SPRITE_SIZE or ny >= SPRITE_SIZE:
					continue
				if copy.get_pixel(nx, ny).a < 0.1:
					img.set_pixel(nx, ny, outline)
