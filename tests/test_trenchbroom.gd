# WindShear — the TrenchBroom converter has to work
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
## The mapper draws the base of a section in TrenchBroom and the converter
## turns that map into a WindShear section.
##
## The quiet failures are the dangerous ones here. A face read with the
## wrong number of numbers puts the room in the wrong place. A brush that
## comes out a metre bigger than it went in makes a level the player cannot
## finish. A converter that writes over a scene the designer has spent an
## afternoon on is worse than no converter at all.
##
## The fixtures under `tests/fixtures/trenchbroom/` are written by hand, so
## the tests do not lean on the map writer to be right.
extends "res://tests/ws_test.gd"

## The reader of map files.
const Parser := preload("res://tools/trenchbroom/ws_map_parser.gd")
## The shape of the brushes.
const Geometry := preload("res://tools/trenchbroom/ws_map_geometry.gd")
## The converter.
const Importer := preload("res://tools/trenchbroom/ws_map_importer.gd")
## The starter map.
const Template := preload("res://tools/trenchbroom/ws_map_template.gd")
## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The block of level geometry.
const KitBlock := preload("res://world/kit/ws_kit_block.gd")
## The model the designer imported.
const KitProp := preload("res://world/kit/ws_kit_prop.gd")
## The exporter, which checks a section is sound.
const Exporter := preload("res://addons/level_tools/ws_section_exporter.gd")

## The map with one of everything in it, in the Valve format.
const VALVE_MAP := "res://tests/fixtures/trenchbroom/valve_room.map"
## The same kind of room in the older Standard format.
const STANDARD_MAP := "res://tests/fixtures/trenchbroom/standard_room.map"
## The map with a slope in it.
const WEDGE_MAP := "res://tests/fixtures/trenchbroom/wedge.map"
## The game definition TrenchBroom reads.
const GAME_DEFINITION := "res://tools/trenchbroom/game/WindShear/WindShear.fgd"
## The game configuration TrenchBroom reads.
const GAME_CONFIG := "res://tools/trenchbroom/game/WindShear/GameConfig.cfg"
## Where the generic CC0 textures live.
const TEXTURE_FOLDER := "res://tools/trenchbroom/game/WindShear/textures"
## Where their licences live.
const LICENCE_FOLDER := "res://tools/trenchbroom/game/WindShear/licenses"
## The credits for the textures.
const CREDITS := "res://tools/trenchbroom/game/WindShear/CREDITS.md"
## The section the fixtures are imported into.
const SECTION_ID := "P1.02"
## Where a made section is written for the test.
const MADE_SCENE := "user://trenchbroom_made.tscn"


func suite_name() -> String:
	return "the trenchbroom converter works"


func run() -> void:
	_test_the_parser_reads_a_valve_map()
	_test_the_parser_reads_a_standard_map()
	_test_the_parser_says_what_it_could_not_read()
	_test_the_geometry_finds_the_box()
	_test_the_geometry_points_the_normals_out()
	_test_the_geometry_finds_the_slope()
	_test_the_importer_turns_map_units_into_metres()
	_test_the_importer_makes_the_geometry()
	_test_the_importer_makes_the_points()
	_test_the_importer_reads_the_properties()
	_test_the_importer_makes_a_ramp_along_a_slope()
	_test_the_importer_leaves_the_unknown_alone()
	_test_the_importer_brings_a_model_in()
	_test_the_made_section_passes_the_exporter()
	_test_the_importer_never_writes_over_your_work()
	_test_the_template_makes_a_map_that_can_be_read()
	_test_the_template_never_writes_over_your_work()
	_test_the_game_definition_knows_the_names()
	_test_the_texture_folder_has_every_name_the_converter_reads()


