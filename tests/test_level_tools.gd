# WindShear — the level tools have to work
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
## The kit and the exporter are how a section gets made without editing
## code, so they have to actually work.
##
## The quiet failures are the dangerous ones. A point that writes the wrong
## place puts a gate in the wrong spot. A block that ignores its size makes
## a room the designer cannot lay out. An export that changes shape every
## run makes a file nobody can review. This suite is the alarm for all of
## them.
extends "res://tests/ws_test.gd"

## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The block of level geometry.
const KitBlock := preload("res://world/kit/ws_kit_block.gd")
## The room shell.
const KitRoom := preload("res://world/kit/ws_kit_room.gd")
## The root of a section.
const KitSection := preload("res://world/kit/ws_section.gd")
## The exporter.
const Exporter := preload("res://addons/level_tools/ws_section_exporter.gd")
## The builder that makes a new section scene.
const Builder := preload("res://addons/level_tools/ws_section_builder.gd")

## The section that is written out.
const EXAMPLE_SCENE := "res://data/sections/cP1/sP1_01.tscn"
## The data that goes with it.
const EXAMPLE_DATA := "res://data/sections/cP1/sP1_01.json"
## Where the fixture scene is written.
const FIXTURE_SCENE := "user://level_tools_fixture.tscn"
## Where a made section is written.
const MADE_SCENE := "user://level_tools_made.tscn"


func suite_name() -> String:
	return "the level tools make sections"


func run_with_scene(scene: Node) -> void:
	_test_the_kinds_are_pinned()
	_test_the_point_hides_what_it_should()
	_test_the_point_knows_where_it_is(scene)
	_test_the_block_makes_the_geometry(scene)
	_test_the_room_makes_the_shell(scene)
	_test_the_example_section_is_in_the_index()
	_test_the_export_matches_the_committed_data()
	_test_the_export_finds_the_mistakes()
	_test_the_kit_scenes_stay_readable()
	_test_the_plugin_is_there()
	_test_the_builder_makes_a_section_that_works()


## The numbers of the kinds are a file format.
##
## Godot writes the kind as a number in the scene. A kind that moves is a
## scene that silently becomes a different thing.
func _test_the_kinds_are_pinned() -> void:
	heading("the kinds keep their numbers")
	same(KitPoint.Kind.SECTION_TRIGGER, 0, "the section trigger is kind zero")
	same(KitPoint.Kind.REGULATION_GATE, 1, "the regulation gate is kind one")
	same(KitPoint.Kind.CHECKPOINT, 2, "the checkpoint is kind two")
	same(KitPoint.Kind.WIND_VOLUME, 3, "the wind volume is kind three")
	same(KitPoint.Kind.HAZARD_VOLUME, 4, "the hazard volume is kind four")
	same(KitPoint.Kind.FILAMENT_ANCHOR, 5, "the filament anchor is kind five")
	same(KitPoint.Kind.PARCEL, 6, "the parcel is kind six")
	same(KitPoint.Kind.SPAWN, 7, "the spawn is kind seven")
	same(KitPoint.Kind.SPLIT_MARKER, 8, "the split marker is kind eight")


## A point only shows the properties that mean something for it.
func _test_the_point_hides_what_it_should() -> void:
	heading("the point hides what it does not need")
	var gate := KitPoint.new()
	gate.kind = KitPoint.Kind.REGULATION_GATE
	ok(not _is_hidden(gate, "gate_state"), "a gate shows its gate state")
	ok(_is_hidden(gate, "wind_strength_mps"), "a gate hides the wind strength")
	ok(_is_hidden(gate, "hazard_damage_per_second"), "a gate hides the hazard damage")

	var wind := KitPoint.new()
	wind.kind = KitPoint.Kind.WIND_VOLUME
	ok(not _is_hidden(wind, "wind_strength_mps"), "a wind volume shows the wind strength")
	ok(_is_hidden(wind, "gate_state"), "a wind volume hides the gate state")

	var ramp := KitBlock.new()
	ramp.shape = KitBlock.Shape.RAMP
	ok(not _is_hidden(ramp, "ramp_rise"), "a ramp shows its rise")

	var floor := KitBlock.new()
	floor.shape = KitBlock.Shape.FLOOR
	ok(_is_hidden(floor, "ramp_rise"), "a floor hides the ramp rise")

	gate.free()
	wind.free()
	ramp.free()
	floor.free()


