# WindShear — world data tests
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
## The section grid, gate schedule and story layer are JSON that the game
## reads at boot. A typo in an id does not crash anything. It quietly takes a
## level out of the campaign, which is the kind of bug that survives to a
## release, so the grid gets checked here.
##
## The campaign is 25 chapters of 12 sections in seven acts. Act 0 is the
## Fracture Year prequel, P1 through P5.
##
## The checks cover:
## [br]- 25 chapters of 12 sections, numbered P1.01 through P5.12 and 1.01 through 20.12;
## [br]- every section has a gate in the schedule, and every gate has a window;
## [br]- every beat points at a section that exists;
## [br]- every ending points at a section and a Fracture that exist.
##
## The loops collect everything that is wrong and report it in one failure
## message. A suite that prints two hundred identical failures is a suite
## nobody reads.
extends "res://tests/ws_test.gd"

## The campaign has twenty-five chapters.
const CHAPTER_COUNT := 25
## The present day runs from chapter 1 to chapter 20.
const PRESENT_CHAPTER_COUNT := 20
## The campaign runs in seven acts: Act 0 is the prequel, Acts I to VI are
## the present day.
const ACT_COUNT := 7
## Act 0: the five Fracture Year prequel chapters, played as Ilsa Renn.
## Ilsa says nothing in any of them.
const PREQUEL_CHAPTERS := ["P1", "P2", "P3", "P4", "P5"]
## The number of sections in every chapter.
const SECTIONS_PER_CHAPTER := 12
## The number of Fractures a player has to know for the hidden ending.
const FRACTURE_COUNT := 12

## The section index.
const INDEX_PATH := "res://data/sections/index.json"
## The gate schedule.
const SCHEDULE_PATH := "res://data/schedule.json"
## The Fracture registry.
const FRACTURES_PATH := "res://data/fractures.json"
## The ending table.
const ENDINGS_PATH := "res://data/story/endings.json"
## The English dialogue.
const DIALOGUE_PATH := "res://data/story/dialogue/en.json"

## The parsed section index.
var _index: Dictionary = {}
## The parsed gate schedule.
var _schedule: Dictionary = {}
## The parsed Fracture registry.
var _fractures: Dictionary = {}
## The parsed ending table.
var _endings: Dictionary = {}
## The parsed dialogue.
var _dialogue: Dictionary = {}

## Every section id in the index.
var _section_ids: Dictionary = {}
## Every Fracture id in the registry.
var _fracture_ids: Dictionary = {}
## Every dialogue id.
var _dialogue_ids: Dictionary = {}
## Every speaker id.
var _speaker_ids: Dictionary = {}


func suite_name() -> String:
	return "the world data holds together"


func run() -> void:
	_read_the_data()
	_test_the_grid_shape()
	_test_the_grid_numbers()
	_test_the_schedule()
	_test_the_fractures()
	_test_the_endings()
	_test_the_beats()


## Reads the five JSON files the world is built out of.
func _read_the_data() -> void:
	_index = _read_json(INDEX_PATH)
	_schedule = _read_json(SCHEDULE_PATH)
	_fractures = _read_json(FRACTURES_PATH)
	_endings = _read_json(ENDINGS_PATH)
	_dialogue = _read_json(DIALOGUE_PATH)

	for section in _array(_index, "sections"):
		_section_ids[section.id] = section
	for fracture in _array(_fractures, "fractures"):
		_fracture_ids[fracture.id] = fracture
	for line in _array(_dialogue, "lines"):
		_dialogue_ids[line.id] = line
	for speaker in _array(_dialogue, "speakers"):
		_speaker_ids[speaker.id] = speaker


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


## The chapter key as a string. JSON numbers arrive as floats, so a number is
## forced back to an int first. The prequel chapters are strings already.
func _chapter_key(value) -> String:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return str(int(value))
	return str(value)


## Every chapter key the grid is allowed to use.
func _known_chapter_keys() -> Dictionary:
	var known := {}
	for chapter in PREQUEL_CHAPTERS:
		known[chapter] = true
	for chapter in range(1, PRESENT_CHAPTER_COUNT + 1):
		known[str(chapter)] = true
	return known


## Joins a list of problems into one readable sentence.
func _list_problems(problems: Array) -> String:
	if problems.is_empty():
		return ""
	if problems.size() <= 6:
		return ", ".join(problems)
	return "%s and %d more" % [", ".join(problems.slice(0, 6)), problems.size() - 6]


