# WindShear — reads a Quake-style map file
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
## Reads a `.map` file, the kind TrenchBroom writes.
##
## A map file is text. It is a list of entities, and an entity is a list of
## properties and brushes. A brush is a list of faces, and a face is three
## points that say where a plane is, the name of the material on it and a
## few numbers about the texture.
##
## Two shapes of face are read:
##
## [codeblock]
## Standard: ( x y z ) ( x y z ) ( x y z ) MATERIAL xoff yoff rot xscale yscale
## Valve:   ( x y z ) ( x y z ) ( x y z ) MATERIAL [ ux uy uz uoff ] [ vx vy vz voff ] rot xscale yscale
## [/codeblock]
##
## The parser does not decide what a map means. It reads it into plain
## dictionaries and arrays, so the importer can decide what a floor is and
## the tests can check what was read without a scene tree.
##
## Everything here is in map units. The importer is the one that turns map
## units into metres.
class_name WSMapParser
extends RefCounted

## What the parser read.
##
## "entities" is a list of entity dictionaries. "problems" is a list of
## lines saying what could not be read.
const RESULT_KEY_ENTITIES := "entities"
const RESULT_KEY_PROBLEMS := "problems"

## The kinds of token the scanner hands back.
const TOKEN_STRING := "string"
const TOKEN_NUMBER := "number"
const TOKEN_PUNCT := "punct"
const TOKEN_END := "end"

## The text being read.
var _text := ""

## Where the scanner is in the text.
var _at := 0

## The line the scanner is on, for the messages.
var _line := 1

## What could not be read.
var problems: PackedStringArray = []


## Reads a map file from disk.
##
## The path may be anywhere on the disk. A map file does not have to live
## inside the project.
func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			RESULT_KEY_ENTITIES: [],
			RESULT_KEY_PROBLEMS: PackedStringArray(["the map file %s is not there" % path]),
		}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			RESULT_KEY_ENTITIES: [],
			RESULT_KEY_PROBLEMS: PackedStringArray(["the map file %s could not be read" % path]),
		}
	return parse_text(file.get_as_text())


## Reads a map out of a string.
##
## Returns a dictionary with "entities" and "problems" in it.
func parse_text(text: String) -> Dictionary:
	_text = text
	_at = 0
	_line = 1
	problems = PackedStringArray()

	var entities: Array = []
	while true:
		var token := _next_token()
		if token["type"] == TOKEN_END:
			break
		if token["type"] != TOKEN_PUNCT or str(token["value"]) != "{":
			_complain("expected an entity", int(token["line"]))
			break
		entities.append(_read_entity())

	return {
		RESULT_KEY_ENTITIES: entities,
		RESULT_KEY_PROBLEMS: problems,
	}


## Reads one entity, the braces are already eaten.
func _read_entity() -> Dictionary:
	var entity := {
		"classname": "",
		"properties": {},
		"origin": Vector3.ZERO,
		"angle": 0.0,
		"brushes": [],
	}

	while true:
		var token := _next_token()
		var kind := str(token["type"])
		if kind == TOKEN_END:
			_complain("the entity was never closed", int(token["line"]))
			break
		if kind == TOKEN_PUNCT:
			var mark := str(token["value"])
			if mark == "}":
				break
			if mark == "{":
				entity["brushes"].append(_read_brush())
				continue
			_complain("unexpected %s in an entity" % mark, int(token["line"]))
			continue

		# A property: a name and a value.
		var key := str(token["value"])
		var value_token := _next_token()
		var value := ""
		if str(value_token["type"]) == TOKEN_NUMBER:
			value = str(value_token["value"])
			# An unquoted value may be several numbers, like `origin 0 0 24`.
			while true:
				var ahead := _peek_token()
				if str(ahead["type"]) != TOKEN_NUMBER:
					break
				value += " " + str(_next_token()["value"])
		elif str(value_token["type"]) == TOKEN_STRING:
			value = str(value_token["value"])
		else:
			_complain("the property %s has no value" % key, int(token["line"]))
		entity["properties"][key] = value

	entity["classname"] = str(entity["properties"].get("classname", ""))
	entity["origin"] = _read_origin(entity["properties"])
	entity["angle"] = _read_angle(entity["properties"])
	return entity


