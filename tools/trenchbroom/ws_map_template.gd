# WindShear — writes a starter map for a section
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
## Writes a map file a designer can open in TrenchBroom and draw in.
##
## The file has a room, the points the section needs and a comment that
## says what the names mean. It is the same format the converter reads,
## because TrenchBroom writes the same format.
##
## [codeblock]
## godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- --template P1.02
## [/codeblock]
class_name WSMapTemplate
extends RefCounted

## The builder, which knows the gates a section has.
const Builder := preload("res://addons/level_tools/ws_section_builder.gd")

## How many map units are in a metre.
const DEFAULT_UNITS_PER_METRE := 32.0

## How big the room in the template is, in metres.
const ROOM_SIZE := Vector3(40.0, 12.0, 24.0)

## How thick the floor of the template is, in metres.
const FLOOR_THICKNESS := 0.5

## How thick the walls of the template are, in metres.
const WALL_THICKNESS := 0.5

## The map of a section, as text.
##
## The room is empty and the points are where the builder puts them. The
## designer moves them and draws the room.
static func build(section_id: String, units_per_metre := DEFAULT_UNITS_PER_METRE) -> String:
	var lines := PackedStringArray()
	lines.append("// WindShear section %s" % section_id)
	lines.append("// Game: WindShear")
	lines.append("// Format: Valve")
	lines.append("//")
	lines.append("// This is the base of the section: the floor, the walls and the points")
	lines.append("// the game reads. The textures are not here; they are made in Godot.")
	lines.append("//")
	lines.append("// The points are placed by hand. These are the names WindShear knows:")
	lines.append("//")
	lines.append("//   func_checkpoint_start   where the player starts")
	lines.append("//   func_checkpoint_end     where the player finishes")
	lines.append("//   func_split_marker       where the split timer is")
	lines.append("//   func_gate               a regulation gate")
	lines.append("//   func_hazard             a hazard volume")
	lines.append("//   func_wind               a wind volume")
	lines.append("//   func_filament           a filament anchor")
	lines.append("//   func_parcel             a parcel")
	lines.append("//   func_spawn              where something appears")
	lines.append("//")
	lines.append("// A brush says what shape it is by the material on it: floor, wall,")
	lines.append("// platform or ramp. The entity a brush is in says the same thing:")
	lines.append("// func_floor, func_wall, func_platform or func_ramp.")
	lines.append("//")
	lines.append("// One unit is %s of a metre." % _unit_text(units_per_metre))
	lines.append("")

	lines.append("{")
	lines.append("\"classname\" \"worldspawn\"")
	lines.append("// brush 0: the floor")
	lines.append("{")
	_append_box(lines, _floor_box(units_per_metre), "floor")
	lines.append("}")
	lines.append("// brush 1: the wall to the north")
	lines.append("{")
	_append_box(lines, _north_wall(units_per_metre), "wall")
	lines.append("}")
	lines.append("// brush 2: the wall to the south")
	lines.append("{")
	_append_box(lines, _south_wall(units_per_metre), "wall")
	lines.append("}")
	lines.append("// brush 3: the wall to the west")
	lines.append("{")
	_append_box(lines, _west_wall(units_per_metre), "wall")
	lines.append("}")
	lines.append("// brush 4: the wall to the east")
	lines.append("{")
	_append_box(lines, _east_wall(units_per_metre), "wall")
	lines.append("}")
	lines.append("}")
	lines.append("")

	lines.append("{")
	lines.append("\"classname\" \"func_checkpoint_start\"")
	lines.append("\"origin\" \"%s\"" % _origin_text(
		Vector3(Builder.START_POSITION.x, Builder.START_POSITION.y, Builder.START_POSITION.z),
		units_per_metre))
	lines.append("}")
	lines.append("")
	lines.append("{")
	lines.append("\"classname\" \"func_checkpoint_end\"")
	lines.append("\"origin\" \"%s\"" % _origin_text(
		Vector3(Builder.END_POSITION.x, Builder.END_POSITION.y, Builder.END_POSITION.z),
		units_per_metre))
	lines.append("}")
	lines.append("")
	lines.append("{")
	lines.append("\"classname\" \"func_split_marker\"")
	lines.append("\"origin\" \"%s\"" % _origin_text(
		Vector3(Builder.START_POSITION.x, Builder.START_POSITION.y, Builder.START_POSITION.z),
		units_per_metre))
	lines.append("}")
	lines.append("")

	var builder := Builder.new()
	var gate_ids := builder.scheduled_gate_ids(section_id)
	for index in gate_ids.size():
		var place := Vector3(-8.0 + 8.0 * float(index), 0.0, 0.0)
		lines.append("{")
		lines.append("\"classname\" \"func_gate\"")
		lines.append("\"origin\" \"%s\"" % _origin_text(place, units_per_metre))
		lines.append("}")

	return "\n".join(lines) + "\n"