## A Valve map is read the way TrenchBroom writes it.
func _test_the_parser_reads_a_valve_map() -> void:
	heading("the parser reads a valve map")
	var parsed := _parse(VALVE_MAP)
	ok(parsed["problems"].is_empty(), "the valve map is read without a problem")
	var entities: Array = parsed["entities"]
	same(entities.size(), 11, "the valve map has eleven entities")

	var world: Dictionary = entities[0]
	text(str(world["classname"]), "worldspawn", "the first entity is the world")
	same(world["brushes"].size(), 2, "the world has two brushes")
	same(world["brushes"][0]["faces"].size(), 6, "the floor has six faces")
	text(str(world["brushes"][0]["material"]), "floor_surface",
		"the brush keeps the name of its material")
	same(world["brushes"][1]["faces"].size(), 6, "the wall has six faces")

	var start: Dictionary = entities[1]
	text(str(start["classname"]), "func_checkpoint_start", "the first point is the start")
	var origin: Vector3 = start["origin"]
	near(origin.x, -384.0, 0.001, "the start is where the map says")
	near(origin.y, 0.0, 0.001, "the start keeps its north and south")
	near(origin.z, 32.0, 0.001, "the start keeps its height")

	var end: Dictionary = entities[2]
	near(float(end["angle"]), 90.0, 0.001, "the end knows which way it looks")

	var gate: Dictionary = entities[4]
	text(str(gate["properties"].get("width", "")), "256", "the gate keeps its width")
	text(str(gate["properties"].get("height", "")), "128", "the gate keeps its height")

	# The two texture axes are read as directions, and the offsets live
	# inside the brackets.
	var face: Dictionary = world["brushes"][0]["faces"][0]
	same(face["axes"].size(), 2, "a valve face has two texture axes")
	same(face["axes"][0].size(), 4, "a texture axis is four numbers")
	near(float(face["rotation"]), 0.0, 0.001, "the face keeps its rotation")
	near(float(face["scale"].x), 1.0, 0.001, "the face keeps its scale")


## The older shape of a map is read too.
func _test_the_parser_reads_a_standard_map() -> void:
	heading("the parser reads a standard map")
	var parsed := _parse(STANDARD_MAP)
	ok(parsed["problems"].is_empty(), "the standard map is read without a problem")
	var entities: Array = parsed["entities"]
	same(entities.size(), 2, "the standard map has two entities")

	var world: Dictionary = entities[0]
	same(world["brushes"].size(), 1, "the standard map has one brush")
	var face: Dictionary = world["brushes"][0]["faces"][0]
	same(face["axes"].size(), 0, "a standard face has no texture axes")
	near(float(face["offset"].x), 0.0, 0.001, "a standard face keeps its offset")
	near(float(face["scale"].y), 1.0, 0.001, "a standard face keeps its scale")

	var start: Dictionary = entities[1]
	text(str(start["classname"]), "func_checkpoint_start", "the point is read")


## A map that is broken has to say so.
func _test_the_parser_says_what_it_could_not_read() -> void:
	heading("the parser says what it could not read")
	var parser: RefCounted = Parser.new()
	var result: Dictionary = parser.parse_text("{\n\"classname\" \"worldspawn\"\n")
	ok(not result["problems"].is_empty(), "an unclosed entity is reported")
	ok(_says_about(result["problems"], "never closed"),
		"the parser says the entity was never closed")

	var empty: Dictionary = parser.parse_text("// nothing but a comment\n")
	same(empty["entities"].size(), 0, "a map with nothing in it has no entities")
	ok(empty["problems"].is_empty(), "a map with nothing in it is not a problem")

	var missing: Dictionary = parser.parse_text("{\n\"classname\"\n}\n")
	ok(not missing["problems"].is_empty(), "a property with no value is reported")


## A box brush comes out exactly as it went in.
func _test_the_geometry_finds_the_box() -> void:
	heading("the geometry finds the box")
	var parsed := _parse(VALVE_MAP)
	var world: Dictionary = parsed["entities"][0]
	var brush: Dictionary = world["brushes"][0]

	var planes := Geometry.planes(brush)
	same(planes.size(), 6, "a box has six planes")
	ok(Geometry.is_box(planes), "a box is a box")

	var box := Geometry.bounds(brush, planes)
	near(box.position.x, -256.0, 0.001, "the box starts at the west")
	near(box.position.y, -256.0, 0.001, "the box starts at the south")
	near(box.position.z, -16.0, 0.001, "the box starts below the floor")
	near(box.size.x, 512.0, 0.001, "the box is sixteen metres wide")
	near(box.size.y, 512.0, 0.001, "the box is sixteen metres deep")
	near(box.size.z, 16.0, 0.001, "the box is half a metre thick")

	# The wall is a box too, and it is not the same box.
	var wall: Dictionary = world["brushes"][1]
	var wall_planes := Geometry.planes(wall)
	ok(Geometry.is_box(wall_planes), "the wall is a box as well")
	var wall_box := Geometry.bounds(wall, wall_planes)
	near(wall_box.size.x, 16.0, 0.001, "the wall is half a metre thick")
	near(wall_box.size.z, 128.0, 0.001, "the wall is four metres tall")