## A point knows where it sits in the section, not in the world.
##
## The section is placed in the world when it loads, so the data has to be
## relative to the section or the point ends up in the wrong place.
func _test_the_point_knows_where_it_is(scene: Node) -> void:
	heading("the point knows where it is")

	# A section that is not in the tree, because that is how the exporter
	# reads one.
	var root := Node3D.new()
	root.name = "Section"
	root.position = Vector3(100.0, 0.0, 0.0)

	var entities := Node3D.new()
	entities.name = "Entities"
	entities.position = Vector3(0.0, 0.0, 5.0)
	root.add_child(entities)

	var point := KitPoint.new()
	point.name = "Gate01"
	point.kind = KitPoint.Kind.REGULATION_GATE
	point.point_id = "P1.01.gate_01"
	point.section_id = "P1.01"
	point.position = Vector3(1.0, 2.0, 3.0)
	entities.add_child(point)

	var data := point.to_data(root)
	var place: Array = data.get("transform", {}).get("position", [])
	near(float(place[0]), 1.0, 0.001, "the point is where it is in the section")
	near(float(place[1]), 2.0, 0.001, "the point keeps its height")
	near(float(place[2]), 8.0, 0.001, "the point keeps its depth from the section")
	text(str(data.get("node", "")), "Entities/Gate01",
		"the point says where it is in the section tree")

	var alone := point.to_data()
	var alone_place: Array = alone.get("transform", {}).get("position", [])
	near(float(alone_place[0]), 1.0, 0.001,
		"the point works the same when it is given no root")
	near(float(alone_place[2]), 8.0, 0.001,
		"the point finds the section root on its own")

	point.free()
	entities.free()
	root.free()


## A block makes the geometry the numbers ask for.
func _test_the_block_makes_the_geometry(scene: Node) -> void:
	heading("the block makes the geometry")
	var block := KitBlock.new()
	block.shape = KitBlock.Shape.FLOOR
	block.size = Vector3(4.0, 2.0, 6.0)
	scene.add_child(block)

	var mesh_instance := _first_mesh(block)
	ok(mesh_instance != null, "the block makes a mesh")
	if mesh_instance != null:
		var mesh := mesh_instance.mesh as BoxMesh
		ok(mesh != null, "the mesh is a box")
		if mesh != null:
			near(mesh.size.x, 4.0, 0.001, "the box is as wide as it was told")
			near(mesh.size.y, 2.0, 0.001, "the box is as tall as it was told")
			near(mesh.size.z, 6.0, 0.001, "the box is as deep as it was told")

	var body := _first_body(block)
	ok(body != null, "the block makes a body to stand on")
	if body != null:
		var collision := body.get_child(0, true) as CollisionShape3D
		ok(collision != null, "the body has a shape")
		if collision != null:
			var shape := collision.shape as BoxShape3D
			ok(shape != null, "the shape is a box")
			if shape != null:
				near(shape.size.x, 4.0, 0.001, "the collision is as wide as the mesh")
				near(shape.size.z, 6.0, 0.001, "the collision is as deep as the mesh")

	# A piece that is not solid has no body, because the player would
	# otherwise stand on something that is only a picture.
	block.solid = false
	ok(_first_body(block) == null, "a piece with no solid has no body")

	block.free()


## A ramp climbs the height it was told to climb.
func _test_the_ramp_climbs(scene: Node) -> void:
	heading("the ramp climbs")
	var ramp := KitBlock.new()
	ramp.shape = KitBlock.Shape.RAMP
	ramp.size = Vector3(6.0, 0.5, 8.0)
	ramp.ramp_rise = 3.0
	scene.add_child(ramp)

	var mesh_instance := _first_mesh(ramp)
	ok(mesh_instance != null, "the ramp makes a mesh")
	if mesh_instance == null:
		ramp.free()
		return

	var mesh := mesh_instance.mesh as BoxMesh
	ok(mesh != null, "the ramp mesh is a box")
	if mesh == null:
		ramp.free()
		return

	var place := mesh_instance.global_transform
	var thickness := mesh.size.y
	var slope := mesh.size.z

	# The underside of the low end sits on the floor and the top face
	# climbs by exactly the rise.
	var low_bottom := place * Vector3(0.0, -thickness * 0.5, -slope * 0.5)
	var low_top := place * Vector3(0.0, thickness * 0.5, -slope * 0.5)
	var high_top := place * Vector3(0.0, thickness * 0.5, slope * 0.5)

	near(low_bottom.y, 0.0, 0.001, "the low end of the ramp sits on the floor")
	near(high_top.y - low_top.y, 3.0, 0.001, "the ramp climbs by the rise it was told")

	ramp.free()


## A room is a floor, four walls and optionally a ceiling.
func _test_the_room_makes_the_shell(scene: Node) -> void:
	heading("the room makes the shell")
	var room := KitRoom.new()
	room.room_size = Vector3(10.0, 4.0, 6.0)
	scene.add_child(room)

	same(room.get_child_count(true), 5, "the room has a floor and four walls")

	room.wall_east = false
	same(room.get_child_count(true), 4, "a wall can be taken out")

	room.ceiling = true
	same(room.get_child_count(true), 5, "a ceiling can be put in")

	room.free()


