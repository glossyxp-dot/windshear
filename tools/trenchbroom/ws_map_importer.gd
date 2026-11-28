# WindShear — turns a TrenchBroom map into a WindShear section
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
## Reads a map made in TrenchBroom and writes the section it describes.
##
## The map is the base of the section: the floor, the walls, the platforms
## and the points the game reads. The textures are not here and they are not
## the job of this converter; they are made in Godot.
##
## The naming scheme is in [member POINT_CLASSES] and [member SHAPE_CLASSES].
## The same names are in `tools/trenchbroom/game/WindShear/WindShear.fgd`, so
## the designer picks them out of a list in TrenchBroom instead of typing
## them.
##
## The map is in map units and the game is in metres. Quake's world is
## thirty-two units to the metre, and that is the default here. A map made
## for another scale can say so with `--units-per-metre`.
class_name WSMapImporter
extends RefCounted

## The parser that reads the map.
const Parser := preload("res://tools/trenchbroom/ws_map_parser.gd")
## The shape of the brushes.
const Geometry := preload("res://tools/trenchbroom/ws_map_geometry.gd")
## The builder, which knows the ids a section needs.
const Builder := preload("res://addons/level_tools/ws_section_builder.gd")
## The exporter, which writes the data beside the scene.
const Exporter := preload("res://addons/level_tools/ws_section_exporter.gd")
## The designer-authored block.
const KitBlock := preload("res://world/kit/ws_kit_block.gd")
## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The model the designer imported.
const KitProp := preload("res://world/kit/ws_kit_prop.gd")

## The campaign index. It says which sections exist and where they live.
const INDEX_PATH := "res://data/sections/index.json"

## How many map units are in a metre.
##
## Quake's world is thirty-two units to the metre, which puts the player at
## fifty-six units tall, the same as in the game.
const DEFAULT_UNITS_PER_METRE := 32.0

## How thick a ramp made out of a slanted brush is, in metres.
##
## A slanted brush is a wedge and the kit's ramp is a plank. A thin plank
## lies along the slope of the wedge, so the surface the player walks on is
## the surface the mapper drew.
const RAMP_THICKNESS := 0.1

## The point entities a map can hold.
##
## The key is the classname the designer puts in TrenchBroom. "id" is the
## part of the point's id that is the same for every section: the start
## checkpoint is always `<section>.start`, because the trigger points at it.
const POINT_CLASSES := {
	"func_checkpoint_start": {
		"kind": KitPoint.Kind.CHECKPOINT, "id": "start", "name": "StartCheckpoint"},
	"func_checkpoint_end": {
		"kind": KitPoint.Kind.CHECKPOINT, "id": "end", "name": "EndCheckpoint"},
	"func_split_marker": {
		"kind": KitPoint.Kind.SPLIT_MARKER, "id": "split", "name": "SplitMarker"},
	"func_gate": {
		"kind": KitPoint.Kind.REGULATION_GATE, "id": "gate", "name": "RegulationGate"},
	"func_hazard": {
		"kind": KitPoint.Kind.HAZARD_VOLUME, "id": "hazard", "name": "HazardVolume"},
	"func_wind": {
		"kind": KitPoint.Kind.WIND_VOLUME, "id": "wind", "name": "WindVolume"},
	"func_filament": {
		"kind": KitPoint.Kind.FILAMENT_ANCHOR, "id": "filament", "name": "FilamentAnchor"},
	"func_parcel": {
		"kind": KitPoint.Kind.PARCEL, "id": "parcel", "name": "Parcel"},
	"func_spawn": {
		"kind": KitPoint.Kind.SPAWN, "id": "spawn", "name": "Spawn"},
	"info_player_start": {
		"kind": KitPoint.Kind.SPAWN, "id": "spawn", "name": "Spawn"},
}

## The brush entities that say what shape the brush is.
const SHAPE_CLASSES := {
	"func_floor": KitBlock.Shape.FLOOR,
	"func_wall": KitBlock.Shape.WALL,
	"func_platform": KitBlock.Shape.PLATFORM,
	"func_ramp": KitBlock.Shape.RAMP,
}