## The normal of a face points away from the inside of the brush.
func _test_the_geometry_points_the_normals_out() -> void:
	heading("the geometry points the normals out")
	var parsed := _parse(VALVE_MAP)
	var world: Dictionary = parsed["entities"][0]
	var brush: Dictionary = world["brushes"][0]
	var planes := Geometry.planes(brush)

	ok(Geometry.contains(planes, Vector3(0.0, 0.0, -8.0)),
		"the middle of the brush is inside the brush")
	ok(not Geometry.contains(planes, Vector3(0.0, 0.0, 100.0)),
		"the air above the floor is not inside the brush")

	# Every normal points away from the middle.
	var middle := Vector3(0.0, 0.0, -8.0)
	for plane in planes:
		var normal: Vector3 = plane["normal"]
		var distance := float(plane["distance"])
		ok(normal.dot(middle) <= distance + 0.001,
			"every normal points out of the brush")


## A brush with one slanted face is a slope.
func _test_the_geometry_finds_the_slope() -> void:
	heading("the geometry finds the slope")
	var parsed := _parse(WEDGE_MAP)
	var world: Dictionary = parsed["entities"][0]
	var brush: Dictionary = world["brushes"][1]

	var planes := Geometry.planes(brush)
	ok(not Geometry.is_box(planes), "a wedge is not a box")
	var box := Geometry.bounds(brush, planes)
	var slope := Geometry.slope(planes, box)
	ok(not slope.is_empty(), "the wedge has a slope in it")

	near(float(slope["rise"]), 48.0, 0.01, "the slope climbs one and a half metres")
	near(float(slope["run"]), 128.0, 0.01, "the slope is four metres long")
	near(float(slope["width"]), 128.0, 0.01, "the slope is four metres wide")
	ok(bool(slope["along_x"]), "the slope runs along the east and west")
	ok(not bool(slope["uphill"]), "the slope is high at the west and low at the east")

	# The floor of the same map is not a slope.
	var floor_planes := Geometry.planes(world["brushes"][0])
	var floor_box := Geometry.bounds(world["brushes"][0], floor_planes)
	ok(Geometry.slope(floor_planes, floor_box).is_empty(),
		"a flat brush has no slope in it")


## The map is in map units and the game is in metres.
func _test_the_importer_turns_map_units_into_metres() -> void:
	heading("the importer turns map units into metres")
	var importer: RefCounted = Importer.new()
	var place: Vector3 = importer.to_godot(Vector3(32.0, 64.0, 16.0))
	near(place.x, 1.0, 0.001, "east stays east")
	near(place.y, 0.5, 0.001, "up stays up")
	near(place.z, -2.0, 0.001, "north turns to the other way round")

	# A map made for another scale says so.
	importer.units_per_metre = 16.0
	var other: Vector3 = importer.to_godot(Vector3(32.0, 0.0, 0.0))
	near(other.x, 2.0, 0.001, "the scale of the map is used")