## The example section is where the campaign index says it is.
func _test_the_example_section_is_in_the_index() -> void:
	heading("the example section is in the index")
	ok(ResourceLoader.exists(EXAMPLE_SCENE), "the example section scene exists")
	ok(FileAccess.file_exists(EXAMPLE_DATA), "the example section data exists")

	var index_file := FileAccess.open("res://data/sections/index.json", FileAccess.READ)
	ok(index_file != null, "the campaign index can be read")
	if index_file == null:
		return
	var index: Variant = JSON.parse_string(index_file.get_as_text())
	ok(typeof(index) == TYPE_DICTIONARY, "the campaign index is a dictionary")
	if typeof(index) != TYPE_DICTIONARY:
		return

	var found := false
	for section in index.get("sections", []):
		if str(section.get("id", "")) == "P1.01":
			found = true
			text(str(section.get("scene_path", "")), EXAMPLE_SCENE,
				"the index points at the example section")
			break
	ok(found, "the campaign index has a P1.01")


## The data on disk is what the scene says.
func _test_the_export_matches_the_committed_data() -> void:
	heading("the export matches the committed data")
	var exporter := Exporter.new()
	ok(exporter.check(EXAMPLE_SCENE), "the example section data is up to date")

	var data := exporter.build(EXAMPLE_SCENE)
	var section: Dictionary = data.get("section", {})
	ok(exporter.problems.is_empty(), "the example section has no problems")
	same(section.get("points", []).size(), 5, "the example section has five points")
	same(section.get("gates", []).size(), 1, "the example section has one gate")

	var gates: Array = section.get("gates", [])
	if gates.size() == 1:
		text(str(gates[0].get("id", "")), "P1.01.gate_01",
			"the gate keeps the id the schedule gives it")

	# The same scene has to give the same bytes every time, or the file is
	# noise and nobody reviews it.
	var first := exporter.to_text(exporter.build(EXAMPLE_SCENE))
	var second := exporter.to_text(exporter.build(EXAMPLE_SCENE))
	ok(first == second, "the export gives the same bytes every time")


## A broken section has to say what is wrong with it.
func _test_the_export_finds_the_mistakes() -> void:
	heading("the export finds the mistakes")
	var fixture := _make_a_broken_section()
	if fixture == null:
		ok(false, "the broken fixture could be written")
		return

	var exporter := Exporter.new()
	exporter.build(fixture, "P1.01")
	var problems := exporter.problems
	ok(problems.size() >= 4, "the broken section is reported")
	ok(_has_problem_about(problems, "two points"),
		"the export says two points have the same name")
	ok(_has_problem_about(problems, "section trigger"),
		"the export says the section has the wrong number of triggers")
	ok(_has_problem_about(problems, "gate_99"),
		"the export says a gate is not in the schedule")
	ok(_has_problem_about(problems, "gate_01"),
		"the export says a scheduled gate is missing from the scene")
	ok(_has_problem_about(problems, "split_marker_id"),
		"the export says a marker does not resolve")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))


## The editor plugin is there and it is an editor plugin.
func _test_the_plugin_is_there() -> void:
	heading("the plugin is there")
	ok(FileAccess.file_exists("res://addons/level_tools/plugin.cfg"),
		"the plugin has its configuration file")
	ok(FileAccess.file_exists("res://addons/level_tools/plugin.gd"),
		"the plugin has its script")
	ok(FileAccess.file_exists("res://addons/level_tools/ws_section_exporter.gd"),
		"the plugin has its exporter")

	var plugin_script: Script = load("res://addons/level_tools/plugin.gd")
	ok(plugin_script != null, "the plugin script loads")
	if plugin_script != null:
		text(plugin_script.get_instance_base_type(), "EditorPlugin",
			"the plugin script is an editor plugin")

	ok(FileAccess.file_exists("res://world/kit/ws_section.gd"),
		"the section root has its script")
	var section_script: Script = load("res://world/kit/ws_section.gd")
	ok(section_script != null, "the section root script loads")
	if section_script != null:
		text(section_script.get_instance_base_type(), "Node3D",
			"the section root is a node in the world")


## The kit scenes hold numbers and not geometry.
##
## The mesh and the body are made when the piece loads, so they are not in
## the saved scene and the file stays readable.
func _test_the_kit_scenes_stay_readable() -> void:
	heading("the kit scenes stay readable")
	for path in ["res://world/kit/floor.tscn", "res://world/kit/platform.tscn",
			"res://world/kit/ramp.tscn", "res://world/kit/room_shell.tscn"]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			ok(false, "%s can be read" % path)
			continue
		var content := file.get_as_text()
		ok(not content.contains("[node name=\"Mesh\""),
			"%s has no saved mesh" % path)
		ok(not content.contains("[node name=\"Body\""),
			"%s has no saved body" % path)