## The material names that say what shape the brush is.
##
## The name is looked for inside the material name, so `wall_stone` is a
## wall.
const MATERIAL_SHAPES := {
	"floor": KitBlock.Shape.FLOOR,
	"wall": KitBlock.Shape.WALL,
	"platform": KitBlock.Shape.PLATFORM,
	"ramp": KitBlock.Shape.RAMP,
}

## The material names that say which of the four materials the brush wears.
const MATERIAL_PALETTES := {
	"surface": KitBlock.Palette.SURFACE,
	"deep": KitBlock.Palette.DEEP,
	"charcoal": KitBlock.Palette.CHARCOAL,
	"glow": KitBlock.Palette.GLOW,
}

## How many map units are in a metre.
var units_per_metre := DEFAULT_UNITS_PER_METRE

## Where the map was read from, so a model next to it can be found.
var map_directory := ""

## What the import did, one line per thing.
var report: PackedStringArray = []

## What stopped the import.
var problems: PackedStringArray = []


## Reads a map and writes the section it describes.
##
## The section is only written when there is no scene there yet, unless the
## caller says otherwise. The designer's work is never thrown away by a
## button.
func import_map(map_path: String, section_id: String, overwrite := false) -> bool:
	report = PackedStringArray()
	problems = PackedStringArray()

	var parser: RefCounted = Parser.new()
	var parsed: Dictionary = parser.parse_file(map_path)
	for problem in parsed[Parser.RESULT_KEY_PROBLEMS]:
		problems.append(str(problem))

	map_directory = map_path.get_base_dir()

	var entities: Array = parsed[Parser.RESULT_KEY_ENTITIES]
	if entities.is_empty():
		if problems.is_empty():
			problems.append("the map has no entities in it")
		return false

	var root := build_section(entities, section_id)
	if not problems.is_empty():
		root.free()
		return false

	var scene_path := write_section(root, section_id, overwrite)
	# The section is packed into the scene file, so the node it was made
	# from is not needed any more.
	root.free()
	if scene_path.is_empty():
		return false

	var exporter := Exporter.new()
	if not exporter.write(scene_path, section_id):
		for problem in exporter.problems:
			problems.append(str(problem))
		return false
	report.append("wrote %s" % Exporter.output_path(scene_path))
	return true


## Builds the section in memory, without writing anything.
##
## This is what the tests use, and what the importer writes when it is
## called. The caller owns the node and frees it.
##
## The map directory is where the map came from, so a model next to it can
## be found. It is empty when the map has no models in it.
func build_section(entities: Array, section_id: String, from_directory := "") -> Node:
	if not from_directory.is_empty():
		map_directory = from_directory

	var builder := Builder.new()
	var entry := section_entry(section_id)
	var root: Node = builder.make(section_id, entry)

	# The map is the room. The shell the builder makes is not used, because
	# the map has its own floor and its own walls.
	var room := root.get_node_or_null("Room")
	if room != null:
		root.remove_child(room)
		room.free()

	var blocks := 0
	var points := 0
	var gate_number := 0
	var counters := {}

	for entity in entities:
		var classname := str(entity.get("classname", ""))
		var brushes: Array = entity.get("brushes", [])

		if classname in POINT_CLASSES:
			points += 1
			_add_the_point(root, entity, classname, section_id, gate_number, counters)
			if classname == "func_gate":
				gate_number += 1
		elif not classname.is_empty() and classname != "worldspawn":
			report.append("skipped the entity %s, there is no WindShear kind for it" % classname)

		if str(entity.get("properties", {}).get("model", "")) != "":
			_add_the_model(root, entity)

		for brush in brushes:
			blocks += 1
			_add_the_block(root, brush, classname)

	report.append("the map has %d blocks and %d points" % [blocks, points])
	return root


## Adds a model to the section.
##
## The model file is copied into the project, so the section keeps working
## on another machine. A model that cannot be found is left out and the
## report says so.
func _add_the_model(root: Node, entity: Dictionary) -> void:
	var properties: Dictionary = entity.get("properties", {})
	var wanted := str(properties.get("model", ""))

	var source := wanted
	if not source.is_absolute_path():
		source = map_directory.path_join(wanted)
	if not FileAccess.file_exists(source):
		report.append("skipped the model %s, there is no such file" % wanted)
		return

	var target := _copy_the_model(source)
	if target.is_empty():
		report.append("skipped the model %s, it could not be copied into the project" % wanted)
		return

	var prop: Node = KitProp.new()
	prop.name = _unique_name(root, "Model")
	prop.set("model_path", target)
	var origin: Vector3 = entity.get("origin", Vector3.ZERO)
	prop.set("position", to_godot(origin))
	root.add_child(prop)
	prop.owner = root
	report.append("put the model %s into the section" % wanted)