## The brushes become the blocks of the section.
func _test_the_importer_makes_the_geometry() -> void:
	heading("the importer makes the geometry")
	var importer: RefCounted = Importer.new()
	var parsed := _parse(VALVE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return

	ok(root.get_node_or_null("Room") == null,
		"the map is the room, so the shell is not used")

	var blocks := _blocks(root)
	same(blocks.size(), 2, "the section has two blocks")
	if blocks.size() < 2:
		root.free()
		return

	var floor: Node = blocks[0]
	same(int(floor.get("shape")), KitBlock.Shape.FLOOR, "the floor is a floor")
	same(int(floor.get("palette")), KitBlock.Palette.SURFACE, "the floor wears the surface material")
	var floor_size: Vector3 = floor.get("size")
	near(floor_size.x, 16.0, 0.001, "the floor is as wide as the brush")
	near(floor_size.y, 0.5, 0.001, "the floor is as thick as the brush")
	near(floor_size.z, 16.0, 0.001, "the floor is as deep as the brush")
	var floor_place: Vector3 = floor.get("position")
	near(floor_place.x, 0.0, 0.001, "the floor is in the middle of the map")
	near(floor_place.y, -0.25, 0.001, "the floor sits below the floor line")

	var wall: Node = blocks[1]
	same(int(wall.get("shape")), KitBlock.Shape.WALL, "the wall is a wall")
	same(int(wall.get("palette")), KitBlock.Palette.CHARCOAL,
		"the wall wears the charcoal material")
	var wall_size: Vector3 = wall.get("size")
	near(wall_size.x, 0.5, 0.001, "the wall is as thick as the brush")
	near(wall_size.y, 4.0, 0.001, "the wall is as tall as the brush")
	near(wall_size.z, 16.0, 0.001, "the wall is as deep as the brush")
	var wall_place: Vector3 = wall.get("position")
	near(wall_place.x, 8.25, 0.001, "the wall is to the east")
	near(wall_place.y, 2.0, 0.001, "the wall stands on the floor")

	root.free()


## The points become the points of the section.
func _test_the_importer_makes_the_points() -> void:
	heading("the importer makes the points")
	var importer: RefCounted = Importer.new()
	var parsed := _parse(VALVE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return

	# The trigger, the two checkpoints, the split marker, the gate and the
	# five points the map holds that have no fixed id.
	same(_points(root).size(), 10, "the section has ten points")

	var start := _point_by_id(root, "P1.02.start")
	ok(start != null, "the start keeps the id the trigger points at")
	if start != null:
		var place: Vector3 = start.get("position")
		near(place.x, -12.0, 0.001, "the start is where the map says")
		near(place.y, 1.0, 0.001, "the start is at the height the map says")

	var end := _point_by_id(root, "P1.02.end")
	ok(end != null, "the end keeps the id the trigger points at")
	if end != null:
		var place: Vector3 = end.get("position")
		near(place.x, 12.0, 0.001, "the end is where the map says")

	var split := _point_by_id(root, "P1.02.split")
	ok(split != null, "the split marker keeps the id the trigger points at")

	var gate := _point_by_id(root, "P1.02.gate_01")
	ok(gate != null, "the gate keeps the id the schedule gives it")
	if gate != null:
		same(int(gate.get("kind")), KitPoint.Kind.REGULATION_GATE, "the gate is a gate")
		var place: Vector3 = gate.get("position")
		near(place.x, 4.0, 0.001, "the gate is where the map says")

	# The points that have no fixed id are numbered in the order they
	# appear in the map.
	var hazard := _point_by_id(root, "P1.02.hazard_01")
	ok(hazard != null, "the hazard is numbered")
	if hazard != null:
		same(int(hazard.get("kind")), KitPoint.Kind.HAZARD_VOLUME, "the hazard is a hazard")
		var place: Vector3 = hazard.get("position")
		near(place.z, -6.0, 0.001, "the hazard is where the map says")

	var wind := _point_by_id(root, "P1.02.wind_01")
	ok(wind != null, "the wind is numbered")
	if wind != null:
		same(int(wind.get("kind")), KitPoint.Kind.WIND_VOLUME, "the wind is a wind")

	var filament := _point_by_id(root, "P1.02.filament_01")
	ok(filament != null, "the filament is numbered")
	if filament != null:
		same(int(filament.get("kind")), KitPoint.Kind.FILAMENT_ANCHOR,
			"the filament is a filament anchor")

	var parcel := _point_by_id(root, "P1.02.parcel_01")
	ok(parcel != null, "the parcel is numbered")

	var spawn := _point_by_id(root, "P1.02.spawn_01")
	ok(spawn != null, "the spawn is numbered")

	root.free()


## The properties on a point are read into the point.
func _test_the_importer_reads_the_properties() -> void:
	heading("the importer reads the properties")
	var importer: RefCounted = Importer.new()
	var parsed := _parse(VALVE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return

	var gate := _point_by_id(root, "P1.02.gate_01")
	if gate != null:
		near(float(gate.get("gate_width")), 8.0, 0.001,
			"the width of the gate is in metres")
		near(float(gate.get("gate_height")), 4.0, 0.001,
			"the height of the gate is in metres")

	var hazard := _point_by_id(root, "P1.02.hazard_01")
	if hazard != null:
		text(str(hazard.get("hazard_kind")), "blade", "the hazard keeps its kind")
		near(float(hazard.get("hazard_damage_per_second")), 12.0, 0.001,
			"the hazard keeps its damage")

	var wind := _point_by_id(root, "P1.02.wind_01")
	if wind != null:
		text(str(wind.get("wind_kind")), "crosswind", "the wind keeps its kind")
		near(float(wind.get("wind_strength_mps")), 8.5, 0.001,
			"the wind keeps its strength")
		near(float(wind.get("wind_direction_degrees")), 270.0, 0.001,
			"the wind keeps its direction")

	var filament := _point_by_id(root, "P1.02.filament_01")
	if filament != null:
		text(str(filament.get("anchor_type")), "ring", "the filament keeps its kind")

	root.free()


## A brush with a slope becomes a ramp along that slope.
func _test_the_importer_makes_a_ramp_along_a_slope() -> void:
	heading("the importer makes a ramp along a slope")
	var importer: RefCounted = Importer.new()
	var parsed := _parse(WEDGE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return

	var blocks := _blocks(root)
	same(blocks.size(), 2, "the section has a floor and a ramp")
	if blocks.size() < 2:
		root.free()
		return

	var ramp: Node = blocks[1]
	same(int(ramp.get("shape")), KitBlock.Shape.RAMP, "the slope became a ramp")
	var size: Vector3 = ramp.get("size")
	near(size.x, 4.0, 0.001, "the ramp is as wide as the slope")
	near(size.y, 0.1, 0.001, "the ramp is a plank")
	near(size.z, 4.0, 0.001, "the ramp is as long as the slope")
	near(float(ramp.get("ramp_rise")), 1.5, 0.001, "the ramp climbs as much as the slope")

	# The surface of the ramp has to lie on the slope the mapper drew.
	# The low end of the slope is half a metre above the floor.
	var place: Vector3 = ramp.get("position")
	var angle := atan2(1.5, 4.0)
	near(place.y + 0.1 * cos(angle), 0.5, 0.001,
		"the surface of the ramp starts at the height of the slope")
	near(place.x, 3.9649, 0.01, "the low end of the ramp is at the low end of the slope")

	# The ramp climbs towards the west, because that is the way the slope
	# climbs in the map.
	var turn: Vector3 = ramp.get("rotation")
	near(turn.y, -PI * 0.5, 0.001, "the ramp climbs the way the slope climbs")

	root.free()


## An entity WindShear does not know is left out, and said.
func _test_the_importer_leaves_the_unknown_alone() -> void:
	heading("the importer leaves the unknown alone")
	var importer: RefCounted = Importer.new()
	var parsed := _parse(VALVE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return
	ok(_says_about(importer.report, "func_unknown_thing"),
		"the report says the unknown entity was left out")
	root.free()


## A model the mapper imported comes into the project with the section.
func _test_the_importer_brings_a_model_in() -> void:
	heading("the importer brings a model in")
	var model_path := "user://trenchbroom_model.obj"
	var file := FileAccess.open(model_path, FileAccess.WRITE)
	if file == null:
		ok(false, "the model fixture could be written")
		return
	file.store_string("# a very small model\nv 0 0 0\n")
	file.close()

	var map_path := "user://trenchbroom_model.map"
	var map_file := FileAccess.open(map_path, FileAccess.WRITE)
	if map_file == null:
		ok(false, "the map fixture could be written")
		return
	map_file.store_string("{\n\"classname\" \"worldspawn\"\n}\n{\n"
		+ "\"classname\" \"func_spawn\"\n\"model\" \"trenchbroom_model.obj\"\n}\n")
	map_file.close()

	var importer: RefCounted = Importer.new()
	var parsed := _parse(map_path)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID,
		map_path.get_base_dir())
	if root == null:
		ok(false, "the section is made")
		return

	var props := _props(root)
	same(props.size(), 1, "the model is in the section")
	if props.size() == 1:
		text(str(props[0].get("model_path")),
			"res://assets/models/trenchbroom_model.obj",
			"the model is copied into the project")
		ok(FileAccess.file_exists("res://assets/models/trenchbroom_model.obj"),
			"the model file is there")
	ok(_says_about(importer.report, "put the model"),
		"the report says the model was brought in")

	root.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(
		"res://assets/models/trenchbroom_model.obj"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(model_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(map_path))


## A section made from a map has to be a section the game can run.
func _test_the_made_section_passes_the_exporter() -> void:
	heading("the made section passes the exporter")
	var importer: RefCounted = Importer.new()
	var parsed := _parse(VALVE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return

	var packed := PackedScene.new()
	var packed_error := packed.pack(root)
	root.free()
	ok(packed_error == OK, "the section can be packed")
	if packed_error != OK:
		return
	ok(ResourceSaver.save(packed, MADE_SCENE) == OK, "the section can be written")

	var exporter := Exporter.new()
	exporter.build(MADE_SCENE, SECTION_ID)
	ok(exporter.problems.is_empty(), "the made section has no problems (%s)" % [
		", ".join(exporter.problems)])

	var data := exporter.build(MADE_SCENE, SECTION_ID)
	var section: Dictionary = data.get("section", {})
	same(section.get("points", []).size(), 10, "the made section exports ten points")
	same(section.get("gates", []).size(), 1, "the made section exports one gate")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(MADE_SCENE))


## The converter never writes over a scene that is already there.
func _test_the_importer_never_writes_over_your_work() -> void:
	heading("the importer never writes over your work")
	var scene_path := "res://data/sections/cP1/sP1_02.tscn"
	ok(FileAccess.file_exists(scene_path), "the demo section is there")
	var before := FileAccess.get_file_as_string(scene_path)

	var importer: RefCounted = Importer.new()
	var parsed := _parse(VALVE_MAP)
	var root: Node = importer.build_section(parsed["entities"], SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return

	var written: String = importer.write_section(root, SECTION_ID)
	root.free()
	ok(written.is_empty(), "the converter refuses to write over a scene that is there")
	ok(_says_about(importer.problems, "already a scene"),
		"the converter says why it stopped")
	ok(FileAccess.get_file_as_string(scene_path) == before,
		"the section that was there is untouched")


## The starter map has to be a map the parser can read.
func _test_the_template_makes_a_map_that_can_be_read() -> void:
	heading("the template makes a map that can be read")
	var text := Template.build(SECTION_ID)
	ok(text.contains("func_checkpoint_start"), "the template has a start")
	ok(text.contains("func_checkpoint_end"), "the template has an end")
	ok(text.contains("func_split_marker"), "the template has a split marker")
	ok(text.contains("func_gate"), "the template has the gate the schedule asks for")

	var parsed := _parse_text(text)
	ok(parsed["problems"].is_empty(), "the template is read without a problem")
	var entities: Array = parsed["entities"]
	same(entities.size(), 5, "the template has the world and four points")

	var world: Dictionary = entities[0]
	same(world["brushes"].size(), 5, "the template has a floor and four walls")

	# The room of the template is forty metres wide and twenty-four deep.
	var floor: Dictionary = world["brushes"][0]
	var planes := Geometry.planes(floor)
	var box := Geometry.bounds(floor, planes)
	ok(Geometry.is_box(planes), "the floor of the template is a box")
	near(box.size.x / 32.0, 40.0, 0.001, "the room is forty metres wide")
	near(box.size.y / 32.0, 24.0, 0.001, "the room is twenty-four metres deep")

	# And the template turns into a section the game can run.
	var importer: RefCounted = Importer.new()
	var root: Node = importer.build_section(entities, SECTION_ID)
	if root == null:
		ok(false, "the section is made")
		return
	same(_blocks(root).size(), 5, "the template makes five blocks")
	same(_points(root).size(), 5, "the template makes five points")
	root.free()


## The starter map never writes over a map that is already there.
func _test_the_template_never_writes_over_your_work() -> void:
	heading("the template never writes over your work")
	var path := "user://trenchbroom_template.map"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		ok(false, "the fixture could be written")
		return
	file.store_string("// mine\n")
	file.close()

	var problem := Template.write(SECTION_ID, path)
	ok(not problem.is_empty(), "the template refuses to write over a map that is there")
	ok(FileAccess.get_file_as_string(path).contains("mine"), "the map is untouched")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## TrenchBroom has to know the same names the converter knows.
func _test_the_game_definition_knows_the_names() -> void:
	heading("the game definition knows the names")
	ok(FileAccess.file_exists(GAME_CONFIG), "the game configuration is there")
	ok(FileAccess.file_exists(GAME_DEFINITION), "the game definition is there")
	if not FileAccess.file_exists(GAME_DEFINITION):
		return

	var definition := FileAccess.get_file_as_string(GAME_DEFINITION)
	for classname in Importer.POINT_CLASSES.keys():
		ok(definition.contains("= %s " % str(classname)),
			"the game definition has %s" % str(classname))
	for classname in Importer.SHAPE_CLASSES.keys():
		ok(definition.contains("= %s " % str(classname)),
			"the game definition has %s" % str(classname))


## The mapper picks a material from a list of pictures, so every name the
## converter reads has to be a real picture and every picture has to be free
## to use.
func _test_the_texture_folder_has_every_name_the_converter_reads() -> void:
	heading("the texture folder has every name the converter reads")
	for shape in Importer.MATERIAL_SHAPES.keys():
		for palette in Importer.MATERIAL_PALETTES.keys():
			var name := "%s_%s.png" % [str(shape), str(palette)]
			var path := "%s/%s" % [TEXTURE_FOLDER, name]
			ok(FileAccess.file_exists(path), "the texture %s is there" % name)
			var image := Image.new()
			ok(image.load(path) == OK, "the texture %s opens" % name)
			ok(image.get_width() > 0 and image.get_height() > 0,
				"the texture %s has a picture in it" % name)
		var plain := "%s.png" % str(shape)
		ok(FileAccess.file_exists("%s/%s" % [TEXTURE_FOLDER, plain]),
			"the texture %s is there" % plain)

	var files := DirAccess.get_files_at(TEXTURE_FOLDER)
	ok(files.size() >= 500, "there are a lot of textures to pick from")
	var broken := 0
	for file in files:
		if not str(file).ends_with(".png"):
			continue
		if not _is_a_picture("%s/%s" % [TEXTURE_FOLDER, file]):
			broken += 1
	same(broken, 0, "every texture in the folder is a picture")

	var config := FileAccess.get_file_as_string(GAME_CONFIG)
	ok(config.contains("\"root\": \"textures\""),
		"the game points at the texture folder")

	ok(FileAccess.file_exists(CREDITS), "the credits for the textures are there")
	var credits := FileAccess.get_file_as_string(CREDITS)
	ok(credits.contains("CC0"), "the credits say the textures are free to use")
	ok(credits.contains("Kenney"), "the credits say who made the textures")

	var licences := DirAccess.get_files_at(LICENCE_FOLDER)
	ok(licences.size() >= 4, "the licences are kept with the textures")
	for licence in licences:
		var words := FileAccess.get_file_as_string("%s/%s" % [LICENCE_FOLDER, licence])
		ok(words.contains("CC0") or words.contains("Creative Commons Zero"),
			"the licence %s says the work is free" % str(licence))


## Whether a file starts with the eight bytes that say it is a PNG.
func _is_a_picture(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var head := file.get_buffer(8)
	return head.size() == 8 and head[0] == 137 and head[1] == 80 \
		and head[2] == 78 and head[3] == 71


## Reads a map file and gives back what was read.
func _parse(path: String) -> Dictionary:
	var parser: RefCounted = Parser.new()
	return parser.parse_file(path)


## Reads a map out of a string.
func _parse_text(text: String) -> Dictionary:
	var parser: RefCounted = Parser.new()
	return parser.parse_text(text)


## The blocks of a section.
func _blocks(root: Node) -> Array:
	var result: Array = []
	for child in root.get_children():
		if child is KitBlock:
			result.append(child)
	return result


## The points of a section.
func _points(root: Node) -> Array:
	var result: Array = []
	for child in root.get_children():
		if child is KitPoint:
			result.append(child)
	return result


## The models of a section.
func _props(root: Node) -> Array:
	var result: Array = []
	for child in root.get_children():
		if child is KitProp:
			result.append(child)
	return result


## The point of a section with that id.
func _point_by_id(root: Node, point_id: String) -> Node:
	for child in root.get_children():
		if child is KitPoint and str(child.get("point_id")) == point_id:
			return child
	return null


## Whether any of the lines says a thing.
func _says_about(lines: PackedStringArray, words: String) -> bool:
	for line in lines:
		if line.contains(words):
			return true
	return false