## Reads one brush, the opening brace is already eaten.
func _read_brush() -> Dictionary:
	var brush := {
		"faces": [],
		"material": "",
	}

	while true:
		var ahead := _peek_token()
		var kind := str(ahead["type"])
		if kind == TOKEN_END:
			_next_token()
			_complain("the brush was never closed", int(ahead["line"]))
			break
		if kind == TOKEN_PUNCT:
			var mark := str(ahead["value"])
			if mark == "}":
				_next_token()
				break
			if mark == "(":
				brush["faces"].append(_read_face())
				continue
			_next_token()
			_complain("unexpected %s in a brush" % mark, int(ahead["line"]))
			continue
		_next_token()
		_complain("unexpected text in a brush", int(ahead["line"]))

	# The material of the first face is the material of the brush, and it
	# is what the designer named the piece with.
	if not brush["faces"].is_empty():
		brush["material"] = str(brush["faces"][0].get("material", ""))
	return brush


## Reads one face. A face is three points in brackets.
func _read_face() -> Dictionary:
	var face := {
		"points": [],
		"material": "",
		"axes": [],
		"offset": Vector2.ZERO,
		"rotation": 0.0,
		"scale": Vector2.ONE,
	}

	for index in 3:
		var point: Variant = _read_point()
		if point == null:
			return face
		face["points"].append(point)

	var material_token := _next_token()
	if str(material_token["type"]) == TOKEN_STRING or str(material_token["type"]) == TOKEN_NUMBER:
		face["material"] = str(material_token["value"])
	else:
		_complain("the face has no material", int(material_token["line"]))

	# The Valve shape puts the two texture axes in brackets and the offsets
	# inside them. The Standard shape puts five plain numbers there and
	# leaves the axes out. Some writers put the axes after the numbers and
	# some put them before, so both orders are read.
	var ahead := _peek_token()
	if str(ahead["type"]) == TOKEN_PUNCT and str(ahead["value"]) == "[":
		face["axes"] = [_read_axis(), _read_axis()]
		face["rotation"] = _read_number()
		face["scale"] = Vector2(_read_number(), _read_number())
		var extra := _peek_token()
		if str(extra["type"]) == TOKEN_NUMBER:
			face["offset"] = Vector2(_read_number(), _read_number())
	else:
		face["offset"] = Vector2(_read_number(), _read_number())
		face["rotation"] = _read_number()
		face["scale"] = Vector2(_read_number(), _read_number())
		var extra := _peek_token()
		if str(extra["type"]) == TOKEN_PUNCT and str(extra["value"]) == "[":
			face["axes"] = [_read_axis(), _read_axis()]

	# Quake 2 writes three more numbers on the face. They are about the
	# surface and WindShear has no use for them, but they have to be eaten
	# so the next face is read from the right place.
	for index in 3:
		var extra := _peek_token()
		if str(extra["type"]) != TOKEN_NUMBER:
			break
		_next_token()

	return face


## Reads three numbers in brackets.
##
## Returns the place, or nothing when the numbers are not there.
func _read_point() -> Variant:
	var open := _next_token()
	if not (str(open["type"]) == TOKEN_PUNCT and str(open["value"]) == "("):
		_complain("a point did not open with a bracket", int(open["line"]))
		return null

	var values: Array = []
	for index in 3:
		var token := _next_token()
		if str(token["type"]) != TOKEN_NUMBER:
			_complain("a point is not three numbers: got %s '%s'" % [
				str(token["type"]), str(token["value"])], int(token["line"]))
			return null
		values.append(float(str(token["value"])))
	var close := _next_token()
	if not (str(close["type"]) == TOKEN_PUNCT and str(close["value"]) == ")"):
		_complain("a point was not closed", int(close["line"]))
	return Vector3(values[0], values[1], values[2])


## Reads four numbers in brackets.
func _read_axis() -> Array:
	var open := _next_token()
	if not (str(open["type"]) == TOKEN_PUNCT and str(open["value"]) == "["):
		_complain("a texture axis did not open with a bracket", int(open["line"]))
		return []

	var values: Array = []
	for index in 4:
		var token := _next_token()
		if str(token["type"]) != TOKEN_NUMBER:
			_complain("a texture axis is not four numbers", int(token["line"]))
			return values
		values.append(float(str(token["value"])))
	var close := _next_token()
	if not (str(close["type"]) == TOKEN_PUNCT and str(close["value"]) == "]"):
		_complain("a texture axis was not closed", int(close["line"]))
	return values