## Copies a model into the project and returns its new path.
func _copy_the_model(source: String) -> String:
	var directory := "res://assets/models/"
	if not DirAccess.dir_exists_absolute(directory):
		if DirAccess.make_dir_recursive_absolute(directory) != OK:
			return ""
	var target := directory + source.get_file()
	var reader := FileAccess.open(source, FileAccess.READ)
	if reader == null:
		return ""
	var writer := FileAccess.open(target, FileAccess.WRITE)
	if writer == null:
		return ""
	writer.store_buffer(reader.get_buffer(reader.get_length()))
	return target


## Adds one point to the section.
##
## The start, the end and the split are already in the section, because the
## trigger points at them. The map says where they are, so they are moved
## and not made again. The gates are the same: the schedule says which
## gates a section has, and the map says where they stand.
func _add_the_point(root: Node, entity: Dictionary, classname: String,
		section_id: String, gate_number: int, counters: Dictionary) -> void:
	var entry: Dictionary = POINT_CLASSES[classname]
	var kind := int(entry["kind"])
	var tool_id := str(entry["id"])

	var point_id := ""
	var node: Node = null

	if kind == KitPoint.Kind.REGULATION_GATE:
		var gate_ids := _scheduled_gate_ids(section_id)
		if gate_number >= gate_ids.size():
			report.append("skipped a gate, the schedule has only %d for this section" % gate_ids.size())
			return
		point_id = gate_ids[gate_number]
		node = _find_point_by_id(root, point_id)
		if node == null:
			report.append("the schedule has a gate called %s and the section does not" % point_id)
			return
	elif tool_id == "start" or tool_id == "end" or tool_id == "split":
		point_id = "%s.%s" % [section_id, tool_id]
		node = _find_point_by_id(root, point_id)
		if node == null:
			node = _make_a_point(root, kind, point_id, section_id, str(entry["name"]))
	else:
		point_id = _point_id_for(root, section_id, tool_id, counters)
		node = _make_a_point(root, kind, point_id, section_id, str(entry["name"]))

	var origin: Vector3 = entity.get("origin", Vector3.ZERO)
	node.set("position", to_godot(origin))
	node.set("rotation", Vector3(0.0, deg_to_rad(float(entity.get("angle", 0.0)) - 90.0), 0.0))
	_read_the_properties(entity, node)


## The id a point of this kind gets.
##
## The start, the end and the split have fixed ids, because the trigger
## points at them. The rest are numbered in the order they appear.
func _point_id_for(root: Node, section_id: String, tool_id: String,
		counters: Dictionary) -> String:
	var number := int(counters.get(tool_id, 0)) + 1
	counters[tool_id] = number
	return "%s.%s_%02d" % [section_id, tool_id, number]


## Makes a point and gives it to the section.
func _make_a_point(root: Node, kind: int, point_id: String, section_id: String,
		node_name: String) -> Node:
	var point: Node = KitPoint.new()
	point.name = _unique_name(root, node_name)
	point.set("kind", kind)
	point.set("point_id", point_id)
	point.set("section_id", section_id)
	root.add_child(point)
	point.owner = root
	return point