## Writes the map of a section to a file.
##
## A file that is already there is never written over.
static func write(section_id: String, path: String,
		units_per_metre := DEFAULT_UNITS_PER_METRE) -> String:
	if FileAccess.file_exists(path):
		return "there is already a file at %s, so nothing was written" % path
	var directory := ProjectSettings.globalize_path(path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "the map could not be written to %s" % path
	file.store_string(build(section_id, units_per_metre))
	return ""


## The floor of the room, in map units.
static func _floor_box(units_per_metre: float) -> AABB:
	var half := ROOM_SIZE * 0.5
	return _box(
		Vector3(-half.x, -half.z, -FLOOR_THICKNESS),
		Vector3(half.x, half.z, 0.0), units_per_metre)


## The north wall of the room, in map units.
static func _north_wall(units_per_metre: float) -> AABB:
	var half := ROOM_SIZE * 0.5
	return _box(
		Vector3(-half.x - WALL_THICKNESS, half.z, 0.0),
		Vector3(half.x + WALL_THICKNESS, half.z + WALL_THICKNESS, ROOM_SIZE.y),
		units_per_metre)


## The south wall of the room, in map units.
static func _south_wall(units_per_metre: float) -> AABB:
	var half := ROOM_SIZE * 0.5
	return _box(
		Vector3(-half.x - WALL_THICKNESS, -half.z - WALL_THICKNESS, 0.0),
		Vector3(half.x + WALL_THICKNESS, -half.z, ROOM_SIZE.y),
		units_per_metre)


## The west wall of the room, in map units.
static func _west_wall(units_per_metre: float) -> AABB:
	var half := ROOM_SIZE * 0.5
	return _box(
		Vector3(-half.x - WALL_THICKNESS, -half.z, 0.0),
		Vector3(-half.x, half.z + WALL_THICKNESS, ROOM_SIZE.y),
		units_per_metre)


## The east wall of the room, in map units.
static func _east_wall(units_per_metre: float) -> AABB:
	var half := ROOM_SIZE * 0.5
	return _box(
		Vector3(half.x, -half.z, 0.0),
		Vector3(half.x + WALL_THICKNESS, half.z + WALL_THICKNESS, ROOM_SIZE.y),
		units_per_metre)


## A box in map units, from two corners in metres.
static func _box(low: Vector3, high: Vector3, units_per_metre: float) -> AABB:
	return AABB(low * units_per_metre, (high - low) * units_per_metre)


## Writes the six faces of a box.
##
## The three points of a face say where it is and which way it looks. The
## order matters: the normal of the face is the cross product of the two
## vectors that go from the first point to the other two, taken in that
## order, and the normal points away from the inside of the brush.
static func _append_box(lines: PackedStringArray, box: AABB, material: String) -> void:
	var low := box.position
	var high := box.end
	var span := box.size

	# The east wall.
	_append_face(lines, Vector3(high.x, low.y, low.z), Vector3(high.x, high.y, low.z),
		Vector3(high.x, low.y, high.z), Vector3(0.0, span.y, 0.0),
		Vector3(0.0, 0.0, span.z), material)
	# The west wall.
	_append_face(lines, Vector3(low.x, low.y, low.z), Vector3(low.x, low.y, high.z),
		Vector3(low.x, high.y, low.z), Vector3(0.0, 0.0, span.z),
		Vector3(0.0, span.y, 0.0), material)
	# The north wall.
	_append_face(lines, Vector3(low.x, high.y, low.z), Vector3(low.x, high.y, high.z),
		Vector3(high.x, high.y, low.z), Vector3(0.0, 0.0, span.z),
		Vector3(span.x, 0.0, 0.0), material)
	# The south wall.
	_append_face(lines, Vector3(low.x, low.y, low.z), Vector3(high.x, low.y, low.z),
		Vector3(low.x, low.y, high.z), Vector3(span.x, 0.0, 0.0),
		Vector3(0.0, 0.0, span.z), material)
	# The ceiling.
	_append_face(lines, Vector3(low.x, low.y, high.z), Vector3(high.x, low.y, high.z),
		Vector3(low.x, high.y, high.z), Vector3(span.x, 0.0, 0.0),
		Vector3(0.0, span.y, 0.0), material)
	# The floor.
	_append_face(lines, Vector3(low.x, low.y, low.z), Vector3(low.x, high.y, low.z),
		Vector3(high.x, low.y, low.z), Vector3(0.0, span.y, 0.0),
		Vector3(span.x, 0.0, 0.0), material)


## Writes one face of a box.
static func _append_face(lines: PackedStringArray, first: Vector3, third: Vector3,
		second: Vector3, first_edge: Vector3, second_edge: Vector3, material: String) -> void:
	var u := _texture_axis(first_edge, second_edge)
	var v := _texture_axis(second_edge, first_edge)
	lines.append("( %s ) ( %s ) ( %s ) %s [ %s 0 ] [ %s 0 ] 0 1 1" % [
		_vector_text(first), _vector_text(second), _vector_text(third),
		material, _vector_text(u), _vector_text(v)])


## The texture axis along one edge of a face.
##
## The texture is not the point of this file, so the axis only has to be a
## real direction that lies in the face.
static func _texture_axis(edge: Vector3, other: Vector3) -> Vector3:
	var axis := edge.normalized()
	if axis.length() < 0.5:
		axis = other.normalized()
	return axis


## A number as the map file writes it.
static func _number(value: float) -> String:
	var rounded := snappedf(value, 0.001)
	if is_equal_approx(rounded, roundf(rounded)):
		return str(int(roundf(rounded)))
	return str(rounded)


## A place, as the map file writes it.
static func _vector_text(value: Vector3) -> String:
	return "%s %s %s" % [_number(value.x), _number(value.y), _number(value.z)]


## A place in Godot, as a place in the map.
static func _origin_text(place: Vector3, units_per_metre: float) -> String:
	var x := place.x * units_per_metre
	var y := -place.z * units_per_metre
	var z := place.y * units_per_metre
	return "%s %s %s" % [_number(x), _number(y), _number(z)]


## What one unit is worth, in words.
static func _unit_text(units_per_metre: float) -> String:
	if is_equal_approx(units_per_metre, 32.0):
		return "one thirty-second"
	return "one %s" % str(snappedf(1.0 / units_per_metre, 0.0001))