## A section made by the builder has to pass the exporter.
##
## This is the button the designer presses first, so it has to make
## something that is already right: the trigger, the two checkpoints, the
## split marker and the gates the schedule asks for.
func _test_the_builder_makes_a_section_that_works() -> void:
	heading("the builder makes a section that works")
	var builder := Builder.new()
	var entry := _index_entry("2.01")
	ok(not entry.is_empty(), "the campaign index has a 2.01")
	var built := builder.build("2.01", MADE_SCENE, entry)
	ok(built, "the builder writes a section scene")
	if not built:
		return

	var packed: PackedScene = load(MADE_SCENE)
	ok(packed != null, "the made section loads")
	if packed == null:
		return

	var scene := packed.instantiate()
	var points: Array = []
	_collect_points(scene, points)
	ok(points.size() == 5, "the made section has a trigger, two checkpoints, a split marker and a gate")

	var exporter := Exporter.new()
	exporter.build(MADE_SCENE, "2.01")
	ok(exporter.problems.is_empty(), "the made section has no problems (%s)" % [
		", ".join(exporter.problems)])

	var data := exporter.build(MADE_SCENE, "2.01")
	var section: Dictionary = data.get("section", {})
	same(section.get("points", []).size(), 5, "the made section exports five points")
	same(section.get("gates", []).size(), 1, "the made section exports one gate")

	scene.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MADE_SCENE))


## Collects the designer-authored points in a scene.
func _collect_points(node: Node, points: Array) -> void:
	for child in node.get_children():
		if child is KitPoint:
			points.append(child)
		_collect_points(child, points)


## One entry of the campaign index.
func _index_entry(section_id: String) -> Dictionary:
	var file := FileAccess.open("res://data/sections/index.json", FileAccess.READ)
	if file == null:
		return {}
	var index: Variant = JSON.parse_string(file.get_as_text())
	if typeof(index) != TYPE_DICTIONARY:
		return {}
	for section in index.get("sections", []):
		if str(section.get("id", "")) == section_id:
			return section
	return {}


## Makes a section scene that is wrong in every way the exporter looks for.
func _make_a_broken_section() -> String:
	var root := Node3D.new()
	root.name = "Broken"

	var first := KitPoint.new()
	first.name = "SectionTrigger"
	first.kind = KitPoint.Kind.SECTION_TRIGGER
	first.point_id = "P1.01.trigger"
	first.section_id = "P1.01"
	first.start_checkpoint_id = "P1.01.start"
	first.end_checkpoint_id = "P1.01.end"
	first.split_marker_id = "P1.01.split"
	root.add_child(first)
	first.owner = root

	var second := KitPoint.new()
	second.name = "SecondTrigger"
	second.kind = KitPoint.Kind.SECTION_TRIGGER
	second.point_id = "P1.01.trigger"
	second.section_id = "P1.01"
	root.add_child(second)
	second.owner = root

	var stranger := KitPoint.new()
	stranger.name = "Stranger"
	stranger.kind = KitPoint.Kind.CHECKPOINT
	stranger.point_id = "P1.01.start"
	stranger.section_id = "9.09"
	root.add_child(stranger)
	stranger.owner = root

	var gate := KitPoint.new()
	gate.name = "RegulationGate_99"
	gate.kind = KitPoint.Kind.REGULATION_GATE
	gate.point_id = "P1.01.gate_99"
	gate.section_id = "P1.01"
	root.add_child(gate)
	gate.owner = root

	var packed := PackedScene.new()
	var packed_error := packed.pack(root)
	root.free()
	if packed_error != OK:
		return ""

	var saved := ResourceSaver.save(packed, FIXTURE_SCENE)
	if saved != OK:
		return ""
	return FIXTURE_SCENE


## Whether a property is hidden from the Inspector.
func _is_hidden(node: Object, property_name: String) -> bool:
	var property := {"name": property_name, "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT}
	node.call("_validate_property", property)
	return int(property.get("usage", 0)) & PROPERTY_USAGE_EDITOR == 0


## The first mesh a piece made.
##
## The mesh is an internal child, so it takes the flag to be found.
func _first_mesh(node: Node) -> MeshInstance3D:
	for child in node.get_children(true):
		if child is MeshInstance3D:
			return child
	return null


## The first body a piece made.
func _first_body(node: Node) -> StaticBody3D:
	for child in node.get_children(true):
		if child is StaticBody3D:
			return child
	return null


## Whether any of the problems says a thing.
func _has_problem_about(problems: PackedStringArray, words: String) -> bool:
	for problem in problems:
		if problem.contains(words):
			return true
	return false
