# WindShear — code policy tests
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
## These are the rules from `CONTRIBUTING.md` that a reviewer cannot check by
## reading a diff:
##
## [br]- every script carries the GPL notice, because the copyleft depends on it;
## [br]- gameplay code does not use global random numbers, because replays must match;
## [br]- frame loops do not allocate, because GC stutter ruins a run;
## [br]- frame loops do not `await`, because a coroutine frame loop is a bug.
##
## Allocation is checked in the shipped runtime code under `addons/windshear/`.
## Developer tools and the greybox HUD are exempt. A label that refreshes ten
## times a second is not a frame loop problem.
extends "res://tests/ws_test.gd"

## Gameplay code lives in these directories.
const GAMEPLAY_DIRS := ["res://addons/windshear", "res://world", "res://ui"]
## The frame-loop rule is enforced only in shipped runtime code.
const STRICT_DIRS := ["res://addons/windshear"]

## Global random functions do not belong in gameplay code.
const RANDOM_FUNCTIONS := ["randf_range", "randi_range", "randfn", "randf", "randi", "randomize"]

## Text that means something was allocated inside a frame loop.
const ALLOCATION_PATTERNS := [
	".new(", ".instantiate(", ".duplicate(", ".append(", ".filter(", ".map(",
	"= []", "= {}", "await ",
]


func suite_name() -> String:
	return "the code policy holds"


func run() -> void:
	_test_licence_headers()
	_test_no_global_random()
	_test_no_allocation_in_frame_loops()
	_test_documentation()


## Collects every GDScript file below [param path].
func _gd_files(path: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_gd_files(path.path_join(entry), out)
		elif entry.ends_with(".gd"):
			out.append(path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()


## Removes comments so a rule is not triggered by a sentence in a docstring.
func _without_comments(source: String) -> String:
	var lines := source.split("\n")
	var kept := PackedStringArray()
	for line in lines:
		var hash_index := line.find("#")
		if hash_index >= 0:
			line = line.substr(0, hash_index)
		kept.append(line)
	return "\n".join(kept)


## Returns the name of the global random function found in [param source].
func _find_global_random(source: String) -> String:
	for entry in RANDOM_FUNCTIONS:
		var function_name := String(entry)
		var from := 0
		while true:
			var index: int = source.find(function_name, from)
			if index < 0:
				break
			from = index + 1
			var after: int = index + function_name.length()
			if after >= source.length() or source[after] != "(":
				continue
			var before := ""
			if index > 0:
				before = source[index - 1]
			if before == "." or before == "_" or _is_word_character(before):
				continue
			return function_name
	return ""


func _is_word_character(character: String) -> bool:
	if character == "":
		return false
	var code := character.unicode_at(0)
	return (code >= 97 and code <= 122) or (code >= 65 and code <= 90) or (code >= 48 and code <= 57)


## Returns the bodies of every `_process` and `_physics_process` in a file.
func _frame_loop_bodies(source: String) -> PackedStringArray:
	var bodies := PackedStringArray()
	var lines := source.split("\n")
	var index := 0
	while index < lines.size():
		var line := lines[index]
		if line.begins_with("func _process") or line.begins_with("func _physics_process"):
			var body := PackedStringArray()
			index += 1
			while index < lines.size() and not lines[index].begins_with("func "):
				body.append(lines[index])
				index += 1
			bodies.append("\n".join(body))
			continue
		index += 1
	return bodies


func _test_licence_headers() -> void:
	heading("licence headers")
	var files := PackedStringArray()
	_gd_files("res://", files)
	ok(files.size() >= 8, "the project has scripts to check (%d found)" % files.size())
	var missing := PackedStringArray()
	for path in files:
		var source := FileAccess.get_file_as_string(path)
		var header := source.substr(0, 1000)
		if not header.contains("GNU General Public License") \
				or not header.contains("Copyright (C) 2026"):
			missing.append(path)
	same(missing.size(), 0, "every script carries the GPL notice: " + ", ".join(missing))


func _test_no_global_random() -> void:
	heading("no global random numbers")
	var offenders := PackedStringArray()
	for directory in GAMEPLAY_DIRS:
		var files := PackedStringArray()
		_gd_files(directory, files)
		for path in files:
			var source := _without_comments(FileAccess.get_file_as_string(path))
			var found := _find_global_random(source)
			if found != "":
				offenders.append("%s uses %s()" % [path, found])
	same(offenders.size(), 0, "gameplay code uses the seeded generator only: " + ", ".join(offenders))


func _test_no_allocation_in_frame_loops() -> void:
	heading("no allocation in the frame loops")
	var offenders := PackedStringArray()
	for directory in STRICT_DIRS:
		var files := PackedStringArray()
		_gd_files(directory, files)
		for path in files:
			var source := FileAccess.get_file_as_string(path)
			for body in _frame_loop_bodies(source):
				var code := _without_comments(body)
				for pattern in ALLOCATION_PATTERNS:
					if code.contains(pattern):
						offenders.append("%s contains '%s' in a frame loop" % [path, pattern])
	same(offenders.size(), 0, "the frame loops allocate nothing: " + ", ".join(offenders))


func _test_documentation() -> void:
	heading("the documentation")
	var readme := FileAccess.get_file_as_string("res://README.md")
	ok(readme.contains("GPL-2.0-or-later"), "the README names the code licence")
	ok(readme.contains("CC-BY-SA 4.0"), "the README names the content licence")

	var licence := FileAccess.get_file_as_string("res://LICENSE")
	ok(licence.contains("GNU GENERAL PUBLIC LICENSE"), "the LICENSE is the GPL")

	var notice := FileAccess.get_file_as_string("res://NOTICE")
	ok(notice.contains("Godot"), "the NOTICE credits the engine")

	var spec := FileAccess.get_file_as_string("res://TECH_SPEC.md")
	ok(spec.contains("4 GB"), "the memory ceiling is documented")
	ok(spec.contains("14.0 m/s"), "the run speed is documented")