## The grid is twenty-five chapters of twelve, with no gaps.
func _test_the_grid_shape() -> void:
	heading("the shape of the grid")
	var sections := _array(_index, "sections")
	var chapters := _array(_index, "chapters")
	same(sections.size(), CHAPTER_COUNT * SECTIONS_PER_CHAPTER,
		"the grid holds twenty-five chapters of twelve sections")
	same(chapters.size(), CHAPTER_COUNT, "the index lists twenty-five chapters")
	same(int(_index.get("_meta", {}).get("chapter_count", 0)), CHAPTER_COUNT,
		"the index metadata agrees")

	# Seven acts, and the act numbers have to be the ones we ship: 0 for the
	# Fracture Year prequel and 1 to 6 for the present day.
	same(int(_index.get("_meta", {}).get("act_count", 0)), ACT_COUNT,
		"the index metadata records seven acts")
	var act_numbers: Array = []
	for chapter in chapters:
		var act := int(chapter.get("act", -1))
		if not act_numbers.has(act):
			act_numbers.append(act)
	act_numbers.sort()
	var wanted_acts := []
	for act in range(0, ACT_COUNT):
		wanted_acts.append(act)
	text(str(act_numbers), str(wanted_acts),
		"the chapters cover acts 0 to 6 with none missing")

	# The ids have to run P1.01 to P5.12 and 1.01 to 20.12 with nothing
	# skipped, and nothing outside that range.
	var missing: Array = []
	for chapter in PREQUEL_CHAPTERS:
		for number in range(1, SECTIONS_PER_CHAPTER + 1):
			var wanted := "%s.%02d" % [chapter, number]
			if not _section_ids.has(wanted):
				missing.append(wanted)
	for chapter in range(1, PRESENT_CHAPTER_COUNT + 1):
		for number in range(1, SECTIONS_PER_CHAPTER + 1):
			var wanted := "%d.%02d" % [chapter, number]
			if not _section_ids.has(wanted):
				missing.append(wanted)
	ok(missing.is_empty(),
		"every section from P1.01 to 20.12 is in the index (missing: %s)" % _list_problems(missing))

	var known := _known_chapter_keys()
	var unexpected: Array = []
	for section in sections:
		var parts := String(section.id).split(".")
		if parts.size() != 2:
			unexpected.append(String(section.id))
			continue
		var number := int(parts[1])
		if number < 1 or number > SECTIONS_PER_CHAPTER:
			unexpected.append(String(section.id))
			continue
		if not known.has(parts[0]):
			unexpected.append(String(section.id))
	ok(unexpected.is_empty(),
		"no section sits outside the grid (stray: %s)" % _list_problems(unexpected))

	# Every chapter has to hold exactly twelve sections. The chapter key is a
	# string, because the prequel chapters are named and the rest are numbered.
	var counts := {}
	for section in sections:
		var key := _chapter_key(section.chapter)
		counts[key] = int(counts.get(key, 0)) + 1
	var uneven: Array = []
	for key in known:
		if int(counts.get(key, 0)) != SECTIONS_PER_CHAPTER:
			uneven.append("%s has %d" % [key, int(counts.get(key, 0))])
	ok(uneven.is_empty(), "every chapter holds twelve sections (%s)" % _list_problems(uneven))

	# The prequel belongs to Act 0 and is played as Ilsa Renn. The present day
	# is played as Lancer.
	var bad_players: Array = []
	var bad_acts: Array = []
	for chapter in chapters:
		var key := _chapter_key(chapter.get("id", chapter.number))
		if key.begins_with("P"):
			if chapter.get("player", "") != "ilsa_renn":
				bad_players.append(key)
			if int(chapter.get("act", -1)) != 0:
				bad_acts.append(key)
		elif int(chapter.get("act", -1)) < 1:
			bad_acts.append(key)
	ok(bad_players.is_empty(),
		"the prequel is played as Ilsa Renn (%s)" % _list_problems(bad_players))
	ok(bad_acts.is_empty(), "every chapter sits in an act (%s)" % _list_problems(bad_acts))


