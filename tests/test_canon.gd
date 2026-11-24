# WindShear — canon tests
# Copyright (C) 2026 the WindShear contributors
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <https://www.gnu.org/licenses/>.
##
## The cast, arsenal, enemy roster and player's numbers are canon. Canon is
## the kind of thing that quietly drifts. Somebody adds a prequel enemy, moves
## a weapon into the wrong act, or gives Lancer a pronoun in a line of
## dialogue. Six months later, the design document and the data disagree about
## who's game it is.
##
## The campaign is 25 chapters of 12 sections in seven acts. Act 0 is the
## five-chapter Fracture Year prequel, P1 through P5.
##
## The canon lives in JSON. This suite checks it against itself and against
## the design document:
##
## [br]- every dialogue speaker is in the cast;
## [br]- Lancer has no pronouns and never speaks;
## [br]- Ilsa is she/her and says nothing in the five Fracture Year prequel chapters;
## [br]- the enemy roster and arsenal agree with each other;
## [br]- the main-game threat does not turn up in the Fracture Year;
## [br]- health and speed numbers match the movement tuning file;
## [br]- every weapon and enemy is named in the design document.
extends "res://tests/ws_test.gd"

## The movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## The cast.
const CAST_PATH := "res://data/cast.json"
## The arsenal.
const ARSENAL_PATH := "res://data/arsenal.json"
## The enemy roster.
const ENEMIES_PATH := "res://data/enemies.json"
## The player's health and speed numbers.
const PLAYER_PATH := "res://data/player.json"
## The English dialogue.
const DIALOGUE_PATH := "res://data/story/dialogue/en.json"
## The section index.
const INDEX_PATH := "res://data/sections/index.json"
## The design document.
const DESIGN_PATH := "res://GAME_DESIGN.md"

## The characters who have to be in the cast.
const EXPECTED_CAST := [
	"lancer",
	"ilsa_renn",
	"warden_saye",
	"the_concord",
	"first_runner",
	"aris_thorne",
	"sergeant_miller",
	"henrik_solberg",
	"talia_korr",
]

## The bio-constructs that exist in the Fracture Year prequel.
const PREQUEL_ENEMIES := [
	"concord_dartbug",
	"concord_ram",
	"concord_stifler",
]

## The threats that only exist in the present day. None of these may be
## named in a prequel chapter.
const MAIN_ONLY_ENEMIES := [
	"concord_trooper",
	"napalm_mortar",
	"concord_overwatch",
	"concord_diver",
	"concord_jammer",
	"warp_synth",
	"concord_sdo_trooper",
	"concord_c01_scatter",
]

## The words that would gender Lancer if they appeared in a Lancer line.
const PRONOUN_WORDS := [" he ", " she ", " his ", " her ", " him ", " hers ", " himself ", " herself "]

var _cast: Dictionary = {}
var _arsenal: Dictionary = {}
var _enemies: Dictionary = {}
var _player: Dictionary = {}
var _dialogue: Dictionary = {}
var _index: Dictionary = {}
var _design := ""


func suite_name() -> String:
	return "the canon holds"


func run() -> void:
	_read_the_canon()
	_test_the_cast()
	_test_the_silence()
	_test_the_arsenal()
	_test_the_enemies()
	_test_the_numbers()
	_test_the_documents()


func _read_the_canon() -> void:
	_cast = _read_json(CAST_PATH)
	_arsenal = _read_json(ARSENAL_PATH)
	_enemies = _read_json(ENEMIES_PATH)
	_player = _read_json(PLAYER_PATH)
	_dialogue = _read_json(DIALOGUE_PATH)
	_index = _read_json(INDEX_PATH)
	_design = FileAccess.get_file_as_string(DESIGN_PATH)