## Reads one number, and says so when there is not one there.
func _read_number() -> float:
	var token := _next_token()
	if str(token["type"]) != TOKEN_NUMBER:
		_complain("a number was expected", int(token["line"]))
		return 0.0
	return float(str(token["value"]))


## The place of an entity, from its origin property.
func _read_origin(properties: Dictionary) -> Vector3:
	var text := str(properties.get("origin", ""))
	if text.is_empty():
		return Vector3.ZERO
	var parts := text.split(" ", false)
	if parts.size() < 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


## Which way an entity faces, in degrees.
##
## An entity has either an angle or three angles. The three are pitch, yaw
## and roll, and only the yaw is a turn around the floor.
func _read_angle(properties: Dictionary) -> float:
	var angle := str(properties.get("angle", ""))
	if not angle.is_empty():
		return float(angle)
	var angles := str(properties.get("angles", ""))
	if angles.is_empty():
		return 0.0
	var parts := angles.split(" ", false)
	if parts.size() < 2:
		return 0.0
	return float(parts[1])


## Takes the next token off the text.
func _next_token() -> Dictionary:
	_skip_the_gaps()
	if _at >= _text.length():
		return {"type": TOKEN_END, "value": "", "line": _line}

	var character := _text[_at]
	if character == "{" or character == "}" or character == "(" or character == ")" \
			or character == "[" or character == "]":
		_at += 1
		return {"type": TOKEN_PUNCT, "value": character, "line": _line}

	if character == "\"":
		_at += 1
		var start := _at
		while _at < _text.length():
			var inner := _text[_at]
			if inner == "\\" and _at + 1 < _text.length():
				_at += 2
				continue
			if inner == "\"":
				var value := _text.substr(start, _at - start)
				_at += 1
				return {"type": TOKEN_STRING, "value": value, "line": _line}
			if inner == "\n":
				break
			_at += 1
		_complain("a quoted string was never closed", _line)
		return {"type": TOKEN_STRING, "value": _text.substr(start, _at - start), "line": _line}

	var start := _at
	while _at < _text.length() and not _is_space(_text[_at]) \
			and _text[_at] != "{" and _text[_at] != "}" and _text[_at] != "(" \
			and _text[_at] != ")" and _text[_at] != "[" and _text[_at] != "]":
		_at += 1
	var word := _text.substr(start, _at - start)
	if _is_a_number(word):
		return {"type": TOKEN_NUMBER, "value": word, "line": _line}
	return {"type": TOKEN_STRING, "value": word, "line": _line}


## Looks at the next token without eating it.
func _peek_token() -> Dictionary:
	var mark := _at
	var line := _line
	var token := _next_token()
	_at = mark
	_line = line
	return token


## Skips the spaces and the comments.
func _skip_the_gaps() -> void:
	while _at < _text.length():
		var character := _text[_at]
		if character == "\n":
			_line += 1
			_at += 1
			continue
		if _is_space(character):
			_at += 1
			continue
		# A comment runs to the end of the line.
		if character == "/" and _at + 1 < _text.length() and _text[_at + 1] == "/":
			while _at < _text.length() and _text[_at] != "\n":
				_at += 1
			continue
		# Heretic 2 lets a semicolon start a comment.
		if character == ";":
			while _at < _text.length() and _text[_at] != "\n":
				_at += 1
			continue
		return


## Whether a character is a space.
func _is_space(character: String) -> bool:
	return character == " " or character == "\t" or character == "\r" \
		or character == "\n" or character == "\v" or character == "\f"


## Whether a word is a number.
func _is_a_number(word: String) -> bool:
	if word.is_empty():
		return false
	var seen_digit := false
	var seen_dot := false
	for index in word.length():
		var character := word[index]
		if character >= "0" and character <= "9":
			seen_digit = true
			continue
		if character == ".":
			if seen_dot:
				return false
			seen_dot = true
			continue
		if character == "-" or character == "+":
			if index != 0:
				return false
			continue
		if character == "e" or character == "E":
			if not seen_digit:
				return false
			continue
		return false
	return seen_digit


## Says what went wrong.
func _complain(text: String, line: int) -> void:
	problems.append("line %d: %s" % [line, text])