## Reads the properties the designer set on the entity.
##
## Every property the importer does not know about is left alone, so a
## property the designer added for their own reasons does not stop the
## import.
func _read_the_properties(entity: Dictionary, node: Node) -> void:
	var properties: Dictionary = entity.get("properties", {})

	var width := str(properties.get("width", ""))
	if not width.is_empty() and "gate_width" in node:
		node.set("gate_width", float(width) / units_per_metre)

	var height := str(properties.get("height", ""))
	if not height.is_empty() and "gate_height" in node:
		node.set("gate_height", float(height) / units_per_metre)

	var hazard_kind := str(properties.get("hazkind", ""))
	if not hazard_kind.is_empty() and "hazard_kind" in node:
		node.set("hazard_kind", hazard_kind)

	var damage := str(properties.get("damage", ""))
	if not damage.is_empty() and "hazard_damage_per_second" in node:
		node.set("hazard_damage_per_second", float(damage))

	var wind_kind := str(properties.get("windkind", ""))
	if not wind_kind.is_empty() and "wind_kind" in node:
		node.set("wind_kind", wind_kind)

	var strength := str(properties.get("strength", ""))
	if not strength.is_empty() and "wind_strength_mps" in node:
		node.set("wind_strength_mps", float(strength))

	var direction := str(properties.get("direction", ""))
	if not direction.is_empty() and "wind_direction_degrees" in node:
		node.set("wind_direction_degrees", float(direction))

	var anchor_type := str(properties.get("anchortype", ""))
	if not anchor_type.is_empty() and "anchor_type" in node:
		node.set("anchor_type", anchor_type)


## Adds one brush to the section, as a block.
##
## A brush that is a plain box becomes a block of exactly that size. A
## brush with a slope becomes a ramp along that slope. Anything else
## becomes the box around it, and the report says so.
func _add_the_block(root: Node, brush: Dictionary, classname: String) -> void:
	var planes := Geometry.planes(brush)
	if planes.size() < 4:
		report.append("skipped a brush, it has only %d faces" % planes.size())
		return

	var box := Geometry.bounds(brush, planes)
	# The map has the floor in Z and the sky in Y. Godot has them the other
	# way round, so the size is turned as well as the place.
	var size := Vector3(box.size.x, box.size.z, box.size.y) / units_per_metre
	if size.x < 0.001 or size.y < 0.001 or size.z < 0.001:
		report.append("skipped a brush, it has no size")
		return

	var block: Node = KitBlock.new()
	block.name = _unique_name(root, "Block")
	block.set("shape", _shape_for(brush, classname))
	block.set("palette", _palette_for(brush))
	root.add_child(block)
	block.owner = root

	if Geometry.is_box(planes):
		block.set("size", size)
		block.set("position", to_godot(box.get_center()))
		return

	var slope := Geometry.slope(planes, box)
	if not slope.is_empty():
		_place_a_ramp(block, box, slope)
		report.append("a brush with a slope became a ramp, and the ramp is a plank along it")
		return

	block.set("size", size)
	block.set("position", to_godot(box.get_center()))
	report.append("a brush that is not a box became the box around it")


## Puts a ramp along a slope.
##
## The ramp's surface lies along the slope, so the surface the player walks
## on is the surface the mapper drew. The ramp is a plank and the brush was
## a wedge, so the plank is thinner than the wedge at the low end.
##
## The slope is in map units, where Z is up. The ramp is a Godot node, so
## the corner is turned on the way out.
func _place_a_ramp(block: Node, box: AABB, slope: Dictionary) -> void:
	var run := float(slope["run"]) / units_per_metre
	var rise := float(slope["rise"]) / units_per_metre
	var width := float(slope["width"]) / units_per_metre
	var uphill: bool = bool(slope["uphill"])
	var along_x := bool(slope["along_x"])

	var centre := box.get_center()
	var uphill_map := Vector3.ZERO
	var low_corner := Vector3.ZERO
	if along_x:
		uphill_map = Vector3(1.0 if uphill else -1.0, 0.0, 0.0)
		low_corner = Vector3(
			box.position.x if uphill else box.end.x,
			centre.y,
			box.position.z)
	else:
		uphill_map = Vector3(0.0, 1.0 if uphill else -1.0, 0.0)
		low_corner = Vector3(
			centre.x,
			box.position.y if uphill else box.end.y,
			box.position.z)

	var thickness := RAMP_THICKNESS
	var slope_length := sqrt(run * run + rise * rise)
	var cosine := 1.0 if slope_length <= 0.0 else run / slope_length
	var sine := 0.0 if slope_length <= 0.0 else rise / slope_length

	# The plank's own origin is the underside of its low end. The surface
	# has to lie on the slope, so the plank sits a little lower and a
	# little further up the slope than the corner of the brush. The
	# corner is in map units, so the offset is too.
	#
	# The top of the slope is not always at the bottom of the brush: a
	# wedge can have a wall at its low end. The height of the slope above
	# the bottom of the brush is the part that has to be added.
	var top_above_bottom := float(slope["low"]) - box.position.z
	var thickness_map := thickness * units_per_metre
	var corner := low_corner \
		+ Vector3(0.0, 0.0, top_above_bottom) \
		+ uphill_map * (thickness_map * sine) \
		+ Vector3(0.0, 0.0, -thickness_map * cosine)

	# The ramp climbs towards its own Z, so the node turns to face the way
	# the slope climbs. North in the map is the other way round in Godot.
	var uphill_godot := Vector3(uphill_map.x, 0.0, -uphill_map.y)

	block.set("shape", KitBlock.Shape.RAMP)
	block.set("size", Vector3(width, thickness, run))
	block.set("ramp_rise", rise)
	block.set("position", to_godot(corner))
	block.set("rotation", Vector3(0.0, atan2(uphill_godot.x, uphill_godot.z), 0.0))


