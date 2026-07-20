class_name StoryCatalog
extends RefCounted
## Frontier mystery beats — reveal slowly; never dump the whole plot.


## Beat id → short handheld lines (2–3 max). Cryptic, suspenseful.
static func beat_lines(beat_id: StringName) -> PackedStringArray:
	match beat_id:
		&"frontier_whisper":
			return PackedStringArray([
				"Something older than the parks is waking in the code-grass.",
				"Your partner feels it too — a pulse under the meadow.",
			])
		&"chapter_open":
			return PackedStringArray([
				"This is Chapter One of the Digital Frontier.",
				"Pleasant Park is only the first porch light.",
			])
		&"alpha_shadow":
			return PackedStringArray([
				"Glitch Alpha wasn’t random. Something herded it toward the road.",
				"Who benefits if travelers never reach Pine Hollow?",
			])
		&"warden_dream":
			return PackedStringArray([
				"The Hollow Warden whispered in root-static… then went quiet.",
				"One chapter ends. The Frontier’s true map is still blank.",
			])
		&"signal_injury":
			return PackedStringArray([
				"A wounded creature-signal flickered near the ranger trail.",
				"Someone — or something — left it that way.",
			])
		&"lost_scout_found":
			return PackedStringArray([
				"The lost scout saw lights moving without footprints.",
				"They pointed north… then asked you not to tell everyone.",
			])
		&"chapter_echo":
			return PackedStringArray([
				"Pleasant Park is safe — for now.",
				"Rest. Train. The next region is already listening.",
			])
		_:
			return PackedStringArray()


static func beat_title(beat_id: StringName) -> String:
	match beat_id:
		&"frontier_whisper":
			return "A Whisper in the Grass"
		&"chapter_open":
			return "Chapter One"
		&"alpha_shadow":
			return "Shadow on the Road"
		&"warden_dream":
			return "Roots Go Quiet"
		&"signal_injury":
			return "Injured Signal"
		&"lost_scout_found":
			return "Scout Recovered"
		&"chapter_echo":
			return "Chapter Echo"
		_:
			return "Story Beat"


static func flag_for_beat(beat_id: StringName) -> StringName:
	return StringName("story_beat_%s" % String(beat_id))