## The per-section fields have to be sane.
func _test_the_grid_numbers() -> void:
	heading("the numbers on the sections")
	var bad_numbers: Array = []
	var bad_names: Array = []
	var bad_paths: Array = []
	var bad_difficulty: Array = []

	for section in _array(_index, "sections"):
		var sid := String(section.id)
		if section.difficulty < 1 or section.difficulty > 10:
			bad_difficulty.append(sid)
		if section.par_time_frames <= 0:
			bad_numbers.append(sid)
		if String(section.display_name).strip_edges() == "":
			bad_names.append(sid)

		# The scene path has to agree with the chapter and the number.
		var key := _chapter_key(section.chapter)
		var number := int(sid.split(".")[1])
		var wanted := "res://data/sections/c%s/s%s_%02d.tscn" % [key, key, number]
		if section.scene_path != wanted:
			bad_paths.append("%s points at %s" % [sid, section.scene_path])

	ok(bad_difficulty.is_empty(),
		"every section has a difficulty on the 1-10 scale (%s)" % _list_problems(bad_difficulty))
	ok(bad_numbers.is_empty(), "every section has a par time (%s)" % _list_problems(bad_numbers))
	ok(bad_names.is_empty(), "every section has a name (%s)" % _list_problems(bad_names))
	ok(bad_paths.is_empty(), "every section points at the right scene (%s)" % _list_problems(bad_paths))

	var untitled: Array = []
	for chapter in _array(_index, "chapters"):
		if String(chapter.title).strip_edges() == "":
			untitled.append(str(chapter.number))
	ok(untitled.is_empty(), "every chapter has a title (%s)" % _list_problems(untitled))


## The schedule has to cover the grid, and the windows have to make sense.
func _test_the_schedule() -> void:
	heading("the gate schedule")
	var chapters := _array(_schedule, "chapters")
	same(chapters.size(), CHAPTER_COUNT, "the schedule covers twenty-five chapters")

	var scheduled := {}
	var bad_counts: Array = []
	var no_gates: Array = []
	var bad_gate_names: Array = []
	var bad_windows: Array = []
	var bad_states: Array = []
	var bad_periods: Array = []

	for chapter in chapters:
		if chapter.sections.size() != SECTIONS_PER_CHAPTER:
			bad_counts.append("%s schedules %d" % [_chapter_key(chapter.chapter), chapter.sections.size()])
		for section in chapter.sections:
			scheduled[section.section_id] = section
			if section.gates.is_empty():
				no_gates.append(String(section.section_id))
			for gate in section.gates:
				if not String(gate.gate_id).begins_with(String(section.section_id) + "."):
					bad_gate_names.append(String(gate.gate_id))
				if gate.windows.is_empty():
					bad_windows.append("%s has no window" % gate.gate_id)
				for window in gate.windows:
					if window.state != "open" and window.state != "closed":
						bad_states.append("%s is %s" % [gate.gate_id, window.state])
					if window.end_frame != null and window.start_frame >= window.end_frame:
						bad_windows.append("%s has a window that ends before it starts" % gate.gate_id)
				if gate.state == "cycling" and gate.cycle_period_frames <= 0:
					bad_periods.append(String(gate.gate_id))

	ok(bad_counts.is_empty(), "every chapter schedules twelve sections (%s)" % _list_problems(bad_counts))
	ok(no_gates.is_empty(), "every section has a gate (%s)" % _list_problems(no_gates))
	ok(bad_gate_names.is_empty(),
		"every gate belongs to its section (%s)" % _list_problems(bad_gate_names))
	ok(bad_windows.is_empty(), "every gate window makes sense (%s)" % _list_problems(bad_windows))
	ok(bad_states.is_empty(), "every gate window is open or closed (%s)" % _list_problems(bad_states))
	ok(bad_periods.is_empty(),
		"every cycling gate has a period (%s)" % _list_problems(bad_periods))

	# Every section in the grid is scheduled, and nothing else is.
	var unscheduled: Array = []
	for section in _array(_index, "sections"):
		if not scheduled.has(section.id):
			unscheduled.append(String(section.id))
	ok(unscheduled.is_empty(),
		"every section in the grid is scheduled (%s)" % _list_problems(unscheduled))

	var orphans: Array = []
	for section_id in scheduled:
		if not _section_ids.has(section_id):
			orphans.append(String(section_id))
	ok(orphans.is_empty(),
		"nothing is scheduled that is not in the grid (%s)" % _list_problems(orphans))


## The Fracture registry has to hold its own rules together.
func _test_the_fractures() -> void:
	heading("the Fractures")
	var fractures := _array(_fractures, "fractures")
	same(fractures.size(), FRACTURE_COUNT, "there are twelve Fractures in the registry")

	var incomplete: Array = []
	var duplicated: Array = []
	var seen := {}
	for fracture in fractures:
		var fid := String(fracture.id)
		if seen.has(fid):
			duplicated.append(fid)
		seen[fid] = true
		if fid.strip_edges() == "" or String(fracture.display_name).strip_edges() == "":
			incomplete.append(fid + " has no name")
		if fracture.version < 1:
			incomplete.append(fid + " has no version")
		if String(fracture.trigger).strip_edges() == "":
			incomplete.append(fid + " has no trigger")
		if String(fracture.effect).strip_edges() == "":
			incomplete.append(fid + " has no effect")
	ok(incomplete.is_empty(), "every Fracture is complete (%s)" % _list_problems(incomplete))
	ok(duplicated.is_empty(), "no Fracture id is used twice (%s)" % _list_problems(duplicated))