## Reads a JSON file and parses it.
func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("could not open " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append(path + " is not a JSON object")
		return {}
	return parsed


## An array out of a parsed JSON object.
func _array(source: Dictionary, key: String) -> Array:
	var value = source.get(key, [])
	if typeof(value) != TYPE_ARRAY:
		return []
	return value


## The chapter key as a string. JSON numbers arrive as floats, and the
## String constructor does not take a float, so this goes through [method str].
func _chapter_key(value) -> String:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return str(int(value))
	return str(value)


## The character with this id, or an empty dictionary.
func _character(character_id: String) -> Dictionary:
	for character in _array(_cast, "characters"):
		if String(character.id) == character_id:
			return character
	return {}


## The enemy with this id, or an empty dictionary.
func _enemy(enemy_id: String) -> Dictionary:
	for enemy in _array(_enemies, "enemies"):
		if String(enemy.id) == enemy_id:
			return enemy
	return {}


## The cast has to hold everyone the campaign names.
func _test_the_cast() -> void:
	heading("the cast")
	var found := {}
	for character in _array(_cast, "characters"):
		found[String(character.id)] = true
	var missing: Array = []
	for character_id in EXPECTED_CAST:
		if not found.has(character_id):
			missing.append(character_id)
	ok(missing.is_empty(), "the cast holds everyone (%s)" % ", ".join(missing))

	var lancer := _character("lancer")
	ok(lancer.get("silent", false) == true, "lancer is silent")
	ok(lancer.get("pronouns", "set") == null, "lancer has no pronouns")
	ok(String(lancer.get("display_name", "")).contains("Ivanov"), "lancer is Lancer Ivanov")

	var ilsa := _character("ilsa_renn")
	ok(ilsa.get("pronouns", "") == "she/her", "ilsa is she/her")
	ok(ilsa.get("silent_in_prequel", false) == true, "ilsa is silent in the prequel")
	ok(String(ilsa.get("note", "")).contains("trained Lancer"), "ilsa trained Lancer")

	ok(_character("warden_saye").get("pronouns", "") == "she/her", "saye is she/her")
	ok(_character("talia_korr").get("pronouns", "") == "she/her", "talia is she/her")
	ok(_character("aris_thorne").get("pronouns", "") == "he/him", "thorne is he/him")
	ok(_character("sergeant_miller").get("pronouns", "") == "he/him", "miller is he/him")
	ok(_character("henrik_solberg").get("pronouns", "") == "he/him", "solberg is he/him")


## Lancer never speaks, and nobody gives Lancer a pronoun.
func _test_the_silence() -> void:
	heading("the silence")
	var speakers := {}
	for speaker in _array(_dialogue, "speakers"):
		speakers[String(speaker.id)] = speaker

	var unknown: Array = []
	for speaker in _array(_dialogue, "speakers"):
		if not _character(String(speaker.id)).is_empty():
			continue
		# The civil-defence channel is a broadcast, not a person. It is still
		# in the cast file, so it is allowed here.
		unknown.append(String(speaker.id))
	ok(unknown.is_empty(), "every speaker is in the cast (%s)" % ", ".join(unknown))

	var not_actions: Array = []
	var gendered: Array = []
	for line in _array(_dialogue, "lines"):
		if String(line.speaker_id) != "lancer":
			continue
		var text := " " + String(line.text).to_lower() + " "
		if not String(line.text).begins_with("["):
			not_actions.append(String(line.id))
		for word in PRONOUN_WORDS:
			if text.contains(word):
				gendered.append("%s says '%s'" % [String(line.id), String(line.text)])
	ok(not_actions.is_empty(),
		"every Lancer line is an action direction (%s)" % ", ".join(not_actions))
	ok(gendered.is_empty(), "no Lancer line has a pronoun (%s)" % ", ".join(gendered))

	# Ilsa does not speak in the prequel. The prequel is P1 through P5, and
	# a prequel beat may not use one of her spoken lines.
	var prequel_speakers: Array = []
	for chapter in _array(_index, "chapters"):
		var key := _chapter_key(chapter.get("id", chapter.number))
		if not key.begins_with("P"):
			continue
		for section_number in range(1, 13):
			var section_id := "%s.%02d" % [key, section_number]
			var beat_path := "res://data/story/beats/%s.beat.json" % section_id
			if not FileAccess.file_exists(beat_path):
				continue
			var beat_document := _read_json(beat_path)
			for beat in _array(beat_document, "beats"):
				for line_id in beat.get("dialogue", []):
					var line := _line(String(line_id))
					if String(line.get("speaker_id", "")) == "ilsa_renn":
						prequel_speakers.append("%s uses %s" % [section_id, String(line_id)])
	ok(prequel_speakers.is_empty(),
		"ilsa says nothing in the prequel (%s)" % ", ".join(prequel_speakers))


## The dialogue line with this id.
func _line(line_id: String) -> Dictionary:
	for line in _array(_dialogue, "lines"):
		if String(line.id) == line_id:
			return line
	return {}


## The arsenal has to agree with the roster and with the acts.
func _test_the_arsenal() -> void:
	heading("the arsenal")
	var weapons := _array(_arsenal, "weapons")
	ok(weapons.size() >= 7, "the arsenal holds at least seven weapons (%d)" % weapons.size())

	var by_id := {}
	for weapon in weapons:
		by_id[String(weapon.id)] = weapon

	ok(by_id.has("p20_courier"), "the P-20 Courier is in the arsenal")
	ok(by_id.has("v9_vigil"), "the V-9 Vigil is in the arsenal")
	ok(by_id.has("m98_longhorn"), "the M98 Longhorn is in the arsenal")
	ok(by_id.has("m44_seam_splitter"), "the M-44 Seam-Splitter is in the arsenal")
	ok(by_id.has("k12_key"), "the K-12 Key is in the arsenal")
	ok(by_id.has("at7_goliath"), "the AT-7 Goliath is in the arsenal")
	ok(by_id.has("l01_arc_lance"), "the L-01 Arc-Lance is in the arsenal")

	# The two 9mm guns share ammunition, and the P-20 says so.
	ok(String(by_id["v9_vigil"].calibre) == "9mm", "the V-9 fires 9mm")
	ok(String(by_id["p20_courier"].calibre) == "9mm", "the P-20 fires 9mm")

	# Availability. The breaching charge is a prequel weapon, the shotgun
	# and the launcher are present-day, and the rail gun is second half.
	ok(_acts_are(by_id["m44_seam_splitter"], ["prequel"]),
		"the M-44 is prequel only")
	ok(_acts_are(by_id["k12_key"], ["main"]), "the K-12 is main game only")
	ok(_acts_are(by_id["at7_goliath"], ["main"]), "the AT-7 is main game only")
	ok(_acts_are(by_id["l01_arc_lance"], ["second_half_main"]),
		"the L-01 is second half main only")
	ok(_acts_are(by_id["p20_courier"], ["prequel", "main"]),
		"the P-20 is in both halves")
	ok(_acts_are(by_id["m98_longhorn"], ["prequel", "main"]),
		"the M98 is in both halves")

	# Only Ilsa gets the prequel-only gear, and only Lancer gets the
	# present-day-only gear.
	ok(_users_are(by_id["m44_seam_splitter"], ["ilsa_renn"]),
		"only Ilsa carries the M-44")
	ok(_users_are(by_id["k12_key"], ["lancer"]), "only Lancer carries the K-12")
	ok(_users_are(by_id["l01_arc_lance"], ["lancer"]), "only Lancer carries the L-01")

	# Every enemy a weapon names has to exist.
	var unknown: Array = []
	for weapon in weapons:
		for target in weapon.get("effective_against", []):
			var target_id := String(target)
			if not target_id.begins_with("concord_") and not target_id.begins_with("warp_"):
				continue
			if _enemy(target_id).is_empty():
				unknown.append("%s names %s" % [String(weapon.id), target_id])
	ok(unknown.is_empty(), "every enemy a weapon names is in the roster (%s)" % ", ".join(unknown))

	# The items and the map utilities.
	ok(_array(_arsenal, "items").size() >= 5, "the arsenal holds at least five usable items")
	ok(_array(_arsenal, "utilities").size() >= 5, "the world holds at least five map utilities")

	var item_ids := {}
	for item in _array(_arsenal, "items"):
		item_ids[String(item.id)] = item
	ok(item_ids.has("field_ration_trauma_kit"), "the ration and trauma kit are in the list")
	ok(item_ids.has("adrenaline_stim_pen"), "the stim-pen is in the list")
	ok(item_ids.has("emp_scrambler_flare"), "the scrambler flare is in the list")
	ok(item_ids.has("thermal_foil_cloak"), "the thermal-foil cloak is in the list")
	ok(item_ids.has("pneumatic_grapple_spool"), "the grapple spool is in the list")
	ok(_acts_are(item_ids["pneumatic_grapple_spool"], ["prequel"]),
		"the grapple spool is prequel only")
	ok(_acts_are(item_ids["adrenaline_stim_pen"], ["main"]),
		"the stim-pen is main game only")


## True when the weapon or item is available in exactly these parts.
func _acts_are(entry: Dictionary, expected: Array) -> bool:
	var acts: Array = []
	for act in entry.get("acts", []):
		acts.append(String(act))
	acts.sort()
	var wanted: Array = expected.duplicate()
	wanted.sort()
	return acts == wanted


## True when the weapon or item is carried by exactly these people.
func _users_are(entry: Dictionary, expected: Array) -> bool:
	var users: Array = []
	for user in entry.get("users", []):
		users.append(String(user))
	users.sort()
	var wanted: Array = expected.duplicate()
	wanted.sort()
	return users == wanted


## The roster has to hold the prequel threat and keep it out of the present
## day's later acts.
func _test_the_enemies() -> void:
	heading("the enemy roster")
	var enemies := _array(_enemies, "enemies")
	ok(enemies.size() >= 11, "the roster holds at least eleven enemies (%d)" % enemies.size())

	for enemy_id in PREQUEL_ENEMIES:
		var enemy := _enemy(enemy_id)
		ok(not enemy.is_empty(), enemy_id + " is in the roster")
		if enemy.is_empty():
			continue
		ok(_has_act(enemy, "prequel"), enemy_id + " exists in the prequel")
		ok(_has_act(enemy, "main"), enemy_id + " exists in the present day")

	for enemy_id in MAIN_ONLY_ENEMIES:
		var enemy := _enemy(enemy_id)
		ok(not enemy.is_empty(), enemy_id + " is in the roster")
		if enemy.is_empty():
			continue
		ok(not _has_act(enemy, "prequel"), enemy_id + " does not exist in the prequel")
		ok(_has_act(enemy, "main") or _has_act(enemy, "second_half_main"),
			enemy_id + " exists in the present day")

	# The Warp Synth's numbers.
	var synth := _enemy("warp_synth")
	ok(int(synth.get("health", 0)) == 200, "the Warp Synth has 200 HP")
	ok(synth.get("bullet_effective", true) == false, "the Warp Synth is immune to bullets")

	# The Dartbug and the Diver damage.
	ok(int(_enemy("concord_dartbug").get("damage", 0)) == 10, "the Dartbug stabs for 10")
	ok(int(_enemy("concord_diver").get("damage", 0)) == 20, "the Diver strikes for 20")
	ok(int(_enemy("concord_overwatch").get("damage", 0)) == 45, "the Overwatch hits for 45")

	# And the main-game threat does not turn up in the Fracture Year.
	var prequel_text := ""
	for chapter in _array(_index, "chapters"):
		var key := _chapter_key(chapter.get("id", chapter.number))
		if not key.begins_with("P"):
			continue
		prequel_text += " " + String(chapter.get("start", "")) + " " + String(chapter.get("play", "")) + " "
	for enemy_id in MAIN_ONLY_ENEMIES:
		var name := String(_enemy(enemy_id).get("name", ""))
		if name == "":
			continue
		ok(not prequel_text.contains(name),
			"%s does not turn up in the prequel" % name)


## True when the enemy is available in this part of the game.
func _has_act(enemy: Dictionary, act: String) -> bool:
	for value in enemy.get("acts", []):
		if String(value) == act:
			return true
	return false


## Health and speed, checked against the movement tuning file. Speed is in
## metres per second.
func _test_the_numbers() -> void:
	heading("the numbers")
	var health: Dictionary = _player.get("health", {})
	var speed: Dictionary = _player.get("speed", {})

	ok(int(health.get("base_max", 0)) == 100, "base health is 100")
	ok(int(health.get("overheal_max", 0)) == 150, "overheal caps at 150")
	ok(int(health.get("prequel_max", 0)) == 100, "ilsa is capped at 100 in the prequel")
	ok(int(health.get("stim_pen_overheal", 0)) == 25, "the stim-pen grants 25 overheal")
	ok(int(health.get("stim_pen_seconds", 0)) == 10, "the stim-pen lasts 10 seconds")
	ok(int(health.get("diver_cell_overheal", 0)) == 15, "the pneumatic cell grants 15 overheal")
	ok(int(health.get("high_energy_core_max_overheal", 0)) == 150,
		"the high-energy core grants the full overheal")

	ok(String(speed.get("unit", "")) == "m/s", "speed is in metres per second")
	ok(absf(float(speed.get("max_sprint", 0.0)) - Tuning.MAX_RUN_SPEED) < 0.001,
		"the sprint speed matches the tuning file")
	ok(int(speed.get("wall_jump_cap", 0)) == Tuning.WALL_KISS_CAP,
		"the wall-jump cap matches the tuning file")
	ok(absf(float(speed.get("wall_jump_ceiling", 0.0)) - Tuning.WALL_KISS_SPEED_CEILING) < 0.001,
		"the wall-jump ceiling matches the tuning file")
	ok(int(speed.get("wall_jump_fracture_cap", 0)) == Tuning.WALL_KISS_FRACTURE_CAP,
		"the Fracture wall-jump cap matches the tuning file")
	ok(absf(float(speed.get("wall_jump_fracture_ceiling", 0.0))
		- Tuning.WALL_KISS_FRACTURE_SPEED_CEILING) < 0.001,
		"the Fracture wall-jump ceiling matches the tuning file")
	ok(absf(float(speed.get("ram_shatter_impact", 0.0)) - 100.0) < 0.001,
		"a Concord Ram shatters at 100 m/s")
	ok(absf(float(speed.get("cloak_speed_threshold", 0.0)) - 8.0) < 0.001,
		"the thermal cloak breaks at 8 m/s")


## The design document has to know about the canon.
func _test_the_documents() -> void:
	heading("the documents")
	var missing_weapons: Array = []
	for weapon in _array(_arsenal, "weapons"):
		if not _design.contains(String(weapon.name)):
			missing_weapons.append(String(weapon.name))
	ok(missing_weapons.is_empty(),
		"the design document names every weapon (%s)" % ", ".join(missing_weapons))

	var missing_enemies: Array = []
	for enemy in _array(_enemies, "enemies"):
		var name := String(enemy.get("name", ""))
		if name == "":
			continue
		if not _design.contains(name):
			missing_enemies.append(name)
	ok(missing_enemies.is_empty(),
		"the design document names every enemy (%s)" % ", ".join(missing_enemies))

	var missing_items: Array = []
	for item in _array(_arsenal, "items"):
		if not _design.contains(String(item.name)):
			missing_items.append(String(item.name))
	ok(missing_items.is_empty(),
		"the design document names every usable item (%s)" % ", ".join(missing_items))

	var missing_characters: Array = []
	for character in _array(_cast, "characters"):
		var name := String(character.get("display_name", ""))
		if name == "":
			continue
		if not _design.contains(name):
			missing_characters.append(name)
	ok(missing_characters.is_empty(),
		"the design document names every character (%s)" % ", ".join(missing_characters))

	# The chapter titles, including the one that changed.
	var titles := {}
	for chapter in _array(_index, "chapters"):
		titles[_chapter_key(chapter.get("id", chapter.number))] = String(chapter.title)
	ok(titles.get("14", "") == "THE MONOLITH", "chapter 14 is THE MONOLITH")
	ok(titles.get("13", "") == "THE FRACTURE YARD", "chapter 13 is THE FRACTURE YARD")
	ok(titles.get("P5", "") == "ZERO CASUALTIES", "p5 is ZERO CASUALTIES")

	# Every chapter has an opening and a reason to exist.
	var thin: Array = []
	for chapter in _array(_index, "chapters"):
		if String(chapter.get("start", "")).strip_edges().length() < 40:
			thin.append(_chapter_key(chapter.get("id", chapter.number)))
		if String(chapter.get("play", "")).strip_edges().length() < 40:
			thin.append(_chapter_key(chapter.get("id", chapter.number)))
	ok(thin.is_empty(), "every chapter opens and plays (%s)" % ", ".join(thin))
