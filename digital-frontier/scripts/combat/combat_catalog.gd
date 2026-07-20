class_name CombatCatalog
extends RefCounted
## Code-driven move lists and reward tables for handheld combat.


static func basic_strike(element: int = CombatTypes.Element.NEUTRAL) -> CombatMove:
	return CombatMove.make(&"strike", "Strike", CombatMove.Category.ATTACK, element, 12.0, 0.96, 0.0, 0.0, &"", 0.0, "A clean partner hit.")


static func moves_for_companion(species_id: StringName, battle_style: StringName) -> Array:
	var el := CombatTypes.species_element(species_id)
	var level := CreatureManager.get_level()
	var moves: Array = [basic_strike(el)]
	match el:
		CombatTypes.Element.EMBER:
			moves.append(CombatMove.make(&"ember_snap", "Ember Snap", CombatMove.Category.SPECIAL, el, 18.0, 0.9, 12.0, 0.0, &"burn", 0.25, "Pixel-fire bite."))
			if level >= 6:
				moves.append(CombatMove.make(&"blaze_spiral", "Blaze Spiral", CombatMove.Category.SPECIAL, el, 24.0, 0.86, 18.0, 0.0, &"burn", 0.4, "Partner growth unlock."))
		CombatTypes.Element.TIDE:
			moves.append(CombatMove.make(&"foam_guard", "Foam Guard", CombatMove.Category.DEFEND, el, 0.0, 1.0, 8.0, 6.0, &"soak", 0.0, "Hardens into tide foam."))
			moves.append(CombatMove.make(&"splash_bash", "Splash Bash", CombatMove.Category.SPECIAL, el, 16.0, 0.92, 10.0))
			if level >= 6:
				moves.append(CombatMove.make(&"tidal_crash", "Tidal Crash", CombatMove.Category.SPECIAL, el, 23.0, 0.87, 16.0))
		CombatTypes.Element.VOLT:
			moves.append(CombatMove.make(&"spark_dash", "Spark Dash", CombatMove.Category.SPECIAL, el, 15.0, 0.93, 10.0, 0.0, &"shock", 0.2, "Blitzes in a yellow arc."))
			if level >= 6:
				moves.append(CombatMove.make(&"volt_burst", "Volt Burst", CombatMove.Category.SPECIAL, el, 22.0, 0.88, 16.0, 0.0, &"shock", 0.35))
		_:
			moves.append(CombatMove.make(&"partner_pulse", "Partner Pulse", CombatMove.Category.SPECIAL, el, 15.0, 0.92, 10.0))
			if level >= 6:
				moves.append(CombatMove.make(&"bond_surge", "Bond Surge", CombatMove.Category.SPECIAL, el, 21.0, 0.9, 14.0))
	match battle_style:
		&"tank":
			moves.append(CombatMove.make(&"brace", "Brace", CombatMove.Category.DEFEND, CombatTypes.Element.NEUTRAL, 0.0, 1.0, 5.0, 4.0))
		&"aggressive":
			moves.append(CombatMove.make(&"fierce_rush", "Fierce Rush", CombatMove.Category.SPECIAL, el, 20.0, 0.85, 14.0))
		&"swift":
			moves.append(CombatMove.make(&"quick_jab", "Quick Jab", CombatMove.Category.ATTACK, el, 11.0, 0.99, 4.0))
	if level >= 10:
		moves.append(CombatMove.make(&"partner_finale", "Partner Finale", CombatMove.Category.SPECIAL, el, 28.0, 0.82, 22.0, 0.0, &"", 0.0, "Signature bonded finish."))
	return moves


static func moves_for_enemy(species_id: StringName, tier: StringName) -> Array:
	var el := CombatTypes.species_element(species_id)
	var moves: Array = [basic_strike(el)]
	match String(species_id):
		"glitch_alpha":
			moves.append(CombatMove.make(&"alpha_howl", "Alpha Howl", CombatMove.Category.SPECIAL, CombatTypes.Element.HEX, 20.0, 0.9, 0.0, 0.0, &"shock", 0.3))
		"hollow_warden":
			moves.append(CombatMove.make(&"root_slam", "Root Slam", CombatMove.Category.SPECIAL, CombatTypes.Element.HEX, 22.0, 0.88, 0.0, 0.0, &"root", 0.35))
			moves.append(CombatMove.make(&"pine_ward", "Pine Ward", CombatMove.Category.DEFEND, CombatTypes.Element.NATURE, 0.0, 1.0, 0.0, 8.0))
		"glitchmite":
			moves.append(CombatMove.make(&"static_nip", "Static Nip", CombatMove.Category.ATTACK, CombatTypes.Element.HEX, 10.0, 0.95))
		"bytebat":
			moves.append(CombatMove.make(&"sonic_dive", "Sonic Dive", CombatMove.Category.SPECIAL, CombatTypes.Element.VOLT, 14.0, 0.9))
		"scrubwolf":
			moves.append(CombatMove.make(&"pack_bite", "Pack Bite", CombatMove.Category.ATTACK, CombatTypes.Element.HEX, 13.0, 0.93))
		"thornboar":
			moves.append(CombatMove.make(&"gore", "Gore", CombatMove.Category.SPECIAL, CombatTypes.Element.NATURE, 16.0, 0.88))
		_:
			if tier == &"elite" or tier == &"mini_boss" or tier == &"boss":
				moves.append(CombatMove.make(&"heavy_hit", "Heavy Hit", CombatMove.Category.SPECIAL, el, 17.0, 0.88))
	return moves


static func reward_for(tier: StringName, level: int) -> Dictionary:
	match tier:
		&"boss":
			return {"xp": 40 + level * 2, "bits": 100 + level * 5, "bond": 8.0}
		&"mini_boss":
			return {"xp": 22 + level, "bits": 55 + level * 3, "bond": 4.0}
		&"elite":
			return {"xp": 14 + level, "bits": 28 + level * 2, "bond": 2.0}
		_:
			return {"xp": 8 + level / 2, "bits": 10 + level, "bond": 1.0}


static func make_battle_record(won: bool, enemy_id: StringName, tier: StringName, turns: int) -> Dictionary:
	## NFC-ready offline battle record — no network required.
	return {
		&"schema": 1,
		&"won": won,
		&"enemy_id": String(enemy_id),
		&"tier": String(tier),
		&"turns": turns,
		&"companion_id": String(CreatureManager.get_companion_id()),
		&"companion_instance": String(CreatureManager.get_companion_instance_id()),
		&"companion_level": CreatureManager.get_level(),
		&"companion_stage": CreatureManager.get_evolution_stage(),
		&"unix": int(Time.get_unix_time_from_system()),
		&"device": "field_unit",
	}