## The ending table has to point at things that exist.
func _test_the_endings() -> void:
	heading("the endings")
	var endings := _array(_endings, "endings")
	ok(endings.size() >= 3, "there are at least three endings")

	var final_choices := {}
	for choice in _array(_endings, "final_choices"):
		final_choices[choice.id] = choice
	ok(final_choices.size() >= 2, "there are at least two final choices")

	var bad_choices: Array = []
	var bad_fractures: Array = []
	var bad_counts: Array = []
	var bad_sections: Array = []
	var no_text: Array = []

	for ending in endings:
		var eid := String(ending.id)
		if String(ending.ending_text).strip_edges() == "":
			no_text.append(eid)
		for condition in ending.conditions.get("all_of", []):
			match condition.type:
				"final_choice":
					if not final_choices.has(condition.equals):
						bad_choices.append("%s names the choice %s" % [eid, condition.equals])
				"fracture_known":
					if not _fracture_ids.has(condition.id):
						bad_fractures.append("%s names the Fracture %s" % [eid, condition.id])
				"fracture_known_count":
					var equals := int(condition.get("equals", -1))
					var below := int(condition.get("less_than", -1))
					if equals != FRACTURE_COUNT and below != FRACTURE_COUNT:
						bad_counts.append("%s counts against %d" % [eid, FRACTURE_COUNT])
				"section_reached":
					if not _section_ids.has(condition.id):
						bad_sections.append("%s waits for %s" % [eid, condition.id])

	ok(no_text.is_empty(), "every ending has text (%s)" % _list_problems(no_text))
	ok(bad_choices.is_empty(), "every ending names a real final choice (%s)" % _list_problems(bad_choices))
	ok(bad_fractures.is_empty(), "every ending names a real Fracture (%s)" % _list_problems(bad_fractures))
	ok(bad_counts.is_empty(),
		"every ending counts against the real Fracture total (%s)" % _list_problems(bad_counts))
	ok(bad_sections.is_empty(), "every ending waits for a real section (%s)" % _list_problems(bad_sections))


## Every beat has to point at a real section and real dialogue.
func _test_the_beats() -> void:
	heading("the beats")
	var beat_files := _beat_files()
	ok(beat_files.size() > 0, "there are beat files")

	var bad_sections: Array = []
	var bad_names: Array = []
	var bad_dialogue: Array = []
	var silent: Array = []
	var bad_speakers: Array = []

	for path in beat_files:
		var parsed := _read_json(path)
		if parsed.is_empty():
			continue

		var sid := String(parsed.get("section_id", ""))
		if not _section_ids.has(sid):
			bad_sections.append("%s points at %s" % [path.get_file(), sid])
		for beat in _array(parsed, "beats"):
			var bid := String(beat.id)
			if not bid.begins_with(sid + "."):
				bad_names.append(bid)
			if beat.get("dialogue", []).is_empty():
				silent.append(bid)
			for line_id in beat.get("dialogue", []):
				if not _dialogue_ids.has(line_id):
					bad_dialogue.append("%s names %s" % [bid, line_id])
			for actor in beat.get("actors", []):
				if String(actor.actor_id).strip_edges() == "":
					bad_speakers.append(bid + " has an actor with no id")

	ok(bad_sections.is_empty(),
		"every beat points at a real section (%s)" % _list_problems(bad_sections))
	ok(bad_names.is_empty(),
		"every beat is named after its section (%s)" % _list_problems(bad_names))
	ok(silent.is_empty(), "every beat has dialogue (%s)" % _list_problems(silent))
	ok(bad_dialogue.is_empty(),
		"every beat names real dialogue lines (%s)" % _list_problems(bad_dialogue))
	ok(bad_speakers.is_empty(),
		"every actor in a beat has an id (%s)" % _list_problems(bad_speakers))

	# And every line has a speaker who exists.
	var orphan_lines: Array = []
	for line in _array(_dialogue, "lines"):
		if not _speaker_ids.has(line.speaker_id):
			orphan_lines.append("%s is spoken by %s" % [line.id, line.speaker_id])
	ok(orphan_lines.is_empty(),
		"every dialogue line has a real speaker (%s)" % _list_problems(orphan_lines))


## Every beat file in the story tree.
func _beat_files() -> PackedStringArray:
	var found := PackedStringArray()
	var directory := DirAccess.open("res://data/story/beats")
	if directory == null:
		return found
	for file_name in directory.get_files():
		if file_name.ends_with(".json"):
			found.append("res://data/story/beats/" + file_name)
	return found