## The shape a brush is, from the entity it is in or the material on it.
func _shape_for(brush: Dictionary, classname: String) -> int:
	if classname in SHAPE_CLASSES:
		return int(SHAPE_CLASSES[classname])
	var material := str(brush.get("material", "")).to_lower()
	for name in MATERIAL_SHAPES.keys():
		if material.contains(str(name)):
			return int(MATERIAL_SHAPES[name])
	return KitBlock.Shape.FLOOR


## The material a brush wears, from the name on its faces.
func _palette_for(brush: Dictionary) -> int:
	var material := str(brush.get("material", "")).to_lower()
	for name in MATERIAL_PALETTES.keys():
		if material.contains(str(name)):
			return int(MATERIAL_PALETTES[name])
	return KitBlock.Palette.SURFACE


## Writes the section to its scene file.
##
## Returns the path it wrote, or an empty string when it did not.
func write_section(root: Node, section_id: String, overwrite := false) -> String:
	var scene_path := scene_path_for(section_id)
	if scene_path.is_empty():
		problems.append("the campaign index has no section called %s" % section_id)
		return ""
	if FileAccess.file_exists(scene_path) and not overwrite:
		problems.append("there is already a scene at %s, so nothing was written" % scene_path)
		return ""

	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		problems.append("the section scene could not be built")
		return ""
	var directory := ProjectSettings.globalize_path(scene_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(directory)
	if ResourceSaver.save(packed, scene_path) != OK:
		problems.append("the section scene could not be written")
		return ""
	report.append("wrote %s" % scene_path)
	return scene_path


## A place in the map, in metres, the way Godot has it.
##
## Quake has the floor in Z and the sky in Y. Godot has the floor in Y and
## the sky in Z, and north is the other way round.
func to_godot(point: Vector3) -> Vector3:
	return Vector3(
		point.x / units_per_metre,
		point.z / units_per_metre,
		-point.y / units_per_metre)


## The path the scene of a section lives at.
func scene_path_for(section_id: String) -> String:
	var entry := section_entry(section_id)
	return str(entry.get("scene_path", ""))


## The entry of a section in the campaign index.
func section_entry(section_id: String) -> Dictionary:
	for section in _index().get("sections", []):
		if str(section.get("id", "")) == section_id:
			return section
	return {}


## The gates the schedule has for a section.
func _scheduled_gate_ids(section_id: String) -> PackedStringArray:
	var ids := PackedStringArray()
	var builder := Builder.new()
	return builder.scheduled_gate_ids(section_id)


## The point in a section with that id.
func _find_point_by_id(root: Node, point_id: String) -> Node:
	for child in root.get_children():
		if child is KitPoint and str(child.get("point_id")) == point_id:
			return child
	return null


## A name nothing else in the section is using.
func _unique_name(root: Node, name: String) -> String:
	var candidate := name
	var number := 1
	while root.has_node(NodePath(candidate)):
		number += 1
		candidate = "%s%d" % [name, number]
	return candidate


## The campaign index.
func _index() -> Dictionary:
	if not FileAccess.file_exists(INDEX_PATH):
		return {}
	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
